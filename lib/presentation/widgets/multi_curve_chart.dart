import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../application/providers/multi_curve_provider.dart';
import '../../application/providers/trend_log_provider.dart';
import '../../domain/models/multi_curve_chart.dart';
import 'trend_log_viewer.dart';

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

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              padding: const EdgeInsets.all(16),
              child: _MultiCurveStatistics(data: state.data!),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MultiCurveViewerState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.multiline_chart,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Comparaison (${state.curveCount} courbes)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          if (state.isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          if (!state.isLoading) ...[
            // Bouton ajouter courbe
            if (state.canAddCurve && widget.onAddCurve != null)
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Ajouter une courbe',
                onPressed: widget.onAddCurve,
              ),
            // Bouton rafraîchir
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Rafraîchir',
              onPressed: () => ref
                  .read(multiCurveViewerProvider(widget.chartId).notifier)
                  .refresh(),
            ),
            // Bouton plein écran
            if (widget.onExpandToFullscreen != null)
              IconButton(
                icon: const Icon(Icons.fullscreen),
                tooltip: 'Plein écran',
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _MultiCurveLineChart(
        data: state.data!,
        visibility: state.curveVisibility,
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

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                ref
                    .read(multiCurveViewerProvider(chartId).notifier)
                    .toggleCurveVisibility(curve.trendLogInstance);
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isVisible
                      ? colorTheme.primaryColor.withAlpha(30)
                      : Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isVisible
                        ? colorTheme.primaryColor.withAlpha(60)
                        : Colors.grey.withAlpha(40),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isVisible ? colorTheme.primaryColor : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      curve.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isVisible ? colorTheme.primaryColor : Colors.grey,
                        decoration:
                            isVisible ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    if (curve.units != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(${curve.units})',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TrendPeriod.values
            .where((p) => p != TrendPeriod.custom)
            .map((period) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(period.label),
                    selected: state.selectedPeriod == period,
                    onSelected: state.isLoading
                        ? null
                        : (selected) {
                            if (selected) {
                              ref
                                  .read(multiCurveViewerProvider(chartId).notifier)
                                  .setPeriod(period);
                            }
                          },
                  ),
                ))
            .toList(),
      ),
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

  @override
  Widget build(BuildContext context) {
    final visibleCurves = widget.data.curves
        .where((c) => widget.visibility[c.trendLogInstance] ?? true)
        .toList();

    if (visibleCurves.isEmpty) {
      return const Center(
        child: Text(
          'Aucune courbe visible\nTouchez la légende pour afficher',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Calculer les limites X
    final allSpots = visibleCurves.expand((c) => c.spots).toList();
    if (allSpots.isEmpty) {
      return const Center(child: Text('Aucune donnée'));
    }

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
    final yPadding = (visibleMaxY - visibleMinY) * 0.1;

    return GestureDetector(
      onScaleStart: (_) {},
      onScaleUpdate: (details) {
        setState(() {
          // Zoom
          final newZoom = (_zoomLevel * details.scale).clamp(1.0, 10.0);
          _zoomLevel = newZoom;

          // Pan (uniquement si zoomé)
          if (_zoomLevel > 1.0) {
            final maxPan = totalRange - (totalRange / _zoomLevel);
            _panOffset = (_panOffset - details.focalPointDelta.dx * 0.5)
                .clamp(0.0, maxPan);
          }
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
                return LineChartBarData(
                  spots: curve.spots,
                  isCurved: true,
                  curveSmoothness: 0.2,
                  color: colorTheme.primaryColor,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: curve.spots.length < 50,
                    getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                      radius: 3,
                      color: colorTheme.dotBorderColor,
                      strokeWidth: 2,
                      strokeColor: colorTheme.primaryColor,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: visibleCurves.length == 1,
                    gradient: LinearGradient(
                      colors: [
                        colorTheme.gradientStart,
                        colorTheme.gradientEnd,
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
                  color: Colors.grey.withAlpha(30),
                  strokeWidth: 1,
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
                    getTitlesWidget: (value, meta) => _buildDateLabel(value),
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
                        _formatValue(value),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final curveIndex = spot.barIndex;
                      if (curveIndex >= visibleCurves.length) return null;

                      final curve = visibleCurves[curveIndex];
                      final colorTheme = ChartColorTheme.fromName(curve.colorThemeName);
                      final timestamp = DateTime.fromMillisecondsSinceEpoch(
                        (widget.data.minTimestamp + spot.x * 60 * 1000).toInt(),
                      );

                      return LineTooltipItem(
                        '${curve.name}\n${DateFormat('HH:mm').format(timestamp)}: ${_formatValue(spot.y)}${curve.units != null ? ' ${curve.units}' : ''}',
                        TextStyle(
                          color: colorTheme.tooltipText,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
            duration: const Duration(milliseconds: 150),
          ),

          // Indicateur de zoom
          if (_zoomLevel > 1.0)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_zoomLevel.toStringAsFixed(1)}x',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateLabel(double value) {
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
      (widget.data.minTimestamp + value * 60 * 1000).toInt(),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        DateFormat('dd/MM\nHH:mm').format(timestamp),
        style: TextStyle(color: Colors.grey.shade600, fontSize: 9),
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
    final visibleCurves = data.visibleCurves;
    if (visibleCurves.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatColumn(
            label: 'Min',
            values: visibleCurves
                .map((c) => (
                      name: c.name,
                      value: c.minValue,
                      color: ChartColorTheme.fromName(c.colorThemeName).primaryColor,
                    ))
                .toList(),
          ),
          _StatColumn(
            label: 'Max',
            values: visibleCurves
                .map((c) => (
                      name: c.name,
                      value: c.maxValue,
                      color: ChartColorTheme.fromName(c.colorThemeName).primaryColor,
                    ))
                .toList(),
          ),
          _StatColumn(
            label: 'Moy',
            values: visibleCurves
                .map((c) => (
                      name: c.name,
                      value: c.avgValue,
                      color: ChartColorTheme.fromName(c.colorThemeName).primaryColor,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final List<({String name, double value, Color color})> values;

  const _StatColumn({required this.label, required this.values});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        ...values.map((v) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: v.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatValue(v.value),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: v.color,
                    ),
                  ),
                ],
              ),
            )),
      ],
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
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends ConsumerWidget {
  final String error;
  final String chartId;

  const _ErrorState({required this.error, required this.chartId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(multiCurveViewerProvider(chartId).notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.multiline_chart, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucune courbe sélectionnée\nAjoutez des trend logs à comparer',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Utilitaires
// =============================================================================

String _formatValue(double value) {
  if (value == value.truncateToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(2);
}
