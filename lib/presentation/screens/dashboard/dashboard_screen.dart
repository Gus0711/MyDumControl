import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/dashboard_provider.dart';
import '../../../application/providers/multi_curve_provider.dart';
import '../../../application/providers/trend_log_provider.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/tables/dashboard_tables.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/curve_selection_dialog.dart';
import 'widgets/dashboard_widget_card.dart';
import 'widgets/add_widget_dialog.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/ui/ui.dart';
import 'dashboard_list_screen.dart' show DashboardGridPreview;

/// Écran affichant un dashboard avec sa grille de widgets
class DashboardScreen extends ConsumerStatefulWidget {
  final int dashboardId;

  const DashboardScreen({super.key, required this.dashboardId});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static const double _gridPadding = 16;
  static const double _gridGap = 14;

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(watchDashboardByIdProvider(widget.dashboardId));
    final widgetsAsync = ref.watch(dashboardWidgetsProvider(widget.dashboardId));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: dashboardAsync.when(
        data: (dashboard) => GradientAppBar(
          title: dashboard?.name ?? l10n.dashboard,
          subtitle: dashboard != null ? l10n.dashboardGridSize(dashboard.columns, dashboard.rows) : null,
          actions: [
            // Rafraîchir
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: l10n.refresh,
              onPressed: () {
                ref.invalidate(dashboardWidgetsProvider(widget.dashboardId));
              },
            ),
            // Menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) async {
                switch (value) {
                  case 'settings':
                    await _showSettingsDialog(context, dashboardAsync.value);
                    break;
                  case 'delete':
                    await _confirmDelete(context);
                    break;
                }
              },
              itemBuilder: (context) => [
                dcMenuItem(context, 'settings', Icons.tune_rounded, l10n.settings),
                const PopupMenuDivider(),
                dcMenuItem(context, 'delete', Icons.delete_outline_rounded, l10n.delete, danger: true),
              ],
            ),
          ],
        ),
        loading: () => GradientAppBar(title: l10n.loading),
        error: (_, _) => GradientAppBar(title: l10n.error),
      ),
      body: dashboardAsync.when(
        data: (dashboard) {
          if (dashboard == null) {
            return DcEmptyState(
              icon: Icons.search_off_rounded,
              title: l10n.dashboardNotFound,
              action: OutlinedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(l10n.back),
              ),
            );
          }

          return widgetsAsync.when(
            data: (widgets) => _buildGrid(context, dashboard, widgets),
            loading: () => const DcLoading(),
            error: (error, _) => DcEmptyState.error(context, title: l10n.error, message: '$error'),
          );
        },
        loading: () => const DcLoading(),
        error: (error, _) => DcEmptyState.error(context, title: l10n.error, message: '$error'),
      ),
    );
  }

  /// Refreshes the data of every chart/stats widget (deduplicated per trend log).
  Future<void> _refreshAll(List<DashboardWidget> widgets) async {
    final futures = <Future<void>>[];
    final seen = <int>{};
    for (final w in widgets) {
      switch (w.widgetType) {
        case DashboardWidgetType.singleTrendChart:
          final c = SingleChartWidgetConfig.fromJsonString(w.configJson);
          if (c != null && seen.add(c.trendLogInstance)) {
            futures.add(ref.read(trendLogViewerProvider(c.trendLogInstance).notifier).refresh());
          }
          break;
        case DashboardWidgetType.statsCard:
          final c = StatsWidgetConfig.fromJsonString(w.configJson);
          if (c != null && seen.add(c.trendLogInstance)) {
            futures.add(ref.read(trendLogViewerProvider(c.trendLogInstance).notifier).refresh());
          }
          break;
        case DashboardWidgetType.multiCurveChart:
          futures.add(ref.read(multiCurveViewerProvider('dashboard_widget_${w.id}').notifier).refresh());
          break;
      }
    }
    await Future.wait(futures.map((f) => f.catchError((_) {})));
  }

  /// Disposes a dialog controller once the closing animation is over.
  void _disposeLater(TextEditingController controller) {
    Future.delayed(const Duration(milliseconds: 400), controller.dispose);
  }

  Widget _buildGrid(BuildContext context, Dashboard dashboard, List<DashboardWidget> widgets) {
    final totalSlots = dashboard.columns * dashboard.rows;

    // Créer un map position -> widget pour accès rapide
    final widgetMap = <int, DashboardWidget>{};
    for (final w in widgets) {
      widgetMap[w.position] = w;
    }

    return RefreshIndicator(
      onRefresh: () => _refreshAll(widgets),
      child: Padding(
        padding: const EdgeInsets.all(_gridPadding),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: dashboard.columns,
            mainAxisSpacing: _gridGap,
            crossAxisSpacing: _gridGap,
            childAspectRatio: _calculateAspectRatio(context, dashboard),
          ),
          itemCount: totalSlots,
          itemBuilder: (context, index) {
            final widgetData = widgetMap[index];

            if (widgetData != null) {
              return _buildWidgetCard(context, dashboard, widgetData, index);
            } else {
              // Toujours afficher le bouton "+" pour les slots vides
              return _buildEmptySlot(context, dashboard, index);
            }
          },
        ),
      ),
    );
  }

  double _calculateAspectRatio(BuildContext context, Dashboard dashboard) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight = screenHeight - 200; // AppBar + padding

    final cellWidth = (screenWidth - 2 * _gridPadding - (dashboard.columns - 1) * _gridGap) / dashboard.columns;
    final cellHeight = (availableHeight - (dashboard.rows - 1) * _gridGap) / dashboard.rows;

    // Limiter pour éviter des widgets trop grands ou trop petits
    final ratio = (cellWidth / cellHeight).clamp(0.8, 2.0);
    return ratio;
  }

  Widget _buildWidgetCard(
    BuildContext context,
    Dashboard dashboard,
    DashboardWidget widgetData,
    int position,
  ) {
    return DashboardWidgetCard(
      key: ValueKey(widgetData.id),
      widget: widgetData,
      onConfigure: () => _configureWidget(context, dashboard, widgetData),
      onDelete: () => _deleteWidget(widgetData),
      onEditTitle: () => _editWidgetTitle(context, widgetData),
    );
  }

  Widget _buildEmptySlot(BuildContext context, Dashboard dashboard, int position) {
    return _EmptySlot(
      label: AppLocalizations.of(context)!.add,
      onTap: () => _addWidget(context, dashboard, position),
    );
  }

  Future<void> _addWidget(BuildContext context, Dashboard dashboard, int position) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddWidgetDialog(),
    );

    if (result != null && mounted) {
      final notifier = ref.read(dashboardNotifierProvider.notifier);
      final widgetType = result['type'] as DashboardWidgetType;

      // Ajouter le widget
      final widgetId = await notifier.addWidget(
        dashboardId: dashboard.id,
        position: position,
        widgetType: widgetType,
        config: result['config'] as Map<String, dynamic>?,
      );

      // Ouvrir directement la configuration si le widget a été créé
      if (widgetId != null && mounted) {
        // Attendre un peu pour que le provider se mette à jour
        await Future.delayed(const Duration(milliseconds: 100));

        // Créer un widget temporaire pour la configuration
        final tempWidget = DashboardWidget(
          id: widgetId,
          dashboardId: dashboard.id,
          position: position,
          widgetType: widgetType,
          configJson: null,
          createdAt: DateTime.now(),
        );

        if (context.mounted) {
          await _configureWidget(context, dashboard, tempWidget);
        }
      }
    }
  }

  Future<void> _configureWidget(
    BuildContext context,
    Dashboard dashboard,
    DashboardWidget widgetData,
  ) async {
    // Selon le type de widget, afficher le dialogue de configuration approprié
    switch (widgetData.widgetType) {
      case DashboardWidgetType.singleTrendChart:
        await _configureSingleChart(context, widgetData);
        break;
      case DashboardWidgetType.multiCurveChart:
        await _configureMultiCurve(context, widgetData);
        break;
      case DashboardWidgetType.statsCard:
        await _configureStatsCard(context, widgetData);
        break;
    }
  }

  Future<void> _configureSingleChart(BuildContext context, DashboardWidget widgetData) async {
    // Récupérer la liste des trend logs disponibles
    final trendLogs = await ref.read(availableTrendLogsProvider.future);

    if (!context.mounted) return;

    final currentConfig = widgetData.configJson != null
        ? SingleChartWidgetConfig.fromJsonString(widgetData.configJson)
        : null;

    final result = await showDialog<int>(
      context: context,
      builder: (context) => _TrendLogSelectionDialog(
        trendLogs: trendLogs,
        selectedInstance: currentConfig?.trendLogInstance,
      ),
    );

    if (result != null && mounted) {
      final notifier = ref.read(dashboardNotifierProvider.notifier);
      await notifier.updateWidget(
        widgetId: widgetData.id,
        config: SingleChartWidgetConfig(trendLogInstance: result).toJson(),
      );
    }
  }

  Future<void> _configureMultiCurve(BuildContext context, DashboardWidget widgetData) async {
    final currentConfig = widgetData.configJson != null
        ? MultiCurveWidgetConfig.fromJsonString(widgetData.configJson)
        : null;

    final result = await showCurveSelectionDialog(
      context,
      initialSelection: currentConfig?.trendLogInstances ?? [],
    );

    if (result != null && mounted) {
      final notifier = ref.read(dashboardNotifierProvider.notifier);
      await notifier.updateWidget(
        widgetId: widgetData.id,
        config: MultiCurveWidgetConfig(
          trendLogInstances: result.instances,
          curveNames: result.names.map((k, v) => MapEntry(k.toString(), v)),
        ).toJson(),
      );
    }
  }

  Future<void> _configureStatsCard(BuildContext context, DashboardWidget widgetData) async {
    final trendLogs = await ref.read(availableTrendLogsProvider.future);

    if (!context.mounted) return;

    final currentConfig = widgetData.configJson != null
        ? StatsWidgetConfig.fromJsonString(widgetData.configJson)
        : null;

    final result = await showDialog<int>(
      context: context,
      builder: (context) => _TrendLogSelectionDialog(
        trendLogs: trendLogs,
        selectedInstance: currentConfig?.trendLogInstance,
      ),
    );

    if (result != null && mounted) {
      final notifier = ref.read(dashboardNotifierProvider.notifier);
      await notifier.updateWidget(
        widgetId: widgetData.id,
        config: StatsWidgetConfig(trendLogInstance: result).toJson(),
      );
    }
  }

  Future<void> _deleteWidget(DashboardWidget widgetData) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.dashboardDeleteWidgetConfirm,
      message: l10n.dashboardDeleteWidgetMessage,
      confirmLabel: l10n.delete,
      destructive: true,
    );

    if (confirmed == true && mounted) {
      await ref.read(dashboardNotifierProvider.notifier).deleteWidget(widgetData.id);
    }
  }

  /// Éditer le titre d'un widget
  Future<void> _editWidgetTitle(BuildContext context, DashboardWidget widgetData) async {
    // Récupérer le titre actuel selon le type de widget
    String currentTitle = '';

    switch (widgetData.widgetType) {
      case DashboardWidgetType.singleTrendChart:
        final config = SingleChartWidgetConfig.fromJsonString(widgetData.configJson);
        currentTitle = config?.title ?? '';
        break;
      case DashboardWidgetType.multiCurveChart:
        final config = MultiCurveWidgetConfig.fromJsonString(widgetData.configJson);
        currentTitle = config?.title ?? '';
        break;
      case DashboardWidgetType.statsCard:
        final config = StatsWidgetConfig.fromJsonString(widgetData.configJson);
        currentTitle = config?.title ?? '';
        break;
    }

    final controller = TextEditingController(text: currentTitle);
    final l10n = AppLocalizations.of(context)!;

    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.dashboardEditTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.dashboardTitleLabel,
            hintText: l10n.dashboardTitleHint,
            prefixIcon: const Icon(Icons.title_rounded, size: 20),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    _disposeLater(controller);
    if (newTitle == null || !mounted) return;

    // Mettre à jour la config avec le nouveau titre
    Map<String, dynamic>? newConfig;

    switch (widgetData.widgetType) {
      case DashboardWidgetType.singleTrendChart:
        final config = SingleChartWidgetConfig.fromJsonString(widgetData.configJson);
        if (config != null) {
          newConfig = SingleChartWidgetConfig(
            trendLogInstance: config.trendLogInstance,
            title: newTitle.isEmpty ? null : newTitle,
            pointName: config.pointName,
            units: config.units,
            colorTheme: config.colorTheme,
          ).toJson();
        }
        break;
      case DashboardWidgetType.multiCurveChart:
        final config = MultiCurveWidgetConfig.fromJsonString(widgetData.configJson);
        if (config != null) {
          newConfig = MultiCurveWidgetConfig(
            trendLogInstances: config.trendLogInstances,
            title: newTitle.isEmpty ? null : newTitle,
            curveNames: config.curveNames,
            curveUnits: config.curveUnits,
          ).toJson();
        }
        break;
      case DashboardWidgetType.statsCard:
        final config = StatsWidgetConfig.fromJsonString(widgetData.configJson);
        if (config != null) {
          newConfig = StatsWidgetConfig(
            trendLogInstance: config.trendLogInstance,
            title: newTitle.isEmpty ? null : newTitle,
            pointName: config.pointName,
            units: config.units,
            showCurrent: config.showCurrent,
            showMin: config.showMin,
            showMax: config.showMax,
            showAvg: config.showAvg,
          ).toJson();
        }
        break;
    }

    if (newConfig != null) {
      await ref.read(dashboardNotifierProvider.notifier).updateWidget(
        widgetId: widgetData.id,
        config: newConfig,
      );
    }
  }

  Future<void> _showSettingsDialog(BuildContext context, Dashboard? dashboard) async {
    if (dashboard == null) return;

    final nameController = TextEditingController(text: dashboard.name);
    int columns = dashboard.columns;
    int rows = dashboard.rows;
    final l10n = AppLocalizations.of(context)!;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.dashboardSettingsTitle),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.name,
                    prefixIcon: const Icon(Icons.insights_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _CounterRow(
                            label: l10n.dashboardColumns,
                            value: columns,
                            onDecrement: columns > 1 ? () => setDialogState(() => columns--) : null,
                            onIncrement: columns < 4 ? () => setDialogState(() => columns++) : null,
                          ),
                          const SizedBox(height: 10),
                          _CounterRow(
                            label: l10n.dashboardRows,
                            value: rows,
                            onDecrement: rows > 1 ? () => setDialogState(() => rows--) : null,
                            onIncrement: rows < 4 ? () => setDialogState(() => rows++) : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    DashboardGridPreview(columns: columns, rows: rows, size: 72),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop({
                'name': nameController.text.trim(),
                'columns': columns,
                'rows': rows,
              }),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );

    _disposeLater(nameController);
    if (result != null && mounted) {
      await ref.read(dashboardNotifierProvider.notifier).updateDashboard(
            id: dashboard.id,
            name: result['name'] as String,
            columns: result['columns'] as int,
            rows: result['rows'] as int,
          );
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteDashboardConfirm,
      message: l10n.dashboardDeletePermanentMessage,
      confirmLabel: l10n.delete,
      destructive: true,
    );

    if (confirmed == true && mounted) {
      await ref.read(dashboardNotifierProvider.notifier).deleteDashboard(widget.dashboardId);
      if (context.mounted) {
        context.pop();
      }
    }
  }
}

// =============================================================================
// Dialogue de sélection de trend log
// =============================================================================

class _TrendLogSelectionDialog extends StatefulWidget {
  final List<AvailableTrendLog> trendLogs;
  final int? selectedInstance;

  const _TrendLogSelectionDialog({
    required this.trendLogs,
    this.selectedInstance,
  });

  @override
  State<_TrendLogSelectionDialog> createState() => _TrendLogSelectionDialogState();
}

class _TrendLogSelectionDialogState extends State<_TrendLogSelectionDialog> {
  int? _selected;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedInstance;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.trendLogs.where((tl) {
      if (_search.isEmpty) return true;
      final searchLower = _search.toLowerCase();
      return tl.pointKey.toLowerCase().contains(searchLower) ||
          (tl.pointName?.toLowerCase().contains(searchLower) ?? false);
    }).toList();
    final l10n = AppLocalizations.of(context)!;

    final dc = context.dc;

    return AlertDialog(
      icon: const Icon(Icons.show_chart_rounded),
      title: Text(l10n.selectTrendLog),
      content: SizedBox(
        width: 440,
        height: 420,
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: l10n.dashboardSearchHint,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: dc.surfaceSunken,
                  borderRadius: BorderRadius.circular(DcRadius.md),
                  border: Border.all(color: dc.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: RadioGroup<int>(
                  groupValue: _selected,
                  onChanged: (value) => setState(() => _selected = value),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(4),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final tl = filtered[index];
                      final isSelected = _selected == tl.instance;

                      return ListTile(
                        dense: true,
                        title: Text(
                          tl.pointName ?? tl.pointKey,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'TL ${tl.instance} · ${tl.pointKey}',
                          style: AppTextStyles.monospacedValue.copyWith(fontSize: 11, color: dc.textMuted),
                        ),
                        selected: isSelected,
                        leading: Radio<int>(value: tl.instance),
                        onTap: () => setState(() => _selected = tl.instance),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _selected != null ? () => Navigator.of(context).pop(_selected) : null,
          child: Text(l10n.validate),
        ),
      ],
    );
  }
}

// =============================================================================
// Emplacement vide et compteur
// =============================================================================

/// Emplacement libre de la grille : contour pointillé, « + Ajouter ».
class _EmptySlot extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _EmptySlot({required this.label, required this.onTap});

  @override
  State<_EmptySlot> createState() => _EmptySlotState();
}

class _EmptySlotState extends State<_EmptySlot> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final color = _hover ? dc.accentTone.fg : dc.textMuted;
    final radius = BorderRadius.circular(DcRadius.lg);

    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(
        color: _hover ? dc.accentTone.border : dc.borderStrong,
        radius: DcRadius.lg,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: _hover ? dc.accentTone.bg.withValues(alpha: 0.5) : dc.surfaceSunken.withValues(alpha: 0.5),
          borderRadius: radius,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onHover: (h) => setState(() => _hover = h),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _hover ? dc.accentTone.bg : dc.surface,
                      border: Border.all(color: _hover ? dc.accentTone.border : dc.border),
                    ),
                    child: Icon(Icons.add_rounded, size: 22, color: color),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.label,
                    style: context.text.labelLarge?.copyWith(color: color),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bordure en pointillés arrondie.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    ).deflate(0.75);
    final path = Path()..addRRect(rrect);
    const dash = 6.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// Ligne « libellé  [-] n [+] » des réglages de grille.
class _CounterRow extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  const _CounterRow({
    required this.label,
    required this.value,
    this.onDecrement,
    this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Row(
      children: [
        Expanded(child: Text(label)),
        Container(
          decoration: BoxDecoration(
            color: dc.surfaceSunken,
            borderRadius: BorderRadius.circular(DcRadius.md),
            border: Border.all(color: dc.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_rounded, size: 18),
                onPressed: onDecrement,
                visualDensity: VisualDensity.compact,
              ),
              SizedBox(
                width: 28,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.monospacedValue.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: dc.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded, size: 18),
                onPressed: onIncrement,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
