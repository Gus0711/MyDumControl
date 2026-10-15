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
import '../../widgets/point_widgets.dart';
import '../../widgets/ui/ui.dart';
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
            Flexible(child: Text(l10n.overrides, overflow: TextOverflow.ellipsis)),
            if (overriddenPoints.isNotEmpty) ...[
              const SizedBox(width: 10),
              DcTag('${overriddenPoints.length}', tone: context.dc.overrideTone, solid: true),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.refresh,
            onPressed: state.isLoading ? null : () => ref.read(pointsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.isLoading && state.points.isNotEmpty) const LinearProgressIndicator(),
          Expanded(child: _buildBody(context, l10n, state, overriddenPoints)),
        ],
      ),
      bottomNavigationBar: overriddenPoints.isEmpty ? null : _buildReleaseBar(context, l10n, overriddenPoints),
    );
  }

  /// Barre de relâchement groupé : tout sélectionner, relâcher la sélection
  Widget _buildReleaseBar(BuildContext context, AppLocalizations l10n, List<BacnetObject> points) {
    final dc = context.dc;
    final keys = points.map(_key).toSet();
    _selected.retainAll(keys); // points relâchés entre-temps
    final allSelected = _selected.length == keys.length;
    return Container(
      decoration: BoxDecoration(
        color: dc.surface,
        border: Border(top: BorderSide(color: dc.border)),
        boxShadow: dc.raisedShadow,
      ),
      child: SafeArea(
        child: DcContent(
          padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
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
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  l10n.overridesSelected(_selected.length),
                  style: context.text.bodyMedium?.copyWith(color: dc.textSecondary),
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: dc.overrideTone.fg, foregroundColor: dc.onSolid),
                onPressed: _selected.isEmpty || _releasing ? null : () => _releaseSelected(context, l10n, points),
                icon: _releasing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.lock_open_rounded),
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
    if (failed.isEmpty) {
      this.context.showSuccess(l10n.releaseSelectionDone(selection.length));
    } else {
      final detail = ref.read(pointsProvider.notifier).lastActionError;
      this.context.showError(
        [l10n.releaseSelectionFailed(failed.length, selection.length), if (detail != null) detail].join('\n'),
      );
    }
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    PointsState state,
    List<BacnetObject> overriddenPoints,
  ) {
    final dc = context.dc;

    if (state.isLoading && state.points.isEmpty) {
      return DcLoading(message: l10n.loadingPoints);
    }

    if (state.error != null && state.points.isEmpty) {
      return DcEmptyState.error(
        context,
        title: l10n.error,
        message: state.error!,
        action: FilledButton.icon(
          onPressed: () => ref.read(pointsProvider.notifier).loadPoints(),
          icon: const Icon(Icons.refresh_rounded),
          label: Text(l10n.retry),
        ),
      );
    }

    if (overriddenPoints.isEmpty) {
      return DcEmptyState(
        icon: Icons.verified_rounded,
        tone: dc.success,
        title: l10n.noOverride,
        message: l10n.allPointsNormal,
        action: state.isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : null,
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
      child: ListView(
        padding: const EdgeInsets.only(top: 4, bottom: 24),
        children: [
          for (final entry in byType.entries)
            DcContent(child: _buildTypeSection(context, l10n, entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildTypeSection(
    BuildContext context,
    AppLocalizations l10n,
    BacnetObjectType type,
    List<BacnetObject> points,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DcSectionHeader(
          BacnetTypeUtils.getTypeDisplayName(l10n, type),
          icon: BacnetTypeUtils.getTypeIcon(type),
          count: points.length,
        ),
        for (final point in points)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _buildOverrideTile(context, l10n, point),
          ),
      ],
    );
  }

  Widget _buildOverrideTile(BuildContext context, AppLocalizations l10n, BacnetObject point) {
    final dc = context.dc;
    // Déterminer si c'est une entrée forcée (out-of-service) ou un forçage classique (priority-array)
    final isInputForced = point.type.isInput && point.outOfService == true;
    final tone = dc.overrideTone;

    final key = _key(point);
    final selected = _selected.contains(key);
    final appSummary = appOverrideSummary(l10n, watchAppOverride(ref, point));

    return DcCard(
      accentColor: tone.fg,
      borderColor: selected ? tone.border : null,
      color: selected ? Color.alphaBlend(tone.bg, dc.surface) : null,
      padding: const EdgeInsets.fromLTRB(4, 10, 10, 10),
      onTap: () => context.push(Routes.pointDetailPath('${point.type.name}:${point.instance}')),
      onLongPress: () => setState(() => selected ? _selected.remove(key) : _selected.add(key)),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            onChanged: _releasing
                ? null
                : (checked) => setState(() => checked == true ? _selected.add(key) : _selected.remove(key)),
          ),
          PointTypeBadge(type: point.type),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(point.displayName, style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    DcTag(
                      isInputForced ? l10n.outOfServiceLabel : l10n.priorityLabel(point.overridePriority ?? 0),
                      icon: isInputForced ? Icons.power_settings_new_rounded : Icons.back_hand_rounded,
                      tone: tone,
                      dense: true,
                    ),
                    Text(
                      point.objectId,
                      style: AppTextStyles.monospacedValue.copyWith(fontSize: 11.5, color: dc.textMuted),
                    ),
                  ],
                ),
                if (appSummary != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: dc.textMuted),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(appSummary, style: context.text.bodySmall?.copyWith(color: dc.textSecondary)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Valeur forcée (la nature du forçage est déjà dans la pastille)
          Container(
            constraints: const BoxConstraints(minWidth: 92),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: tone.bg,
              borderRadius: BorderRadius.circular(DcRadius.md - 2),
              border: Border.all(color: tone.border),
            ),
            child: Text(
              BacnetTypeUtils.formatOverrideValue(point),
              textAlign: TextAlign.right,
              style: AppTextStyles.monospacedValue.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: tone.fg),
            ),
          ),
          const SizedBox(width: 2),
          Icon(Icons.chevron_right_rounded, color: dc.textMuted),
        ],
      ),
    );
  }
}
