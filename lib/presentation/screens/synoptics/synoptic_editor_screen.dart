import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../application/providers/synoptics_provider.dart';
import '../../../application/providers/points_provider.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/tables/synoptic_bindings_table.dart';
import '../../../domain/models/bacnet_object.dart';

/// Écran d'édition des liaisons d'un synoptique
class SynopticEditorScreen extends ConsumerStatefulWidget {
  final int synopticId;

  const SynopticEditorScreen({super.key, required this.synopticId});

  @override
  ConsumerState<SynopticEditorScreen> createState() => _SynopticEditorScreenState();
}

class _SynopticEditorScreenState extends ConsumerState<SynopticEditorScreen> {
  String? _selectedElementId;

  @override
  Widget build(BuildContext context) {
    final synopticAsync = ref.watch(synopticByIdProvider(widget.synopticId));
    final bindingsAsync = ref.watch(synopticBindingsProvider(widget.synopticId));

    return Scaffold(
      appBar: AppBar(
        title: synopticAsync.when(
          data: (synoptic) => Text('Éditer: ${synoptic?.name ?? 'Synoptique'}'),
          loading: () => const Text('Chargement...'),
          error: (_, __) => const Text('Erreur'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Aide',
            onPressed: () => _showHelp(context),
          ),
        ],
      ),
      body: synopticAsync.when(
        data: (synoptic) {
          if (synoptic == null) {
            return const Center(child: Text('Synoptique non trouvé'));
          }

          // Trouver les éléments disponibles pour ce SVG
          final svgAsset = builtInSvgAssets.firstWhere(
            (a) => a.path == synoptic.svgAssetPath,
            orElse: () => SvgAssetInfo(
              path: synoptic.svgAssetPath,
              name: 'Inconnu',
              description: '',
              elementIds: [],
            ),
          );

          final isDark = Theme.of(context).brightness == Brightness.dark;
          final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
          final bgColor = isDark ? Colors.grey.shade900 : Colors.grey.shade100;

          return Row(
            children: [
              // Panneau gauche: SVG
              Expanded(
                flex: 2,
                child: Container(
                  color: bgColor,
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Aperçu du synoptique',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      // SVG
                      Expanded(
                        child: InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 3.0,
                          child: Center(
                            child: SvgPicture.asset(
                              synoptic.svgAssetPath,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Panneau droit: Liste des éléments
              Container(
                width: 350,
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: borderColor)),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: borderColor)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.link, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Éléments configurables',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),

                    // Liste des éléments
                    Expanded(
                      child: bindingsAsync.when(
                        data: (bindings) => _buildElementsList(
                          context,
                          svgAsset.elementIds,
                          bindings,
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Erreur: $e')),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur: $error')),
      ),
    );
  }

  Widget _buildElementsList(
    BuildContext context,
    List<String> elementIds,
    List<SynopticBinding> bindings,
  ) {
    // Créer une map des bindings par elementId
    final bindingsMap = {for (final b in bindings) b.svgElementId: b};

    if (elementIds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Aucun élément configurable détecté',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: elementIds.length,
      itemBuilder: (context, index) {
        final elementId = elementIds[index];
        final binding = bindingsMap[elementId];

        return _ElementCard(
          elementId: elementId,
          binding: binding,
          synopticId: widget.synopticId,
          isSelected: _selectedElementId == elementId,
          onTap: () {
            setState(() => _selectedElementId = elementId);
            _showBindingEditor(context, elementId, binding);
          },
        );
      },
    );
  }

  void _showBindingEditor(
    BuildContext context,
    String elementId,
    SynopticBinding? existingBinding,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _BindingEditorSheet(
        synopticId: widget.synopticId,
        elementId: elementId,
        existingBinding: existingBinding,
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline),
            SizedBox(width: 8),
            Text('Comment configurer'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Sélectionnez un élément dans la liste\n'
              '2. Choisissez le point BACnet à associer\n'
              '3. Configurez le type de liaison:\n'
              '   • Valeur: affiche la valeur du point\n'
              '   • Couleur: change la couleur selon l\'état\n'
              '   • Animation: active/désactive une animation\n'
              '4. Personnalisez le format si nécessaire',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }
}

/// Carte d'un élément configurable
class _ElementCard extends StatelessWidget {
  final String elementId;
  final SynopticBinding? binding;
  final int synopticId;
  final bool isSelected;
  final VoidCallback onTap;

  const _ElementCard({
    required this.elementId,
    required this.binding,
    required this.synopticId,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasBinding = binding != null;
    final typeInfo = _getElementTypeInfo(elementId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Couleurs adaptées au thème
    final iconBgColor = hasBinding
        ? (isDark ? Colors.green.shade900 : Colors.green.shade50)
        : (isDark ? Colors.grey.shade800 : Colors.grey.shade100);
    final iconColor = hasBinding
        ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
        : (isDark ? Colors.grey.shade400 : Colors.grey.shade500);
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icône selon le type
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  typeInfo.icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeInfo.label,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      elementId,
                      style: TextStyle(
                        fontSize: 11,
                        color: subtitleColor,
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (hasBinding) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.link, size: 12, color: iconColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              binding!.pointName ?? binding!.pointRef,
                              style: TextStyle(
                                fontSize: 11,
                                color: iconColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Indicateur de statut
              Icon(
                hasBinding ? Icons.check_circle : Icons.add_circle_outline,
                color: hasBinding ? iconColor : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  _ElementTypeInfo _getElementTypeInfo(String elementId) {
    if (elementId.startsWith('val_')) {
      return _ElementTypeInfo(Icons.numbers, 'Valeur numérique');
    } else if (elementId.startsWith('ind_')) {
      return _ElementTypeInfo(Icons.circle, 'Indicateur d\'état');
    } else if (elementId.startsWith('anim_')) {
      return _ElementTypeInfo(Icons.animation, 'Animation');
    }
    return _ElementTypeInfo(Icons.extension, 'Élément');
  }
}

class _ElementTypeInfo {
  final IconData icon;
  final String label;

  const _ElementTypeInfo(this.icon, this.label);
}

/// Sheet pour éditer une liaison
class _BindingEditorSheet extends ConsumerStatefulWidget {
  final int synopticId;
  final String elementId;
  final SynopticBinding? existingBinding;

  const _BindingEditorSheet({
    required this.synopticId,
    required this.elementId,
    required this.existingBinding,
  });

  @override
  ConsumerState<_BindingEditorSheet> createState() => _BindingEditorSheetState();
}

class _BindingEditorSheetState extends ConsumerState<_BindingEditorSheet> {
  BacnetObject? _selectedPoint;
  late BindingType _bindingType;
  final _formatController = TextEditingController();
  final _onColorController = TextEditingController(text: '#27ae60');
  final _offColorController = TextEditingController(text: '#e74c3c');
  final _thresholdController = TextEditingController(text: '0.5');
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    // Déterminer le type par défaut selon le préfixe de l'élément
    if (widget.elementId.startsWith('val_')) {
      _bindingType = BindingType.value;
      _formatController.text = '{value}';
    } else if (widget.elementId.startsWith('ind_')) {
      _bindingType = BindingType.color;
    } else if (widget.elementId.startsWith('anim_')) {
      _bindingType = BindingType.animation;
    } else {
      _bindingType = BindingType.value;
    }

    // Charger les valeurs existantes
    if (widget.existingBinding != null) {
      _bindingType = widget.existingBinding!.bindingType;
      final config = BindingConfig.fromJson(widget.existingBinding!.configJson);
      if (config.format != null) _formatController.text = config.format!;
      if (config.onColor != null) _onColorController.text = config.onColor!;
      if (config.offColor != null) _offColorController.text = config.offColor!;
      _thresholdController.text = config.threshold.toString();
    }
  }

  @override
  void dispose() {
    _formatController.dispose();
    _onColorController.dispose();
    _offColorController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pointsState = ref.watch(pointsProvider);
    final filteredPoints = pointsState.points.where((p) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return p.objectName.toLowerCase().contains(query) ||
          p.objectId.toLowerCase().contains(query) ||
          (p.description?.toLowerCase().contains(query) ?? false);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final sheetBgColor = Theme.of(context).colorScheme.surface;
        final handleColor = isDark ? Colors.grey.shade600 : Colors.grey.shade300;
        final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
        final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

        return Container(
          decoration: BoxDecoration(
            color: sheetBgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: handleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Configurer la liaison',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            widget.elementId,
                            style: TextStyle(
                              color: subtitleColor,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (widget.existingBinding != null)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Supprimer la liaison',
                      onPressed: _deleteBinding,
                    ),
                ],
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Type de liaison
                  const Text(
                    'Type de liaison',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<BindingType>(
                    selected: {_bindingType},
                    onSelectionChanged: (set) {
                      setState(() => _bindingType = set.first);
                    },
                    segments: const [
                      ButtonSegment(
                        value: BindingType.value,
                        icon: Icon(Icons.numbers),
                        label: Text('Valeur'),
                      ),
                      ButtonSegment(
                        value: BindingType.color,
                        icon: Icon(Icons.palette),
                        label: Text('Couleur'),
                      ),
                      ButtonSegment(
                        value: BindingType.animation,
                        icon: Icon(Icons.animation),
                        label: Text('Animation'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Configuration selon le type
                  if (_bindingType == BindingType.value) ...[
                    const Text(
                      'Format d\'affichage',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _formatController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Ex: {value}°C ou {value}%',
                        helperText: 'Utilisez {value} pour la valeur du point',
                      ),
                    ),
                  ],

                  if (_bindingType == BindingType.color) ...[
                    const Text(
                      'Couleurs',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _onColorController,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: 'ON',
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _parseColor(_onColorController.text),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _offColorController,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: 'OFF',
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _parseColor(_offColorController.text),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (_bindingType == BindingType.animation) ...[
                    const Text(
                      'Configuration Animation',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.blue.shade900.withValues(alpha: 0.3) : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.blue.shade700 : Colors.blue.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                size: 16,
                                color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Animation ON/OFF',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'L\'animation sera visible quand la valeur du point est > seuil (actif), '
                            'et masquée sinon.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.blue.shade200 : Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Seuil pour couleur et animation
                  if (_bindingType == BindingType.color || _bindingType == BindingType.animation) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Seuil ON/OFF',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _thresholdController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '0.5',
                        helperText: 'Valeur > seuil = ON, sinon OFF (pour booléen: 0.5)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Sélection du point
                  const Text(
                    'Point BACnet',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

                  // Recherche
                  TextField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Rechercher un point...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),

                  const SizedBox(height: 12),

                  // Liste des points
                  if (pointsState.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (filteredPoints.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Aucun point trouvé'),
                      ),
                    )
                  else
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: filteredPoints.length,
                        itemBuilder: (context, index) {
                          final point = filteredPoints[index];
                          final isSelected = _selectedPoint?.objectId == point.objectId ||
                              (widget.existingBinding?.pointRef == point.objectId && _selectedPoint == null);

                          return ListTile(
                            dense: true,
                            selected: isSelected,
                            selectedTileColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            title: Text(
                              point.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${point.objectId} = ${point.formattedValue}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            leading: Icon(
                              Icons.sensors,
                              size: 20,
                              color: isSelected ? Theme.of(context).primaryColor : null,
                            ),
                            trailing: isSelected ? const Icon(Icons.check, size: 20) : null,
                            onTap: () {
                              setState(() => _selectedPoint = point);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _canSave() ? _saveBinding : null,
                      child: const Text('Enregistrer'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      },
    );
  }

  bool _canSave() {
    return _selectedPoint != null ||
        (widget.existingBinding != null && _selectedPoint == null);
  }

  Color _parseColor(String hex) {
    try {
      final cleanHex = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleanHex', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  String _buildConfigJson() {
    final threshold = double.tryParse(_thresholdController.text) ?? 0.5;
    final config = BindingConfig(
      format: _bindingType == BindingType.value ? _formatController.text : null,
      onColor: _bindingType == BindingType.color ? _onColorController.text : null,
      offColor: _bindingType == BindingType.color ? _offColorController.text : null,
      threshold: threshold,
    );
    return config.toJson();
  }

  Future<void> _saveBinding() async {
    final pointRef = _selectedPoint?.objectId ?? widget.existingBinding?.pointRef;
    if (pointRef == null) return;

    final success = await ref.read(synopticsNotifierProvider.notifier).upsertBinding(
          synopticId: widget.synopticId,
          svgElementId: widget.elementId,
          pointRef: pointRef,
          bindingType: _bindingType,
          configJson: _buildConfigJson(),
          pointName: _selectedPoint?.objectName ?? widget.existingBinding?.pointName,
        );

    if (mounted && success) {
      Navigator.pop(context);
    }
  }

  Future<void> _deleteBinding() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la liaison ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(synopticsNotifierProvider.notifier).deleteBinding(
            widget.synopticId,
            widget.elementId,
          );
      if (mounted) Navigator.pop(context);
    }
  }
}
