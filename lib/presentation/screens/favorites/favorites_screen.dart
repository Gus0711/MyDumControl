import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/favorites_provider.dart';
import '../../../application/providers/points_provider.dart';
import '../../../application/providers/active_connection_provider.dart';
import '../../../application/providers/super_favorites_provider.dart';
import '../../../application/providers/trend_log_provider.dart';
import '../../../core/router/routes.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/models/bacnet_object.dart';
import '../../shared/utils/bacnet_type_utils.dart';

/// Écran des favoris - affiche les points favoris avec leurs valeurs live
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);
    final connectionState = ref.watch(activeConnectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoris'),
        actions: [
          // Bouton pour tout supprimer
          favoritesAsync.maybeWhen(
            data: (favorites) => favorites.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.delete_sweep),
                    tooltip: 'Supprimer tous les favoris',
                    onPressed: () => _confirmDeleteAll(context, ref),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(pointsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: !connectionState.isConnected
          ? _buildNotConnected(context)
          : favoritesAsync.when(
              data: (favorites) => _buildFavoritesList(context, ref, favorites),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text('Erreur: $error'),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNotConnected(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Non connecté',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connectez-vous à un automate pour voir vos favoris',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(
    BuildContext context,
    WidgetRef ref,
    List<Favorite> favorites,
  ) {
    if (favorites.isEmpty) {
      return _buildEmptyState(context);
    }

    // Récupérer les points pour avoir les valeurs live
    final pointsState = ref.watch(pointsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(pointsProvider.notifier).refresh(),
      child: ReorderableListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: favorites.length,
        onReorder: (oldIndex, newIndex) {
          if (newIndex > oldIndex) newIndex--;
          final ids = favorites.map((f) => f.id).toList();
          final movedId = ids.removeAt(oldIndex);
          ids.insert(newIndex, movedId);
          ref.read(favoritesNotifierProvider.notifier).reorderFavorites(ids);
        },
        itemBuilder: (context, index) {
          final favorite = favorites[index];
          // Chercher le point live correspondant
          final livePoint = _findLivePoint(pointsState.points, favorite);

          return _FavoriteTile(
            key: ValueKey(favorite.id),
            favorite: favorite,
            livePoint: livePoint,
            onTap: () => _navigateToPoint(context, favorite),
            onDelete: () => _deleteFavorite(context, ref, favorite),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 24),
          Text(
            'Aucun favori',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des points aux favoris en cliquant\nsur l\'étoile dans la liste des points',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => GoRouter.of(context).push(Routes.points),
            icon: const Icon(Icons.list_alt),
            label: const Text('Voir les points'),
          ),
        ],
      ),
    );
  }

  BacnetObject? _findLivePoint(List<BacnetObject> points, Favorite favorite) {
    // Le pointRef est au format "AV:1" ou "BI:5"
    // On doit matcher avec type.shortName:instance
    try {
      return points.firstWhere(
        (p) => p.objectId == favorite.pointRef,
      );
    } catch (_) {
      return null;
    }
  }

  void _navigateToPoint(BuildContext context, Favorite favorite) {
    // Convertir le pointRef (ex: "AV:1") en format du router (ex: "analogValue:1")
    final parts = favorite.pointRef.split(':');
    if (parts.length != 2) return;

    // Trouver le type par shortName
    final type = BacnetObjectType.values.cast<BacnetObjectType?>().firstWhere(
          (t) => t?.shortName == parts[0],
          orElse: () => null,
        );

    if (type != null) {
      context.push(Routes.pointDetailPath('${type.name}:${parts[1]}'));
    }
  }

  Future<void> _deleteFavorite(
    BuildContext context,
    WidgetRef ref,
    Favorite favorite,
  ) async {
    await ref.read(favoritesNotifierProvider.notifier).removeFavoriteById(favorite.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${favorite.pointName} retiré des favoris'),
          action: SnackBarAction(
            label: 'Annuler',
            onPressed: () {
              // TODO: Implémenter l'annulation (nécessite de stocker le favori supprimé)
            },
          ),
        ),
      );
    }
  }

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer tous les favoris ?'),
        content: const Text(
          'Cette action supprimera tous vos favoris pour cet automate.\n\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer tout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(favoritesNotifierProvider.notifier).clearAllFavorites();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tous les favoris ont été supprimés')),
        );
      }
    }
  }
}

/// Tile pour afficher un favori avec sa valeur live
class _FavoriteTile extends ConsumerWidget {
  final Favorite favorite;
  final BacnetObject? livePoint;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FavoriteTile({
    super.key,
    required this.favorite,
    this.livePoint,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Récupérer le type BacnetObjectType depuis le String apiName
    final type = BacnetObjectType.values.cast<BacnetObjectType?>().firstWhere(
          (t) => t?.apiName == favorite.objectType,
          orElse: () => null,
        );

    final typeColor = type != null
        ? BacnetTypeUtils.getTypeColor(type)
        : Colors.grey;

    final valueColor = livePoint != null
        ? BacnetTypeUtils.getValueColor(livePoint!)
        : Colors.grey;

    // Construire la clé pour le trend log (format: "analog-value:123")
    final parts = favorite.pointRef.split(':');
    final instance = parts.length > 1 ? parts[1] : '';
    final trendLogKey = '${favorite.objectType}:$instance';
    final hasTrendLog = ref.watch(hasTrendLogProvider(trendLogKey));

    return Dismissible(
      key: ValueKey(favorite.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: typeColor.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            type != null ? BacnetTypeUtils.getTypeIcon(type) : Icons.help_outline,
            color: typeColor,
            size: 20,
          ),
        ),
        title: Text(
          favorite.pointName,
          style: const TextStyle(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              favorite.pointRef,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontFamily: 'monospace',
              ),
            ),
            if (favorite.pointDescription != null) ...[
              const Text(' - ', style: TextStyle(fontSize: 12)),
              Expanded(
                child: Text(
                  favorite.pointDescription!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouton Super Favori
            IconButton(
              icon: Icon(
                favorite.isSuperFavorite ? Icons.star : Icons.star_border,
                color: favorite.isSuperFavorite ? Colors.amber : Colors.grey.shade400,
                size: 20,
              ),
              tooltip: favorite.isSuperFavorite
                  ? 'Retirer des super favoris'
                  : 'Ajouter aux super favoris',
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                final toggleFn = ref.read(toggleSuperFavoriteProvider);
                await toggleFn(favorite.id);
              },
            ),
            // Indicateur de trend log
            if (hasTrendLog)
              Tooltip(
                message: 'Trend log disponible',
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.show_chart,
                    size: 16,
                    color: Colors.blue.shade600,
                  ),
                ),
              ),
            // Indicateur de forçage
            if (livePoint?.isOverridden == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, size: 10, color: Colors.red.shade700),
                    const SizedBox(width: 2),
                    Text(
                      'P${livePoint!.overridePriority}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            // Valeur
            Container(
              constraints: const BoxConstraints(minWidth: 60),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: valueColor.withAlpha(30),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                livePoint != null
                    ? BacnetTypeUtils.formatValue(livePoint!)
                    : '-',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 4),
            // Handle pour réorganiser
            ReorderableDragStartListener(
              index: 0, // sera ignoré car on utilise ReorderableListView
              child: Icon(Icons.drag_handle, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}
