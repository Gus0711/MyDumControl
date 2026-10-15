import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../application/providers/dashboard_provider.dart';
import '../../../../application/providers/trend_log_provider.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/database/tables/dashboard_tables.dart';
import '../../../widgets/trend_log_viewer.dart';
import '../../../widgets/multi_curve_chart.dart';
import '../../../widgets/ui/ui.dart';
import '../../../../l10n/app_localizations.dart';

/// Carte affichant un widget de dashboard (graphique, stats, etc.)
class DashboardWidgetCard extends ConsumerStatefulWidget {
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
  ConsumerState<DashboardWidgetCard> createState() => _DashboardWidgetCardState();
}

class _DashboardWidgetCardState extends ConsumerState<DashboardWidgetCard> {
  bool _hover = false;

  DashboardWidget get _data => widget.widget;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final (title, icon, tone) = _getTitleIconTone(AppLocalizations.of(context)!, dc);
    final radius = BorderRadius.circular(DcRadius.lg);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: dc.surface,
          borderRadius: radius,
          border: Border.all(color: _hover ? dc.borderStrong : dc.border),
          boxShadow: dc.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Column(
            children: [
              // Barre de titre avec boutons d'action
              _WidgetHeader(
                title: title,
                icon: icon,
                tone: tone,
                showActions: _hover || !_isDesktop,
                onConfigure: widget.onConfigure,
                onDelete: widget.onDelete,
                onEditTitle: widget.onEditTitle,
              ),

              // Contenu du widget
              Expanded(
                child: _buildWidgetContent(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sur bureau, les actions n'apparaissent qu'au survol.
  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  /// Récupère le titre, l'icône et le ton selon le type et la config
  (String, IconData, DcTone) _getTitleIconTone(AppLocalizations l10n, DcTokens dc) {
    switch (_data.widgetType) {
      case DashboardWidgetType.singleTrendChart:
        final config = SingleChartWidgetConfig.fromJsonString(_data.configJson);
        return (
          config?.displayTitle ?? l10n.dashboardChartDefault,
          Icons.show_chart_rounded,
          dc.accentTone,
        );

      case DashboardWidgetType.multiCurveChart:
        final config = MultiCurveWidgetConfig.fromJsonString(_data.configJson);
        return (
          config == null
              ? l10n.multiCurveChart
              : config.title ?? l10n.dashboardComparisonTitle(config.trendLogInstances.length),
          Icons.stacked_line_chart_rounded,
          dc.violet,
        );

      case DashboardWidgetType.statsCard:
        final config = StatsWidgetConfig.fromJsonString(_data.configJson);
        return (
          config?.displayTitle ?? l10n.statsCard,
          Icons.analytics_outlined,
          dc.success,
        );
    }
  }

  Widget _buildWidgetContent(BuildContext context) {
    switch (_data.widgetType) {
      case DashboardWidgetType.singleTrendChart:
        return _buildSingleChart(context);
      case DashboardWidgetType.multiCurveChart:
        return _buildMultiCurve(context);
      case DashboardWidgetType.statsCard:
        return _buildStatsCard(context);
    }
  }

  Widget _loader() => const Center(
        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
      );

  /// Message compact (erreur ou vide) avec bouton Réessayer.
  Widget _retryState(BuildContext context, {required bool error, required VoidCallback onRetry}) {
    final dc = context.dc;
    final tone = error ? dc.danger : dc.neutral;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DcIconBox(
            icon: error ? Icons.error_outline_rounded : Icons.show_chart_rounded,
            tone: tone,
            size: 36,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(AppLocalizations.of(context)!.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleChart(BuildContext context) {
    final config = SingleChartWidgetConfig.fromJsonString(_data.configJson);

    if (config == null) {
      return _buildUnconfigured(context, AppLocalizations.of(context)!.dashboardChartDefault, Icons.show_chart_rounded);
    }

    final state = ref.watch(trendLogViewerProvider(config.trendLogInstance));

    if (state.isLoading && state.data == null) {
      return _loader();
    }

    if (state.error != null && state.data == null) {
      return _retryState(
        context,
        error: true,
        onRetry: () => ref.read(trendLogViewerProvider(config.trendLogInstance).notifier).loadData(),
      );
    }

    if (state.data == null) {
      // Pas encore chargé : un seul chargement, déclenché hors de build
      return _LoadOnce(
        onLoad: () => ref
            .read(trendLogViewerProvider(config.trendLogInstance).notifier)
            .loadData(period: TrendPeriod.day),
        child: _loader(),
      );
    }

    if (state.data!.records.isEmpty) {
      // Vide = état final (pas de rechargement automatique)
      if (state.isLoading) {
        return _loader();
      }
      return _retryState(
        context,
        error: state.error != null,
        onRetry: () => ref
            .read(trendLogViewerProvider(config.trendLogInstance).notifier)
            .loadData(period: TrendPeriod.day),
      );
    }

    // Utiliser EmbeddedTrendChart pour le mode dashboard (plus compact)
    return EmbeddedTrendChart(
      trendLogInstance: config.trendLogInstance,
      units: config.units,
      colorTheme: ChartColorTheme.fromName(config.colorTheme),
    );
  }

  Widget _buildMultiCurve(BuildContext context) {
    final config = MultiCurveWidgetConfig.fromJsonString(_data.configJson);

    if (config == null || config.trendLogInstances.isEmpty) {
      return _buildUnconfigured(context, AppLocalizations.of(context)!.multiCurveChart, Icons.stacked_line_chart_rounded);
    }

    final chartId = 'dashboard_widget_${_data.id}';

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

  Widget _buildStatsCard(BuildContext context) {
    final config = StatsWidgetConfig.fromJsonString(_data.configJson);

    if (config == null) {
      return _buildUnconfigured(context, AppLocalizations.of(context)!.statsCard, Icons.analytics_outlined);
    }

    final state = ref.watch(trendLogViewerProvider(config.trendLogInstance));

    if (state.data == null && !state.isLoading && state.error == null) {
      return _LoadOnce(
        onLoad: () => ref
            .read(trendLogViewerProvider(config.trendLogInstance).notifier)
            .loadData(),
        child: _loader(),
      );
    }

    if (state.isLoading) return _loader();
    if (state.error != null) {
      return _retryState(
        context,
        error: true,
        onRetry: () => ref.read(trendLogViewerProvider(config.trendLogInstance).notifier).loadData(),
      );
    }
    if (state.data == null) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noData,
          style: context.text.bodyMedium?.copyWith(color: context.dc.textMuted),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(14),
      child: _buildStatsContent(context, state.data!, config),
    );
  }

  Widget _buildStatsContent(
    BuildContext context,
    dynamic data,
    StatsWidgetConfig config,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final dc = context.dc;

    final stats = <Widget>[
      if (config.showMin && data.minValue != null)
        _StatBlock(
          label: l10n.statisticsMin,
          value: formatNumber(data.minValue!),
          unit: config.units,
          icon: Icons.south_rounded,
          tone: dc.accentTone,
        ),
      if (config.showAvg && data.avgValue != null)
        _StatBlock(
          label: l10n.statisticsAvg,
          value: formatNumber(data.avgValue!),
          unit: config.units,
          icon: Icons.horizontal_rule_rounded,
          tone: dc.violet,
        ),
      if (config.showMax && data.maxValue != null)
        _StatBlock(
          label: l10n.statisticsMax,
          value: formatNumber(data.maxValue!),
          unit: config.units,
          icon: Icons.north_rounded,
          tone: dc.danger,
        ),
    ];

    if (stats.isEmpty) {
      return Center(
        child: Text(l10n.noData, style: context.text.bodyMedium?.copyWith(color: dc.textMuted)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Côte à côte si la place le permet, sinon empilés
        final horizontal = constraints.maxWidth >= 120.0 * stats.length;
        final children = [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) SizedBox(width: horizontal ? 10 : 0, height: horizontal ? 0 : 8),
            Expanded(child: stats[i]),
          ],
        ];
        return horizontal
            ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
      },
    );
  }

  Widget _buildUnconfigured(BuildContext context, String type, IconData icon) {
    final dc = context.dc;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DcIconBox(icon: icon, tone: dc.neutral, size: 44),
            const SizedBox(height: 10),
            Text(type, style: context.text.titleSmall?.copyWith(color: dc.textSecondary)),
            const SizedBox(height: 2),
            Text(
              AppLocalizations.of(context)!.dashboardNotConfigured,
              style: context.text.bodySmall?.copyWith(color: dc.textMuted),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: widget.onConfigure,
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: Text(AppLocalizations.of(context)!.dashboardConfigure),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Widgets auxiliaires
// =============================================================================

/// Barre de titre du widget avec actions
class _WidgetHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final DcTone tone;
  final bool showActions;
  final VoidCallback onConfigure;
  final VoidCallback onDelete;
  final VoidCallback? onEditTitle;

  const _WidgetHeader({
    required this.title,
    required this.icon,
    required this.tone,
    required this.showActions,
    required this.onConfigure,
    required this.onDelete,
    this.onEditTitle,
  });

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 44,
      padding: const EdgeInsets.only(left: 12, right: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: dc.border)),
      ),
      child: Row(
        children: [
          DcIconBox(icon: icon, tone: tone, size: 26),
          const SizedBox(width: 10),

          // Titre (cliquable pour éditer)
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Tooltip(
                message: onEditTitle != null ? l10n.dashboardEditTitle : title,
                child: InkWell(
                  onTap: onEditTitle,
                  borderRadius: BorderRadius.circular(DcRadius.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall?.copyWith(color: dc.textPrimary),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Boutons d'action (au survol sur bureau)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 140),
            opacity: showActions ? 1 : 0,
            child: IgnorePointer(
              ignoring: !showActions,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HeaderActionButton(
                    icon: Icons.tune_rounded,
                    tooltip: l10n.dashboardConfigure,
                    onTap: onConfigure,
                  ),
                  _HeaderActionButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: l10n.delete,
                    color: dc.danger.fg,
                    onTap: onDelete,
                  ),
                ],
              ),
            ),
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
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, size: 17, color: color ?? context.dc.textSecondary),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}

/// Bloc statistique (min / moy / max) : libellé, grande valeur, unité.
class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final DcTone tone;

  const _StatBlock({
    required this.label,
    required this.value,
    this.unit,
    required this.icon,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: dc.surfaceSunken,
        borderRadius: BorderRadius.circular(DcRadius.md),
        border: Border.all(color: dc.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: tone.fg),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.overline.copyWith(color: dc.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: AppTextStyles.valueDisplay.copyWith(fontSize: 26, color: tone.fg),
                  ),
                  if (unit != null && unit!.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: AppTextStyles.unitText.copyWith(color: dc.textSecondary),
                    ),
                ],
              ),
              maxLines: 1,
            ),
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
