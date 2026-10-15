import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/schedule_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/schedule.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/ui/ui.dart';

/// Écran de liste des schedules (plannings)
class SchedulesListScreen extends ConsumerWidget {
  const SchedulesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final schedulesAsync = ref.watch(schedulesListProvider);

    return Scaffold(
      appBar: GradientAppBar(
        title: l10n.plannings,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(schedulesListProvider),
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: schedulesAsync.when(
        loading: () => const DcLoading(),
        error: (error, stack) => DcEmptyState.error(
          context,
          title: l10n.loadingError,
          message: error.toString(),
          action: FilledButton.icon(
            onPressed: () => ref.invalidate(schedulesListProvider),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.retry),
          ),
        ),
        data: (schedules) {
          if (schedules.isEmpty) {
            return DcEmptyState(
              icon: Icons.calendar_month_rounded,
              title: l10n.noPlanning,
              message: l10n.noScheduleConfigured,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(schedulesListProvider);
              await ref.read(schedulesListProvider.future);
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth.clamp(0.0, DcSpace.contentMaxWidth) - 32;
                final columns = width >= 1000 ? 3 : (width >= 640 ? 2 : 1);
                const spacing = 12.0;
                final itemWidth = (width - spacing * (columns - 1)) / columns;

                return ListView(
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    DcContent(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DcSectionHeader(
                            l10n.plannings,
                            count: schedules.length,
                            icon: Icons.calendar_month_rounded,
                            padding: const EdgeInsets.fromLTRB(4, 20, 0, 10),
                          ),
                          Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: [
                              for (final schedule in schedules)
                                SizedBox(
                                  width: itemWidth,
                                  child: _ScheduleListTile(schedule: schedule),
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
        },
      ),
    );
  }
}

/// Carte d'un schedule dans la liste
class _ScheduleListTile extends StatelessWidget {
  final ScheduleSummary schedule;

  const _ScheduleListTile({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dc = context.dc;
    final isBoolean = schedule.valueType == ScheduleValueType.boolean;
    final hasDescription = schedule.description != null && schedule.description!.isNotEmpty;

    return DcCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      onTap: () {
        context.push(
          Routes.scheduleDetail.replaceFirst(':instance', schedule.instance.toString()),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DcIconBox(
            icon: Icons.calendar_month_rounded,
            tone: dc.toneOf(AppColors.multiStateValue),
            size: 42,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.objectName,
                  style: context.text.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasDescription) ...[
                  const SizedBox(height: 2),
                  Text(
                    schedule.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(color: dc.textSecondary),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    DcTag(
                      l10n.instanceLabel(schedule.instance.toString()),
                      icon: Icons.tag_rounded,
                      mono: true,
                      dense: true,
                    ),
                    DcTag(
                      isBoolean ? l10n.onOff : l10n.multiState,
                      icon: isBoolean ? Icons.toggle_on_outlined : Icons.format_list_numbered_rounded,
                      tone: isBoolean ? dc.success : dc.violet,
                      dense: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Icon(Icons.chevron_right_rounded, color: dc.textMuted),
          ),
        ],
      ),
    );
  }
}
