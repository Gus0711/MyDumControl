import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/active_connection_provider.dart';
import '../../application/providers/database_provider.dart';
import '../../application/providers/favorites_provider.dart';
import '../../domain/models/bacnet_object.dart';

/// Id of the active connection only (does not change on refresh/state ticks).
final _activeConnectionIdProvider = Provider<int?>((ref) {
  return ref.watch(activeConnectionProvider.select((s) => s.connection?.id));
});

/// Favorite state of every favorite point of the active connection, keyed by
/// pointRef. One single Drift stream shared by all FavoriteButtons (a point
/// absent from the map is not a favorite).
final favoriteStatesMapProvider =
    StreamProvider<Map<String, FavoriteState>>((ref) {
  final connectionId = ref.watch(_activeConnectionIdProvider);
  if (connectionId == null) return Stream.value(const {});
  final database = ref.watch(databaseProvider);
  return database.watchFavoritesByConnection(connectionId).map((favorites) => {
        for (final f in favorites)
          f.pointRef: f.isSuperFavorite
              ? FavoriteState.superFavorite
              : FavoriteState.favorite,
      });
});

/// Bouton pour gérer l'état favori d'un point (cycle à 3 états)
/// ☆ (gris) → ⭐ (jaune) → ✨ (orange) → ☆ (gris)
class FavoriteButton extends ConsumerWidget {
  final BacnetObject point;
  final double size;

  const FavoriteButton({
    super.key,
    required this.point,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Select only this point's state so a tile rebuilds only when it changes.
    final state = ref.watch(favoriteStatesMapProvider.select(
      (async) => async.valueOrNull?[point.objectId] ?? FavoriteState.none,
    ));
    return _buildButton(context, ref, state);
  }

  Widget _buildButton(BuildContext context, WidgetRef ref, FavoriteState state) {
    final (icon, color, tooltip) = _getIconData(state);

    return IconButton(
      icon: Icon(icon, color: color, size: size),
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(
        minWidth: size + 8,
        minHeight: size + 8,
      ),
      tooltip: tooltip,
      onPressed: () async {
        final notifier = ref.read(favoritesNotifierProvider.notifier);
        await notifier.cycleFavoriteState(point);
      },
    );
  }

  /// Retourne l'icône, la couleur et le tooltip selon l'état
  (IconData, Color, String) _getIconData(FavoriteState state) {
    switch (state) {
      case FavoriteState.none:
        return (
          Icons.star_border,
          Colors.grey,
          'Ajouter aux favoris',
        );
      case FavoriteState.favorite:
        return (
          Icons.star,
          Colors.amber,
          'Promouvoir en super favori',
        );
      case FavoriteState.superFavorite:
        return (
          Icons.auto_awesome,
          Colors.amber.shade600,
          'Rétrograder en favori',
        );
    }
  }
}
