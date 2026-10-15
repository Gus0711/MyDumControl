import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../application/providers/synoptics_provider.dart';
import '../../../application/providers/points_provider.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/tables/synoptic_bindings_table.dart';
import '../../../domain/models/bacnet_object.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/point_widgets.dart';
import '../../widgets/ui/ui.dart';

/// Écran d'édition des liaisons d'un synoptique
class SynopticEditorScreen extends ConsumerStatefulWidget {
  final int synopticId;

  const SynopticEditorScreen({super.key, required this.synopticId});

  @override
  ConsumerState<SynopticEditorScreen> createState() => _SynopticEditorScreenState();
}

class _SynopticEditorScreenState extends ConsumerState<SynopticEditorScreen> {
  String? _selectedElementId;

  /// Right panel: fixed width on wide screens, expanded below the preview on narrow ones.
  Widget _sidePanel({required bool narrow, required Color borderColor, required Widget child}) {
    final decorated = Container(
      width: narrow ? null : 350,
      decoration: BoxDecoration(
        border: narrow
            ? Border(top: BorderSide(color: borderColor))
            : Border(left: BorderSide(color: borderColor)),
      ),
      child: child,
    );
    return narrow ? Expanded(flex: 3, child: decorated) : decorated;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final synopticAsync = ref.watch(synopticByIdProvider(widget.synopticId));
    final bindingsAsync = ref.watch(synopticBindingsProvider(widget.synopticId));

    return Scaffold(
      appBar: GradientAppBar(
        title: synopticAsync.when(
          data: (synoptic) => l10n.synopticEditTitle(synoptic?.name ?? l10n.synopticDefaultName),
          loading: () => l10n.loading,
          error: (_, _) => l10n.error,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: l10n.synopticHelp,
            onPressed: () => _showHelp(context),
          ),
        ],
      ),
      body: synopticAsync.when(
        data: (synoptic) {
          if (synoptic == null) {
            return DcEmptyState(icon: Icons.schema_outlined, title: l10n.synopticNotFound);
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

          final dc = context.dc;
          final borderColor = dc.border;
          final bgColor = dc.surfaceSunken;

          // Narrow screens (phones): stack the preview above the element list
          final narrow = MediaQuery.of(context).size.width < 700;

          return Flex(
            direction: narrow ? Axis.vertical : Axis.horizontal,
            children: [
              // Panneau gauche: SVG
              Expanded(
                flex: 2,
                child: Container(
                  color: bgColor,
                  child: Column(
                    children: [
                      // Header
                      DcSectionHeader(
                        l10n.synopticPreview,
                        icon: Icons.visibility_outlined,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
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
              _sidePanel(
                narrow: narrow,
                borderColor: borderColor,
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      decoration: BoxDecoration(
                        color: dc.surface,
                        border: Border(bottom: BorderSide(color: borderColor)),
                      ),
                      child: Row(
                        children: [
                          DcIconBox(icon: Icons.link_rounded, size: 32),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.synopticConfigurableElements,
                              style: context.text.titleMedium,
                            ),
                          ),
                          bindingsAsync.maybeWhen(
                            data: (bindings) => DcTag(
                              '${bindings.length}/${svgAsset.elementIds.length}',
                              tone: dc.accentTone,
                              mono: true,
                              dense: true,
                            ),
                            orElse: () => const SizedBox.shrink(),
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
                        loading: () => const DcLoading(),
                        error: (e, _) => DcEmptyState.error(
                          context,
                          title: l10n.error,
                          message: e.toString(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const DcLoading(),
        error: (error, _) => DcEmptyState.error(
          context,
          title: l10n.error,
          message: error.toString(),
        ),
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
    final l10n = AppLocalizations.of(context)!;

    if (elementIds.isEmpty) {
      return DcEmptyState(
        icon: Icons.info_outline_rounded,
        title: l10n.synopticNoConfigurableElements,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.help_outline_rounded),
        title: Text(l10n.synopticHowToConfigure),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.synopticHelpSteps),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.understood),
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
    final typeInfo = _getElementTypeInfo(AppLocalizations.of(context)!, elementId);
    final dc = context.dc;
    final tone = hasBinding ? dc.success : dc.neutral;

    return DcCard(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      color: isSelected ? dc.accentTone.bg : null,
      borderColor: isSelected ? dc.accentTone.border : null,
      child: Row(
        children: [
          // Icône selon le type
          DcIconBox(icon: typeInfo.icon, tone: tone, size: 38),
          const SizedBox(width: 12),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(typeInfo.label, style: context.text.titleSmall),
                const SizedBox(height: 2),
                Text(
                  elementId,
                  style: AppTextStyles.monospacedValue.copyWith(
                    fontSize: 11,
                    color: dc.textMuted,
                  ),
                ),
                if (hasBinding) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.link_rounded, size: 13, color: tone.fg),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          binding!.pointName ?? binding!.pointRef,
                          style: context.text.bodySmall?.copyWith(
                            color: tone.fg,
                            fontWeight: FontWeight.w500,
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
            hasBinding ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
            color: hasBinding ? tone.fg : dc.textMuted,
            size: 22,
          ),
        ],
      ),
    );
  }

  _ElementTypeInfo _getElementTypeInfo(AppLocalizations l10n, String elementId) {
    if (elementId.startsWith('val_')) {
      return _ElementTypeInfo(Icons.pin_outlined, l10n.synopticNumericValue);
    } else if (elementId.startsWith('ind_')) {
      return _ElementTypeInfo(Icons.radio_button_checked_rounded, l10n.synopticStateIndicator);
    } else if (elementId.startsWith('anim_')) {
      return _ElementTypeInfo(Icons.animation_rounded, l10n.synopticAnimation);
    }
    return _ElementTypeInfo(Icons.extension_outlined, l10n.synopticElement);
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
    final l10n = AppLocalizations.of(context)!;
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
        final dc = context.dc;
        final borderColor = dc.border;
        final sectionStyle = context.text.labelLarge?.copyWith(color: dc.textPrimary);

        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(DcRadius.xl)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.synopticConfigureBinding,
                            style: context.text.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.elementId,
                            style: AppTextStyles.monospacedValue.copyWith(
                              color: dc.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (widget.existingBinding != null)
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, color: dc.danger.fg),
                      tooltip: l10n.synopticDeleteBinding,
                      onPressed: _deleteBinding,
                    ),
                ],
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  // Type de liaison
                  Text(l10n.synopticBindingType, style: sectionStyle),
                  const SizedBox(height: 8),
                  SegmentedButton<BindingType>(
                    selected: {_bindingType},
                    onSelectionChanged: (set) {
                      setState(() => _bindingType = set.first);
                    },
                    segments: [
                      ButtonSegment(
                        value: BindingType.value,
                        icon: const Icon(Icons.pin_outlined),
                        label: Text(l10n.value),
                      ),
                      ButtonSegment(
                        value: BindingType.color,
                        icon: const Icon(Icons.palette_outlined),
                        label: Text(l10n.synopticColor),
                      ),
                      ButtonSegment(
                        value: BindingType.animation,
                        icon: const Icon(Icons.animation_rounded),
                        label: Text(l10n.synopticAnimation),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Configuration selon le type
                  if (_bindingType == BindingType.value) ...[
                    Text(l10n.synopticDisplayFormat, style: sectionStyle),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _formatController,
                      style: AppTextStyles.monospacedValue.copyWith(fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: l10n.synopticFormatHint('{value}'),
                        helperText: l10n.synopticFormatHelper('{value}'),
                      ),
                    ),
                  ],

                  if (_bindingType == BindingType.color) ...[
                    Text(l10n.synopticColors, style: sectionStyle),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _onColorController,
                            style: AppTextStyles.monospacedValue.copyWith(fontSize: 13.5),
                            decoration: InputDecoration(
                              labelText: 'ON',
                              prefixIcon: _ColorSwatch(color: _parseColor(_onColorController.text)),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _offColorController,
                            style: AppTextStyles.monospacedValue.copyWith(fontSize: 13.5),
                            decoration: InputDecoration(
                              labelText: 'OFF',
                              prefixIcon: _ColorSwatch(color: _parseColor(_offColorController.text)),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (_bindingType == BindingType.animation) ...[
                    Text(l10n.synopticAnimationConfig, style: sectionStyle),
                    const SizedBox(height: 8),
                    DcBanner(
                      tone: dc.info,
                      icon: Icons.info_outline_rounded,
                      title: l10n.synopticAnimationOnOff,
                      message: l10n.synopticAnimationExplanation,
                    ),
                  ],

                  // Seuil pour couleur et animation
                  if (_bindingType == BindingType.color || _bindingType == BindingType.animation) ...[
                    const SizedBox(height: 16),
                    Text(l10n.synopticThreshold, style: sectionStyle),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _thresholdController,
                      style: AppTextStyles.monospacedValue.copyWith(fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: '0.5',
                        helperText: l10n.synopticThresholdHelper,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Sélection du point
                  Text(l10n.synopticBacnetPoint, style: sectionStyle),
                  const SizedBox(height: 8),

                  // Recherche
                  TextField(
                    decoration: InputDecoration(
                      hintText: l10n.searchPoint,
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),

                  const SizedBox(height: 12),

                  // Liste des points
                  if (pointsState.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (filteredPoints.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.synopticNoPointFound,
                          style: context.text.bodyMedium?.copyWith(color: dc.textSecondary),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 240,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: dc.surfaceSunken,
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(DcRadius.md),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(4),
                        itemCount: filteredPoints.length,
                        itemBuilder: (context, index) {
                          final point = filteredPoints[index];
                          final isSelected = _selectedPoint?.objectId == point.objectId ||
                              (widget.existingBinding?.pointRef == point.objectId && _selectedPoint == null);

                          return ListTile(
                            dense: true,
                            selected: isSelected,
                            title: Text(
                              point.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${point.objectId} = ${point.formattedValue}',
                              style: AppTextStyles.monospacedValue.copyWith(
                                fontSize: 11,
                                color: dc.textMuted,
                              ),
                            ),
                            leading: PointTypeBadge(type: point.type, size: 32),
                            trailing: isSelected
                                ? Icon(Icons.check_circle_rounded, size: 20, color: dc.accentTone.fg)
                                : null,
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
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _canSave() ? _saveBinding : null,
                      child: Text(l10n.save),
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
      return context.dc.textMuted;
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
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showConfirmDialog(
      context,
      title: l10n.synopticDeleteBindingTitle,
      message: l10n.synopticIrreversible,
      confirmLabel: l10n.delete,
      destructive: true,
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

/// Pastille de couleur dans un champ de saisie (ON / OFF).
class _ColorSwatch extends StatelessWidget {
  final Color color;

  const _ColorSwatch({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(DcRadius.sm),
        border: Border.all(color: context.dc.borderStrong),
      ),
    );
  }
}
