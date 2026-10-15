import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/favorites_provider.dart';
import '../../../application/providers/favorite_folders_provider.dart';
import '../../../application/providers/points_provider.dart';
import '../../../application/providers/active_connection_provider.dart';
import '../../../application/providers/trend_log_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/models/bacnet_object.dart';
import '../../shared/utils/bacnet_type_utils.dart';
import '../../widgets/favorite_button.dart';
import '../../widgets/favorite_folder_dialog.dart';
import '../../widgets/assign_folders_dialog.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/point_widgets.dart';
import '../../widgets/ui/ui.dart';
import '../../../l10n/app_localizations.dart';

/// Écran des favoris - affiche les points favoris organisés par dossiers
/// Live points indexed by objectId (O(1) lookup per favorite tile).
final _pointsByIdProvider = Provider<Map<String, BacnetObject>>((ref) {
  final points = ref.watch(pointsProvider.select((s) => s.points));
  return {for (final p in points) p.objectId: p};
});

/// favoriteId -> folders containing it, derived from the folder streams.
final _foldersByFavoriteProvider = Provider<Map<int, List<FavoriteFolder>>>((ref) {
  final folders = ref.watch(favoriteFoldersProvider).valueOrNull ?? const <FavoriteFolder>[];
  final map = <int, List<FavoriteFolder>>{};
  for (final folder in folders) {
    final favorites = ref.watch(favoritesInFolderProvider(folder.id)).valueOrNull ?? const <Favorite>[];
    for (final favorite in favorites) {
      map.putIfAbsent(favorite.id, () => []).add(folder);
    }
  }
  return map;
});

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
    final l10n = AppLocalizations.of(context)!;
    final connectionState = ref.watch(activeConnectionProvider);
    final foldersAsync = ref.watch(favoriteFoldersProvider);
    final unassignedAsync = ref.watch(unassignedFavoritesProvider);
    final allFavoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: GradientAppBar(
        titleWidget: _selectionMode
            ? Text(l10n.selectedCount(_selectedFavoriteIds.length))
            : Text(l10n.favorites),
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
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
                      ? Icons.deselect_rounded
                      : Icons.select_all_rounded,
                ),
                tooltip: _selectedFavoriteIds.length == allFavorites.length
                    ? l10n.deselectAll
                    : l10n.selectAll,
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
              icon: const Icon(Icons.checklist_rounded),
              tooltip: l10n.selectionMode,
              onPressed: _toggleSelectionMode,
            ),
            IconButton(
              icon: const Icon(Icons.create_new_folder_outlined),
              tooltip: l10n.newFolder,
              onPressed: () => _createFolder(context),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: l10n.refresh,
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
                loading: () => const DcLoading(),
                error: (e, _) => DcEmptyState.error(context, title: l10n.error, message: '$e'),
              ),
              loading: () => const DcLoading(),
              error: (e, _) => DcEmptyState.error(context, title: l10n.error, message: '$e'),
            ),
      // Barre d'actions en bas quand sélection active
      bottomNavigationBar: _selectionMode && _selectedFavoriteIds.isNotEmpty
          ? _buildSelectionActions(context)
          : null,
    );
  }

  Widget _buildSelectionActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dc = context.dc;
    return Container(
      decoration: BoxDecoration(
        color: dc.surface,
        border: Border(top: BorderSide(color: dc.border)),
        boxShadow: dc.raisedShadow,
      ),
      child: SafeArea(
        child: DcContent(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.selectedCount(_selectedFavoriteIds.length),
                  style: context.text.bodyMedium?.copyWith(color: dc.textSecondary),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _deleteSelected(context),
                icon: Icon(Icons.delete_outline_rounded, color: dc.danger.fg),
                label: Text(l10n.delete, style: TextStyle(color: dc.danger.fg)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: dc.danger.border)),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: () => _assignSelectedToFolders(context),
                icon: const Icon(Icons.drive_file_move_outline),
                label: Text(l10n.assignToFolders),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _assignSelectedToFolders(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final foldersAsync = ref.read(favoriteFoldersProvider);
    final folders = foldersAsync.valueOrNull ?? [];

    if (folders.isEmpty) {
      context.showInfo(l10n.createFolderFirst);
      return;
    }

    // Dialog pour choisir les dossiers
    final selectedFolderIds = await showDialog<List<int>>(
      context: context,
      builder: (context) => _SelectFoldersForBatchDialog(folders: folders),
    );

    if (selectedFolderIds != null && selectedFolderIds.isNotEmpty) {
      final notifier = ref.read(favoriteFoldersNotifierProvider.notifier);
      final ids = _selectedFavoriteIds.toList(); // snapshot: the set may change during awaits
      for (final favoriteId in ids) {
        // Ajouter aux dossiers sélectionnés (sans retirer des autres)
        for (final folderId in selectedFolderIds) {
          await notifier.assignToFolder(favoriteId, folderId);
        }
      }

      if (context.mounted) {
        context.showSuccess(l10n.favoritesAssigned(ids.length, selectedFolderIds.length));
        _toggleSelectionMode();
      }
    }
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteFavoritesConfirm),
        content: Text(
          l10n.deleteFavoritesMessage(_selectedFavoriteIds.length),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: context.dc.danger.fg,
              foregroundColor: context.dc.onSolid,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final notifier = ref.read(favoritesNotifierProvider.notifier);
      final ids = _selectedFavoriteIds.toList(); // snapshot: the set may change during awaits
      for (final favoriteId in ids) {
        await notifier.removeFavoriteById(favoriteId);
      }

      if (context.mounted) {
        context.showSuccess(l10n.favoritesDeleted(ids.length));
        _toggleSelectionMode();
      }
    }
  }

  Widget _buildNotConnected(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DcEmptyState(
      icon: Icons.cloud_off_rounded,
      title: l10n.notConnected,
      message: l10n.connectToViewFavorites,
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
        padding: EdgeInsets.only(top: 8, bottom: _selectionMode ? 100 : 80),
        // onReorderItem: newIndex is already adjusted for the removed item
        onReorderItem: (oldIndex, newIndex) {
          if (_selectionMode) return; // Pas de réordonnancement en mode sélection
          final folderIds = folders.map((f) => f.id).toList();
          if (oldIndex < folderIds.length && newIndex <= folderIds.length) {
            final movedId = folderIds.removeAt(oldIndex);
            folderIds.insert(newIndex, movedId);
            ref.read(favoriteFoldersNotifierProvider.notifier).reorderFolders(folderIds);
          }
        },
        children: [
          // Dossiers
          for (final (index, folder) in folders.indexed)
            _FolderSection(
                key: ValueKey('folder_${folder.id}'),
                index: index,
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
              ),

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
    final l10n = AppLocalizations.of(context)!;
    return DcEmptyState(
      icon: Icons.star_outline_rounded,
      tone: context.dc.toneOf(AppColors.multiStateOutput),
      title: l10n.noFavorite,
      message: l10n.addFavoritesHint,
      action: FilledButton.icon(
        onPressed: () => GoRouter.of(context).push(Routes.points),
        icon: const Icon(Icons.format_list_bulleted_rounded),
        label: Text(l10n.viewPoints),
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
    final l10n = AppLocalizations.of(context)!;
    final success = await ref.read(favoriteFoldersNotifierProvider.notifier).assignToFolder(favoriteId, folderId);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        dcSnackBar(
          l10n.favoriteAddedToFolder,
          color: AppSnackColors.success,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _deleteFolder(BuildContext context, FavoriteFolder folder) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteFolderConfirm),
        content: Text(
          l10n.deleteFolderMessage(folder.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: context.dc.danger.fg,
              foregroundColor: context.dc.onSolid,
            ),
            child: Text(l10n.delete),
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

/// Couleur d'un dossier (#RRGGBB), bleu par défaut.
Color _parseFolderColor(String hex) {
  try {
    final hexCode = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  } catch (e) {
    return AppColors.brandSky;
  }
}

/// Icône d'un dossier d'après son nom enregistré.
IconData _folderIconData(String iconName) {
  final entry = folderIcons.cast<(String, IconData)?>().firstWhere(
        (e) => e?.$1 == iconName,
        orElse: () => null,
      );
  return entry?.$2 ?? Icons.folder_rounded;
}

/// Cadre d'une section (dossier ou « sans dossier ») : surface bordée.
class _SectionFrame extends StatelessWidget {
  final Widget header;
  final List<Widget> rows;
  final DcTone? highlight;

  const _SectionFrame({required this.header, required this.rows, this.highlight});

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return DcContent(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: highlight != null ? Color.alphaBlend(highlight!.bg, dc.surface) : dc.surface,
          borderRadius: BorderRadius.circular(DcRadius.lg),
          border: Border.all(color: highlight?.fg ?? dc.border, width: highlight != null ? 1.5 : 1),
          boxShadow: dc.cardShadow,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(DcRadius.lg),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              if (rows.isNotEmpty) ...[
                const Divider(height: 1),
                ...rows,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Section d'un dossier de favoris
class _FolderSection extends ConsumerWidget {
  /// Position dans la liste réordonnable (poignée de déplacement).
  final int index;
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
    required this.index,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dc = context.dc;
    final favoritesAsync = ref.watch(favoritesInFolderProvider(folder.id));
    final tone = dc.toneOf(_parseFolderColor(folder.color));
    final icon = _folderIconData(folder.icon);

    return favoritesAsync.when(
      data: (favorites) => DragTarget<int>(
        onWillAcceptWithDetails: (details) => true,
        onAcceptWithDetails: (details) {
          onAssignFavorite(details.data, folder.id);
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          return _SectionFrame(
            highlight: isHovering ? tone : null,
            header: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                child: Row(
                  children: [
                    // Handle drag
                    ReorderableDragStartListener(
                      index: index,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.grab,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.drag_indicator_rounded, color: dc.textMuted, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Icône du dossier
                    AnimatedScale(
                      scale: isHovering ? 1.12 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: DcIconBox(icon: icon, tone: tone, size: 38),
                    ),
                    const SizedBox(width: 12),
                    // Nom et compteur
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            folder.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.titleMedium,
                          ),
                          Text(
                            isHovering ? l10n.dropHereToAdd : l10n.favoritesCount(favorites.length),
                            style: context.text.bodySmall?.copyWith(
                              color: isHovering ? tone.fg : dc.textMuted,
                              fontWeight: isHovering ? FontWeight.w600 : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Menu actions
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_horiz_rounded, color: dc.textSecondary),
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
                        dcMenuItem(context, 'edit', Icons.edit_outlined, l10n.editFolder),
                        dcMenuItem(context, 'delete', Icons.delete_outline_rounded, l10n.deleteFolder, danger: true),
                      ],
                    ),
                    // Chevron expand/collapse
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(Icons.expand_more_rounded, color: dc.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            rows: !isExpanded
                ? const []
                : favorites.isEmpty
                    ? [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                          child: Text(
                            l10n.emptyFolderHint,
                            style: context.text.bodySmall?.copyWith(
                              color: dc.textMuted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ]
                    : [
                        for (final favorite in favorites)
                          _FavoriteTileInFolder(
                            favorite: favorite,
                            folderId: folder.id,
                            selectionMode: selectionMode,
                            isSelected: selectedIds.contains(favorite.id),
                            onToggleSelection: () => onToggleSelection(favorite.id),
                          ),
                      ],
          );
        },
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
    final l10n = AppLocalizations.of(context)!;
    final dc = context.dc;
    return _SectionFrame(
      header: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          child: Row(
            children: [
              const SizedBox(width: 34), // Aligné avec les dossiers (poignée)
              DcIconBox(icon: Icons.folder_off_outlined, tone: dc.neutral, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.noFolder, style: context.text.titleMedium),
                    Text(
                      l10n.favoritesCount(favorites.length),
                      style: context.text.bodySmall?.copyWith(color: dc.textMuted),
                    ),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 180),
                child: Icon(Icons.expand_more_rounded, color: dc.textMuted),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      rows: !isExpanded
          ? const []
          : [
              for (final favorite in favorites)
                _FavoriteTileInFolder(
                  favorite: favorite,
                  folderId: null,
                  selectionMode: selectionMode,
                  isSelected: selectedIds.contains(favorite.id),
                  onToggleSelection: () => onToggleSelection(favorite.id),
                ),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dc = context.dc;
    final l10n = AppLocalizations.of(context)!;
    // Only rebuild when this favorite's live point changes (O(1) lookup)
    final livePoint = ref.watch(_pointsByIdProvider.select((m) => m[favorite.pointRef]));
    // Folders of this favorite derived from already-watched folder streams (no per-tile query)
    final folders = ref.watch(_foldersByFavoriteProvider.select((m) => m[favorite.id])) ?? const <FavoriteFolder>[];
    final folderIds = folders.map((f) => f.id).toList();

    final type = BacnetObjectType.values.cast<BacnetObjectType?>().firstWhere(
          (t) => t?.apiName == favorite.objectType,
          orElse: () => null,
        );
    final typeTone = type != null ? BacnetTypeUtils.typeTone(context, type) : dc.neutral;

    // Trend log
    final parts = favorite.pointRef.split(':');
    final instance = parts.length > 1 ? parts[1] : '';
    final trendLogKey = '${favorite.objectType}:$instance';
    final hasTrendLog = ref.watch(hasTrendLogProvider(trendLogKey));

    // Widget du contenu de la tile
    final tileContent = Material(
      color: isSelected ? dc.accentTone.bg : Colors.transparent,
      child: InkWell(
        onTap: selectionMode ? onToggleSelection : () => _navigateToPoint(context, favorite),
        onLongPress: selectionMode ? null : () => _showAssignDialog(context, ref, favorite, folderIds),
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: dc.border.withValues(alpha: 0.6))),
          ),
          padding: EdgeInsets.fromLTRB(selectionMode ? 6 : 16, 9, 10, 9),
          child: Row(
            children: [
              if (selectionMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onToggleSelection?.call(),
                )
              else if (type != null)
                PointTypeBadge(type: type, size: 36)
              else
                DcIconBox(icon: Icons.help_outline_rounded, tone: dc.neutral, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      favorite.pointName,
                      style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          favorite.pointRef,
                          style: AppTextStyles.monospacedValue.copyWith(fontSize: 11, color: dc.textMuted),
                        ),
                        if (folders.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          // Pastilles colorées des dossiers
                          ...folders.take(4).map((folder) => Tooltip(
                                message: folder.name,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 3),
                                  decoration: BoxDecoration(
                                    color: _parseFolderColor(folder.color),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )),
                          if (folders.length > 4)
                            Text(
                              '+${folders.length - 4}',
                              style: context.text.labelSmall?.copyWith(color: dc.textMuted),
                            ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Bouton assigner aux dossiers
              IconButton(
                icon: Icon(Icons.drive_file_move_outline, size: 18, color: dc.textMuted),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: l10n.assignToFoldersDialog,
                onPressed: () => _showAssignDialog(context, ref, favorite, folderIds),
              ),
              // Bouton favori
              if (livePoint != null)
                FavoriteButton(point: livePoint, size: 18)
              else
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    favorite.isSuperFavorite ? Icons.auto_awesome_rounded : Icons.star_rounded,
                    color: favorite.isSuperFavorite ? AppColors.brandOrange : AppColors.multiStateOutput,
                    size: 18,
                  ),
                ),
              // Trend log
              if (hasTrendLog)
                Tooltip(
                  message: l10n.trendLogAvailable,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.show_chart_rounded, size: 18, color: dc.accentTone.fg),
                  ),
                ),
              // État (alarme, forçage, hors service)
              if (livePoint != null && PointStatusTags.hasAny(livePoint)) ...[
                const SizedBox(width: 4),
                PointStatusTags(point: livePoint),
              ],
              const SizedBox(width: 8),
              // Valeur
              if (livePoint != null)
                PointValueChip(point: livePoint, minWidth: 56)
              else
                Container(
                  constraints: const BoxConstraints(minWidth: 56),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: dc.neutral.bg,
                    borderRadius: BorderRadius.circular(DcRadius.md - 2),
                    border: Border.all(color: dc.neutral.border),
                  ),
                  child: Text(
                    '—',
                    textAlign: TextAlign.right,
                    style: AppTextStyles.monospacedValue.copyWith(color: dc.textMuted),
                  ),
                ),
            ],
          ),
        ),
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
        color: Colors.transparent,
        child: Container(
          width: 240,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: dc.surfaceRaised,
            borderRadius: BorderRadius.circular(DcRadius.md),
            border: Border.all(color: typeTone.fg, width: 1.5),
            boxShadow: dc.raisedShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: AppColors.multiStateOutput, size: 16),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  favorite.pointName,
                  style: context.text.labelLarge?.copyWith(color: dc.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: tileContent,
      ),
      child: Dismissible(
        key: ValueKey('fav_${favorite.id}_$folderId'),
        direction: DismissDirection.endToStart,
        background: Container(
          color: dc.danger.bg,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: Icon(Icons.delete_outline_rounded, color: dc.danger.fg),
        ),
        onDismissed: (_) async {
          // Capture before the await: the tile is already out of the tree
          final messenger = ScaffoldMessenger.of(context);
          final message = AppLocalizations.of(context)!.removedFromFavorites(favorite.pointName);
          await ref.read(favoritesNotifierProvider.notifier).removeFavoriteById(favorite.id);
          messenger.showSnackBar(dcSnackBar(message));
        },
        child: tileContent,
      ),
    );
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
    List<int> folderIds,
  ) async {
    final currentIds = folderIds;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dc = context.dc;
    return AlertDialog(
      title: Text(l10n.assignToFoldersDialog),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.selectFoldersToAdd,
              style: context.text.bodyMedium?.copyWith(color: dc.textSecondary),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.folders.map((folder) {
                    final isSelected = _selectedFolderIds.contains(folder.id);
                    final tone = dc.toneOf(_parseFolderColor(folder.color));

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: CheckboxListTile(
                        value: isSelected,
                        selected: isSelected,
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
                        secondary: DcIconBox(icon: _folderIconData(folder.icon), tone: tone, size: 32),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.trailing,
                      ),
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
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _selectedFolderIds.isEmpty
              ? null
              : () => Navigator.pop(context, _selectedFolderIds.toList()),
          child: Text(l10n.assign),
        ),
      ],
    );
  }
}
