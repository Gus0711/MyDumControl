import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/dashboard_provider.dart';
import '../../../core/router/routes.dart';
import '../../../data/database/app_database.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../../l10n/app_localizations.dart';

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
            icon: const Icon(Icons.add),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(context, error),
      ),
      floatingActionButton: dashboardsAsync.maybeWhen(
        data: (dashboards) => dashboards.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () => _showCreateDialog(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.dashboardNewShort),
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.dashboard_customize_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withAlpha(100),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noDashboard,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.dashboardEmptyHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.createDashboard),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardList(BuildContext context, List<Dashboard> dashboards) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardsProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: dashboards.length,
        itemBuilder: (context, index) {
          final dashboard = dashboards[index];
          return _DashboardCard(
            key: ValueKey(dashboard.id),
            dashboard: dashboard,
            index: index,
            animationController: _animationController,
            onTap: () => context.push(Routes.dashboardViewPath(dashboard.id)),
            onEdit: () => _showEditDialog(context, dashboard),
            onDelete: () => _showDeleteConfirmation(context, dashboard),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              l10n.loadingError,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(dashboardsProvider),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
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

      if (id != null && mounted) {
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteDashboardConfirm),
        content: Text(l10n.deleteDashboardMessage(dashboard.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(dashboardNotifierProvider.notifier).deleteDashboard(dashboard.id);
    }
  }
}

// =============================================================================
// Carte de dashboard
// =============================================================================

class _DashboardCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          offset: Offset(0, 30 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icône avec grille
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildGridPreview(context),
                ),
                const SizedBox(width: 16),
                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.dashboard,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              dashboard.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Builder(
                        builder: (context) {
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          return Text(
                            l10n.dashboardGridSize(dashboard.columns, dashboard.rows),
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Actions
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
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
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: const Icon(Icons.edit),
                        title: Text(l10n.edit),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: const Icon(Icons.delete, color: Colors.red),
                        title: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridPreview(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: dashboard.columns,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: dashboard.columns * dashboard.rows,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: color.withAlpha(60 + (index * 20) % 100),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        },
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
      content: SingleChildScrollView(
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
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}), // Met à jour l'état du bouton Créer
            ),
            const SizedBox(height: 24),

            // Grille
            Text(
              l10n.dashboardGridLayout,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

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
            const SizedBox(height: 12),

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

            const SizedBox(height: 16),

            // Aperçu
            Center(
              child: Builder(
                builder: (context) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return Container(
                    width: 120,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? Colors.grey.shade600 : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _columns,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                      ),
                      itemCount: _columns * _rows,
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withAlpha(60),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),
            Center(
              child: Builder(
                builder: (context) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return Text(
                    l10n.widgets(_columns * _rows),
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontSize: 12,
                    ),
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
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: onDecrement,
          visualDensity: VisualDensity.compact,
        ),
        Container(
          width: 40,
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: onIncrement,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
