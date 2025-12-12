import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/dashboard_provider.dart';
import '../../../application/providers/multi_curve_provider.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/tables/dashboard_tables.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/curve_selection_dialog.dart';
import 'widgets/dashboard_widget_card.dart';
import 'widgets/add_widget_dialog.dart';

/// Écran affichant un dashboard avec sa grille de widgets
class DashboardScreen extends ConsumerStatefulWidget {
  final int dashboardId;

  const DashboardScreen({super.key, required this.dashboardId});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(watchDashboardByIdProvider(widget.dashboardId));
    final widgetsAsync = ref.watch(dashboardWidgetsProvider(widget.dashboardId));

    return Scaffold(
      appBar: dashboardAsync.when(
        data: (dashboard) => GradientAppBar(
          title: dashboard?.name ?? 'Dashboard',
          actions: [
            // Rafraîchir
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Rafraîchir',
              onPressed: () {
                ref.invalidate(dashboardWidgetsProvider(widget.dashboardId));
              },
            ),
            // Menu
            PopupMenuButton<String>(
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
                const PopupMenuItem(
                  value: 'settings',
                  child: ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Paramètres'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
        loading: () => const GradientAppBar(title: 'Chargement...'),
        error: (_, __) => const GradientAppBar(title: 'Erreur'),
      ),
      body: dashboardAsync.when(
        data: (dashboard) {
          if (dashboard == null) {
            return const Center(child: Text('Dashboard introuvable'));
          }

          return widgetsAsync.when(
            data: (widgets) => _buildGrid(context, dashboard, widgets),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Erreur: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur: $error')),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, Dashboard dashboard, List<DashboardWidget> widgets) {
    final totalSlots = dashboard.columns * dashboard.rows;

    // Créer un map position -> widget pour accès rapide
    final widgetMap = <int, DashboardWidget>{};
    for (final w in widgets) {
      widgetMap[w.position] = w;
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardWidgetsProvider(widget.dashboardId));
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: dashboard.columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
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

    final cellWidth = (screenWidth - 32 - (dashboard.columns - 1) * 12) / dashboard.columns;
    final cellHeight = (availableHeight - (dashboard.rows - 1) * 12) / dashboard.rows;

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
    return Card(
      elevation: 0,
      color: Colors.grey.withAlpha(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.withAlpha(50),
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: InkWell(
        onTap: () => _addWidget(context, dashboard, position),
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 40,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                'Ajouter',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
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

        if (mounted) {
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

    if (!mounted) return;

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

    if (!mounted) return;

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le widget ?'),
        content: const Text('Ce widget sera supprimé du tableau de bord.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
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

    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le titre'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Titre',
            hintText: 'Laisser vide pour le titre par défaut',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

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

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Paramètres du dashboard'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Colonnes: '),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: columns > 1
                        ? () => setDialogState(() => columns--)
                        : null,
                  ),
                  Text('$columns'),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: columns < 4
                        ? () => setDialogState(() => columns++)
                        : null,
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Lignes: '),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: rows > 1 ? () => setDialogState(() => rows--) : null,
                  ),
                  Text('$rows'),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: rows < 4 ? () => setDialogState(() => rows++) : null,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop({
                'name': nameController.text.trim(),
                'columns': columns,
                'rows': rows,
              }),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le tableau de bord ?'),
        content: const Text(
          'Ce tableau de bord et tous ses widgets seront supprimés définitivement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(dashboardNotifierProvider.notifier).deleteDashboard(widget.dashboardId);
      if (mounted) {
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

    return AlertDialog(
      title: const Text('Sélectionner un trend log'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final tl = filtered[index];
                  final isSelected = _selected == tl.instance;

                  return ListTile(
                    title: Text(tl.pointName ?? tl.pointKey),
                    subtitle: Text('TL ${tl.instance}'),
                    selected: isSelected,
                    leading: Radio<int>(
                      value: tl.instance,
                      groupValue: _selected,
                      onChanged: (value) => setState(() => _selected = value),
                    ),
                    onTap: () => setState(() => _selected = tl.instance),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _selected != null ? () => Navigator.of(context).pop(_selected) : null,
          child: const Text('Valider'),
        ),
      ],
    );
  }
}
