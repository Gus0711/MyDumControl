import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/favorite_folders_provider.dart';
import '../../data/database/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import 'favorite_folder_dialog.dart';
import 'ui/ui.dart';

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
      return AppColors.brandSky;
    }
  }

  IconData _getIconData(String iconName) {
    final entry = folderIcons.cast<(String, IconData)?>().firstWhere(
          (e) => e?.$1 == iconName,
          orElse: () => null,
        );
    return entry?.$2 ?? Icons.folder_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(favoriteFoldersProvider);
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
            // Info sur le favori
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: dc.surfaceSunken,
                borderRadius: BorderRadius.circular(DcRadius.md),
                border: Border.all(color: dc.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.multiStateOutput, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.favorite.pointName,
                      style: context.text.titleSmall?.copyWith(color: dc.textPrimary),
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
                        DcIconBox(icon: Icons.folder_off_outlined, tone: dc.neutral, size: 52),
                        const SizedBox(height: 12),
                        Text(
                          l10n.widgetNoFolder,
                          style: context.text.bodyMedium?.copyWith(color: dc.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => _createNewFolder(context),
                          icon: const Icon(Icons.create_new_folder_outlined),
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
                          final tone = dc.toneOf(_parseColor(folder.color));
                          final icon = _getIconData(folder.icon);

                          return CheckboxListTile(
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
                            secondary: DcIconBox(icon: icon, tone: tone, size: 32),
                            dense: true,
                            controlAffinity: ListTileControlAffinity.trailing,
                          );
                        }),
                        const Divider(height: 16),
                        ListTile(
                          leading: Icon(Icons.create_new_folder_outlined, color: dc.accentTone.fg),
                          title: Text(l10n.widgetNewFolderEllipsis),
                          dense: true,
                          onTap: () => _createNewFolder(context),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: DcLoading(),
              ),
              error: (error, _) => DcBanner(
                tone: dc.danger,
                icon: Icons.error_outline_rounded,
                message: l10n.errorWithMessage(error.toString()),
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
