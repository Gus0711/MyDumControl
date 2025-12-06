import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../data/database/app_database.dart';
import '../../domain/models/bacnet_object.dart';
import 'database_provider.dart';
import 'active_connection_provider.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

/// État du favori : 0 = pas favori, 1 = favori, 2 = super favori
enum FavoriteState {
  none,       // ☆ Pas favori
  favorite,   // ⭐ Favori (étoile jaune)
  superFavorite, // ✨ Super favori (étoile étincelante)
}

/// Provider pour les favoris de la connexion active
final favoritesProvider = StreamProvider<List<Favorite>>((ref) {
  final database = ref.watch(databaseProvider);
  final activeConnection = ref.watch(activeConnectionProvider);

  if (activeConnection.connection == null) {
    return Stream.value([]);
  }

  return database.watchFavoritesByConnection(activeConnection.connection!.id);
});

/// Provider pour savoir si un point spécifique est favori
final isFavoriteProvider = StreamProvider.family<bool, String>((ref, pointRef) {
  final database = ref.watch(databaseProvider);
  final activeConnection = ref.watch(activeConnectionProvider);

  if (activeConnection.connection == null) {
    return Stream.value(false);
  }

  return database.watchIsFavorite(activeConnection.connection!.id, pointRef);
});

/// Provider pour l'état complet du favori (none, favorite, superFavorite)
final favoriteStateProvider = StreamProvider.family<FavoriteState, String>((ref, pointRef) {
  final database = ref.watch(databaseProvider);
  final activeConnection = ref.watch(activeConnectionProvider);

  if (activeConnection.connection == null) {
    return Stream.value(FavoriteState.none);
  }

  final connectionId = activeConnection.connection!.id;

  // On écoute la liste des favoris et on détermine l'état
  return database.watchFavoritesByConnection(connectionId).map((favorites) {
    try {
      final favorite = favorites.firstWhere((f) => f.pointRef == pointRef);
      return favorite.isSuperFavorite ? FavoriteState.superFavorite : FavoriteState.favorite;
    } catch (_) {
      return FavoriteState.none;
    }
  });
});

/// Provider pour le nombre de favoris
final favoritesCountProvider = FutureProvider<int>((ref) async {
  final database = ref.watch(databaseProvider);
  final activeConnection = ref.watch(activeConnectionProvider);

  if (activeConnection.connection == null) {
    return 0;
  }

  return database.countFavorites(activeConnection.connection!.id);
});

/// Notifier pour gérer les actions sur les favoris
class FavoritesNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  FavoritesNotifier(this._ref) : super(const AsyncValue.data(null));

  /// Toggle un favori (ajouter/supprimer)
  Future<bool> toggleFavorite(BacnetObject object) async {
    final activeConnection = _ref.read(activeConnectionProvider);
    if (activeConnection.connection == null) {
      _logger.w('toggleFavorite: no active connection');
      return false;
    }

    final database = _ref.read(databaseProvider);
    final connectionId = activeConnection.connection!.id;

    try {
      state = const AsyncValue.loading();

      final isNowFavorite = await database.toggleFavorite(
        connectionId: connectionId,
        pointRef: object.objectId,
        pointName: object.objectName,
        pointDescription: object.description,
        objectType: object.type.apiName,
      );

      _logger.i(
        'toggleFavorite: ${object.objectId} is now ${isNowFavorite ? "favorite" : "not favorite"}',
      );

      state = const AsyncValue.data(null);
      return isNowFavorite;
    } catch (e, st) {
      _logger.e('toggleFavorite error: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Cycle l'état du favori : none → favorite → superFavorite → favorite → none
  /// Le cycle "monte" puis "descend" pour une UX plus douce
  /// Retourne le nouvel état
  Future<FavoriteState> cycleFavoriteState(BacnetObject object) async {
    final activeConnection = _ref.read(activeConnectionProvider);
    if (activeConnection.connection == null) {
      _logger.w('cycleFavoriteState: no active connection');
      return FavoriteState.none;
    }

    final database = _ref.read(databaseProvider);
    final connectionId = activeConnection.connection!.id;

    try {
      state = const AsyncValue.loading();

      // Récupérer l'état actuel
      final favorites = await database.getFavoritesByConnection(connectionId);
      Favorite? existing;
      try {
        existing = favorites.firstWhere((f) => f.pointRef == object.objectId);
      } catch (_) {
        existing = null;
      }

      FavoriteState newState;

      if (existing == null) {
        // ☆ Pas favori → ⭐ Favori (on monte)
        await database.addFavorite(FavoritesCompanion.insert(
          connectionId: connectionId,
          pointRef: object.objectId,
          pointName: object.objectName,
          pointDescription: Value(object.description),
          objectType: object.type.apiName,
          // wasPromoted = false par défaut
        ));
        newState = FavoriteState.favorite;
        _logger.i('cycleFavoriteState: ${object.objectId} ☆ → ⭐ (favori)');
      } else if (!existing.isSuperFavorite && !existing.wasPromoted) {
        // ⭐ Favori (montée) → ✨ Super favori
        await database.setSuperFavorite(existing.id, true);
        newState = FavoriteState.superFavorite;
        _logger.i('cycleFavoriteState: ${object.objectId} ⭐ → ✨ (super favori)');
      } else if (existing.isSuperFavorite) {
        // ✨ Super favori → ⭐ Favori (on descend, marquer wasPromoted)
        await database.demoteSuperFavorite(existing.id);
        newState = FavoriteState.favorite;
        _logger.i('cycleFavoriteState: ${object.objectId} ✨ → ⭐ (rétrogradé)');
      } else {
        // ⭐ Favori (wasPromoted = true) → ☆ Pas favori (suppression)
        await database.deleteFavoriteById(existing.id);
        newState = FavoriteState.none;
        _logger.i('cycleFavoriteState: ${object.objectId} ⭐ → ☆ (supprimé)');
      }

      state = const AsyncValue.data(null);
      return newState;
    } catch (e, st) {
      _logger.e('cycleFavoriteState error: $e');
      state = AsyncValue.error(e, st);
      return FavoriteState.none;
    }
  }

  /// Ajoute un point aux favoris
  Future<bool> addFavorite(BacnetObject object) async {
    final activeConnection = _ref.read(activeConnectionProvider);
    if (activeConnection.connection == null) {
      return false;
    }

    final database = _ref.read(databaseProvider);
    final connectionId = activeConnection.connection!.id;

    // Vérifier si déjà favori
    final alreadyFavorite = await database.isFavorite(connectionId, object.objectId);
    if (alreadyFavorite) {
      return true;
    }

    try {
      await database.addFavorite(FavoritesCompanion.insert(
        connectionId: connectionId,
        pointRef: object.objectId,
        pointName: object.objectName,
        pointDescription: Value(object.description),
        objectType: object.type.apiName,
      ));
      _logger.i('addFavorite: ${object.objectId} added');
      return true;
    } catch (e) {
      _logger.e('addFavorite error: $e');
      return false;
    }
  }

  /// Supprime un favori
  Future<bool> removeFavorite(String pointRef) async {
    final activeConnection = _ref.read(activeConnectionProvider);
    if (activeConnection.connection == null) {
      return false;
    }

    final database = _ref.read(databaseProvider);
    final connectionId = activeConnection.connection!.id;

    try {
      await database.deleteFavorite(connectionId, pointRef);
      _logger.i('removeFavorite: $pointRef removed');
      return true;
    } catch (e) {
      _logger.e('removeFavorite error: $e');
      return false;
    }
  }

  /// Supprime un favori par son ID
  Future<bool> removeFavoriteById(int favoriteId) async {
    final database = _ref.read(databaseProvider);

    try {
      await database.deleteFavoriteById(favoriteId);
      _logger.i('removeFavoriteById: $favoriteId removed');
      return true;
    } catch (e) {
      _logger.e('removeFavoriteById error: $e');
      return false;
    }
  }

  /// Réorganise les favoris (après drag & drop)
  Future<bool> reorderFavorites(List<int> favoriteIds) async {
    final activeConnection = _ref.read(activeConnectionProvider);
    if (activeConnection.connection == null) {
      return false;
    }

    final database = _ref.read(databaseProvider);
    final connectionId = activeConnection.connection!.id;

    try {
      await database.reorderFavorites(connectionId, favoriteIds);
      _logger.i('reorderFavorites: reordered ${favoriteIds.length} favorites');
      return true;
    } catch (e) {
      _logger.e('reorderFavorites error: $e');
      return false;
    }
  }

  /// Supprime tous les favoris de la connexion active
  Future<bool> clearAllFavorites() async {
    final activeConnection = _ref.read(activeConnectionProvider);
    if (activeConnection.connection == null) {
      return false;
    }

    final database = _ref.read(databaseProvider);
    final connectionId = activeConnection.connection!.id;

    try {
      await database.deleteAllFavoritesByConnection(connectionId);
      _logger.i('clearAllFavorites: all favorites cleared');
      return true;
    } catch (e) {
      _logger.e('clearAllFavorites error: $e');
      return false;
    }
  }
}

/// Provider pour les actions sur les favoris
final favoritesNotifierProvider =
    StateNotifierProvider<FavoritesNotifier, AsyncValue<void>>((ref) {
  return FavoritesNotifier(ref);
});
