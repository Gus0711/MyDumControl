import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../data/database/app_database.dart';
import 'database_provider.dart';
import 'active_connection_provider.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

/// Provider pour les dossiers de favoris de la connexion active
final favoriteFoldersProvider = StreamProvider<List<FavoriteFolder>>((ref) {
  final database = ref.watch(databaseProvider);
  final connectionId = ref.watch(activeConnectionProvider.select((s) => s.connection?.id));

  if (connectionId == null) {
    return Stream.value([]);
  }

  return database.watchFavoriteFoldersByConnection(connectionId);
});

/// Provider pour les favoris sans dossier de la connexion active
final unassignedFavoritesProvider = StreamProvider<List<Favorite>>((ref) {
  final database = ref.watch(databaseProvider);
  final connectionId = ref.watch(activeConnectionProvider.select((s) => s.connection?.id));

  if (connectionId == null) {
    return Stream.value([]);
  }

  return database.watchUnassignedFavorites(connectionId);
});

/// Provider pour les favoris d'un dossier spécifique
final favoritesInFolderProvider = StreamProvider.family<List<Favorite>, int>((ref, folderId) {
  final database = ref.watch(databaseProvider);
  return database.watchFavoritesInFolder(folderId);
});

/// Provider pour les IDs des dossiers d'un favori
final folderIdsForFavoriteProvider = StreamProvider.family<List<int>, int>((ref, favoriteId) {
  final database = ref.watch(databaseProvider);
  return database.watchFolderIdsForFavorite(favoriteId);
});

/// Provider pour les dossiers complets d'un favori (avec couleurs, icônes, etc.)
/// Relu à chaque changement d'assignation (stream DB) ; les modifications
/// d'un dossier (nom, couleur, suppression) invalident la famille.
final foldersForFavoriteProvider = StreamProvider.autoDispose.family<List<FavoriteFolder>, int>((ref, favoriteId) {
  final database = ref.watch(databaseProvider);
  return database
      .watchFolderIdsForFavorite(favoriteId)
      .asyncMap((_) => database.getFoldersForFavorite(favoriteId));
});

/// Notifier pour gérer les dossiers de favoris
class FavoriteFoldersNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  FavoriteFoldersNotifier(this._ref) : super(const AsyncValue.data(null));

  /// Crée un nouveau dossier
  Future<int?> createFolder({
    required String name,
    required String color,
    required String icon,
  }) async {
    final activeConnection = _ref.read(activeConnectionProvider);
    if (activeConnection.connection == null) {
      _logger.w('createFolder: no active connection');
      return null;
    }

    final database = _ref.read(databaseProvider);
    final connectionId = activeConnection.connection!.id;

    try {
      state = const AsyncValue.loading();

      final id = await database.createFavoriteFolder(
        FavoriteFoldersCompanion.insert(
          connectionId: connectionId,
          name: name,
          color: Value(color),
          icon: Value(icon),
        ),
      );

      _logger.i('createFolder: created "$name" with id $id');
      state = const AsyncValue.data(null);
      return id;
    } catch (e, st) {
      _logger.e('createFolder error: $e');
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Met à jour un dossier
  Future<bool> updateFolder({
    required int folderId,
    String? name,
    String? color,
    String? icon,
  }) async {
    final database = _ref.read(databaseProvider);

    try {
      state = const AsyncValue.loading();

      await database.updateFavoriteFolderProperties(
        folderId: folderId,
        name: name,
        color: color,
        icon: icon,
      );

      _ref.invalidate(foldersForFavoriteProvider);
      _logger.i('updateFolder: updated folder $folderId');
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      _logger.e('updateFolder error: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Supprime un dossier
  Future<bool> deleteFolder(int folderId) async {
    final database = _ref.read(databaseProvider);

    try {
      state = const AsyncValue.loading();

      await database.deleteFavoriteFolder(folderId);

      _ref.invalidate(foldersForFavoriteProvider);
      _logger.i('deleteFolder: deleted folder $folderId');
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      _logger.e('deleteFolder error: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Réordonne les dossiers
  Future<bool> reorderFolders(List<int> folderIds) async {
    final activeConnection = _ref.read(activeConnectionProvider);
    if (activeConnection.connection == null) {
      return false;
    }

    final database = _ref.read(databaseProvider);
    final connectionId = activeConnection.connection!.id;

    try {
      await database.reorderFavoriteFolders(connectionId, folderIds);
      _ref.invalidate(foldersForFavoriteProvider);
      _logger.i('reorderFolders: reordered ${folderIds.length} folders');
      return true;
    } catch (e) {
      _logger.e('reorderFolders error: $e');
      return false;
    }
  }

  /// Assigne un favori à un dossier
  Future<bool> assignToFolder(int favoriteId, int folderId) async {
    final database = _ref.read(databaseProvider);

    try {
      await database.assignFavoriteToFolder(favoriteId, folderId);
      _ref.invalidate(foldersForFavoriteProvider(favoriteId));
      _logger.i('assignToFolder: favorite $favoriteId -> folder $folderId');
      return true;
    } catch (e) {
      _logger.e('assignToFolder error: $e');
      return false;
    }
  }

  /// Retire un favori d'un dossier
  Future<bool> unassignFromFolder(int favoriteId, int folderId) async {
    final database = _ref.read(databaseProvider);

    try {
      await database.unassignFavoriteFromFolder(favoriteId, folderId);
      _ref.invalidate(foldersForFavoriteProvider(favoriteId));
      _logger.i('unassignFromFolder: favorite $favoriteId removed from folder $folderId');
      return true;
    } catch (e) {
      _logger.e('unassignFromFolder error: $e');
      return false;
    }
  }

  /// Met à jour les dossiers d'un favori (multi-sélection)
  Future<bool> setFavoriteFolders(int favoriteId, List<int> folderIds) async {
    final database = _ref.read(databaseProvider);

    try {
      state = const AsyncValue.loading();

      await database.setFavoriteFolders(favoriteId, folderIds);

      _ref.invalidate(foldersForFavoriteProvider(favoriteId));
      _logger.i('setFavoriteFolders: favorite $favoriteId -> ${folderIds.length} folders');
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      _logger.e('setFavoriteFolders error: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Provider pour le notifier des dossiers de favoris
final favoriteFoldersNotifierProvider =
    StateNotifierProvider<FavoriteFoldersNotifier, AsyncValue<void>>((ref) {
  return FavoriteFoldersNotifier(ref);
});
