import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/synoptics_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../../l10n/app_localizations.dart';

/// Écran de liste des synoptiques
class SynopticsListScreen extends ConsumerWidget {
  const SynopticsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final synopticsAsync = ref.watch(synopticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.synopticsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(l10n.errorWithMessage(error.toString())),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(synopticsProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dashboard_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.synopticEmptyTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.synopticEmptyHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showCreateDialog(context, ref),
              icon: const Icon(Icons.add),
              label: Text(l10n.synopticCreate),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSynopticsList(
    BuildContext context,
    WidgetRef ref,
    List<Synoptic> synoptics,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: synoptics.length,
      itemBuilder: (context, index) {
        final synoptic = synoptics[index];
        return _SynopticCard(
          synoptic: synoptic,
          onTap: () => context.push(Routes.synopticViewPath(synoptic.id)),
          onEdit: () => context.push(Routes.synopticEditPath(synoptic.id)),
          onDelete: () => _confirmDelete(context, ref, synoptic),
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

  void _confirmDelete(BuildContext context, WidgetRef ref, Synoptic synoptic) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.synopticDeleteTitle),
        content: Text(l10n.synopticDeleteMessage(synoptic.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(synopticsNotifierProvider.notifier).deleteSynoptic(synoptic.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

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
    final bindingsCount = ref.watch(bindingsCountProvider(synoptic.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.dashboard,
                  size: 28,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      synoptic.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (synoptic.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        synoptic.description!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.link, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        bindingsCount.when(
                          data: (count) => Text(
                            l10n.synopticBindingsCount(count),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                          loading: () => const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1),
                          ),
                          error: (_, __) => Text(
                            l10n.synopticBindingsUnknown,
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ),
                        if (synoptic.connectionId == null) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l10n.synopticGlobal,
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
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
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 20),
                        const SizedBox(width: 12),
                        Text(l10n.synopticEditBindings),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        const SizedBox(width: 12),
                        Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<SvgAssetInfo>(
              initialValue: _selectedAsset,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.synopticConfigurableElementsCount(_selectedAsset!.elementIds.length),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],

            const SizedBox(height: 20),

            // Nom
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.synopticNameLabel,
                hintText: l10n.synopticNameHint,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.synopticDescriptionOptional,
                border: const OutlineInputBorder(),
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
        ElevatedButton(
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
