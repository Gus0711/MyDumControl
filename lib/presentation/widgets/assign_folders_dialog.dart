import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/favorite_folders_provider.dart';
import '../../data/database/app_database.dart';
import '../../l10n/app_localizations.dart';
import 'favorite_folder_dialog.dart';

/// Dialog pour assigner un favori à plusieurs dossiers
class AssignFoldersDialog extends ConsumerStatefulWidget {
  /// Le favori à assigner
  final Favorite favorite;

  /// Les IDs des dossiers actuellement assignés
  final List<int> currentFolderIds;

  const AssignFoldersDialog({
    super.key,
    required this.favorite,
    required this.currentFolderIds,
  });

  /// Affiche le dialog et retourne la liste des IDs de dossiers sélectionnés
  static Future<List<int>?> show(
    BuildContext context, {
    required Favorite favorite,
    required List<int> currentFolderIds,
  }) {
    return showDialog<List<int>>(
      context: context,
      builder: (context) => AssignFoldersDialog(
        favorite: favorite,
        currentFolderIds: currentFolderIds,
      ),
    );
  }

  @override
  ConsumerState<AssignFoldersDialog> createState() => _AssignFoldersDialogState();
}

class _AssignFoldersDialogState extends ConsumerState<AssignFoldersDialog> {
  late Set<int> _selectedFolderIds;

  @override
  void initState() {
    super.initState();
    _selectedFolderIds = Set.from(widget.currentFolderIds);
  }

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
    final foldersAsync = ref.watch(favoriteFoldersProvider);
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.assignToFoldersDialog),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info sur le favori
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.favorite.pointName,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Liste des dossiers
            foldersAsync.when(
              data: (folders) {
                if (folders.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.folder_off, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          l10n.widgetNoFolder,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => _createNewFolder(context),
                          icon: const Icon(Icons.create_new_folder),
                          label: Text(l10n.widgetCreateFolder),
                        ),
                      ],
                    ),
                  );
                }

                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...folders.map((folder) {
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
                        }),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.create_new_folder),
                          title: Text(l10n.widgetNewFolderEllipsis),
                          dense: true,
                          onTap: () => _createNewFolder(context),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.errorWithMessage(error.toString())),
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
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedFolderIds.toList()),
          child: Text(l10n.apply),
        ),
      ],
    );
  }

  Future<void> _createNewFolder(BuildContext context) async {
    final result = await FavoriteFolderDialog.show(context);
    if (result != null && mounted) {
      final notifier = ref.read(favoriteFoldersNotifierProvider.notifier);
      final newId = await notifier.createFolder(
        name: result.name,
        color: result.color,
        icon: result.icon,
      );
      if (newId != null) {
        setState(() {
          _selectedFolderIds.add(newId);
        });
      }
    }
  }
}
