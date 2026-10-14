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
  none, // ☆ Pas favori
  favorite, // ⭐ Favori (étoile jaune)
  superFavorite, // ✨ Super favori (étoile étincelante)
}

/// Provider pour les favoris de la connexion active
/// Ne dépend que de l'id de la connexion active (pas des autres champs de
/// ActiveConnectionState, qui changent souvent après la connexion).
final favoritesProvider = StreamProvider<List<Favorite>>((ref) {
  final database = ref.watch(databaseProvider);
  final connectionId = ref.watch(activeConnectionProvider.select((s) => s.connection?.id));

  if (connectionId == null) {
    return Stream.value([]);
  }

  return database.watchFavoritesByConnection(connectionId);
});

/// État de chaque favori de la connexion active, indexé par pointRef
/// (un seul stream DB partagé par toutes les tuiles)
final _favoriteStatesByRefProvider = Provider<AsyncValue<Map<String, FavoriteState>>>((ref) {
  return ref
      .watch(favoritesProvider)
      .whenData(
        (favorites) => {
          for (final f in favorites)
            f.pointRef: f.isSuperFavorite ? FavoriteState.superFavorite : FavoriteState.favorite,
        },
      );
});

/// Provider pour l'état complet du favori (none, favorite, superFavorite)
/// Dérivé de [favoritesProvider] : la tuile ne se reconstruit que si l'état
/// de SON point change.
final favoriteStateProvider = Provider.autoDispose.family<AsyncValue<FavoriteState>, String>((ref, pointRef) {
  return ref.watch(
    _favoriteStatesByRefProvider.select((async) => async.whenData((states) => states[pointRef] ?? FavoriteState.none)),
  );
});

/// Notifier pour gérer les actions sur les favoris
class FavoritesNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  FavoritesNotifier(this._ref) : super(const AsyncValue.data(null));

  /// pointRefs dont le cycle est en cours (évite un double tap concurrent)
  final Set<String> _cycling = {};

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

    if (!_cycling.add(object.objectId)) {
      _logger.d('cycleFavoriteState: ${object.objectId} already cycling, ignored');
      return _ref.read(favoriteStateProvider(object.objectId)).valueOrNull ?? FavoriteState.none;
    }

    try {
      state = const AsyncValue.loading();

      // Lecture + écriture dans une transaction (atomique)
      final newState = await database.transaction(() async {
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
          await database.addFavorite(
            FavoritesCompanion.insert(
              connectionId: connectionId,
              pointRef: object.objectId,
              pointName: object.objectName,
              pointDescription: Value(object.description),
              objectType: object.type.apiName,
              // wasPromoted = false par défaut
            ),
          );
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
        return newState;
      });

      state = const AsyncValue.data(null);
      return newState;
    } catch (e, st) {
      _logger.e('cycleFavoriteState error: $e');
      state = AsyncValue.error(e, st);
      return _ref.read(favoriteStateProvider(object.objectId)).valueOrNull ?? FavoriteState.none;
    } finally {
      _cycling.remove(object.objectId);
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
}

/// Provider pour les actions sur les favoris
final favoritesNotifierProvider = StateNotifierProvider<FavoritesNotifier, AsyncValue<void>>((ref) {
  return FavoritesNotifier(ref);
});
