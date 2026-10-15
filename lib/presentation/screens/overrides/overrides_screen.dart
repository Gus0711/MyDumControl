import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/points_provider.dart';
import '../../../core/router/routes.dart';
import '../../../domain/models/bacnet_object.dart';
import '../../shared/utils/bacnet_type_utils.dart';
import '../../widgets/app_override_info.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../../l10n/app_localizations.dart';

/// Écran listant les points forcés (overrides)
class OverridesScreen extends ConsumerStatefulWidget {
  const OverridesScreen({super.key});

  @override
  ConsumerState<OverridesScreen> createState() => _OverridesScreenState();
}

class _OverridesScreenState extends ConsumerState<OverridesScreen> {
  /// Points sélectionnés ("type:instance")
  final Set<String> _selected = {};
  bool _releasing = false;

  static String _key(BacnetObject p) => '${p.type.apiName}:${p.instance}';

  @override
  void initState() {
    super.initState();
    // Charger les points si pas déjà chargés
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(pointsProvider);
      if (state.points.isEmpty && !state.isLoading) {
        ref.read(pointsProvider.notifier).loadPoints();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(pointsProvider);
    final overriddenPoints = state.overriddenPoints;

    return Scaffold(
      appBar: GradientAppBar(
        titleWidget: Row(
          children: [
            Text(l10n.overrides),
            if (overriddenPoints.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${overriddenPoints.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: state.isLoading
                ? null
                : () => ref.read(pointsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: _buildBody(context, l10n, state, overriddenPoints),
      bottomNavigationBar: overriddenPoints.isEmpty ? null : _buildReleaseBar(context, l10n, overriddenPoints),
    );
  }

  /// Barre de relâchement groupé : tout sélectionner, relâcher la sélection
  Widget _buildReleaseBar(BuildContext context, AppLocalizations l10n, List<BacnetObject> points) {
    final keys = points.map(_key).toSet();
    _selected.retainAll(keys); // points relâchés entre-temps
    final allSelected = _selected.length == keys.length;
    return SafeArea(
      child: Material(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Checkbox(
                value: _selected.isEmpty ? false : (allSelected ? true : null),
                tristate: true,
                onChanged: _releasing
                    ? null
                    : (_) => setState(() {
                          if (allSelected) {
                            _selected.clear();
                          } else {
                            _selected.addAll(keys);
                          }
                        }),
              ),
              Expanded(child: Text(l10n.overridesSelected(_selected.length))),
              FilledButton.icon(
                onPressed: _selected.isEmpty || _releasing
                    ? null
                    : () => _releaseSelected(context, l10n, points),
                icon: _releasing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.lock_open),
                label: Text(l10n.releaseSelection),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _releaseSelected(BuildContext context, AppLocalizations l10n, List<BacnetObject> points) async {
    final selection = points.where((p) => _selected.contains(_key(p))).toList();
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.releaseSelection,
      message: l10n.releaseSelectionMessage(selection.length),
      confirmLabel: l10n.release,
    );
    if (!confirmed || !mounted) return;

    setState(() => _releasing = true);
    final failed = await ref.read(pointsProvider.notifier).releaseMany(selection);
    if (!mounted) return;
    setState(() {
      _releasing = false;
      _selected
        ..clear()
        ..addAll(failed.map(_key)); // garder les échecs sélectionnés
    });
    final messenger = ScaffoldMessenger.of(this.context);
    if (failed.isEmpty) {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.releaseSelectionDone(selection.length)),
        backgroundColor: Colors.green,
      ));
    } else {
      final detail = ref.read(pointsProvider.notifier).lastActionError;
      messenger.showSnackBar(SnackBar(
        content: Text([
          l10n.releaseSelectionFailed(failed.length, selection.length),
          if (detail != null) detail,
        ].join('\n')),
        backgroundColor: Colors.red,
      ));
    }
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, PointsState state, List<BacnetObject> overriddenPoints) {
    if (state.isLoading && state.points.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.loadingPoints),
          ],
        ),
      );
    }

    if (state.error != null && state.points.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(state.error!),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.read(pointsProvider.notifier).loadPoints(),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (overriddenPoints.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade400),
            const SizedBox(height: 16),
            Text(
              l10n.noOverride,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.green.shade700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.allPointsNormal,
              style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
            if (state.isLoading) ...[
              const SizedBox(height: 16),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      );
    }

    // Grouper par type
    final byType = <BacnetObjectType, List<BacnetObject>>{};
    for (final point in overriddenPoints) {
      byType.putIfAbsent(point.type, () => []);
      byType[point.type]!.add(point);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(pointsProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: byType.length,
        itemBuilder: (context, index) {
          final type = byType.keys.elementAt(index);
          final points = byType[type]!;
          return _buildTypeSection(context, type, points, state.isLoading);
        },
      ),
    );
  }

  Widget _buildTypeSection(
    BuildContext context,
    BacnetObjectType type,
    List<BacnetObject> points,
    bool isLoading,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête du type
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Icon(BacnetTypeUtils.getTypeIcon(type), color: BacnetTypeUtils.getTypeColor(type), size: 20),
              const SizedBox(width: 8),
              Text(
                BacnetTypeUtils.getTypeDisplayName(AppLocalizations.of(context)!, type),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${points.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
              if (isLoading) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        ),
        // Liste des points forcés
        ...points.map((point) => _buildOverrideTile(context, AppLocalizations.of(context)!, point)),
      ],
    );
  }

  Widget _buildOverrideTile(BuildContext context, AppLocalizations l10n, BacnetObject point) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Déterminer si c'est une entrée forcée (out-of-service) ou un forçage classique (priority-array)
    final isInputForced = point.type.isInput && point.outOfService == true;
    final tileColor = isInputForced ? Colors.orange : Colors.red;

    final key = _key(point);
    final appSummary = appOverrideSummary(l10n, watchAppOverride(ref, point));
    return ListTile(
      onTap: () => context.push(Routes.pointDetailPath('${point.type.name}:${point.instance}')),
      onLongPress: () => setState(() => _selected.contains(key) ? _selected.remove(key) : _selected.add(key)),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: _selected.contains(key),
            onChanged: _releasing
                ? null
                : (checked) => setState(() => checked == true ? _selected.add(key) : _selected.remove(key)),
          ),
          Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: tileColor.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tileColor.shade300),
        ),
        child: Icon(
          isInputForced ? Icons.power_settings_new : Icons.lock,
          color: tileColor.shade700,
          size: 20,
        ),
          ),
        ],
      ),
      title: Text(
        point.displayName,
        style: const TextStyle(fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          isInputForced
              ? '${l10n.outOfServiceLabel} • ${point.type.shortName}:${point.instance}'
              : '${l10n.priorityLabel(point.overridePriority ?? 0)} • ${point.type.shortName}:${point.instance}',
          ?appSummary,
        ].join('\n'),
        style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Valeur forcée
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tileColor.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: tileColor.shade200),
                ),
                child: Text(
                  BacnetTypeUtils.formatOverrideValue(point),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: tileColor.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isInputForced ? l10n.outOfServiceLabel : l10n.forcedLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: tileColor.shade400,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
        ],
      ),
    );
  }
}
