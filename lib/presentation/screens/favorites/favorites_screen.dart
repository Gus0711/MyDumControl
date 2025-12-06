import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/favorites_provider.dart';
import '../../../application/providers/favorite_folders_provider.dart';
import '../../../application/providers/points_provider.dart';
import '../../../application/providers/active_connection_provider.dart';
import '../../../application/providers/trend_log_provider.dart';
import '../../../core/router/routes.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/models/bacnet_object.dart';
import '../../shared/utils/bacnet_type_utils.dart';
import '../../widgets/favorite_button.dart';
import '../../widgets/favorite_folder_dialog.dart';
import '../../widgets/assign_folders_dialog.dart';

/// Écran des favoris - affiche les points favoris organisés par dossiers
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  final Set<int> _expandedFolders = {};
  bool _unassignedExpanded = true;

  // Mode sélection multiple
  bool _selectionMode = false;
  final Set<int> _selectedFavoriteIds = {};

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) {
        _selectedFavoriteIds.clear();
      }
    });
  }

  void _toggleFavoriteSelection(int favoriteId) {
    setState(() {
      if (_selectedFavoriteIds.contains(favoriteId)) {
        _selectedFavoriteIds.remove(favoriteId);
      } else {
        _selectedFavoriteIds.add(favoriteId);
      }
      // Désactiver le mode si plus rien n'est sélectionné
      if (_selectedFavoriteIds.isEmpty && _selectionMode) {
        _selectionMode = false;
      }
    });
  }

  void _selectAll(List<Favorite> allFavorites) {
    setState(() {
      _selectedFavoriteIds.addAll(allFavorites.map((f) => f.id));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedFavoriteIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(activeConnectionProvider);
    final foldersAsync = ref.watch(favoriteFoldersProvider);
    final unassignedAsync = ref.watch(unassignedFavoritesProvider);
    final allFavoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: _selectionMode
            ? Text('${_selectedFavoriteIds.length} sélectionné${_selectedFavoriteIds.length > 1 ? 's' : ''}')
            : const Text('Favoris'),
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: [
          if (_selectionMode) ...[
            // Sélectionner tout
            allFavoritesAsync.maybeWhen(
              data: (allFavorites) => IconButton(
                icon: Icon(
                  _selectedFavoriteIds.length == allFavorites.length
                      ? Icons.deselect
                      : Icons.select_all,
                ),
                tooltip: _selectedFavoriteIds.length == allFavorites.length
                    ? 'Tout désélectionner'
                    : 'Tout sélectionner',
                onPressed: () {
                  if (_selectedFavoriteIds.length == allFavorites.length) {
                    _deselectAll();
                  } else {
                    _selectAll(allFavorites);
                  }
                },
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ] else ...[
            // Mode normal
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: 'Mode sélection',
              onPressed: _toggleSelectionMode,
            ),
            IconButton(
              icon: const Icon(Icons.create_new_folder_outlined),
              tooltip: 'Nouveau dossier',
              onPressed: () => _createFolder(context),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Rafraîchir',
              onPressed: () => ref.read(pointsProvider.notifier).refresh(),
            ),
          ],
        ],
      ),
      body: !connectionState.isConnected
          ? _buildNotConnected(context)
          : foldersAsync.when(
              data: (folders) => unassignedAsync.when(
                data: (unassigned) => _buildContent(context, folders, unassigned),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur: $e')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
            ),
      // Barre d'actions en bas quand sélection active
      bottomNavigationBar: _selectionMode && _selectedFavoriteIds.isNotEmpty
          ? _buildSelectionActions(context)
          : null,
    );
  }

  Widget _buildSelectionActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _assignSelectedToFolders(context),
                icon: const Icon(Icons.folder),
                label: const Text('Assigner aux dossiers'),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _deleteSelected(context),
              icon: const Icon(Icons.delete),
              label: const Text('Supprimer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignSelectedToFolders(BuildContext context) async {
    final foldersAsync = ref.read(favoriteFoldersProvider);
    final folders = foldersAsync.valueOrNull ?? [];

    if (folders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Créez d\'abord un dossier')),
      );
      return;
    }

    // Dialog pour choisir les dossiers
    final selectedFolderIds = await showDialog<List<int>>(
      context: context,
      builder: (context) => _SelectFoldersForBatchDialog(folders: folders),
    );

    if (selectedFolderIds != null && selectedFolderIds.isNotEmpty) {
      final notifier = ref.read(favoriteFoldersNotifierProvider.notifier);
      for (final favoriteId in _selectedFavoriteIds) {
        // Ajouter aux dossiers sélectionnés (sans retirer des autres)
        for (final folderId in selectedFolderIds) {
          await notifier.assignToFolder(favoriteId, folderId);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedFavoriteIds.length} favori${_selectedFavoriteIds.length > 1 ? 's' : ''} '
              'assigné${_selectedFavoriteIds.length > 1 ? 's' : ''} à '
              '${selectedFolderIds.length} dossier${selectedFolderIds.length > 1 ? 's' : ''}',
            ),
          ),
        );
        _toggleSelectionMode();
      }
    }
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer les favoris ?'),
        content: Text(
          'Voulez-vous supprimer ${_selectedFavoriteIds.length} favori${_selectedFavoriteIds.length > 1 ? 's' : ''} ?',
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
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final notifier = ref.read(favoritesNotifierProvider.notifier);
      for (final favoriteId in _selectedFavoriteIds) {
        await notifier.removeFavoriteById(favoriteId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedFavoriteIds.length} favori${_selectedFavoriteIds.length > 1 ? 's' : ''} supprimé${_selectedFavoriteIds.length > 1 ? 's' : ''}'),
          ),
        );
        _toggleSelectionMode();
      }
    }
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
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
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

  Widget _buildContent(
    BuildContext context,
    List<FavoriteFolder> folders,
    List<Favorite> unassigned,
  ) {
    final hasContent = folders.isNotEmpty || unassigned.isNotEmpty;

    if (!hasContent) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(pointsProvider.notifier).refresh(),
      child: ReorderableListView(
        padding: EdgeInsets.only(bottom: _selectionMode ? 100 : 80),
        onReorder: (oldIndex, newIndex) {
          if (_selectionMode) return; // Pas de réordonnancement en mode sélection
          if (newIndex > oldIndex) newIndex--;
          final folderIds = folders.map((f) => f.id).toList();
          if (oldIndex < folderIds.length && newIndex <= folderIds.length) {
            final movedId = folderIds.removeAt(oldIndex);
            folderIds.insert(newIndex, movedId);
            ref.read(favoriteFoldersNotifierProvider.notifier).reorderFolders(folderIds);
          }
        },
        children: [
          // Dossiers
          ...folders.map((folder) => _FolderSection(
                key: ValueKey('folder_${folder.id}'),
                folder: folder,
                isExpanded: _expandedFolders.contains(folder.id),
                onToggle: () => setState(() {
                  if (_expandedFolders.contains(folder.id)) {
                    _expandedFolders.remove(folder.id);
                  } else {
                    _expandedFolders.add(folder.id);
                  }
                }),
                onEdit: () => _editFolder(context, folder),
                onDelete: () => _deleteFolder(context, folder),
                selectionMode: _selectionMode,
                selectedIds: _selectedFavoriteIds,
                onToggleSelection: _toggleFavoriteSelection,
                onAssignFavorite: (favoriteId, folderId) => _assignFavoriteToFolder(context, favoriteId, folderId),
              )),

          // Favoris sans dossier
          if (unassigned.isNotEmpty)
            _UnassignedSection(
              key: const ValueKey('unassigned'),
              favorites: unassigned,
              isExpanded: _unassignedExpanded,
              onToggle: () => setState(() {
                _unassignedExpanded = !_unassignedExpanded;
              }),
              selectionMode: _selectionMode,
              selectedIds: _selectedFavoriteIds,
              onToggleSelection: _toggleFavoriteSelection,
            ),
        ],
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

  Future<void> _createFolder(BuildContext context) async {
    final result = await FavoriteFolderDialog.show(context);
    if (result != null) {
      final id = await ref.read(favoriteFoldersNotifierProvider.notifier).createFolder(
            name: result.name,
            color: result.color,
            icon: result.icon,
          );
      if (id != null) {
        setState(() {
          _expandedFolders.add(id);
        });
      }
    }
  }

  Future<void> _editFolder(BuildContext context, FavoriteFolder folder) async {
    final result = await FavoriteFolderDialog.show(context, folder: folder);
    if (result != null) {
      await ref.read(favoriteFoldersNotifierProvider.notifier).updateFolder(
            folderId: folder.id,
            name: result.name,
            color: result.color,
            icon: result.icon,
          );
    }
  }

  Future<void> _assignFavoriteToFolder(BuildContext context, int favoriteId, int folderId) async {
    final success = await ref.read(favoriteFoldersNotifierProvider.notifier).assignToFolder(favoriteId, folderId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Favori ajouté au dossier'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _deleteFolder(BuildContext context, FavoriteFolder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le dossier ?'),
        content: Text(
          'Le dossier "${folder.name}" sera supprimé.\n\n'
          'Les favoris qu\'il contient ne seront pas supprimés, '
          'ils seront déplacés dans "Sans dossier".',
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
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(favoriteFoldersNotifierProvider.notifier).deleteFolder(folder.id);
      _expandedFolders.remove(folder.id);
    }
  }
}

/// Section d'un dossier de favoris
class _FolderSection extends ConsumerWidget {
  final FavoriteFolder folder;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool selectionMode;
  final Set<int> selectedIds;
  final void Function(int) onToggleSelection;
  final void Function(int favoriteId, int folderId) onAssignFavorite;

  const _FolderSection({
    super.key,
    required this.folder,
    required this.isExpanded,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.selectionMode,
    required this.selectedIds,
    required this.onToggleSelection,
    required this.onAssignFavorite,
  });

  Color _parseColor(String hex) {
    try {
      final hexCode = hex.replaceFirst('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  IconData _getIconData(String iconName) {
    final entry = folderIcons.cast<(String, IconData)?>().firstWhere(
          (e) => e?.$1 == iconName,
          orElse: () => null,
        );
    return entry?.$2 ?? Icons.folder;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesInFolderProvider(folder.id));
    final color = _parseColor(folder.color);
    final icon = _getIconData(folder.icon);

    return favoritesAsync.when(
      data: (favorites) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du dossier avec DragTarget
          DragTarget<int>(
            onWillAcceptWithDetails: (details) => true,
            onAcceptWithDetails: (details) {
              onAssignFavorite(details.data, folder.id);
            },
            builder: (context, candidateData, rejectedData) {
              final isHovering = candidateData.isNotEmpty;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isHovering ? color.withAlpha(30) : Colors.transparent,
                  border: isHovering
                      ? Border.all(color: color, width: 2)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: isHovering
                    ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
                    : EdgeInsets.zero,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onToggle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          // Handle drag
                          ReorderableDragStartListener(
                            index: 0,
                            child: Icon(Icons.drag_handle, color: Colors.grey.shade400, size: 20),
                          ),
                          const SizedBox(width: 8),
                          // Icône du dossier
                          AnimatedScale(
                            scale: isHovering ? 1.2 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(icon, color: color, size: 28),
                          ),
                          const SizedBox(width: 12),
                          // Nom et compteur
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  folder.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  isHovering
                                      ? 'Déposez ici pour ajouter'
                                      : '${favorites.length} favori${favorites.length > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isHovering ? color : Colors.grey.shade600,
                                    fontWeight: isHovering ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Menu actions
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  onEdit();
                                  break;
                                case 'delete':
                                  onDelete();
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Modifier'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Text('Supprimer', style: TextStyle(color: Colors.red.shade400)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Chevron expand/collapse
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Favoris dans le dossier
          if (isExpanded) ...[
            if (favorites.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 72, bottom: 8),
                child: Text(
                  'Dossier vide - glissez des favoris ici',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ...favorites.map((favorite) => _FavoriteTileInFolder(
                    favorite: favorite,
                    folderId: folder.id,
                    selectionMode: selectionMode,
                    isSelected: selectedIds.contains(favorite.id),
                    onToggleSelection: () => onToggleSelection(favorite.id),
                  )),
          ],
          const Divider(height: 1),
        ],
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// Section des favoris sans dossier
class _UnassignedSection extends ConsumerWidget {
  final List<Favorite> favorites;
  final bool isExpanded;
  final VoidCallback onToggle;
  final bool selectionMode;
  final Set<int> selectedIds;
  final void Function(int) onToggleSelection;

  const _UnassignedSection({
    super.key,
    required this.favorites,
    required this.isExpanded,
    required this.onToggle,
    required this.selectionMode,
    required this.selectedIds,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const SizedBox(width: 28), // Espace pour aligner avec les dossiers
                  Icon(Icons.folder_off_outlined, color: Colors.grey.shade500, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sans dossier',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                        ),
                        Text(
                          '${favorites.length} favori${favorites.length > 1 ? 's' : ''}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Favoris
        if (isExpanded)
          ...favorites.map((favorite) => _FavoriteTileInFolder(
                favorite: favorite,
                folderId: null,
                selectionMode: selectionMode,
                isSelected: selectedIds.contains(favorite.id),
                onToggleSelection: () => onToggleSelection(favorite.id),
              )),
        const Divider(height: 1),
      ],
    );
  }
}

/// Tile pour un favori dans un dossier (ou sans dossier)
class _FavoriteTileInFolder extends ConsumerWidget {
  final Favorite favorite;
  final int? folderId;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback? onToggleSelection;

  const _FavoriteTileInFolder({
    required this.favorite,
    required this.folderId,
    this.selectionMode = false,
    this.isSelected = false,
    this.onToggleSelection,
  });

  Color _parseColor(String hex) {
    try {
      final hexCode = hex.replaceFirst('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pointsState = ref.watch(pointsProvider);
    final livePoint = _findLivePoint(pointsState.points, favorite);
    final folderIdsAsync = ref.watch(folderIdsForFavoriteProvider(favorite.id));
    final foldersAsync = ref.watch(foldersForFavoriteProvider(favorite.id));

    final type = BacnetObjectType.values.cast<BacnetObjectType?>().firstWhere(
          (t) => t?.apiName == favorite.objectType,
          orElse: () => null,
        );

    final typeColor = type != null ? BacnetTypeUtils.getTypeColor(type) : Colors.grey;
    final valueColor = livePoint != null ? BacnetTypeUtils.getValueColor(livePoint) : Colors.grey;

    // Trend log
    final parts = favorite.pointRef.split(':');
    final instance = parts.length > 1 ? parts[1] : '';
    final trendLogKey = '${favorite.objectType}:$instance';
    final hasTrendLog = ref.watch(hasTrendLogProvider(trendLogKey));

    // Tags des dossiers
    final folders = foldersAsync.valueOrNull ?? [];

    // Widget du contenu de la tile
    final tileContent = ListTile(
      onTap: selectionMode
          ? onToggleSelection
          : () => _navigateToPoint(context, favorite),
      onLongPress: selectionMode
          ? null
          : () => _showAssignDialog(context, ref, favorite, folderIdsAsync),
      contentPadding: EdgeInsets.only(left: selectionMode ? 16 : 56, right: 8),
      leading: selectionMode
          ? Checkbox(
              value: isSelected,
              onChanged: (_) => onToggleSelection?.call(),
            )
          : Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: typeColor.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                type != null ? BacnetTypeUtils.getTypeIcon(type) : Icons.help_outline,
                color: typeColor,
                size: 18,
              ),
            ),
      title: Text(
        favorite.pointName,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Text(
            favorite.pointRef,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontFamily: 'monospace'),
          ),
          if (folders.isNotEmpty) ...[
            const SizedBox(width: 8),
            // Tags colorés des dossiers
            ...folders.take(4).map((folder) => Tooltip(
                  message: folder.name,
                  child: Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 3),
                    decoration: BoxDecoration(
                      color: _parseColor(folder.color),
                      shape: BoxShape.circle,
                    ),
                  ),
                )),
            if (folders.length > 4)
              Text(
                '+${folders.length - 4}',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
              ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton assigner aux dossiers
          IconButton(
            icon: Icon(
              Icons.folder_outlined,
              size: 18,
              color: Colors.grey.shade600,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Assigner aux dossiers',
            onPressed: () => _showAssignDialog(context, ref, favorite, folderIdsAsync),
          ),
          // Bouton favori
          if (livePoint != null)
            FavoriteButton(point: livePoint, size: 18)
          else
            Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                favorite.isSuperFavorite ? Icons.auto_awesome : Icons.star,
                color: favorite.isSuperFavorite ? Colors.amber.shade600 : Colors.amber,
                size: 18,
              ),
            ),
          // Trend log
          if (hasTrendLog)
            Icon(Icons.show_chart, size: 16, color: Colors.blue.shade600),
          // Override indicator
          if (livePoint?.isOverridden == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'P${livePoint!.overridePriority}',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red.shade700),
              ),
            ),
          // Valeur
          Container(
            constraints: const BoxConstraints(minWidth: 50),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: valueColor.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              livePoint != null ? BacnetTypeUtils.formatValue(livePoint) : '-',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: valueColor),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );

    // En mode sélection, pas de drag & drop
    if (selectionMode) {
      return tileContent;
    }

    // Wrapping dans LongPressDraggable pour le drag & drop
    return LongPressDraggable<int>(
      data: favorite.id,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: typeColor, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  favorite.pointName,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: tileContent,
      ),
      child: Dismissible(
        key: ValueKey('fav_${favorite.id}_$folderId'),
        direction: DismissDirection.endToStart,
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) async {
          await ref.read(favoritesNotifierProvider.notifier).removeFavoriteById(favorite.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${favorite.pointName} retiré des favoris')),
            );
          }
        },
        child: tileContent,
      ),
    );
  }

  BacnetObject? _findLivePoint(List<BacnetObject> points, Favorite favorite) {
    try {
      return points.firstWhere((p) => p.objectId == favorite.pointRef);
    } catch (_) {
      return null;
    }
  }

  void _navigateToPoint(BuildContext context, Favorite favorite) {
    final parts = favorite.pointRef.split(':');
    if (parts.length != 2) return;

    final type = BacnetObjectType.values.cast<BacnetObjectType?>().firstWhere(
          (t) => t?.shortName == parts[0],
          orElse: () => null,
        );

    if (type != null) {
      context.push(Routes.pointDetailPath('${type.name}:${parts[1]}'));
    }
  }

  Future<void> _showAssignDialog(
    BuildContext context,
    WidgetRef ref,
    Favorite favorite,
    AsyncValue<List<int>> folderIdsAsync,
  ) async {
    final currentIds = folderIdsAsync.valueOrNull ?? [];
    final result = await AssignFoldersDialog.show(
      context,
      favorite: favorite,
      currentFolderIds: currentIds,
    );

    if (result != null) {
      await ref.read(favoriteFoldersNotifierProvider.notifier).setFavoriteFolders(
            favorite.id,
            result,
          );
    }
  }
}

/// Dialog pour sélectionner des dossiers (assignation en lot)
class _SelectFoldersForBatchDialog extends StatefulWidget {
  final List<FavoriteFolder> folders;

  const _SelectFoldersForBatchDialog({required this.folders});

  @override
  State<_SelectFoldersForBatchDialog> createState() => _SelectFoldersForBatchDialogState();
}

class _SelectFoldersForBatchDialogState extends State<_SelectFoldersForBatchDialog> {
  final Set<int> _selectedFolderIds = {};

  Color _parseColor(String hex) {
    try {
      final hexCode = hex.replaceFirst('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  IconData _getIconData(String iconName) {
    final entry = folderIcons.cast<(String, IconData)?>().firstWhere(
          (e) => e?.$1 == iconName,
          orElse: () => null,
        );
    return entry?.$2 ?? Icons.folder;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assigner aux dossiers'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sélectionnez les dossiers auxquels ajouter les favoris',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.folders.map((folder) {
                    final isSelected = _selectedFolderIds.contains(folder.id);
                    final color = _parseColor(folder.color);
                    final icon = _getIconData(folder.icon);

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedFolderIds.add(folder.id);
                          } else {
                            _selectedFolderIds.remove(folder.id);
                          }
                        });
                      },
                      title: Text(folder.name),
                      secondary: Icon(icon, color: color),
                      dense: true,
                      controlAffinity: ListTileControlAffinity.trailing,
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _selectedFolderIds.isEmpty
              ? null
              : () => Navigator.pop(context, _selectedFolderIds.toList()),
          child: const Text('Assigner'),
        ),
      ],
    );
  }
}
