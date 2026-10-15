import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/dashboard_provider.dart';
import '../../../core/router/routes.dart';
import '../../../data/database/app_database.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/ui/ui.dart';

/// Écran listant tous les dashboards de la connexion active
class DashboardListScreen extends ConsumerStatefulWidget {
  const DashboardListScreen({super.key});

  @override
  ConsumerState<DashboardListScreen> createState() => _DashboardListScreenState();
}

class _DashboardListScreenState extends ConsumerState<DashboardListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardsAsync = ref.watch(dashboardsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: GradientAppBar(
        title: l10n.dashboards,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: l10n.createDashboard,
            onPressed: () => _showCreateDialog(context),
          ),
        ],
      ),
      body: dashboardsAsync.when(
        data: (dashboards) {
          if (dashboards.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildDashboardList(context, dashboards);
        },
        loading: () => const DcLoading(),
        error: (error, _) => _buildErrorState(context, error),
      ),
      floatingActionButton: dashboardsAsync.maybeWhen(
        data: (dashboards) => dashboards.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () => _showCreateDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.dashboardNewShort),
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DcEmptyState(
      icon: Icons.insights_rounded,
      tone: context.dc.violet,
      title: l10n.noDashboard,
      message: l10n.dashboardEmptyHint,
      action: FilledButton.icon(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.createDashboard),
      ),
    );
  }

  Widget _buildDashboardList(BuildContext context, List<Dashboard> dashboards) {
    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardsProvider);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.clamp(0.0, DcSpace.contentMaxWidth) - 32;
          final columns = width >= 1060 ? 3 : (width >= 660 ? 2 : 1);
          const spacing = 12.0;
          final itemWidth = (width - spacing * (columns - 1)) / columns;

          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              DcContent(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DcSectionHeader(
                      l10n.dashboards,
                      count: dashboards.length,
                      padding: const EdgeInsets.fromLTRB(4, 20, 0, 10),
                    ),
                    Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (var index = 0; index < dashboards.length; index++)
                          SizedBox(
                            width: itemWidth,
                            child: _DashboardCard(
                              key: ValueKey(dashboards[index].id),
                              dashboard: dashboards[index],
                              index: index,
                              animationController: _animationController,
                              onTap: () => context.push(Routes.dashboardViewPath(dashboards[index].id)),
                              onEdit: () => _showEditDialog(context, dashboards[index]),
                              onDelete: () => _showDeleteConfirmation(context, dashboards[index]),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context)!;
    return DcEmptyState.error(
      context,
      title: l10n.loadingError,
      message: error.toString(),
      action: FilledButton.icon(
        onPressed: () => ref.invalidate(dashboardsProvider),
        icon: const Icon(Icons.refresh_rounded),
        label: Text(l10n.retry),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _DashboardFormDialog(),
    );

    if (result != null && mounted) {
      final notifier = ref.read(dashboardNotifierProvider.notifier);
      final id = await notifier.createDashboard(
        name: result['name'] as String,
        columns: result['columns'] as int,
        rows: result['rows'] as int,
      );

      if (id != null && context.mounted) {
        context.push(Routes.dashboardViewPath(id));
      }
    }
  }

  Future<void> _showEditDialog(BuildContext context, Dashboard dashboard) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _DashboardFormDialog(
        initialName: dashboard.name,
        initialColumns: dashboard.columns,
        initialRows: dashboard.rows,
      ),
    );

    if (result != null && mounted) {
      final notifier = ref.read(dashboardNotifierProvider.notifier);
      await notifier.updateDashboard(
        id: dashboard.id,
        name: result['name'] as String,
        columns: result['columns'] as int,
        rows: result['rows'] as int,
      );
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context, Dashboard dashboard) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteDashboardConfirm,
      message: l10n.deleteDashboardMessage(dashboard.name),
      confirmLabel: l10n.delete,
      destructive: true,
    );

    if (confirmed == true && mounted) {
      await ref.read(dashboardNotifierProvider.notifier).deleteDashboard(dashboard.id);
    }
  }
}

// =============================================================================
// Carte de dashboard
// =============================================================================

class _DashboardCard extends ConsumerWidget {
  final Dashboard dashboard;
  final int index;
  final AnimationController animationController;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DashboardCard({
    super.key,
    required this.dashboard,
    required this.index,
    required this.animationController,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dc = context.dc;
    final widgetCount = ref.watch(dashboardWidgetsProvider(dashboard.id)).valueOrNull?.length;
    final animation = CurvedAnimation(
      parent: animationController,
      curve: Interval(
        (index * 0.1).clamp(0.0, 0.5),
        ((index * 0.1) + 0.5).clamp(0.5, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 24 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
      child: DcCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
        child: Row(
          children: [
            // Aperçu de la grille
            DashboardGridPreview(columns: dashboard.columns, rows: dashboard.rows, size: 56),
            const SizedBox(width: 14),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dashboard.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      DcTag(
                        l10n.dashboardGridSize(dashboard.columns, dashboard.rows),
                        icon: Icons.grid_view_rounded,
                        dense: true,
                      ),
                      if (widgetCount != null)
                        DcTag(
                          l10n.widgets(widgetCount),
                          tone: widgetCount > 0 ? dc.violet : dc.neutral,
                          dense: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: dc.textSecondary, size: 20),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
              itemBuilder: (context) => [
                dcMenuItem(context, 'edit', Icons.edit_outlined, l10n.edit),
                const PopupMenuDivider(),
                dcMenuItem(context, 'delete', Icons.delete_outline_rounded, l10n.delete, danger: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Miniature de la grille d'un tableau de bord (colonnes x lignes).
class DashboardGridPreview extends StatelessWidget {
  final int columns;
  final int rows;
  final double size;

  const DashboardGridPreview({super.key, required this.columns, required this.rows, required this.size});

  @override
  Widget build(BuildContext context) {
    final tone = context.dc.violet;
    const gap = 3.0;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.14),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(size * 0.26),
        border: Border.all(color: tone.border),
      ),
      child: Column(
        children: [
          for (var r = 0; r < rows; r++) ...[
            if (r > 0) const SizedBox(height: gap),
            Expanded(
              child: Row(
                children: [
                  for (var c = 0; c < columns; c++) ...[
                    if (c > 0) const SizedBox(width: gap),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: tone.fg.withValues(alpha: 0.30 + 0.15 * ((r + c) % 3)),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// Dialogue de création/édition
// =============================================================================

class _DashboardFormDialog extends StatefulWidget {
  final String? initialName;
  final int? initialColumns;
  final int? initialRows;

  const _DashboardFormDialog({
    this.initialName,
    this.initialColumns,
    this.initialRows,
  });

  @override
  State<_DashboardFormDialog> createState() => _DashboardFormDialogState();
}

class _DashboardFormDialogState extends State<_DashboardFormDialog> {
  late final TextEditingController _nameController;
  int _columns = 1;
  int _rows = 2;

  bool get _isEditing => widget.initialName != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _columns = widget.initialColumns ?? 1;
    _rows = widget.initialRows ?? 2;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(_isEditing ? l10n.editDashboard : l10n.newDashboard),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nom
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.name,
                  hintText: l10n.dashboardNameHint,
                  prefixIcon: const Icon(Icons.insights_rounded, size: 20),
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}), // Met à jour l'état du bouton Créer
              ),
              const SizedBox(height: 20),

              // Grille
              DcSectionHeader(
                l10n.dashboardGridLayout,
                padding: const EdgeInsets.only(bottom: 8),
              ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        // Colonnes
                        Row(
                          children: [
                            Expanded(child: Text(l10n.dashboardColumns)),
                            _buildCounter(
                              value: _columns,
                              onDecrement: _columns > 1 ? () => setState(() => _columns--) : null,
                              onIncrement: _columns < 4 ? () => setState(() => _columns++) : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Lignes
                        Row(
                          children: [
                            Expanded(child: Text(l10n.dashboardRows)),
                            _buildCounter(
                              value: _rows,
                              onDecrement: _rows > 1 ? () => setState(() => _rows--) : null,
                              onIncrement: _rows < 4 ? () => setState(() => _rows++) : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Aperçu
                  Column(
                    children: [
                      DashboardGridPreview(columns: _columns, rows: _rows, size: 80),
                      const SizedBox(height: 6),
                      Text(
                        l10n.widgets(_columns * _rows),
                        style: context.text.bodySmall?.copyWith(color: context.dc.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _nameController.text.trim().isNotEmpty
              ? () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop({
                    'name': _nameController.text.trim(),
                    'columns': _columns,
                    'rows': _rows,
                  });
                }
              : null,
          child: Text(_isEditing ? l10n.save : l10n.create),
        ),
      ],
    );
  }

  Widget _buildCounter({
    required int value,
    VoidCallback? onDecrement,
    VoidCallback? onIncrement,
  }) {
    final dc = context.dc;
    return Container(
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
    );
  }
}
