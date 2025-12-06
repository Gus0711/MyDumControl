import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/favorites_provider.dart';
import '../../domain/models/bacnet_object.dart';

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
    final favoriteStateAsync = ref.watch(favoriteStateProvider(point.objectId));

    return favoriteStateAsync.when(
      data: (state) => _buildButton(context, ref, state),
      loading: () => SizedBox(
        width: size + 8,
        height: size + 8,
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, _) => _buildButton(context, ref, FavoriteState.none),
    );
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
