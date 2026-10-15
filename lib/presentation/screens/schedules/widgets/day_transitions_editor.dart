import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../application/providers/schedule_provider.dart';
import '../../../../domain/models/schedule.dart';
import 'schedule_dialogs.dart';
import 'schedule_colors.dart';
import '../../../widgets/ui/ui.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../shared/utils/schedule_l10n.dart';

/// Widget d'édition des créneaux d'un jour
class DayTransitionsEditor extends ConsumerWidget {
  final Schedule schedule;
  final WeekDay day;
  final bool isEditing;

  const DayTransitionsEditor({
    super.key,
    required this.schedule,
    required this.day,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editState = ref.watch(scheduleEditProvider);
    final daySchedule = isEditing && editState.editedSchedule != null
        ? editState.editedSchedule!.weeklySchedule.getDay(day)
        : schedule.weeklySchedule.getDay(day);

    // Convertir les transitions en créneaux pour l'affichage
    final slots = TimeSlotConverter.transitionsToSlots(daySchedule.sortedTransitions);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: colorScheme.outline),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header avec nom du jour et actions
          _buildHeader(context, ref, theme, colorScheme, editState),
          const SizedBox(height: 12),

          // Liste des créneaux ou message vide
          if (slots.isEmpty)
            _buildEmptyState(context, ref, theme, colorScheme)
          else
            _buildSlotsList(context, ref, slots, theme, colorScheme),

          // Bouton ajouter (en mode édition)
          if (isEditing) ...[
            const SizedBox(height: 12),
            _buildAddButton(context, ref, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ColorScheme colorScheme,
    ScheduleEditState editState,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Icon(Icons.calendar_today_rounded, size: 18, color: context.dc.accent),
        const SizedBox(width: 8),
        Text(
          weekDayName(l10n, day),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),

        // Actions sur le jour (en mode édition)
        if (isEditing) ...[
          // Bouton copier
          IconButton(
            icon: const Icon(Icons.content_copy, size: 20),
            tooltip: l10n.scheduleCopyDay,
            onPressed: () {
              ref.read(scheduleEditProvider.notifier).copyDay(day);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.scheduleDayCopied(weekDayName(l10n, day))),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),

          // Bouton coller (si presse-papier non vide)
          if (editState.clipboardSourceDay != null)
            IconButton(
              icon: const Icon(Icons.content_paste, size: 20),
              tooltip: l10n.schedulePasteFrom(weekDayShortName(l10n, editState.clipboardSourceDay!)),
              onPressed: () {
                ref.read(scheduleEditProvider.notifier).pasteDay(day);
              },
            ),

          // Menu plus d'actions
          PopupMenuButton<DayAction>(
            icon: const Icon(Icons.more_vert, size: 20),
            tooltip: l10n.scheduleMoreActions,
            onSelected: (action) => _handleDayAction(context, ref, action, editState),
            itemBuilder: (context) => [
              if (editState.clipboardSourceDay != null) ...[
                PopupMenuItem(
                  value: DayAction.pasteToWorkDays,
                  child: ListTile(
                    leading: const Icon(Icons.work_outline),
                    title: Text(l10n.schedulePasteToWorkDays),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                PopupMenuItem(
                  value: DayAction.pasteToAll,
                  child: ListTile(
                    leading: const Icon(Icons.calendar_month),
                    title: Text(l10n.schedulePasteToAllDays),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                const PopupMenuDivider(),
              ],
              PopupMenuItem(
                value: DayAction.clear,
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: colorScheme.error),
                  title: Text(l10n.scheduleClearDay, style: TextStyle(color: colorScheme.error)),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
        ],

        // Bouton fermer
        IconButton(
          icon: const Icon(Icons.close, size: 20),
          tooltip: l10n.close,
          onPressed: () {
            ref.read(scheduleEditProvider.notifier).selectDay(day);
            // Toggle off selection
            if (ref.read(scheduleEditProvider).selectedDay == day) {
              // On ne peut pas vraiment désélectionner, mais on peut fermer le panel
              // via le parent widget
            }
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.event_busy,
              size: 48,
              color: context.dc.textMuted,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.scheduleNoTransition,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: context.dc.textMuted,
              ),
            ),
            if (isEditing) ...[
              const SizedBox(height: 4),
              Text(
                l10n.scheduleTapPlusToAdd,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.dc.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSlotsList(
    BuildContext context,
    WidgetRef ref,
    List<TimeSlot> slots,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 250),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: slots.length,
        itemBuilder: (context, index) {
          final slot = slots[index];
          return _TimeSlotTile(
            schedule: schedule,
            slot: slot,
            index: index,
            day: day,
            isEditing: isEditing,
          );
        },
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, WidgetRef ref, ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showAddSlotDialog(context, ref),
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.scheduleAddSlot),
      ),
    );
  }

  Future<void> _showAddSlotDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<TimeSlot>(
      context: context,
      builder: (context) => TimeSlotDialog(
        schedule: schedule,
        title: AppLocalizations.of(context)!.scheduleNewSlot,
      ),
    );

    if (result != null) {
      // Utiliser addTimeSlot qui gère les chevauchements intelligemment
      ref.read(scheduleEditProvider.notifier).addTimeSlot(day, result);
    }
  }

  void _handleDayAction(
    BuildContext context,
    WidgetRef ref,
    DayAction action,
    ScheduleEditState editState,
  ) {
    final notifier = ref.read(scheduleEditProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    switch (action) {
      case DayAction.copy:
        notifier.copyDay(day);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.scheduleDayCopied(weekDayName(l10n, day)))),
        );
        break;
      case DayAction.paste:
        notifier.pasteDay(day);
        break;
      case DayAction.pasteToWorkDays:
        notifier.pasteDayToWorkDays();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.schedulePastedToWorkDays)),
        );
        break;
      case DayAction.pasteToAll:
        notifier.pasteDayToAllDays();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.schedulePastedToAllDays)),
        );
        break;
      case DayAction.clear:
        notifier.clearDay(day);
        break;
    }
  }
}

/// Tuile pour un créneau horaire
class _TimeSlotTile extends ConsumerWidget {
  final Schedule schedule;
  final TimeSlot slot;
  final int index;
  final WeekDay day;
  final bool isEditing;

  const _TimeSlotTile({
    required this.schedule,
    required this.slot,
    required this.index,
    required this.day,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final stateText = schedule.localizedStateText(l10n, slot.value);
    final color = _getColorForValue(slot.value, colorScheme);

    return Dismissible(
      key: ValueKey('${day.apiKey}_slot_$index'),
      direction: isEditing ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => DeleteSlotDialog(
            slot: slot,
            stateText: stateText,
          ),
        );
      },
      onDismissed: (direction) {
        _deleteSlot(ref);
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(4),
          ),
          child: slot.isAllDay
              ? Text(
                  l10n.scheduleFullDay,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                )
              : Text(
                  '${slot.formattedStart} - ${slot.formattedEnd}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontFamily: AppTextStyles.monoFamily,
                  ),
                ),
        ),
        title: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                stateText,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            // Badge durée
            if (!slot.isAllDay)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  slot.formattedDuration,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: context.dc.textMuted,
                  ),
                ),
              ),
          ],
        ),
        trailing: isEditing
            ? IconButton(
                icon: const Icon(Icons.edit, size: 20),
                tooltip: l10n.edit,
                onPressed: () => _showEditDialog(context, ref),
              )
            : null,
        onTap: isEditing ? () => _showEditDialog(context, ref) : null,
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<TimeSlot>(
      context: context,
      builder: (context) => TimeSlotDialog(
        schedule: schedule,
        existingSlot: slot,
        title: AppLocalizations.of(context)!.scheduleEditSlot,
      ),
    );

    if (result != null) {
      // Utiliser updateTimeSlot qui gère les chevauchements intelligemment
      ref.read(scheduleEditProvider.notifier).updateTimeSlot(day, slot, result);
    }
  }

  void _deleteSlot(WidgetRef ref) {
    // Utiliser removeTimeSlot du provider
    ref.read(scheduleEditProvider.notifier).removeTimeSlot(day, slot);
  }

  Color _getColorForValue(dynamic value, ColorScheme colorScheme) {
    return ScheduleColors.getColorForValue(value, schedule.valueType, colorScheme);
  }
}
