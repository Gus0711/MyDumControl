import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/connections_table.dart';
import 'tables/folders_table.dart';

part 'app_database.g.dart';

/// Base de données principale de l'application
@DriftDatabase(tables: [Folders, Connections])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

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

  /// Supprime une connexion par son ID
  Future<int> deleteConnectionById(int id) {
    return (delete(connections)..where((c) => c.id.equals(id))).go();
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
    // D'abord, déplacer toutes les connexions du dossier vers la racine
    await (update(connections)..where((c) => c.folderId.equals(id))).write(
      const ConnectionsCompanion(folderId: Value(null)),
    );
    // Ensuite, supprimer le dossier
    await (delete(folders)..where((f) => f.id.equals(id))).go();
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
}
