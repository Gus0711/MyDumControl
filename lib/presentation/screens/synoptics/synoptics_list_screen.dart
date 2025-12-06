import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/synoptics_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/database/app_database.dart';

/// Écran de liste des synoptiques
class SynopticsListScreen extends ConsumerWidget {
  const SynopticsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final synopticsAsync = ref.watch(synopticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Synoptiques'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Créer un synoptique',
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
              Text('Erreur: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(synopticsProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
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
              'Aucun synoptique',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Créez votre premier synoptique pour visualiser\nvos points sur un schéma graphique',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showCreateDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Créer un synoptique'),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le synoptique ?'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${synoptic.name}" ?\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(synopticsNotifierProvider.notifier).deleteSynoptic(synoptic.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
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
                            '$count liaison${count > 1 ? 's' : ''}',
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
                            '-- liaisons',
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
                              'Global',
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
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 12),
                        Text('Éditer les liaisons'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        const SizedBox(width: 12),
                        const Text('Supprimer', style: TextStyle(color: Colors.red)),
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
    return AlertDialog(
      title: const Text('Nouveau synoptique'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sélection du SVG
            const Text(
              'Modèle SVG',
              style: TextStyle(fontWeight: FontWeight.w500),
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
                '${_selectedAsset!.elementIds.length} éléments configurables',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],

            const SizedBox(height: 20),

            // Nom
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom du synoptique',
                hintText: 'Ex: Circuit Chauffage RDC',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
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
              : const Text('Créer'),
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
