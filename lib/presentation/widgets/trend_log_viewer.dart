import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../application/providers/trend_log_provider.dart';
import '../../domain/models/trend_log.dart';

// =============================================================================
// Utilitaires partagés
// =============================================================================

/// Formate une valeur numérique pour l'affichage
String _formatValue(double value) {
  if (value == value.truncateToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(2);
}

/// Données préparées pour le graphique
class _ChartData {
  final List<FlSpot> spots;
  final double minTimestamp;
  final double minY;
  final double maxY;
  final double yPadding;

  const _ChartData({
    required this.spots,
    required this.minTimestamp,
    required this.minY,
    required this.maxY,
    required this.yPadding,
  });

  /// Prépare les données pour le graphique à partir des records
  static _ChartData? fromRecords(List<TrendLogRecord> records) {
    final valueRecords = records
        .where((r) => r.isValueRecord && r.numericValue != null)
        .toList();

    if (valueRecords.isEmpty) return null;

    // Trier par timestamp
    valueRecords.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Créer les spots pour le graphique
    final spots = <FlSpot>[];
    final minTimestamp = valueRecords.first.timestamp.millisecondsSinceEpoch.toDouble();

    for (final record in valueRecords) {
      final x = (record.timestamp.millisecondsSinceEpoch.toDouble() - minTimestamp) / 1000 / 60;
      spots.add(FlSpot(x, record.numericValue!));
    }

    // Calculer les valeurs min/max pour l'axe Y
    final values = valueRecords.map((r) => r.numericValue!).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final yPadding = (maxY - minY) * 0.1;

    return _ChartData(
      spots: spots,
      minTimestamp: minTimestamp,
      minY: minY,
      maxY: maxY,
      yPadding: yPadding,
    );
  }
}

// =============================================================================
// Widgets partagés
// =============================================================================

/// Sélecteur de période pour les trend logs
class _PeriodSelector extends ConsumerWidget {
  final int trendLogInstance;
  final TrendLogViewerState state;

  const _PeriodSelector({
    required this.trendLogInstance,
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
                                  .read(trendLogViewerProvider(trendLogInstance).notifier)
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

/// Affiche les statistiques du trend log
class _StatisticsBar extends StatelessWidget {
  final TrendLogData data;

  const _StatisticsBar({required this.data});

  @override
  Widget build(BuildContext context) {
    final valueRecords = data.records.where((r) => r.isValueRecord).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'Points', value: valueRecords.toString()),
          if (data.minValue != null)
            _StatItem(label: 'Min', value: _formatValue(data.minValue!)),
          if (data.maxValue != null)
            _StatItem(label: 'Max', value: _formatValue(data.maxValue!)),
          if (data.avgValue != null)
            _StatItem(label: 'Moy', value: _formatValue(data.avgValue!)),
        ],
      ),
    );
  }
}

/// Item de statistique individuel
class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}

/// Widget d'état de chargement
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

/// Widget d'état d'erreur
class _ErrorState extends ConsumerWidget {
  final String error;
  final int trendLogInstance;

  const _ErrorState({required this.error, required this.trendLogInstance});

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
              onPressed: () => ref
                  .read(trendLogViewerProvider(trendLogInstance).notifier)
                  .loadData(),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget d'état vide
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
            Icon(Icons.show_chart, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucune donnée pour cette période',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tableau de données du trend log
class _DataTable extends StatelessWidget {
  final TrendLogData data;
  final String? units;
  final double? fixedHeight;

  const _DataTable({
    required this.data,
    this.units,
    this.fixedHeight,
  });

  @override
  Widget build(BuildContext context) {
    var valueRecords = data.records.where((r) => r.isValueRecord).toList();

    // Trier par timestamp décroissant
    valueRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Limiter si hauteur fixe (mode compact)
    if (fixedHeight != null) {
      valueRecords = valueRecords.take(100).toList();
    }

    final table = DataTable(
      columnSpacing: 16,
      headingRowHeight: fixedHeight != null ? 40 : 48,
      dataRowMinHeight: fixedHeight != null ? 36 : 40,
      dataRowMaxHeight: fixedHeight != null ? 36 : 40,
      columns: const [
        DataColumn(label: Text('Date/Heure')),
        DataColumn(label: Text('Valeur'), numeric: true),
        DataColumn(label: Text('Status')),
      ],
      rows: valueRecords.map((record) => _buildRow(record)).toList(),
    );

    if (fixedHeight != null) {
      return SizedBox(
        height: fixedHeight,
        child: SingleChildScrollView(child: table),
      );
    }

    return SingleChildScrollView(child: table);
  }

  DataRow _buildRow(TrendLogRecord record) {
    final fontSize = fixedHeight != null ? 12.0 : 13.0;

    return DataRow(
      cells: [
        DataCell(Text(
          DateFormat('dd/MM/yyyy HH:mm:ss').format(record.timestamp),
          style: TextStyle(fontSize: fontSize),
        )),
        DataCell(Text(
          record.numericValue != null
              ? '${_formatValue(record.numericValue!)}${units != null ? ' $units' : ''}'
              : record.value?.toString() ?? '-',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: fontSize),
        )),
        DataCell(Text(
          record.status ?? 'OK',
          style: TextStyle(
            fontSize: fontSize - 1,
            color: record.status == 'Normal' || record.status == null
                ? Colors.green
                : Colors.orange,
          ),
        )),
      ],
    );
  }
}

// =============================================================================
// TrendLogViewer - Widget principal (compact, dans une Card)
// =============================================================================

/// Widget pour afficher l'historique d'un trend log avec graphique
class TrendLogViewer extends ConsumerStatefulWidget {
  final int trendLogInstance;
  final String? pointName;
  final String? units;

  const TrendLogViewer({
    super.key,
    required this.trendLogInstance,
    this.pointName,
    this.units,
  });

  @override
  ConsumerState<TrendLogViewer> createState() => _TrendLogViewerState();
}

class _TrendLogViewerState extends ConsumerState<TrendLogViewer> {
  bool _showTable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trendLogViewerProvider(widget.trendLogInstance).notifier).loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trendLogViewerProvider(widget.trendLogInstance));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, state),
            const SizedBox(height: 16),
            _PeriodSelector(
              trendLogInstance: widget.trendLogInstance,
              state: state,
            ),
            const SizedBox(height: 16),
            _buildContent(state),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TrendLogViewerState state) {
    final hasData = state.data != null && state.data!.records.isNotEmpty;

    return Row(
      children: [
        Icon(Icons.show_chart, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Historique',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        if (hasData)
          IconButton(
            icon: const Icon(Icons.fullscreen),
            tooltip: 'Plein écran',
            onPressed: () => _openFullscreen(context, state),
          ),
        IconButton(
          icon: Icon(_showTable ? Icons.show_chart : Icons.table_chart),
          tooltip: _showTable ? 'Voir graphique' : 'Voir tableau',
          onPressed: () => setState(() => _showTable = !_showTable),
        ),
        if (hasData)
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exporter CSV',
            onPressed: () => _exportCsv(state.data!),
          ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Rafraîchir',
          onPressed: state.isLoading
              ? null
              : () => ref
                  .read(trendLogViewerProvider(widget.trendLogInstance).notifier)
                  .refresh(),
        ),
      ],
    );
  }

  Widget _buildContent(TrendLogViewerState state) {
    if (state.isLoading) {
      return _LoadingState(message: state.loadingMessage);
    }

    if (state.error != null) {
      return _ErrorState(
        error: state.error!,
        trendLogInstance: widget.trendLogInstance,
      );
    }

    if (state.data == null || state.data!.records.isEmpty) {
      return const _EmptyState();
    }

    return Column(
      children: [
        _StatisticsBar(data: state.data!),
        const SizedBox(height: 16),
        if (_showTable)
          _DataTable(
            data: state.data!,
            units: widget.units,
            fixedHeight: 250,
          )
        else
          _buildChart(state.data!),
      ],
    );
  }

  Widget _buildChart(TrendLogData data) {
    final chartData = _ChartData.fromRecords(data.records);
    if (chartData == null) return const _EmptyState();

    return SizedBox(
      height: 200,
      child: _TrendChart(
        chartData: chartData,
        units: widget.units,
        primaryColor: Theme.of(context).colorScheme.primary,
        showDots: chartData.spots.length < 50,
        dateFormat: 'HH:mm',
      ),
    );
  }

  void _openFullscreen(BuildContext context, TrendLogViewerState state) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TrendLogFullscreenView(
          trendLogInstance: widget.trendLogInstance,
          pointName: widget.pointName,
          units: widget.units,
          initialData: state.data,
        ),
      ),
    );
  }

  Future<void> _exportCsv(TrendLogData data) async {
    final valueRecords = data.records.where((r) => r.isValueRecord).toList();
    if (valueRecords.isEmpty) return;

    valueRecords.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final buffer = StringBuffer();
    buffer.writeln('Timestamp,Value,Unit,Status');

    for (final record in valueRecords) {
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(record.timestamp);
      final value = record.numericValue?.toString() ?? record.value?.toString() ?? '';
      final unit = widget.units ?? '';
      final status = record.status ?? 'Normal';
      buffer.writeln('$timestamp,$value,$unit,$status');
    }

    try {
      final directory = await getTemporaryDirectory();
      final fileName = 'trend_${widget.trendLogInstance}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(buffer.toString());

      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Export historique ${widget.pointName ?? 'Trend Log ${widget.trendLogInstance}'}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// =============================================================================
// TrendLogFullscreenView - Vue plein écran
// =============================================================================

/// Vue plein écran du trend log avec graphique optimisé pour mobile
class TrendLogFullscreenView extends ConsumerStatefulWidget {
  final int trendLogInstance;
  final String? pointName;
  final String? units;
  final TrendLogData? initialData;

  const TrendLogFullscreenView({
    super.key,
    required this.trendLogInstance,
    this.pointName,
    this.units,
    this.initialData,
  });

  @override
  ConsumerState<TrendLogFullscreenView> createState() => _TrendLogFullscreenViewState();
}

class _TrendLogFullscreenViewState extends ConsumerState<TrendLogFullscreenView> {
  bool _isLandscape = false;
  bool _showTable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialData == null) {
        ref.read(trendLogViewerProvider(widget.trendLogInstance).notifier).loadData();
      }
    });
  }

  @override
  void dispose() {
    // Restaurer l'orientation automatique
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _toggleOrientation() {
    setState(() => _isLandscape = !_isLandscape);

    SystemChrome.setPreferredOrientations(_isLandscape
        ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
        : [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trendLogViewerProvider(widget.trendLogInstance));
    final data = state.data ?? widget.initialData;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pointName ?? 'Historique'),
        actions: [
          IconButton(
            icon: Icon(_isLandscape ? Icons.screen_lock_portrait : Icons.screen_lock_landscape),
            tooltip: _isLandscape ? 'Mode portrait' : 'Mode paysage',
            onPressed: _toggleOrientation,
          ),
          IconButton(
            icon: Icon(_showTable ? Icons.show_chart : Icons.table_chart),
            tooltip: _showTable ? 'Voir graphique' : 'Voir tableau',
            onPressed: () => setState(() => _showTable = !_showTable),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
            onPressed: state.isLoading
                ? null
                : () => ref
                    .read(trendLogViewerProvider(widget.trendLogInstance).notifier)
                    .refresh(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _PeriodSelector(
                trendLogInstance: widget.trendLogInstance,
                state: state,
              ),
            ),
            if (data != null && data.records.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _StatisticsBar(data: data),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildContent(state, data),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(TrendLogViewerState state, TrendLogData? data) {
    if (state.isLoading) {
      return _LoadingState(message: state.loadingMessage);
    }

    if (state.error != null) {
      return _ErrorState(
        error: state.error!,
        trendLogInstance: widget.trendLogInstance,
      );
    }

    if (data == null || data.records.isEmpty) {
      return const _EmptyState();
    }

    if (_showTable) {
      return _DataTable(data: data, units: widget.units);
    }

    return _buildFullscreenChart(data);
  }

  Widget _buildFullscreenChart(TrendLogData data) {
    final chartData = _ChartData.fromRecords(data.records);
    if (chartData == null) {
      return Center(
        child: Text(
          'Aucune donnée numérique',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return _TrendChart(
      chartData: chartData,
      units: widget.units,
      primaryColor: Theme.of(context).colorScheme.primary,
      showDots: chartData.spots.length < 30,
      showVerticalGrid: true,
      showAxisLabel: true,
      dateFormat: _isLandscape ? 'HH:mm' : 'dd/MM\nHH:mm',
      rotateDateLabels: !_isLandscape,
    );
  }
}

// =============================================================================
// _TrendChart - Widget graphique réutilisable
// =============================================================================

/// Widget graphique de tendance réutilisable
class _TrendChart extends StatelessWidget {
  final _ChartData chartData;
  final String? units;
  final Color primaryColor;
  final bool showDots;
  final bool showVerticalGrid;
  final bool showAxisLabel;
  final String dateFormat;
  final bool rotateDateLabels;

  const _TrendChart({
    required this.chartData,
    required this.primaryColor,
    this.units,
    this.showDots = true,
    this.showVerticalGrid = false,
    this.showAxisLabel = false,
    this.dateFormat = 'HH:mm',
    this.rotateDateLabels = false,
  });

  @override
  Widget build(BuildContext context) {
    final yRange = chartData.maxY - chartData.minY;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: showVerticalGrid,
          horizontalInterval: yRange > 0 ? yRange / 5 : 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: showAxisLabel && units != null
                ? Text(
                    units!,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  )
                : null,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: showAxisLabel ? 60 : 50,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    _formatValue(value),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: rotateDateLabels ? 50 : 30,
              interval: chartData.spots.length > 1
                  ? (chartData.spots.last.x - chartData.spots.first.x) / 6
                  : null,
              getTitlesWidget: (value, meta) => _buildDateLabel(value),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: Colors.grey.shade400),
            bottom: BorderSide(color: Colors.grey.shade400),
          ),
        ),
        minY: chartData.minY - chartData.yPadding,
        maxY: chartData.maxY + chartData.yPadding,
        lineBarsData: [
          LineChartBarData(
            spots: chartData.spots,
            isCurved: true,
            curveSmoothness: 0.2,
            color: primaryColor,
            barWidth: 2,
            dotData: FlDotData(
              show: showDots,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 3,
                color: primaryColor,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: primaryColor.withAlpha(25),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final timestamp = DateTime.fromMillisecondsSinceEpoch(
                  (chartData.minTimestamp + spot.x * 60 * 1000).toInt(),
                );
                return LineTooltipItem(
                  '${DateFormat('dd/MM/yyyy HH:mm').format(timestamp)}\n${_formatValue(spot.y)}${units != null ? ' $units' : ''}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDateLabel(double value) {
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
      (chartData.minTimestamp + value * 60 * 1000).toInt(),
    );

    final label = Text(
      DateFormat(dateFormat).format(timestamp),
      style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
      textAlign: TextAlign.center,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: rotateDateLabels ? RotatedBox(quarterTurns: -1, child: label) : label,
    );
  }
}

// =============================================================================
// TrendLogIndicator - Indicateur compact pour la liste des points
// =============================================================================

/// Widget compact pour afficher l'icône de trend dans la liste des points
class TrendLogIndicator extends ConsumerWidget {
  final String pointKey;
  final VoidCallback? onTap;

  const TrendLogIndicator({
    super.key,
    required this.pointKey,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mappingAsync = ref.watch(trendLogMappingProvider);

    return mappingAsync.when(
      data: (mapping) {
        if (!mapping.containsKey(pointKey)) {
          return const SizedBox.shrink();
        }

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.show_chart,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
