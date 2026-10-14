import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:logger/logger.dart';
import 'tables/connections_table.dart';
import 'tables/folders_table.dart';
import 'tables/favorites_table.dart';
import 'tables/favorite_folders_table.dart';
import 'tables/favorite_folder_assignments_table.dart';
import 'tables/cache_tables.dart';
import 'tables/synoptics_table.dart';
import 'tables/synoptic_bindings_table.dart';
import 'tables/dashboard_tables.dart';

part 'app_database.g.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

/// Returns true if a cache entry written at [cachedAt] is younger than [maxAge].
bool isCacheFresh(DateTime cachedAt, Duration maxAge, {DateTime? now}) {
  return (now ?? DateTime.now()).difference(cachedAt) < maxAge;
}

/// Base de données principale de l'application
@DriftDatabase(tables: [
  Folders,
  Connections,
  Favorites,
  FavoriteFolders,
  FavoriteFolderAssignments,
  CachedPoints,
  CachedDeviceInfo,
  CachedTrendLogMapping,
  CachedObjectsSummary,
  Synoptics,
  SynopticBindings,
  Dashboards,
  DashboardWidgets,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // Migration de v1 à v2 : ajout de la table folders et colonne folderId
            await m.createTable(folders);
            await m.addColumn(connections, connections.folderId);
          }
          if (from < 3) {
            // Migration de v2 à v3 : ajout de la table favorites
            await m.createTable(favorites);
          }
          if (from < 4) {
            // Migration de v3 à v4 : ajout des tables de cache
            await m.createTable(cachedPoints);
            await m.createTable(cachedDeviceInfo);
            await m.createTable(cachedTrendLogMapping);
            await m.createTable(cachedObjectsSummary);
          }
          if (from < 5) {
            // Migration de v4 à v5 : ajout de isSuperFavorite aux favoris
            await m.addColumn(favorites, favorites.isSuperFavorite);
          }
          if (from < 6) {
            // Migration de v5 à v6 : ajout de wasPromoted pour le cycle de favoris
            await m.addColumn(favorites, favorites.wasPromoted);
          }
          if (from < 7) {
            // Migration de v6 à v7 : ajout des dossiers de favoris
            await m.createTable(favoriteFolders);
            await m.createTable(favoriteFolderAssignments);
          }
          if (from < 8) {
            // Migration de v7 à v8 : ajout des synoptiques
            await m.createTable(synoptics);
            await m.createTable(synopticBindings);
          }
          if (from < 9) {
            // Migration de v8 à v9 : ajout du support BACnet natif
            await m.addColumn(connections, connections.connectionType);
            await m.addColumn(connections, connections.bacnetDeviceId);
          }
          if (from < 10) {
            // Migration de v9 à v10 : ajout du modèle de l'automate
            await m.addColumn(connections, connections.modelName);
          }
          if (from < 11) {
            // Migration de v10 à v11 : ajout des dashboards
            await m.createTable(dashboards);
            await m.createTable(dashboardWidgets);
          }
          if (from < 12) {
            // Migration de v11 à v12 : ajout de designerUrl pour Envysion
            await m.addColumn(connections, connections.designerUrl);
          }
          if (from < 13) {
            // Migration de v12 à v13 : index secondaires sur les colonnes de jointure
            // (purely additive, existing data is untouched)
            await m.createIndex(idxFavoriteFolderAssignmentsFolderId);
            await m.createIndex(idxDashboardsConnectionId);
            await m.createIndex(idxDashboardWidgetsDashboardId);
            await m.createIndex(idxSynopticsConnectionId);
          }
        },
        beforeOpen: (details) async {
          // Cache maintenance: drop expired cache rows so they don't stay forever.
          // Never block opening the database on this.
          try {
            await clearExpiredCache();
          } catch (e) {
            _logger.w('clearExpiredCache on open failed: $e');
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'mydumcontrol.db');
  }

  // === Opérations CRUD pour les connexions ===

  /// Récupère toutes les connexions
  Future<List<Connection>> getAllConnections() => select(connections).get();

  /// Stream de toutes les connexions (pour écouter les changements)
  Stream<List<Connection>> watchAllConnections() => select(connections).watch();

  /// Récupère une connexion par son ID
  Future<Connection?> getConnectionById(int id) {
    return (select(connections)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insère une nouvelle connexion et retourne son ID
  Future<int> insertConnection(ConnectionsCompanion connection) {
    return into(connections).insert(connection);
  }

  /// Met à jour une connexion existante
  Future<bool> updateConnection(Connection connection) {
    return update(connections).replace(connection);
  }

  /// Supprime une connexion par son ID, ainsi que toutes ses données liées
  /// (favoris, dossiers de favoris, caches, dashboards, synoptiques spécifiques).
  Future<int> deleteConnectionById(int id) => deleteConnectionCascade(id);

  /// Deletes a connection and every row that references it, in one transaction.
  ///
  /// Foreign keys are not enforced (no PRAGMA foreign_keys), so the cascade is
  /// done explicitly. Returns the number of deleted connection rows (0 or 1).
  Future<int> deleteConnectionCascade(int id) {
    return transaction(() async {
      final favoriteIds = selectOnly(favorites)
        ..addColumns([favorites.id])
        ..where(favorites.connectionId.equals(id));
      final folderIds = selectOnly(favoriteFolders)
        ..addColumns([favoriteFolders.id])
        ..where(favoriteFolders.connectionId.equals(id));
      await (delete(favoriteFolderAssignments)
            ..where((a) =>
                a.favoriteId.isInQuery(favoriteIds) |
                a.folderId.isInQuery(folderIds)))
          .go();
      await (delete(favorites)..where((f) => f.connectionId.equals(id))).go();
      await (delete(favoriteFolders)..where((f) => f.connectionId.equals(id)))
          .go();

      await _clearAllCacheRows(id);

      final dashboardIds = selectOnly(dashboards)
        ..addColumns([dashboards.id])
        ..where(dashboards.connectionId.equals(id));
      await (delete(dashboardWidgets)
            ..where((w) => w.dashboardId.isInQuery(dashboardIds)))
          .go();
      await (delete(dashboards)..where((d) => d.connectionId.equals(id))).go();

      final synopticIds = selectOnly(synoptics)
        ..addColumns([synoptics.id])
        ..where(synoptics.connectionId.equals(id));
      await (delete(synopticBindings)
            ..where((b) => b.synopticId.isInQuery(synopticIds)))
          .go();
      await (delete(synoptics)..where((s) => s.connectionId.equals(id))).go();

      return (delete(connections)..where((c) => c.id.equals(id))).go();
    });
  }

  /// Met à jour la date de dernière connexion
  Future<void> updateLastConnectedAt(int id) {
    return (update(connections)..where((c) => c.id.equals(id))).write(
      ConnectionsCompanion(
        lastConnectedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Met à jour la version de l'API détectée
  Future<void> updateApiVersion(int id, String version) {
    return (update(connections)..where((c) => c.id.equals(id))).write(
      ConnectionsCompanion(
        apiVersion: Value(version),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Met à jour le modèle de l'automate
  Future<void> updateModelName(int id, String modelName) {
    return (update(connections)..where((c) => c.id.equals(id))).write(
      ConnectionsCompanion(
        modelName: Value(modelName),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Met à jour l'empreinte du certificat
  Future<void> updateCertificateFingerprint(int id, String fingerprint) {
    return (update(connections)..where((c) => c.id.equals(id))).write(
      ConnectionsCompanion(
        certificateFingerprint: Value(fingerprint),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Met à jour le dossier d'une connexion
  Future<void> updateConnectionFolder(int connectionId, int? folderId) {
    return (update(connections)..where((c) => c.id.equals(connectionId))).write(
      ConnectionsCompanion(
        folderId: Value(folderId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Récupère les connexions d'un dossier (null = racine)
  Future<List<Connection>> getConnectionsByFolder(int? folderId) {
    if (folderId == null) {
      return (select(connections)..where((c) => c.folderId.isNull())).get();
    }
    return (select(connections)..where((c) => c.folderId.equals(folderId))).get();
  }

  /// Stream des connexions d'un dossier
  Stream<List<Connection>> watchConnectionsByFolder(int? folderId) {
    if (folderId == null) {
      return (select(connections)..where((c) => c.folderId.isNull())).watch();
    }
    return (select(connections)..where((c) => c.folderId.equals(folderId))).watch();
  }

  // === Opérations CRUD pour les dossiers ===

  /// Récupère tous les dossiers triés par ordre
  Future<List<Folder>> getAllFolders() {
    return (select(folders)..orderBy([(f) => OrderingTerm.asc(f.sortOrder)])).get();
  }

  /// Stream de tous les dossiers
  Stream<List<Folder>> watchAllFolders() {
    return (select(folders)..orderBy([(f) => OrderingTerm.asc(f.sortOrder)])).watch();
  }

  /// Récupère un dossier par son ID
  Future<Folder?> getFolderById(int id) {
    return (select(folders)..where((f) => f.id.equals(id))).getSingleOrNull();
  }

  /// Insère un nouveau dossier et retourne son ID
  Future<int> insertFolder(FoldersCompanion folder) {
    return into(folders).insert(folder);
  }

  /// Met à jour un dossier existant
  Future<bool> updateFolder(Folder folder) {
    return update(folders).replace(folder);
  }

  /// Supprime un dossier par son ID (les connexions du dossier passent à la racine)
  Future<void> deleteFolderById(int id) async {
    await transaction(() async {
      // D'abord, déplacer toutes les connexions du dossier vers la racine
      await (update(connections)..where((c) => c.folderId.equals(id))).write(
        const ConnectionsCompanion(folderId: Value(null)),
      );
      // Ensuite, supprimer le dossier
      await (delete(folders)..where((f) => f.id.equals(id))).go();
    });
  }

  /// Met à jour l'ordre des dossiers
  Future<void> updateFolderOrder(int id, int newOrder) {
    return (update(folders)..where((f) => f.id.equals(id))).write(
      FoldersCompanion(sortOrder: Value(newOrder)),
    );
  }

  /// Récupère le prochain ordre de tri disponible
  Future<int> getNextFolderSortOrder() async {
    final result = await customSelect(
      'SELECT MAX(sort_order) as max_order FROM folders',
    ).getSingleOrNull();
    final maxOrder = result?.read<int?>('max_order') ?? -1;
    return maxOrder + 1;
  }

  // === Opérations CRUD pour les favoris ===

  /// Récupère tous les favoris d'une connexion, triés par ordre
  Future<List<Favorite>> getFavoritesByConnection(int connectionId) {
    return (select(favorites)
          ..where((f) => f.connectionId.equals(connectionId))
          ..orderBy([(f) => OrderingTerm.asc(f.sortOrder)]))
        .get();
  }

  /// Stream des favoris d'une connexion (pour écouter les changements)
  Stream<List<Favorite>> watchFavoritesByConnection(int connectionId) {
    return (select(favorites)
          ..where((f) => f.connectionId.equals(connectionId))
          ..orderBy([(f) => OrderingTerm.asc(f.sortOrder)]))
        .watch();
  }

  /// Vérifie si un point est dans les favoris
  Future<bool> isFavorite(int connectionId, String pointRef) async {
    final result = await (select(favorites)
          ..where((f) =>
              f.connectionId.equals(connectionId) & f.pointRef.equals(pointRef)))
        .getSingleOrNull();
    return result != null;
  }

  /// Stream pour savoir si un point est favori
  Stream<bool> watchIsFavorite(int connectionId, String pointRef) {
    return (select(favorites)
          ..where((f) =>
              f.connectionId.equals(connectionId) & f.pointRef.equals(pointRef)))
        .watchSingleOrNull()
        .map((f) => f != null);
  }

  /// Ajoute un point aux favoris
  Future<int> addFavorite(FavoritesCompanion favorite) {
    return transaction(() async {
      // Récupérer le prochain ordre de tri
      final nextOrder =
          await getNextFavoriteSortOrder(favorite.connectionId.value);
      return into(favorites).insert(
        favorite.copyWith(sortOrder: Value(nextOrder)),
      );
    });
  }

  /// Supprime un favori par son ID (et ses assignations de dossiers)
  Future<int> deleteFavoriteById(int id) {
    return transaction(() async {
      await (delete(favoriteFolderAssignments)
            ..where((a) => a.favoriteId.equals(id)))
          .go();
      return (delete(favorites)..where((f) => f.id.equals(id))).go();
    });
  }

  /// Supprime un favori par connexion et référence de point
  /// (et ses assignations de dossiers)
  Future<int> deleteFavorite(int connectionId, String pointRef) {
    return transaction(() async {
      final ids = selectOnly(favorites)
        ..addColumns([favorites.id])
        ..where(favorites.connectionId.equals(connectionId) &
            favorites.pointRef.equals(pointRef));
      await (delete(favoriteFolderAssignments)
            ..where((a) => a.favoriteId.isInQuery(ids)))
          .go();
      return (delete(favorites)
            ..where((f) =>
                f.connectionId.equals(connectionId) &
                f.pointRef.equals(pointRef)))
          .go();
    });
  }

  /// Toggle un favori (ajoute ou supprime)
  Future<bool> toggleFavorite({
    required int connectionId,
    required String pointRef,
    required String pointName,
    String? pointDescription,
    required String objectType,
  }) {
    // Read-then-write inside a transaction so concurrent toggles are serialized
    return transaction(() async {
      final existing = await (select(favorites)
            ..where((f) =>
                f.connectionId.equals(connectionId) &
                f.pointRef.equals(pointRef)))
          .getSingleOrNull();

      if (existing != null) {
        await deleteFavoriteById(existing.id);
        return false; // N'est plus favori
      } else {
        await addFavorite(FavoritesCompanion.insert(
          connectionId: connectionId,
          pointRef: pointRef,
          pointName: pointName,
          pointDescription: Value(pointDescription),
          objectType: objectType,
        ));
        return true; // Est maintenant favori
      }
    });
  }

  /// Supprime tous les favoris d'une connexion (et leurs assignations)
  Future<int> deleteAllFavoritesByConnection(int connectionId) {
    return transaction(() async {
      final ids = selectOnly(favorites)
        ..addColumns([favorites.id])
        ..where(favorites.connectionId.equals(connectionId));
      await (delete(favoriteFolderAssignments)
            ..where((a) => a.favoriteId.isInQuery(ids)))
          .go();
      return (delete(favorites)
            ..where((f) => f.connectionId.equals(connectionId)))
          .go();
    });
  }

  /// Met à jour l'ordre d'un favori
  Future<void> updateFavoriteOrder(int id, int newOrder) {
    return (update(favorites)..where((f) => f.id.equals(id))).write(
      FavoritesCompanion(sortOrder: Value(newOrder)),
    );
  }

  /// Réorganise les favoris (après drag & drop)
  Future<void> reorderFavorites(int connectionId, List<int> favoriteIds) async {
    await transaction(() async {
      for (int i = 0; i < favoriteIds.length; i++) {
        await updateFavoriteOrder(favoriteIds[i], i);
      }
    });
  }

  /// Récupère le prochain ordre de tri pour les favoris
  Future<int> getNextFavoriteSortOrder(int connectionId) async {
    final result = await customSelect(
      'SELECT MAX(sort_order) as max_order FROM favorites WHERE connection_id = ?',
      variables: [Variable.withInt(connectionId)],
    ).getSingleOrNull();
    final maxOrder = result?.read<int?>('max_order') ?? -1;
    return maxOrder + 1;
  }

  /// Compte le nombre de favoris pour une connexion
  Future<int> countFavorites(int connectionId) async {
    final count = favorites.id.count();
    final query = selectOnly(favorites)
      ..addColumns([count])
      ..where(favorites.connectionId.equals(connectionId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // === Super Favoris ===

  /// Récupère les super favoris d'une connexion
  Future<List<Favorite>> getSuperFavoritesByConnection(int connectionId) {
    return (select(favorites)
          ..where((f) =>
              f.connectionId.equals(connectionId) & f.isSuperFavorite.equals(true))
          ..orderBy([(f) => OrderingTerm.asc(f.sortOrder)]))
        .get();
  }

  /// Stream des super favoris d'une connexion
  Stream<List<Favorite>> watchSuperFavoritesByConnection(int connectionId) {
    return (select(favorites)
          ..where((f) =>
              f.connectionId.equals(connectionId) & f.isSuperFavorite.equals(true))
          ..orderBy([(f) => OrderingTerm.asc(f.sortOrder)]))
        .watch();
  }

  /// Récupère tous les super favoris groupés par connexion
  Future<Map<int, List<Favorite>>> getAllSuperFavoritesGrouped() async {
    final allSuperFavs = await (select(favorites)
          ..where((f) => f.isSuperFavorite.equals(true))
          ..orderBy([(f) => OrderingTerm.asc(f.sortOrder)]))
        .get();

    final grouped = <int, List<Favorite>>{};
    for (final fav in allSuperFavs) {
      grouped.putIfAbsent(fav.connectionId, () => []).add(fav);
    }
    return grouped;
  }

  /// Stream de tous les super favoris groupés par connexion
  Stream<Map<int, List<Favorite>>> watchAllSuperFavoritesGrouped() {
    return (select(favorites)
          ..where((f) => f.isSuperFavorite.equals(true))
          ..orderBy([(f) => OrderingTerm.asc(f.sortOrder)]))
        .watch()
        .map((allSuperFavs) {
      final grouped = <int, List<Favorite>>{};
      for (final fav in allSuperFavs) {
        grouped.putIfAbsent(fav.connectionId, () => []).add(fav);
      }
      return grouped;
    });
  }

  /// Toggle le statut super favori d'un favori
  Future<bool> toggleSuperFavorite(int favoriteId) async {
    final existing = await (select(favorites)
          ..where((f) => f.id.equals(favoriteId)))
        .getSingleOrNull();

    if (existing == null) return false;

    final newValue = !existing.isSuperFavorite;
    await (update(favorites)..where((f) => f.id.equals(favoriteId))).write(
      FavoritesCompanion(isSuperFavorite: Value(newValue)),
    );
    return newValue;
  }

  /// Met à jour le statut super favori
  Future<void> setSuperFavorite(int favoriteId, bool isSuperFavorite) async {
    await (update(favorites)..where((f) => f.id.equals(favoriteId))).write(
      FavoritesCompanion(isSuperFavorite: Value(isSuperFavorite)),
    );
  }

  /// Rétrograde un super favori en favori simple (pour le cycle)
  /// Met isSuperFavorite = false et wasPromoted = true
  Future<void> demoteSuperFavorite(int favoriteId) async {
    await (update(favorites)..where((f) => f.id.equals(favoriteId))).write(
      const FavoritesCompanion(
        isSuperFavorite: Value(false),
        wasPromoted: Value(true),
      ),
    );
  }

  /// Compte les super favoris pour une connexion
  Future<int> countSuperFavorites(int connectionId) async {
    final count = favorites.id.count();
    final query = selectOnly(favorites)
      ..addColumns([count])
      ..where(favorites.connectionId.equals(connectionId) &
          favorites.isSuperFavorite.equals(true));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ==========================================================================
  // === CACHE : Propriétés statiques des points ===
  // ==========================================================================

  /// Durée de validité du cache des points statiques (très long car rarement modifié)
  static const pointsCacheMaxAge = Duration(hours: 24);

  /// Récupère toutes les propriétés statiques cachées pour une connexion
  Future<List<CachedPoint>> getAllCachedPoints(int connectionId) {
    return (select(cachedPoints)
          ..where((c) => c.connectionId.equals(connectionId)))
        .get();
  }

  /// Vérifie si le cache des points est valide (non expiré)
  /// The cache is valid only if its oldest row is still fresh.
  Future<bool> isPointsCacheValid(int connectionId) async {
    final oldest = cachedPoints.cachedAt.min();
    final query = selectOnly(cachedPoints)
      ..addColumns([oldest])
      ..where(cachedPoints.connectionId.equals(connectionId));
    final cachedAt = (await query.getSingleOrNull())?.read(oldest);

    if (cachedAt == null) return false;
    return isCacheFresh(cachedAt, pointsCacheMaxAge);
  }

  /// Sauvegarde plusieurs points en cache (batch upsert, cachedAt rafraîchi)
  Future<void> cachePoints(List<CachedPointsCompanion> points) async {
    final now = DateTime.now();
    await batch((batch) {
      batch.insertAllOnConflictUpdate(
        cachedPoints,
        points.map((p) => p.copyWith(cachedAt: Value(now))).toList(),
      );
    });
  }

  /// Remplace tout le cache des points d'une connexion (transaction).
  ///
  /// Points absent from [points] (deleted on the controller) are purged, and
  /// every row gets the same fresh cachedAt.
  Future<void> replaceCachedPoints(
    int connectionId,
    List<CachedPointsCompanion> points,
  ) async {
    final now = DateTime.now();
    await transaction(() async {
      await clearPointsCache(connectionId);
      await batch((batch) {
        batch.insertAll(
          cachedPoints,
          points
              .map((p) => p.copyWith(
                    connectionId: Value(connectionId),
                    cachedAt: Value(now),
                  ))
              .toList(),
          mode: InsertMode.insertOrReplace,
        );
      });
    });
  }

  /// Supprime le cache des points pour une connexion
  Future<void> clearPointsCache(int connectionId) async {
    await (delete(cachedPoints)
          ..where((c) => c.connectionId.equals(connectionId)))
        .go();
  }

  /// Compte les points en cache pour une connexion
  Future<int> countCachedPoints(int connectionId) async {
    final count = cachedPoints.pointRef.count();
    final query = selectOnly(cachedPoints)
      ..addColumns([count])
      ..where(cachedPoints.connectionId.equals(connectionId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ==========================================================================
  // === CACHE : Device Info ===
  // ==========================================================================

  /// Durée de validité du cache device info
  static const deviceInfoCacheMaxAge = Duration(hours: 1);

  /// Récupère le device info depuis le cache
  Future<CachedDeviceInfoData?> getCachedDeviceInfo(int connectionId) {
    return (select(cachedDeviceInfo)
          ..where((c) => c.connectionId.equals(connectionId)))
        .getSingleOrNull();
  }

  /// Vérifie si le cache device info est valide
  Future<bool> isDeviceInfoCacheValid(int connectionId) async {
    final result = await getCachedDeviceInfo(connectionId);
    if (result == null) return false;
    return isCacheFresh(result.cachedAt, deviceInfoCacheMaxAge);
  }

  /// Sauvegarde le device info en cache
  Future<void> cacheDeviceInfo(CachedDeviceInfoCompanion info) async {
    await into(cachedDeviceInfo).insertOnConflictUpdate(info);
  }

  /// Supprime le cache device info pour une connexion
  Future<void> clearDeviceInfoCache(int connectionId) async {
    await (delete(cachedDeviceInfo)
          ..where((c) => c.connectionId.equals(connectionId)))
        .go();
  }

  // ==========================================================================
  // === CACHE : Trend Log Mapping ===
  // ==========================================================================

  /// Durée de validité du cache trend log mapping
  static const trendLogMappingCacheMaxAge = Duration(hours: 1);

  /// Récupère le mapping trend log depuis le cache
  Future<Map<String, int>?> getCachedTrendLogMapping(int connectionId) async {
    final result = await (select(cachedTrendLogMapping)
          ..where((c) => c.connectionId.equals(connectionId)))
        .getSingleOrNull();

    if (result == null) return null;

    // Vérifier si expiré
    if (!isCacheFresh(result.cachedAt, trendLogMappingCacheMaxAge)) return null;

    // Décoder le JSON
    try {
      final decoded = jsonDecode(result.mappingJson) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, (value as num).toInt()));
    } catch (e) {
      // Corrupted row: log it and drop it so it is not re-read on every open
      _logger.w('Corrupted trend log mapping cache for connection $connectionId: $e');
      await clearTrendLogMappingCache(connectionId);
      return null;
    }
  }

  /// Vérifie si le cache trend log mapping est valide
  Future<bool> isTrendLogMappingCacheValid(int connectionId) async {
    final result = await (select(cachedTrendLogMapping)
          ..where((c) => c.connectionId.equals(connectionId)))
        .getSingleOrNull();

    if (result == null) return false;
    return isCacheFresh(result.cachedAt, trendLogMappingCacheMaxAge);
  }

  /// Sauvegarde le mapping trend log en cache
  Future<void> cacheTrendLogMapping(int connectionId, Map<String, int> mapping) async {
    final jsonStr = jsonEncode(mapping);
    await into(cachedTrendLogMapping).insertOnConflictUpdate(
      CachedTrendLogMappingCompanion(
        connectionId: Value(connectionId),
        mappingJson: Value(jsonStr),
        entryCount: Value(mapping.length),
        cachedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Supprime le cache trend log mapping pour une connexion
  Future<void> clearTrendLogMappingCache(int connectionId) async {
    await (delete(cachedTrendLogMapping)
          ..where((c) => c.connectionId.equals(connectionId)))
        .go();
  }

  // ==========================================================================
  // === CACHE : Objects Summary ===
  // ==========================================================================

  /// Durée de validité du cache objects summary
  static const objectsSummaryCacheMaxAge = Duration(minutes: 30);

  /// Récupère le résumé des objets depuis le cache
  Future<CachedObjectsSummaryData?> getCachedObjectsSummary(int connectionId) async {
    final result = await (select(cachedObjectsSummary)
          ..where((c) => c.connectionId.equals(connectionId)))
        .getSingleOrNull();

    if (result == null) return null;

    // Vérifier si expiré
    if (!isCacheFresh(result.cachedAt, objectsSummaryCacheMaxAge)) return null;

    return result;
  }

  /// Vérifie si le cache objects summary est valide
  Future<bool> isObjectsSummaryCacheValid(int connectionId) async {
    final result = await (select(cachedObjectsSummary)
          ..where((c) => c.connectionId.equals(connectionId)))
        .getSingleOrNull();

    if (result == null) return false;
    return isCacheFresh(result.cachedAt, objectsSummaryCacheMaxAge);
  }

  /// Sauvegarde le résumé des objets en cache
  Future<void> cacheObjectsSummary(CachedObjectsSummaryCompanion summary) async {
    await into(cachedObjectsSummary).insertOnConflictUpdate(summary);
  }

  /// Supprime le cache objects summary pour une connexion
  Future<void> clearObjectsSummaryCache(int connectionId) async {
    await (delete(cachedObjectsSummary)
          ..where((c) => c.connectionId.equals(connectionId)))
        .go();
  }

  // ==========================================================================
  // === CACHE : Opérations globales ===
  // ==========================================================================

  /// Supprime tout le cache pour une connexion
  Future<void> clearAllCache(int connectionId) async {
    await transaction(() => _clearAllCacheRows(connectionId));
  }

  Future<void> _clearAllCacheRows(int connectionId) async {
    await clearPointsCache(connectionId);
    await clearDeviceInfoCache(connectionId);
    await clearTrendLogMappingCache(connectionId);
    await clearObjectsSummaryCache(connectionId);
  }

  /// Vide tout le cache, toutes connexions confondues
  Future<void> clearAllCacheGlobal() async {
    await transaction(() async {
      await delete(cachedPoints).go();
      await delete(cachedDeviceInfo).go();
      await delete(cachedTrendLogMapping).go();
      await delete(cachedObjectsSummary).go();
    });
  }

  /// Statistiques globales du cache (COUNT, sans charger les lignes)
  Future<({int totalPoints, int totalDevices})> getGlobalCacheStats() async {
    final pointsCount = cachedPoints.pointRef.count();
    final devicesCount = cachedDeviceInfo.connectionId.count();
    final points = await (selectOnly(cachedPoints)..addColumns([pointsCount]))
        .getSingle();
    final devices =
        await (selectOnly(cachedDeviceInfo)..addColumns([devicesCount]))
            .getSingle();
    return (
      totalPoints: points.read(pointsCount) ?? 0,
      totalDevices: devices.read(devicesCount) ?? 0,
    );
  }

  /// Supprime tout le cache expiré (maintenance)
  Future<void> clearExpiredCache() async {
    final now = DateTime.now();

    // Points cache (24h)
    final pointsExpiry = now.subtract(pointsCacheMaxAge);
    await (delete(cachedPoints)..where((c) => c.cachedAt.isSmallerThanValue(pointsExpiry))).go();

    // Device info cache (1h)
    final deviceExpiry = now.subtract(deviceInfoCacheMaxAge);
    await (delete(cachedDeviceInfo)..where((c) => c.cachedAt.isSmallerThanValue(deviceExpiry))).go();

    // Trend log mapping cache (1h)
    final trendExpiry = now.subtract(trendLogMappingCacheMaxAge);
    await (delete(cachedTrendLogMapping)..where((c) => c.cachedAt.isSmallerThanValue(trendExpiry))).go();

    // Objects summary cache (30min)
    final summaryExpiry = now.subtract(objectsSummaryCacheMaxAge);
    await (delete(cachedObjectsSummary)..where((c) => c.cachedAt.isSmallerThanValue(summaryExpiry))).go();
  }

  // ==========================================================================
  // === DOSSIERS DE FAVORIS ===
  // ==========================================================================

  /// Récupère tous les dossiers de favoris pour une connexion
  Future<List<FavoriteFolder>> getFavoriteFoldersByConnection(int connectionId) {
    return (select(favoriteFolders)
          ..where((f) => f.connectionId.equals(connectionId))
          ..orderBy([(f) => OrderingTerm.asc(f.sortOrder)]))
        .get();
  }

  /// Stream des dossiers de favoris pour une connexion
  Stream<List<FavoriteFolder>> watchFavoriteFoldersByConnection(int connectionId) {
    return (select(favoriteFolders)
          ..where((f) => f.connectionId.equals(connectionId))
          ..orderBy([(f) => OrderingTerm.asc(f.sortOrder)]))
        .watch();
  }

  /// Crée un nouveau dossier de favoris
  Future<int> createFavoriteFolder(FavoriteFoldersCompanion folder) {
    return transaction(() async {
      // Calculer le prochain sortOrder
      final maxOrder = favoriteFolders.sortOrder.max();
      final query = selectOnly(favoriteFolders)
        ..addColumns([maxOrder])
        ..where(favoriteFolders.connectionId.equals(folder.connectionId.value));
      final result = await query.getSingleOrNull();
      final nextOrder = (result?.read(maxOrder) ?? -1) + 1;

      return into(favoriteFolders).insert(
        folder.copyWith(sortOrder: Value(nextOrder)),
      );
    });
  }

  /// Met à jour un dossier de favoris
  Future<bool> updateFavoriteFolder(FavoriteFolder folder) {
    return update(favoriteFolders).replace(folder);
  }

  /// Met à jour les propriétés d'un dossier
  Future<void> updateFavoriteFolderProperties({
    required int folderId,
    String? name,
    String? color,
    String? icon,
  }) async {
    await (update(favoriteFolders)..where((f) => f.id.equals(folderId))).write(
      FavoriteFoldersCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        color: color != null ? Value(color) : const Value.absent(),
        icon: icon != null ? Value(icon) : const Value.absent(),
      ),
    );
  }

  /// Supprime un dossier de favoris (et ses assignations)
  Future<void> deleteFavoriteFolder(int folderId) async {
    await transaction(() async {
      // D'abord supprimer les assignations
      await (delete(favoriteFolderAssignments)
            ..where((a) => a.folderId.equals(folderId)))
          .go();
      // Puis le dossier
      await (delete(favoriteFolders)..where((f) => f.id.equals(folderId))).go();
    });
  }

  /// Réordonne les dossiers de favoris
  Future<void> reorderFavoriteFolders(int connectionId, List<int> folderIds) async {
    await transaction(() async {
      for (int i = 0; i < folderIds.length; i++) {
        await (update(favoriteFolders)..where((f) => f.id.equals(folderIds[i])))
            .write(FavoriteFoldersCompanion(sortOrder: Value(i)));
      }
    });
  }

  // ==========================================================================
  // === ASSIGNATION FAVORIS <-> DOSSIERS ===
  // ==========================================================================

  /// Récupère les dossiers assignés à un favori
  Future<List<FavoriteFolder>> getFoldersForFavorite(int favoriteId) async {
    final query = select(favoriteFolders).join([
      innerJoin(
        favoriteFolderAssignments,
        favoriteFolderAssignments.folderId.equalsExp(favoriteFolders.id),
      ),
    ])
      ..where(favoriteFolderAssignments.favoriteId.equals(favoriteId))
      ..orderBy([OrderingTerm.asc(favoriteFolders.sortOrder)]);

    final results = await query.get();
    return results.map((row) => row.readTable(favoriteFolders)).toList();
  }

  /// Stream des IDs de dossiers assignés à un favori
  Stream<List<int>> watchFolderIdsForFavorite(int favoriteId) {
    return (select(favoriteFolderAssignments)
          ..where((a) => a.favoriteId.equals(favoriteId)))
        .watch()
        .map((assignments) => assignments.map((a) => a.folderId).toList());
  }

  /// Récupère les favoris d'un dossier
  Future<List<Favorite>> getFavoritesInFolder(int folderId) async {
    final query = select(favorites).join([
      innerJoin(
        favoriteFolderAssignments,
        favoriteFolderAssignments.favoriteId.equalsExp(favorites.id),
      ),
    ])
      ..where(favoriteFolderAssignments.folderId.equals(folderId))
      ..orderBy([OrderingTerm.asc(favorites.sortOrder)]);

    final results = await query.get();
    return results.map((row) => row.readTable(favorites)).toList();
  }

  /// Stream des favoris d'un dossier
  Stream<List<Favorite>> watchFavoritesInFolder(int folderId) {
    final query = select(favorites).join([
      innerJoin(
        favoriteFolderAssignments,
        favoriteFolderAssignments.favoriteId.equalsExp(favorites.id),
      ),
    ])
      ..where(favoriteFolderAssignments.folderId.equals(folderId))
      ..orderBy([OrderingTerm.asc(favorites.sortOrder)]);

    return query.watch().map(
          (rows) => rows.map((row) => row.readTable(favorites)).toList(),
        );
  }

  /// Récupère les favoris sans dossier pour une connexion
  Future<List<Favorite>> getUnassignedFavorites(int connectionId) async {
    // Sous-requête : IDs des favoris qui ont au moins un dossier
    final assignedIds = selectOnly(favoriteFolderAssignments, distinct: true)
      ..addColumns([favoriteFolderAssignments.favoriteId]);

    final query = select(favorites)
      ..where((f) =>
          f.connectionId.equals(connectionId) &
          f.id.isNotInQuery(assignedIds))
      ..orderBy([(f) => OrderingTerm.asc(f.sortOrder)]);

    return query.get();
  }

  /// Stream des favoris sans dossier pour une connexion
  Stream<List<Favorite>> watchUnassignedFavorites(int connectionId) {
    final assignedIds = selectOnly(favoriteFolderAssignments, distinct: true)
      ..addColumns([favoriteFolderAssignments.favoriteId]);

    final query = select(favorites)
      ..where((f) =>
          f.connectionId.equals(connectionId) &
          f.id.isNotInQuery(assignedIds))
      ..orderBy([(f) => OrderingTerm.asc(f.sortOrder)]);

    return query.watch();
  }

  /// Assigne un favori à un dossier
  Future<void> assignFavoriteToFolder(int favoriteId, int folderId) async {
    await into(favoriteFolderAssignments).insert(
      FavoriteFolderAssignmentsCompanion.insert(
        favoriteId: favoriteId,
        folderId: folderId,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// Retire un favori d'un dossier
  Future<void> unassignFavoriteFromFolder(int favoriteId, int folderId) async {
    await (delete(favoriteFolderAssignments)
          ..where((a) =>
              a.favoriteId.equals(favoriteId) & a.folderId.equals(folderId)))
        .go();
  }

  /// Met à jour les dossiers d'un favori (remplace toutes les assignations)
  Future<void> setFavoriteFolders(int favoriteId, List<int> folderIds) async {
    await transaction(() async {
      // Supprimer les anciennes assignations
      await (delete(favoriteFolderAssignments)
            ..where((a) => a.favoriteId.equals(favoriteId)))
          .go();

      // Ajouter les nouvelles
      for (final folderId in folderIds) {
        await into(favoriteFolderAssignments).insert(
          FavoriteFolderAssignmentsCompanion.insert(
            favoriteId: favoriteId,
            folderId: folderId,
          ),
        );
      }
    });
  }

  /// Compte les favoris dans un dossier
  Future<int> countFavoritesInFolder(int folderId) async {
    final count = favoriteFolderAssignments.id.count();
    final query = selectOnly(favoriteFolderAssignments)
      ..addColumns([count])
      ..where(favoriteFolderAssignments.folderId.equals(folderId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ==========================================================================
  // === SYNOPTIQUES ===
  // ==========================================================================

  /// Récupère tous les synoptiques (globaux + spécifiques à une connexion)
  Future<List<Synoptic>> getAllSynoptics() {
    return (select(synoptics)..orderBy([(s) => OrderingTerm.asc(s.sortOrder)])).get();
  }

  /// Stream de tous les synoptiques
  Stream<List<Synoptic>> watchAllSynoptics() {
    return (select(synoptics)..orderBy([(s) => OrderingTerm.asc(s.sortOrder)])).watch();
  }

  /// Récupère les synoptiques disponibles pour une connexion (globaux + spécifiques)
  Future<List<Synoptic>> getSynopticsForConnection(int? connectionId) {
    if (connectionId == null) {
      // Seulement les globaux
      return (select(synoptics)
            ..where((s) => s.connectionId.isNull())
            ..orderBy([(s) => OrderingTerm.asc(s.sortOrder)]))
          .get();
    }
    // Globaux + spécifiques à cette connexion
    return (select(synoptics)
          ..where((s) => s.connectionId.isNull() | s.connectionId.equals(connectionId))
          ..orderBy([(s) => OrderingTerm.asc(s.sortOrder)]))
        .get();
  }

  /// Stream des synoptiques pour une connexion
  Stream<List<Synoptic>> watchSynopticsForConnection(int? connectionId) {
    if (connectionId == null) {
      return (select(synoptics)
            ..where((s) => s.connectionId.isNull())
            ..orderBy([(s) => OrderingTerm.asc(s.sortOrder)]))
          .watch();
    }
    return (select(synoptics)
          ..where((s) => s.connectionId.isNull() | s.connectionId.equals(connectionId))
          ..orderBy([(s) => OrderingTerm.asc(s.sortOrder)]))
        .watch();
  }

  /// Récupère un synoptique par son ID
  Future<Synoptic?> getSynopticById(int id) {
    return (select(synoptics)..where((s) => s.id.equals(id))).getSingleOrNull();
  }

  /// Crée un nouveau synoptique
  Future<int> createSynoptic(SynopticsCompanion synoptic) {
    return transaction(() async {
      // Calculer le prochain sortOrder
      final maxOrder = synoptics.sortOrder.max();
      final query = selectOnly(synoptics)..addColumns([maxOrder]);
      final result = await query.getSingleOrNull();
      final nextOrder = (result?.read(maxOrder) ?? -1) + 1;

      return into(synoptics).insert(
        synoptic.copyWith(sortOrder: Value(nextOrder)),
      );
    });
  }

  /// Met à jour un synoptique
  Future<bool> updateSynoptic(Synoptic synoptic) {
    return update(synoptics).replace(synoptic);
  }

  /// Met à jour les propriétés d'un synoptique
  Future<void> updateSynopticProperties({
    required int synopticId,
    String? name,
    String? description,
    int? connectionId,
  }) async {
    await (update(synoptics)..where((s) => s.id.equals(synopticId))).write(
      SynopticsCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        description: description != null ? Value(description) : const Value.absent(),
        connectionId: connectionId != null ? Value(connectionId) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Supprime un synoptique et ses liaisons
  Future<void> deleteSynoptic(int synopticId) async {
    await transaction(() async {
      // D'abord supprimer les liaisons
      await (delete(synopticBindings)..where((b) => b.synopticId.equals(synopticId))).go();
      // Puis le synoptique
      await (delete(synoptics)..where((s) => s.id.equals(synopticId))).go();
    });
  }

  /// Réordonne les synoptiques
  Future<void> reorderSynoptics(List<int> synopticIds) async {
    await transaction(() async {
      for (int i = 0; i < synopticIds.length; i++) {
        await (update(synoptics)..where((s) => s.id.equals(synopticIds[i])))
            .write(SynopticsCompanion(sortOrder: Value(i)));
      }
    });
  }

  // ==========================================================================
  // === LIAISONS SYNOPTIQUES (BINDINGS) ===
  // ==========================================================================

  /// Récupère toutes les liaisons d'un synoptique
  Future<List<SynopticBinding>> getBindingsForSynoptic(int synopticId) {
    return (select(synopticBindings)..where((b) => b.synopticId.equals(synopticId))).get();
  }

  /// Stream des liaisons d'un synoptique
  Stream<List<SynopticBinding>> watchBindingsForSynoptic(int synopticId) {
    return (select(synopticBindings)..where((b) => b.synopticId.equals(synopticId))).watch();
  }

  /// Récupère une liaison par son ID
  Future<SynopticBinding?> getBindingById(int id) {
    return (select(synopticBindings)..where((b) => b.id.equals(id))).getSingleOrNull();
  }

  /// Récupère une liaison par synoptique et élément SVG
  Future<SynopticBinding?> getBindingByElement(int synopticId, String svgElementId) {
    return (select(synopticBindings)
          ..where((b) => b.synopticId.equals(synopticId) & b.svgElementId.equals(svgElementId)))
        .getSingleOrNull();
  }

  /// Crée ou met à jour une liaison (upsert)
  Future<int> upsertBinding(SynopticBindingsCompanion binding) {
    return transaction(() async {
      // On doit d'abord vérifier si une liaison existe déjà pour cet élément SVG
      final existing = await getBindingByElement(
        binding.synopticId.value,
        binding.svgElementId.value,
      );

      if (existing != null) {
        // Mettre à jour la liaison existante
        await (update(synopticBindings)..where((b) => b.id.equals(existing.id)))
            .write(
          SynopticBindingsCompanion(
            pointRef: binding.pointRef,
            bindingType: binding.bindingType,
            configJson: binding.configJson,
            pointName: binding.pointName,
          ),
        );
        return existing.id;
      } else {
        // Créer une nouvelle liaison
        return into(synopticBindings).insert(binding);
      }
    });
  }

  /// Crée une nouvelle liaison
  Future<int> createBinding(SynopticBindingsCompanion binding) {
    return into(synopticBindings).insert(binding);
  }

  /// Met à jour une liaison existante
  Future<void> updateBinding({
    required int bindingId,
    String? pointRef,
    BindingType? bindingType,
    String? configJson,
    String? pointName,
  }) async {
    await (update(synopticBindings)..where((b) => b.id.equals(bindingId))).write(
      SynopticBindingsCompanion(
        pointRef: pointRef != null ? Value(pointRef) : const Value.absent(),
        bindingType: bindingType != null ? Value(bindingType) : const Value.absent(),
        configJson: configJson != null ? Value(configJson) : const Value.absent(),
        pointName: pointName != null ? Value(pointName) : const Value.absent(),
      ),
    );
  }

  /// Supprime une liaison
  Future<int> deleteBinding(int bindingId) {
    return (delete(synopticBindings)..where((b) => b.id.equals(bindingId))).go();
  }

  /// Supprime une liaison par synoptique et élément
  Future<int> deleteBindingByElement(int synopticId, String svgElementId) {
    return (delete(synopticBindings)
          ..where((b) => b.synopticId.equals(synopticId) & b.svgElementId.equals(svgElementId)))
        .go();
  }

  /// Supprime toutes les liaisons d'un synoptique
  Future<int> deleteAllBindingsForSynoptic(int synopticId) {
    return (delete(synopticBindings)..where((b) => b.synopticId.equals(synopticId))).go();
  }

  /// Compte les liaisons d'un synoptique
  Future<int> countBindings(int synopticId) async {
    final count = synopticBindings.id.count();
    final query = selectOnly(synopticBindings)
      ..addColumns([count])
      ..where(synopticBindings.synopticId.equals(synopticId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Récupère les points référencés par un synoptique (pour chargement batch)
  Future<List<String>> getPointRefsForSynoptic(int synopticId) async {
    final bindings = await getBindingsForSynoptic(synopticId);
    return bindings.map((b) => b.pointRef).toSet().toList();
  }

  // ==========================================================================
  // === DASHBOARDS ===
  // ==========================================================================

  /// Récupère tous les dashboards pour une connexion
  Future<List<Dashboard>> getDashboardsForConnection(int? connectionId) async {
    final query = select(dashboards)
      ..where((d) => connectionId != null
          ? d.connectionId.equals(connectionId) | d.connectionId.isNull()
          : d.connectionId.isNull())
      ..orderBy([(d) => OrderingTerm.asc(d.sortOrder)]);
    return query.get();
  }

  /// Stream des dashboards pour une connexion
  Stream<List<Dashboard>> watchDashboardsForConnection(int? connectionId) {
    final query = select(dashboards)
      ..where((d) => connectionId != null
          ? d.connectionId.equals(connectionId) | d.connectionId.isNull()
          : d.connectionId.isNull())
      ..orderBy([(d) => OrderingTerm.asc(d.sortOrder)]);
    return query.watch();
  }

  /// Récupère un dashboard par son ID
  Future<Dashboard?> getDashboardById(int id) {
    return (select(dashboards)..where((d) => d.id.equals(id))).getSingleOrNull();
  }

  /// Stream d'un dashboard par ID
  Stream<Dashboard?> watchDashboardById(int id) {
    return (select(dashboards)..where((d) => d.id.equals(id))).watchSingleOrNull();
  }

  /// Crée un nouveau dashboard
  Future<int> createDashboard({
    required String name,
    int? connectionId,
    int columns = 2,
    int rows = 2,
  }) {
    return transaction(() async {
      // Calculer le prochain sortOrder (MAX + 1, robuste aux suppressions)
      final maxOrder = dashboards.sortOrder.max();
      final query = selectOnly(dashboards)
        ..addColumns([maxOrder])
        ..where(connectionId != null
            ? dashboards.connectionId.equals(connectionId) |
                dashboards.connectionId.isNull()
            : dashboards.connectionId.isNull());
      final result = await query.getSingleOrNull();
      final nextOrder = (result?.read(maxOrder) ?? -1) + 1;

      return into(dashboards).insert(DashboardsCompanion(
        name: Value(name),
        connectionId: Value(connectionId),
        columns: Value(columns),
        rows: Value(rows),
        sortOrder: Value(nextOrder),
      ));
    });
  }

  /// Met à jour un dashboard
  Future<bool> updateDashboard({
    required int id,
    String? name,
    int? columns,
    int? rows,
  }) async {
    final updated = await (update(dashboards)..where((d) => d.id.equals(id))).write(
      DashboardsCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        columns: columns != null ? Value(columns) : const Value.absent(),
        rows: rows != null ? Value(rows) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return updated > 0;
  }

  /// Supprime un dashboard et tous ses widgets
  Future<int> deleteDashboard(int id) {
    return transaction(() async {
      // Supprimer d'abord les widgets
      await (delete(dashboardWidgets)..where((w) => w.dashboardId.equals(id)))
          .go();
      // Puis supprimer le dashboard
      return (delete(dashboards)..where((d) => d.id.equals(id))).go();
    });
  }

  /// Réorganise l'ordre des dashboards
  Future<void> reorderDashboards(List<int> dashboardIds) async {
    await transaction(() async {
      for (int i = 0; i < dashboardIds.length; i++) {
        await (update(dashboards)..where((d) => d.id.equals(dashboardIds[i]))).write(
          DashboardsCompanion(sortOrder: Value(i)),
        );
      }
    });
  }

  // ==========================================================================
  // === DASHBOARD WIDGETS ===
  // ==========================================================================

  /// Récupère les widgets d'un dashboard
  Future<List<DashboardWidget>> getDashboardWidgets(int dashboardId) {
    return (select(dashboardWidgets)
          ..where((w) => w.dashboardId.equals(dashboardId))
          ..orderBy([(w) => OrderingTerm.asc(w.position)]))
        .get();
  }

  /// Stream des widgets d'un dashboard
  Stream<List<DashboardWidget>> watchDashboardWidgets(int dashboardId) {
    return (select(dashboardWidgets)
          ..where((w) => w.dashboardId.equals(dashboardId))
          ..orderBy([(w) => OrderingTerm.asc(w.position)]))
        .watch();
  }

  /// Ajoute un widget au dashboard
  Future<int> addDashboardWidget({
    required int dashboardId,
    required int position,
    required DashboardWidgetType widgetType,
    String? configJson,
  }) {
    return into(dashboardWidgets).insert(DashboardWidgetsCompanion(
      dashboardId: Value(dashboardId),
      position: Value(position),
      widgetType: Value(widgetType),
      configJson: Value(configJson),
    ));
  }

  /// Met à jour un widget
  Future<bool> updateDashboardWidget({
    required int widgetId,
    DashboardWidgetType? widgetType,
    String? configJson,
    int? position,
  }) async {
    final updated = await (update(dashboardWidgets)..where((w) => w.id.equals(widgetId))).write(
      DashboardWidgetsCompanion(
        widgetType: widgetType != null ? Value(widgetType) : const Value.absent(),
        configJson: configJson != null ? Value(configJson) : const Value.absent(),
        position: position != null ? Value(position) : const Value.absent(),
      ),
    );
    return updated > 0;
  }

  /// Supprime un widget
  Future<int> deleteDashboardWidget(int widgetId) {
    return (delete(dashboardWidgets)..where((w) => w.id.equals(widgetId))).go();
  }

  /// Supprime un widget par position (utile pour vider un slot)
  Future<int> deleteDashboardWidgetByPosition(int dashboardId, int position) {
    return (delete(dashboardWidgets)
          ..where((w) => w.dashboardId.equals(dashboardId) & w.position.equals(position)))
        .go();
  }

  /// Réorganise les widgets dans le dashboard
  Future<void> reorderDashboardWidgets(int dashboardId, Map<int, int> widgetPositions) async {
    await transaction(() async {
      for (final entry in widgetPositions.entries) {
        await (update(dashboardWidgets)..where((w) => w.id.equals(entry.key))).write(
          DashboardWidgetsCompanion(position: Value(entry.value)),
        );
      }
    });
  }

  /// Compte les widgets d'un dashboard
  Future<int> countDashboardWidgets(int dashboardId) async {
    final count = dashboardWidgets.id.count();
    final query = selectOnly(dashboardWidgets)
      ..addColumns([count])
      ..where(dashboardWidgets.dashboardId.equals(dashboardId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }
}
