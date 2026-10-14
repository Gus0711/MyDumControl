import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../application/providers/dashboard_provider.dart';
import '../../../../application/providers/trend_log_provider.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/database/tables/dashboard_tables.dart';
import '../../../widgets/trend_log_viewer.dart';
import '../../../widgets/multi_curve_chart.dart';
import '../../../../l10n/app_localizations.dart';

/// Carte affichant un widget de dashboard (graphique, stats, etc.)
class DashboardWidgetCard extends ConsumerWidget {
  final DashboardWidget widget;
  final VoidCallback onConfigure;
  final VoidCallback onDelete;
  final VoidCallback? onEditTitle;

  const DashboardWidgetCard({
    super.key,
    required this.widget,
    required this.onConfigure,
    required this.onDelete,
    this.onEditTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (title, icon) = _getTitleAndIcon(AppLocalizations.of(context)!);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Barre de titre avec boutons d'action
          _WidgetHeader(
            title: title,
            icon: icon,
            onConfigure: onConfigure,
            onDelete: onDelete,
            onEditTitle: onEditTitle,
          ),

          // Contenu du widget
          Expanded(
            child: _buildWidgetContent(context, ref),
          ),
        ],
      ),
    );
  }

  /// Récupère le titre et l'icône selon le type et la config
  (String, IconData) _getTitleAndIcon(AppLocalizations l10n) {
    switch (widget.widgetType) {
      case DashboardWidgetType.singleTrendChart:
        final config = SingleChartWidgetConfig.fromJsonString(widget.configJson);
        return (
          config?.displayTitle ?? l10n.dashboardChartDefault,
          Icons.show_chart,
        );

      case DashboardWidgetType.multiCurveChart:
        final config = MultiCurveWidgetConfig.fromJsonString(widget.configJson);
        return (
          config == null
              ? l10n.multiCurveChart
              : config.title ?? l10n.dashboardComparisonTitle(config.trendLogInstances.length),
          Icons.multiline_chart,
        );

      case DashboardWidgetType.statsCard:
        final config = StatsWidgetConfig.fromJsonString(widget.configJson);
        return (
          config?.displayTitle ?? l10n.statsCard,
          Icons.analytics,
        );
    }
  }

  Widget _buildWidgetContent(BuildContext context, WidgetRef ref) {
    switch (widget.widgetType) {
      case DashboardWidgetType.singleTrendChart:
        return _buildSingleChart(context, ref);
      case DashboardWidgetType.multiCurveChart:
        return _buildMultiCurve(context, ref);
      case DashboardWidgetType.statsCard:
        return _buildStatsCard(context, ref);
    }
  }

  Widget _buildSingleChart(BuildContext context, WidgetRef ref) {
    final config = SingleChartWidgetConfig.fromJsonString(widget.configJson);

    if (config == null) {
      return _buildUnconfigured(context, AppLocalizations.of(context)!.dashboardChartDefault, Icons.show_chart);
    }

    final state = ref.watch(trendLogViewerProvider(config.trendLogInstance));

    if (state.isLoading && state.data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.data == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref
                  .read(trendLogViewerProvider(config.trendLogInstance).notifier)
                  .loadData(),
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      );
    }

    if (state.data == null) {
      // Pas encore chargé : un seul chargement, déclenché hors de build
      return _LoadOnce(
        onLoad: () => ref
            .read(trendLogViewerProvider(config.trendLogInstance).notifier)
            .loadData(period: TrendPeriod.day),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.data!.records.isEmpty) {
      // Vide = état final (pas de rechargement automatique)
      if (state.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              state.error != null ? Icons.error_outline : Icons.show_chart,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref
                  .read(trendLogViewerProvider(config.trendLogInstance).notifier)
                  .loadData(period: TrendPeriod.day),
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      );
    }

    // Utiliser EmbeddedTrendChart pour le mode dashboard (plus compact)
    return EmbeddedTrendChart(
      trendLogInstance: config.trendLogInstance,
      units: config.units,
      colorTheme: ChartColorTheme.fromName(config.colorTheme),
    );
  }

  Widget _buildMultiCurve(BuildContext context, WidgetRef ref) {
    final config = MultiCurveWidgetConfig.fromJsonString(widget.configJson);

    if (config == null || config.trendLogInstances.isEmpty) {
      return _buildUnconfigured(context, AppLocalizations.of(context)!.multiCurveChart, Icons.multiline_chart);
    }

    final chartId = 'dashboard_widget_${widget.id}';

    return MultiCurveChart(
      chartId: chartId,
      initialTrendLogInstances: config.trendLogInstances,
      curveNames: config.curveNamesAsInt,
      curveUnits: config.curveUnitsAsInt,
      showHeader: false, // Le titre est dans le DashboardWidgetCard
      showPeriodSelector: false,
      showStatistics: false,
    );
  }

  Widget _buildStatsCard(BuildContext context, WidgetRef ref) {
    final config = StatsWidgetConfig.fromJsonString(widget.configJson);

    if (config == null) {
      return _buildUnconfigured(context, AppLocalizations.of(context)!.statsCard, Icons.analytics);
    }

    final state = ref.watch(trendLogViewerProvider(config.trendLogInstance));

    if (state.data == null && !state.isLoading && state.error == null) {
      return _LoadOnce(
        onLoad: () => ref
            .read(trendLogViewerProvider(config.trendLogInstance).notifier)
            .loadData(),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Stats
          if (state.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (state.error != null)
            Center(
              child: Icon(Icons.error_outline, color: Colors.red.shade300),
            )
          else if (state.data != null)
            _buildStatsContent(context, state.data!, config)
          else
            Center(child: Text(AppLocalizations.of(context)!.noData)),
        ],
      ),
    );
  }

  Widget _buildStatsContent(
    BuildContext context,
    dynamic data,
    StatsWidgetConfig config,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        if (config.showMin && data.minValue != null)
          _StatChip(
            label: l10n.statisticsMin,
            value: _formatValue(data.minValue!),
            unit: config.units,
            icon: Icons.arrow_downward,
            color: Colors.blue,
          ),
        if (config.showMax && data.maxValue != null)
          _StatChip(
            label: l10n.statisticsMax,
            value: _formatValue(data.maxValue!),
            unit: config.units,
            icon: Icons.arrow_upward,
            color: Colors.red,
          ),
        if (config.showAvg && data.avgValue != null)
          _StatChip(
            label: l10n.statisticsAvg,
            value: _formatValue(data.avgValue!),
            unit: config.units,
            icon: Icons.horizontal_rule,
            color: colorScheme.primary,
          ),
      ],
    );
  }

  Widget _buildUnconfigured(BuildContext context, String type, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 40,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            type,
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.dashboardNotConfigured,
            style: TextStyle(
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}

// =============================================================================
// Widgets auxiliaires
// =============================================================================

/// Barre de titre du widget avec actions
class _WidgetHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onConfigure;
  final VoidCallback onDelete;
  final VoidCallback? onEditTitle;

  const _WidgetHeader({
    required this.title,
    required this.icon,
    required this.onConfigure,
    required this.onDelete,
    this.onEditTitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary.withAlpha(20),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.primary.withAlpha(30),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Icône
          Icon(
            icon,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 6),

          // Titre (cliquable pour éditer)
          Expanded(
            child: GestureDetector(
              onTap: onEditTitle,
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Boutons d'action
          _HeaderActionButton(
            icon: Icons.edit,
            tooltip: AppLocalizations.of(context)!.dashboardConfigure,
            onTap: onConfigure,
          ),
          _HeaderActionButton(
            icon: Icons.delete_outline,
            tooltip: AppLocalizations.of(context)!.delete,
            color: Colors.red,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

/// Petit bouton d'action dans le header
class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  const _HeaderActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? Theme.of(context).colorScheme.onSurfaceVariant;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: buttonColor),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              Text(
                '$value${unit != null ? ' $unit' : ''}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Triggers [onLoad] once after the first frame (never from build repeatedly).
class _LoadOnce extends StatefulWidget {
  final VoidCallback onLoad;
  final Widget child;

  const _LoadOnce({required this.onLoad, required this.child});

  @override
  State<_LoadOnce> createState() => _LoadOnceState();
}

class _LoadOnceState extends State<_LoadOnce> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onLoad();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
