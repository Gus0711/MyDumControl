import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/synoptics_provider.dart';
import '../../../core/router/routes.dart';
import '../../../data/database/app_database.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/database/tables/synoptic_bindings_table.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/synoptic_painters/circuit_regule_painter.dart';
import '../../widgets/ui/ui.dart';
import '../../../core/theme/app_colors.dart';

/// Écran de visualisation d'un synoptique avec données temps réel
class SynopticViewerScreen extends ConsumerStatefulWidget {
  final int synopticId;

  const SynopticViewerScreen({super.key, required this.synopticId});

  @override
  ConsumerState<SynopticViewerScreen> createState() => _SynopticViewerScreenState();
}

class _SynopticViewerScreenState extends ConsumerState<SynopticViewerScreen> {
  final TransformationController _transformController = TransformationController();

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final synopticAsync = ref.watch(synopticByIdProvider(widget.synopticId));
    final bindingsAsync = ref.watch(synopticBindingsProvider(widget.synopticId));
    final liveState = ref.watch(synopticLiveProvider(widget.synopticId));

    return Scaffold(
      appBar: GradientAppBar(
        title: synopticAsync.when(
          data: (synoptic) => synoptic?.name ?? l10n.synopticDefaultName,
          loading: () => l10n.loading,
          error: (_, _) => l10n.error,
        ),
        actions: [
          // Indicateur de chargement
          if (liveState.isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            ),
          // Bouton refresh
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.refresh,
            onPressed: () {
              ref.read(synopticLiveProvider(widget.synopticId).notifier).forceRefresh();
            },
          ),
          // Bouton éditer
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.synopticEditBindings,
            onPressed: () => context.push(Routes.synopticEditPath(widget.synopticId)),
          ),
          // Bouton réinitialiser le zoom
          IconButton(
            icon: const Icon(Icons.fit_screen_rounded),
            tooltip: l10n.synopticResetZoom,
            onPressed: () {
              _transformController.value = Matrix4.identity();
            },
          ),
        ],
      ),
      body: synopticAsync.when(
        data: (synoptic) {
          if (synoptic == null) {
            return DcEmptyState(icon: Icons.schema_outlined, title: l10n.synopticNotFound);
          }

          return Column(
            children: [
              // Erreur éventuelle
              if (liveState.error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: DcBanner(
                    tone: context.dc.warning,
                    icon: Icons.warning_amber_rounded,
                    message: l10n.synopticUpdateError('${liveState.error}'),
                    dense: true,
                  ),
                ),

              // Synoptique interactif
              Expanded(
                child: InteractiveViewer(
                  transformationController: _transformController,
                  minScale: 0.5,
                  maxScale: 4.0,
                  boundaryMargin: const EdgeInsets.all(100),
                  child: Center(
                    child: bindingsAsync.when(
                      data: (bindings) => _buildSynopticWidget(
                        context,
                        synoptic,
                        bindings,
                        liveState,
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text(
                        l10n.errorWithMessage(e.toString()),
                        style: TextStyle(color: context.dc.danger.fg),
                      ),
                    ),
                  ),
                ),
              ),

              // Barre d'infos en bas
              _buildInfoBar(context, liveState),
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

  /// Construit le widget synoptique approprié (Flutter natif ou SVG)
  Widget _buildSynopticWidget(
    BuildContext context,
    Synoptic synoptic,
    List<SynopticBinding> bindings,
    SynopticLiveState liveState,
  ) {
    // Utiliser le widget Flutter natif pour Circuit Régulé
    if (synoptic.svgAssetPath.contains('CR_V0.1')) {
      return _buildCircuitReguleWidget(context, bindings, liveState);
    }

    // Fallback vers SVG avec overlays pour les autres
    return _SvgWithOverlays(
      svgAssetPath: synoptic.svgAssetPath,
      bindings: bindings,
      liveState: liveState,
      onElementTap: (binding) => _showPointDetails(context, binding),
    );
  }

  /// Widget Flutter natif pour le Circuit Régulé
  Widget _buildCircuitReguleWidget(
    BuildContext context,
    List<SynopticBinding> bindings,
    SynopticLiveState liveState,
  ) {
    // Extraire les données des bindings
    double? tempDepart;
    double? positionV3V;
    bool pompeActive = false;
    bool v3vActive = false;

    SynopticBinding? tempBinding;
    SynopticBinding? v3vBinding;
    SynopticBinding? pompeBinding;

    for (final binding in bindings) {
      final value = liveState.pointValues[binding.pointRef];
      final config = BindingConfig.fromJson(binding.configJson);

      if (binding.svgElementId == 'val_temp_depart') {
        tempBinding = binding;
        if (value is num) tempDepart = value.toDouble();
      } else if (binding.svgElementId == 'val_v3v_position') {
        v3vBinding = binding;
        if (value is num) positionV3V = value.toDouble();
      } else if (binding.svgElementId == 'anim_pompe_rotation' ||
          binding.svgElementId == 'ind_pompe_etat') {
        pompeBinding = binding;
        pompeActive = config.isOn(value);
      } else if (binding.svgElementId == 'ind_v3v_etat') {
        v3vActive = config.isOn(value);
      }
    }

    return AspectRatio(
      aspectRatio: 340 / 540, // Ratio du SVG original
      child: CircuitReguleWidget(
        data: CircuitReguleData(
          tempDepart: tempDepart,
          positionV3V: positionV3V,
          pompeActive: pompeActive,
          v3vActive: v3vActive,
        ),
        onTempTap: tempBinding != null
            ? () => _showPointDetails(context, tempBinding!)
            : null,
        onPompeTap: pompeBinding != null
            ? () => _showPointDetails(context, pompeBinding!)
            : null,
        onV3VTap: v3vBinding != null
            ? () => _showPointDetails(context, v3vBinding!)
            : null,
      ),
    );
  }

  Widget _buildInfoBar(BuildContext context, SynopticLiveState liveState) {
    final l10n = AppLocalizations.of(context)!;
    final bindingsCount = liveState.bindings.length;
    final pointsCount = liveState.pointValues.length;

    final dc = context.dc;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: dc.surface,
        border: Border(top: BorderSide(color: dc.border)),
      ),
      child: Row(
        children: [
          DcTag(l10n.synopticBindingsCount(bindingsCount), icon: Icons.link_rounded, dense: true),
          const SizedBox(width: 8),
          DcTag(
            l10n.synopticActivePointsCount(pointsCount),
            icon: Icons.sensors_rounded,
            tone: pointsCount > 0 ? dc.success : dc.neutral,
            dense: true,
          ),
          const Spacer(),
          Icon(Icons.pinch_rounded, size: 14, color: dc.textMuted),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              l10n.synopticPinchToZoom,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall?.copyWith(color: dc.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  void _showPointDetails(BuildContext context, SynopticBinding binding) {
    final liveState = ref.read(synopticLiveProvider(widget.synopticId));
    final value = liveState.pointValues[binding.pointRef];
    final config = BindingConfig.fromJson(binding.configJson);
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DcIconBox(icon: _getBindingIcon(binding.bindingType), size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        binding.pointName ?? binding.pointRef,
                        style: context.text.titleMedium,
                      ),
                      Text(
                        binding.pointRef,
                        style: AppTextStyles.monospacedValue.copyWith(
                          color: context.dc.textMuted,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            DcInfoRow(label: l10n.synopticSvgElement, value: binding.svgElementId, mono: true, labelWidth: 140),
            DcInfoRow(
              label: l10n.synopticBindingType,
              value: _getBindingTypeName(l10n, binding.bindingType),
              labelWidth: 140,
            ),
            DcInfoRow(
              label: l10n.synopticCurrentValue,
              value: config.formatValue(value),
              mono: true,
              valueColor: context.dc.accentTone.fg,
              labelWidth: 140,
            ),
            if (binding.bindingType == BindingType.color)
              DcInfoRow(
                label: l10n.state,
                value: config.isOn(value) ? 'ON' : 'OFF',
                valueColor: config.isOn(value) ? context.dc.success.fg : context.dc.textSecondary,
                labelWidth: 140,
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Naviguer vers le détail du point
                  context.push(Routes.pointDetailPath(binding.pointRef));
                },
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(l10n.synopticViewPoint),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getBindingIcon(BindingType type) {
    switch (type) {
      case BindingType.value:
        return Icons.pin_outlined;
      case BindingType.color:
        return Icons.palette_outlined;
      case BindingType.animation:
        return Icons.animation_rounded;
    }
  }

  String _getBindingTypeName(AppLocalizations l10n, BindingType type) {
    switch (type) {
      case BindingType.value:
        return l10n.synopticNumericValue;
      case BindingType.color:
        return l10n.synopticColorIndicator;
      case BindingType.animation:
        return l10n.synopticAnimation;
    }
  }
}

/// Widget qui affiche le SVG avec des overlays pour les valeurs
class _SvgWithOverlays extends StatefulWidget {
  final String svgAssetPath;
  final List<SynopticBinding> bindings;
  final SynopticLiveState liveState;
  final Function(SynopticBinding) onElementTap;

  const _SvgWithOverlays({
    required this.svgAssetPath,
    required this.bindings,
    required this.liveState,
    required this.onElementTap,
  });

  @override
  State<_SvgWithOverlays> createState() => _SvgWithOverlaysState();
}

class _SvgWithOverlaysState extends State<_SvgWithOverlays>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // SVG de base
        SvgPicture.asset(
          widget.svgAssetPath,
          fit: BoxFit.contain,
        ),

        // Overlays pour les valeurs numériques
        ..._buildValueOverlays(context),

        // Overlays pour les indicateurs couleur
        ..._buildColorOverlays(context),

        // Overlays pour les animations
        ..._buildAnimationOverlays(context),
      ],
    );
  }

  List<Widget> _buildValueOverlays(BuildContext context) {
    final overlays = <Widget>[];

    for (final binding in widget.bindings) {
      if (binding.bindingType == BindingType.value) {
        final value = widget.liveState.pointValues[binding.pointRef];
        final config = BindingConfig.fromJson(binding.configJson);
        final displayValue = config.formatValue(value);

        final position = _getOverlayPosition(binding.svgElementId);
        if (position != null) {
          overlays.add(
            Positioned(
              left: position.dx,
              top: position.dy,
              child: GestureDetector(
                onTap: () => widget.onElementTap(binding),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.brandNavy.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(DcRadius.sm),
                    border: Border.all(color: AppColors.brandSky.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    displayValue,
                    style: AppTextStyles.monospacedValue.copyWith(
                      color: const Color(0xFF8FD3FF),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    return overlays;
  }

  List<Widget> _buildColorOverlays(BuildContext context) {
    final overlays = <Widget>[];

    for (final binding in widget.bindings) {
      if (binding.bindingType == BindingType.color) {
        final value = widget.liveState.pointValues[binding.pointRef];
        final config = BindingConfig.fromJson(binding.configJson);
        final isOn = config.isOn(value);
        final color = isOn
            ? _parseColor(config.onColor ?? '#27ae60')
            : _parseColor(config.offColor ?? '#e74c3c');

        final position = _getOverlayPosition(binding.svgElementId);
        if (position != null) {
          overlays.add(
            Positioned(
              left: position.dx,
              top: position.dy,
              child: GestureDetector(
                onTap: () => widget.onElementTap(binding),
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: isOn ? 8 : 2,
                        spreadRadius: isOn ? 2 : 0,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    return overlays;
  }

  List<Widget> _buildAnimationOverlays(BuildContext context) {
    final overlays = <Widget>[];

    for (final binding in widget.bindings) {
      if (binding.bindingType == BindingType.animation) {
        final value = widget.liveState.pointValues[binding.pointRef];
        final config = BindingConfig.fromJson(binding.configJson);
        final isActive = config.isOn(value);

        final position = _getOverlayPosition(binding.svgElementId);
        if (position != null) {
          overlays.add(
            Positioned(
              left: position.dx,
              top: position.dy,
              child: GestureDetector(
                onTap: () => widget.onElementTap(binding),
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    final tone = isActive ? context.dc.success : context.dc.neutral;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.success.withValues(alpha: 0.15 + 0.2 * _animController.value)
                            : tone.bg,
                        borderRadius: BorderRadius.circular(DcRadius.sm),
                        border: Border.all(color: isActive ? AppColors.success : tone.border, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isActive)
                            RotationTransition(
                              turns: _animController,
                              child: Icon(
                                Icons.settings_rounded,
                                size: 16,
                                color: tone.fg,
                              ),
                            )
                          else
                            Icon(
                              Icons.settings_rounded,
                              size: 16,
                              color: tone.fg,
                            ),
                          const SizedBox(width: 4),
                          Text(
                            isActive ? 'ON' : 'OFF',
                            style: AppTextStyles.monospacedValue.copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: tone.fg,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        }
      }
    }

    return overlays;
  }

  Color _parseColor(String hex) {
    try {
      final cleanHex = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleanHex', radix: 16));
    } catch (_) {
      return AppColors.disconnected;
    }
  }

  Offset? _getOverlayPosition(String svgElementId) {
    // Positions approximatives pour le SVG CR_V0.1 (340x540)
    // Note: Ces valeurs doivent être ajustées en fonction du rendu réel
    switch (svgElementId) {
      case 'val_temp_depart':
        return const Offset(45, 83);
      case 'val_v3v_position':
        return const Offset(62, 351);
      case 'ind_pompe_etat':
        return const Offset(100, 200);
      case 'ind_v3v_etat':
        return const Offset(90, 380);
      case 'anim_pompe_rotation':
        return const Offset(130, 230);
      default:
        return null;
    }
  }
}
