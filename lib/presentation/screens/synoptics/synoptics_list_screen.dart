import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/synoptics_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/ui/ui.dart';

/// Écran de liste des synoptiques
class SynopticsListScreen extends ConsumerWidget {
  const SynopticsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final synopticsAsync = ref.watch(synopticsProvider);

    return Scaffold(
      appBar: GradientAppBar(
        title: l10n.synopticsTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: l10n.synopticCreate,
            onPressed: () => _showCreateDialog(context, ref),
          ),
        ],
      ),
      body: synopticsAsync.when(
        data: (synoptics) {
          if (synoptics.isEmpty) {
            return _buildEmptyState(context, ref);
          }
          return _buildSynopticsList(context, ref, synoptics);
        },
        loading: () => const DcLoading(),
        error: (error, _) => DcEmptyState.error(
          context,
          title: l10n.error,
          message: error.toString(),
          action: FilledButton.icon(
            onPressed: () => ref.invalidate(synopticsProvider),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.retry),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return DcEmptyState(
      icon: Icons.schema_rounded,
      tone: context.dc.toneOf(_synopticColor),
      title: l10n.synopticEmptyTitle,
      message: l10n.synopticEmptyHint,
      action: FilledButton.icon(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.synopticCreate),
      ),
    );
  }

  Widget _buildSynopticsList(
    BuildContext context,
    WidgetRef ref,
    List<Synoptic> synoptics,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(0.0, DcSpace.contentMaxWidth) - 40;
        final columns = width >= 1000 ? 3 : (width >= 640 ? 2 : 1);
        const spacing = 14.0;
        final itemWidth = (width - spacing * (columns - 1)) / columns;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: DcContent(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DcSectionHeader(
                  AppLocalizations.of(context)!.synopticsTitle,
                  count: synoptics.length,
                  padding: const EdgeInsets.fromLTRB(2, 20, 0, 12),
                ),
                Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final synoptic in synoptics)
                      SizedBox(
                        width: itemWidth,
                        child: _SynopticCard(
                          synoptic: synoptic,
                          onTap: () => context.push(Routes.synopticViewPath(synoptic.id)),
                          onEdit: () => context.push(Routes.synopticEditPath(synoptic.id)),
                          onDelete: () => _confirmDelete(context, ref, synoptic),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _CreateSynopticDialog(ref: ref),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Synoptic synoptic) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.synopticDeleteTitle,
      message: l10n.synopticDeleteMessage(synoptic.name),
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (confirmed) {
      await ref.read(synopticsNotifierProvider.notifier).deleteSynoptic(synoptic.id);
    }
  }
}

/// Couleur des synoptiques (cyan de la palette des modules).
const Color _synopticColor = AppColors.analogValue;

/// Carte d'un synoptique dans la liste
class _SynopticCard extends ConsumerWidget {
  final Synoptic synoptic;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SynopticCard({
    required this.synoptic,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dc = context.dc;
    final bindingsCount = ref.watch(bindingsCountProvider(synoptic.id));

    return DcCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 6, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DcIconBox(
            icon: Icons.schema_rounded,
            tone: dc.toneOf(_synopticColor),
            size: 46,
          ),
          const SizedBox(width: 14),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  synoptic.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleMedium,
                ),
                if (synoptic.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    synoptic.description!,
                    style: context.text.bodySmall?.copyWith(color: dc.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    bindingsCount.when(
                      data: (count) => DcTag(
                        l10n.synopticBindingsCount(count),
                        icon: Icons.link_rounded,
                        tone: count > 0 ? dc.accentTone : dc.neutral,
                        dense: true,
                      ),
                      loading: () => const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                      error: (_, _) => DcTag(l10n.synopticBindingsUnknown, dense: true),
                    ),
                    if (synoptic.connectionId == null)
                      DcTag(l10n.synopticGlobal, icon: Icons.public_rounded, tone: dc.success, dense: true),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: dc.textSecondary, size: 20),
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
              dcMenuItem(context, 'edit', Icons.edit_outlined, l10n.synopticEditBindings),
              const PopupMenuDivider(),
              dcMenuItem(context, 'delete', Icons.delete_outline_rounded, l10n.delete, danger: true),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dialog pour créer un nouveau synoptique
class _CreateSynopticDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _CreateSynopticDialog({required this.ref});

  @override
  ConsumerState<_CreateSynopticDialog> createState() => _CreateSynopticDialogState();
}

class _CreateSynopticDialogState extends ConsumerState<_CreateSynopticDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  SvgAssetInfo? _selectedAsset;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    if (builtInSvgAssets.isNotEmpty) {
      _selectedAsset = builtInSvgAssets.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.synopticNew),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sélection du SVG
            Text(
              l10n.synopticSvgModel,
              style: context.text.labelLarge,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<SvgAssetInfo>(
              initialValue: _selectedAsset,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.schema_outlined, size: 20),
              ),
              items: builtInSvgAssets.map((asset) {
                return DropdownMenuItem(
                  value: asset,
                  child: Text(asset.name),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedAsset = value),
            ),
            if (_selectedAsset != null) ...[
              const SizedBox(height: 4),
              Text(
                _selectedAsset!.description,
                style: context.text.bodySmall?.copyWith(color: context.dc.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.synopticConfigurableElementsCount(_selectedAsset!.elementIds.length),
                style: context.text.bodySmall?.copyWith(color: context.dc.textMuted),
              ),
            ],

            const SizedBox(height: 20),

            // Nom
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.synopticNameLabel,
                hintText: l10n.synopticNameHint,
              ),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.synopticDescriptionOptional,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isCreating || _selectedAsset == null || _nameController.text.trim().isEmpty
              ? null
              : _create,
          child: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.create),
        ),
      ],
    );
  }

  Future<void> _create() async {
    if (_selectedAsset == null || _nameController.text.trim().isEmpty) return;

    setState(() => _isCreating = true);

    final id = await widget.ref.read(synopticsNotifierProvider.notifier).createSynoptic(
          name: _nameController.text.trim(),
          svgAssetPath: _selectedAsset!.path,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );

    if (mounted) {
      Navigator.pop(context);
      if (id != null) {
        // Ouvrir l'éditeur pour configurer les liaisons
        context.push(Routes.synopticEditPath(id));
      }
    }
  }
}
