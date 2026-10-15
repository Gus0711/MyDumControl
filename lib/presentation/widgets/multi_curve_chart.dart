import 'dart:math' as math;
import 'package:flutter/foundation.dart' show listEquals, mapEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/utils/formatters.dart';
import '../../application/providers/multi_curve_provider.dart';
import '../../application/providers/trend_log_provider.dart';
import '../../domain/models/multi_curve_chart.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/dc_tokens.dart';
import 'chart_chrome.dart';
import 'chart_downsample.dart';
import 'trend_log_viewer.dart';
import 'ui/dc_banner.dart';
import 'ui/dc_layout.dart';
import 'ui/dc_tag.dart';

// =============================================================================
// MultiCurveChart - Widget principal pour afficher plusieurs courbes
// =============================================================================

/// Widget pour afficher plusieurs trend logs sur un même graphique
class MultiCurveChart extends ConsumerStatefulWidget {
  final String chartId;
  final List<int>? initialTrendLogInstances;
  final Map<int, String>? curveNames;
  final Map<int, String?>? curveUnits;
  final double? height;
  final bool showHeader;
  final bool showLegend;
  final bool showPeriodSelector;
  final bool showStatistics;
  final VoidCallback? onAddCurve;
  final VoidCallback? onExpandToFullscreen;

  const MultiCurveChart({
    super.key,
    required this.chartId,
    this.initialTrendLogInstances,
    this.curveNames,
    this.curveUnits,
    this.height,
    this.showHeader = true,
    this.showLegend = true,
    this.showPeriodSelector = true,
    this.showStatistics = true,
    this.onAddCurve,
    this.onExpandToFullscreen,
  });

  @override
  ConsumerState<MultiCurveChart> createState() => _MultiCurveChartState();
}

class _MultiCurveChartState extends ConsumerState<MultiCurveChart> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeChart();
  }

  @override
  void didUpdateWidget(covariant MultiCurveChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final configChanged = oldWidget.chartId != widget.chartId ||
        !listEquals(oldWidget.initialTrendLogInstances, widget.initialTrendLogInstances) ||
        !mapEquals(oldWidget.curveNames, widget.curveNames) ||
        !mapEquals(oldWidget.curveUnits, widget.curveUnits);
    final instances = widget.initialTrendLogInstances;
    if (!configChanged || instances == null || instances.isEmpty) return;

    // Reconfiguration (ex: dashboard widget edited): re-initialize the provider
    final chartId = widget.chartId;
    final names = widget.curveNames == null ? null : Map<int, String>.of(widget.curveNames!);
    final units = widget.curveUnits == null ? null : Map<int, String?>.of(widget.curveUnits!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(multiCurveViewerProvider(chartId).notifier).reconfigure(
            List<int>.of(instances),
            names: names,
            units: units,
          );
    });
  }

  void _initializeChart() {
    if (_initialized) return;
    if (widget.initialTrendLogInstances == null || widget.initialTrendLogInstances!.isEmpty) return;

    _initialized = true; // Marquer immédiatement pour éviter les doubles appels

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Vérifier si le provider est déjà initialisé
      final currentState = ref.read(multiCurveViewerProvider(widget.chartId));
      if (currentState.selectedTrendLogInstances.isNotEmpty) {
        // Déjà initialisé, juste rafraîchir si les données sont vides
        if (currentState.data == null && !currentState.isLoading) {
          ref.read(multiCurveViewerProvider(widget.chartId).notifier).loadData();
        }
        return;
      }

      // Initialiser le provider
      ref.read(multiCurveViewerProvider(widget.chartId).notifier).initialize(
            widget.initialTrendLogInstances!,
            names: widget.curveNames,
            units: widget.curveUnits,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(multiCurveViewerProvider(widget.chartId));

    final dc = context.dc;
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: dc.surface,
        borderRadius: BorderRadius.circular(DcRadius.lg),
        border: Border.all(color: dc.border),
        boxShadow: dc.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec actions (optionnel - masqué si utilisé dans dashboard widget)
          if (widget.showHeader) _buildHeader(context, state),

          // Sélecteur de période
          if (widget.showPeriodSelector)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _MultiCurvePeriodSelector(
                chartId: widget.chartId,
                state: state,
              ),
            ),

          // Légende
          if (widget.showLegend && state.data != null && state.data!.curves.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: _CurveLegend(
                chartId: widget.chartId,
                curves: state.data!.curves,
                visibility: state.curveVisibility,
              ),
            ),

          // Contenu principal
          Expanded(
            child: _buildContent(state),
          ),

          // Statistiques
          if (widget.showStatistics && state.data != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _MultiCurveStatistics(data: state.data!),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MultiCurveViewerState state) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          DcIconBox(icon: Icons.stacked_line_chart_rounded, tone: context.dc.violet, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.chartComparisonTitle(state.curveCount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleMedium,
            ),
          ),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.all(10),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          if (!state.isLoading) ...[
            // Bouton ajouter courbe
            if (state.canAddCurve && widget.onAddCurve != null)
              IconButton(
                icon: const Icon(Icons.add_rounded, size: 20),
                tooltip: l10n.chartAddCurve,
                onPressed: widget.onAddCurve,
              ),
            // Bouton rafraîchir
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              tooltip: l10n.refresh,
              onPressed: () => ref
                  .read(multiCurveViewerProvider(widget.chartId).notifier)
                  .refresh(),
            ),
            // Bouton plein écran
            if (widget.onExpandToFullscreen != null)
              IconButton(
                icon: const Icon(Icons.open_in_full_rounded, size: 20),
                tooltip: l10n.trendFullscreen,
                onPressed: widget.onExpandToFullscreen,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(MultiCurveViewerState state) {
    if (state.isLoading && state.data == null) {
      return _LoadingState(message: state.loadingMessage);
    }

    if (state.error != null && state.data == null) {
      return _ErrorState(
        error: state.error!,
        chartId: widget.chartId,
      );
    }

    if (state.data == null || state.data!.curves.isEmpty) {
      return const _EmptyState();
    }

    final chart = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _MultiCurveLineChart(
        data: state.data!,
        visibility: state.curveVisibility,
      ),
    );

    // Partial failure: keep the loaded curves and show the error above them
    final error = state.error ??
        (state.curveErrors.isEmpty
            ? null
            : AppLocalizations.of(context)!.chartCurvesNotLoaded(state.curveErrors.length));
    if (error == null) return chart;

    return Column(
      children: [
        _ErrorBanner(message: error),
        Expanded(child: chart),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DcBanner(
        tone: context.dc.warning,
        icon: Icons.warning_amber_rounded,
        message: message,
        dense: true,
      ),
    );
  }
}

// =============================================================================
// Légende des courbes
// =============================================================================

class _CurveLegend extends ConsumerWidget {
  final String chartId;
  final List<CurveData> curves;
  final Map<int, bool> visibility;

  const _CurveLegend({
    required this.chartId,
    required this.curves,
    required this.visibility,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: curves.map((curve) {
          final colorTheme = ChartColorTheme.fromName(curve.colorThemeName);
          final isVisible = visibility[curve.trendLogInstance] ?? true;
          final dc = context.dc;
          final seriesColor = chartSeriesColor(context, colorTheme.primaryColor);
          final tone = dc.toneOf(colorTheme.primaryColor);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                ref
                    .read(multiCurveViewerProvider(chartId).notifier)
                    .toggleCurveVisibility(curve.trendLogInstance);
              },
              borderRadius: BorderRadius.circular(DcRadius.md),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isVisible ? tone.bg : Colors.transparent,
                  borderRadius: BorderRadius.circular(DcRadius.md),
                  border: Border.all(color: isVisible ? tone.border : dc.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 3,
                      decoration: BoxDecoration(
                        color: isVisible ? seriesColor : dc.textMuted,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      curve.name,
                      style: context.text.labelMedium?.copyWith(
                        color: isVisible ? dc.textPrimary : dc.textMuted,
                        decoration: isVisible ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    if (curve.units != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        curve.units!,
                        style: AppTextStyles.monospacedValue.copyWith(
                          fontSize: 10.5,
                          color: isVisible ? tone.fg : dc.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================================
// Sélecteur de période
// =============================================================================

class _MultiCurvePeriodSelector extends ConsumerWidget {
  final String chartId;
  final MultiCurveViewerState state;

  const _MultiCurvePeriodSelector({
    required this.chartId,
    required this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ChartSegmented<TrendPeriod>(
      values: TrendPeriod.values.where((p) => p != TrendPeriod.custom).toList(),
      selected: state.selectedPeriod,
      labelOf: (period) => trendPeriodLabel(l10n, period),
      onSelected: state.isLoading
          ? null
          : (period) => ref.read(multiCurveViewerProvider(chartId).notifier).setPeriod(period),
    );
  }
}

// =============================================================================
// Graphique multi-courbes
// =============================================================================

class _MultiCurveLineChart extends StatefulWidget {
  final MultiCurveData data;
  final Map<int, bool> visibility;

  const _MultiCurveLineChart({
    required this.data,
    required this.visibility,
  });

  @override
  State<_MultiCurveLineChart> createState() => _MultiCurveLineChartState();
}

class _MultiCurveLineChartState extends State<_MultiCurveLineChart> {
  // Zoom & Pan
  double _zoomLevel = 1.0;
  double _panOffset = 0.0;
  double _baseZoom = 1.0; // zoom at the start of the current gesture
  double _chartWidth = 300.0; // last known width, used for pan sensitivity

  @override
  void didUpdateWidget(covariant _MultiCurveLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // New data set: restart from the full view
    if (!identical(oldWidget.data, widget.data)) {
      _zoomLevel = 1.0;
      _panOffset = 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleCurves = widget.data.curves
        .where((c) => widget.visibility[c.trendLogInstance] ?? true)
        .toList();

    if (visibleCurves.isEmpty) {
      return ChartMessage(
        icon: Icons.visibility_off_outlined,
        message: AppLocalizations.of(context)!.chartNoVisibleCurve,
        compact: true,
      );
    }

    // Calculer les limites X
    final allSpots = visibleCurves.expand((c) => c.spots).toList();
    if (allSpots.isEmpty) {
      return ChartMessage(
        icon: Icons.show_chart_rounded,
        message: AppLocalizations.of(context)!.noData,
        compact: true,
      );
    }
    final palette = ChartPalette.of(context);

    final minX = allSpots.map((s) => s.x).reduce(math.min);
    final maxX = allSpots.map((s) => s.x).reduce(math.max);
    final totalRange = maxX - minX;
    final visibleRange = totalRange / _zoomLevel;
    final actualMinX = minX + _panOffset;
    final actualMaxX = actualMinX + visibleRange;

    // Calculer les limites Y pour les courbes visibles
    double visibleMinY = double.infinity;
    double visibleMaxY = double.negativeInfinity;
    for (final curve in visibleCurves) {
      if (curve.minValue < visibleMinY) visibleMinY = curve.minValue;
      if (curve.maxValue > visibleMaxY) visibleMaxY = curve.maxValue;
    }
    // Padding minimal quand toutes les valeurs sont identiques (min == max)
    final yRange = visibleMaxY - visibleMinY;
    final yPadding = yRange > 0 ? yRange * 0.1 : 1.0;

    return LayoutBuilder(builder: (context, constraints) {
    if (constraints.maxWidth.isFinite && constraints.maxWidth > 0) {
      _chartWidth = constraints.maxWidth;
    }
    return GestureDetector(
      onScaleStart: (_) => _baseZoom = _zoomLevel,
      onScaleUpdate: (details) {
        setState(() {
          // Zoom relatif au zoom de départ (details.scale est cumulatif)
          _zoomLevel = (_baseZoom * details.scale).clamp(1.0, 10.0);

          // Pan proportionnel à la plage visible, re-clampé à chaque update
          final maxPan = totalRange - (totalRange / _zoomLevel);
          if (_zoomLevel > 1.0) {
            final minutesPerPixel = (totalRange / _zoomLevel) / _chartWidth;
            _panOffset = _panOffset - details.focalPointDelta.dx * minutesPerPixel;
          }
          _panOffset = _panOffset.clamp(0.0, maxPan > 0 ? maxPan : 0.0);
        });
      },
      onDoubleTap: () {
        setState(() {
          _zoomLevel = 1.0;
          _panOffset = 0.0;
        });
      },
      child: Stack(
        children: [
          LineChart(
            LineChartData(
              lineBarsData: visibleCurves.map((curve) {
                final colorTheme = ChartColorTheme.fromName(curve.colorThemeName);
                final seriesColor = chartSeriesColor(context, colorTheme.primaryColor);
                final spots = downsampleMinMax(
                  visibleWindow(curve.spots, actualMinX - visibleRange * 0.1,
                      actualMaxX + visibleRange * 0.1),
                );
                return LineChartBarData(
                  spots: spots.isNotEmpty ? spots : downsampleMinMax(curve.spots),
                  isCurved: spots.length <= kRichRenderingMaxPoints,
                  curveSmoothness: 0.2,
                  color: seriesColor,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  isStrokeJoinRound: true,
                  dotData: FlDotData(
                    show: spots.length < 50,
                    getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                      radius: 3,
                      color: palette.dotStroke,
                      strokeWidth: 2,
                      strokeColor: seriesColor,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: visibleCurves.length == 1,
                    gradient: LinearGradient(
                      colors: [
                        seriesColor.withValues(alpha: context.dc.isDark ? 0.28 : 0.2),
                        seriesColor.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                );
              }).toList(),
              minX: actualMinX,
              maxX: actualMaxX,
              minY: visibleMinY - yPadding,
              maxY: visibleMaxY + yPadding,
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: false,
                horizontalInterval: _calculateYInterval(visibleMinY, visibleMaxY),
                getDrawingHorizontalLine: (value) => FlLine(
                  color: palette.grid,
                  strokeWidth: 1,
                  dashArray: [3, 4],
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: _calculateXInterval(actualMinX, actualMaxX),
                    getTitlesWidget: (value, meta) => _buildDateLabel(value, palette),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    interval: _calculateYInterval(visibleMinY, visibleMaxY),
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        formatNumber(value),
                        textAlign: TextAlign.right,
                        style: palette.axisLabel,
                      ),
                    ),
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(bottom: BorderSide(color: palette.axis)),
              ),
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  tooltipRoundedRadius: DcRadius.md,
                  tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  getTooltipColor: (_) => palette.tooltipBackground,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final curveIndex = spot.barIndex;
                      if (curveIndex >= visibleCurves.length) return null;

                      final curve = visibleCurves[curveIndex];
                      final colorTheme = ChartColorTheme.fromName(curve.colorThemeName);
                      final timestamp = DateTime.fromMillisecondsSinceEpoch(
                        (widget.data.minTimestamp + spot.x * 60 * 1000).toInt(),
                      );
                      // Pastille de la série, lisible sur le fond inversé de l'infobulle
                      final marker = context.dc.isDark
                          ? colorTheme.primaryColor
                          : DcTone.fromColor(colorTheme.primaryColor, Brightness.dark).fg;

                      return LineTooltipItem(
                        '',
                        AppTextStyles.monospacedValue.copyWith(
                          color: palette.tooltipText,
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.left,
                        children: [
                          TextSpan(text: '● ', style: TextStyle(color: marker)),
                          TextSpan(
                            text: '${curve.name}\n',
                            style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text: '${DateFormat('HH:mm').format(timestamp)}  ',
                            style: TextStyle(color: palette.tooltipText.withValues(alpha: 0.7)),
                          ),
                          TextSpan(
                            text: '${formatNumber(spot.y)}${curve.units != null ? ' ${curve.units}' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      );
                    }).toList();
                  },
                ),
              ),
            ),
            duration: Duration.zero,
          ),

          // Indicateur de zoom
          if (_zoomLevel > 1.0)
            Positioned(
              top: 8,
              right: 8,
              child: DcTag(
                '${_zoomLevel.toStringAsFixed(1)}×',
                icon: Icons.zoom_in_rounded,
                tone: context.dc.accentTone,
                mono: true,
              ),
            ),
        ],
      ),
    );
    });
  }

  Widget _buildDateLabel(double value, ChartPalette palette) {
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
      (widget.data.minTimestamp + value * 60 * 1000).toInt(),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        DateFormat('dd/MM\nHH:mm').format(timestamp),
        style: palette.axisLabel.copyWith(fontSize: 9.5),
        textAlign: TextAlign.center,
      ),
    );
  }

  double _calculateXInterval(double minX, double maxX) {
    final range = maxX - minX;
    if (range <= 60) return 10; // 10 minutes
    if (range <= 360) return 60; // 1 heure
    if (range <= 1440) return 240; // 4 heures
    if (range <= 10080) return 1440; // 1 jour
    return 4320; // 3 jours
  }

  double _calculateYInterval(double minY, double maxY) {
    final range = maxY - minY;
    if (range <= 0) return 1;
    if (range <= 10) return 2;
    if (range <= 50) return 10;
    if (range <= 100) return 20;
    return (range / 5).ceilToDouble();
  }
}

// =============================================================================
// Statistiques multi-courbes
// =============================================================================

class _MultiCurveStatistics extends StatelessWidget {
  final MultiCurveData data;

  const _MultiCurveStatistics({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dc = context.dc;
    final visibleCurves = data.visibleCurves;
    if (visibleCurves.isEmpty) return const SizedBox.shrink();

    final headerStyle = AppTextStyles.overline.copyWith(color: dc.textMuted, fontSize: 10);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: dc.surfaceSunken,
        borderRadius: BorderRadius.circular(DcRadius.md),
        border: Border.all(color: dc.border),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2.2),
          1: FlexColumnWidth(),
          2: FlexColumnWidth(),
          3: FlexColumnWidth(),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              const SizedBox.shrink(),
              for (final label in [l10n.statisticsMin, l10n.statisticsMax, l10n.statisticsAvg])
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(label.toUpperCase(), textAlign: TextAlign.right, style: headerStyle),
                ),
            ],
          ),
          for (final c in visibleCurves)
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 3,
                        decoration: BoxDecoration(
                          color: chartSeriesColor(context, ChartColorTheme.fromName(c.colorThemeName).primaryColor),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall?.copyWith(color: dc.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                for (final v in [c.minValue, c.maxValue, c.avgValue])
                  Text(
                    formatNumber(v),
                    textAlign: TextAlign.right,
                    style: AppTextStyles.monospacedValue.copyWith(
                      color: dc.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// États de chargement/erreur/vide
// =============================================================================

class _LoadingState extends StatelessWidget {
  final String? message;

  const _LoadingState({this.message});

  @override
  Widget build(BuildContext context) => ChartMessage.loading(message: message, compact: true);
}

class _ErrorState extends ConsumerWidget {
  final String error;
  final String chartId;

  const _ErrorState({required this.error, required this.chartId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ChartMessage(
      icon: Icons.error_outline_rounded,
      tone: context.dc.danger,
      message: error,
      compact: true,
      action: OutlinedButton.icon(
        onPressed: () => ref.read(multiCurveViewerProvider(chartId).notifier).refresh(),
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: Text(AppLocalizations.of(context)!.retry),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ChartMessage(
      icon: Icons.stacked_line_chart_rounded,
      message: AppLocalizations.of(context)!.chartNoCurveSelected,
      compact: true,
    );
  }
}

// =============================================================================
// Utilitaires
// =============================================================================

