import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/favorites_provider.dart';
import '../../domain/models/bacnet_object.dart';

/// Bouton pour ajouter/retirer un point des favoris
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
    final isFavoriteAsync = ref.watch(isFavoriteProvider(point.objectId));

    return isFavoriteAsync.when(
      data: (isFavorite) => IconButton(
        icon: Icon(
          isFavorite ? Icons.star : Icons.star_border,
          color: isFavorite ? Colors.amber : Colors.grey,
          size: size,
        ),
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(
          minWidth: size + 8,
          minHeight: size + 8,
        ),
        tooltip: isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
        onPressed: () async {
          final notifier = ref.read(favoritesNotifierProvider.notifier);
          await notifier.toggleFavorite(point);
        },
      ),
      loading: () => SizedBox(
        width: size + 8,
        height: size + 8,
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => IconButton(
        icon: Icon(
          Icons.star_border,
          color: Colors.grey,
          size: size,
        ),
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(
          minWidth: size + 8,
          minHeight: size + 8,
        ),
        onPressed: () async {
          final notifier = ref.read(favoritesNotifierProvider.notifier);
          await notifier.toggleFavorite(point);
        },
      ),
    );
  }
}
