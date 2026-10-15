import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../application/providers/schedule_provider.dart';
import '../../../../domain/models/schedule.dart';
import 'schedule_colors.dart';
import 'schedule_dialogs.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../shared/utils/schedule_l10n.dart';
import '../../../widgets/ui/ui.dart';

/// Vue semaine compacte avec tous les jours en colonnes verticales
/// Style Google Agenda - affiche les 7 jours côte à côte
class VerticalDayScheduleView extends ConsumerWidget {
  final Schedule schedule;
  final bool isEditing;
  final WeekDay? initialDay;
  final ValueChanged<WeekDay>? onDayChanged;

  const VerticalDayScheduleView({
    super.key,
    required this.schedule,
    required this.isEditing,
    this.initialDay,
    this.onDayChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // En mode édition, utiliser les données éditées
    final editState = ref.watch(scheduleEditProvider);
    final displaySchedule = isEditing && editState.editedSchedule != null
        ? editState.editedSchedule!
        : schedule;

    return _CompactWeekView(
      schedule: displaySchedule,
      isEditing: isEditing,
      clipboardSourceDay: editState.clipboardSourceDay,
      onSlotTap: isEditing ? (day, slot) => _onSlotTap(context, ref, day, slot) : null,
      onDayTap: isEditing ? (day) => _onDayTap(context, ref, day) : null,
      onDayHeaderTap: isEditing ? (day) => _showDayActionsMenu(context, ref, day, editState.clipboardSourceDay) : null,
    );
  }

  void _showDayActionsMenu(BuildContext context, WidgetRef ref, WeekDay day, WeekDay? clipboardSource) {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final dc = ctx.dc;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                  child: _SheetHeader(icon: Icons.today_rounded, title: weekDayName(l10n, day)),
                ),
                ListTile(
                  leading: const Icon(Icons.content_copy_rounded),
                  title: Text(l10n.scheduleCopyDay),
                  onTap: () {
                    ref.read(scheduleEditProvider.notifier).copyDay(day);
                    Navigator.pop(ctx);
                    context.showInfo(l10n.scheduleDayCopied(weekDayName(l10n, day)));
                  },
                ),
                if (clipboardSource != null) ...[
                  ListTile(
                    leading: const Icon(Icons.content_paste_rounded),
                    title: Text(l10n.schedulePasteFrom(weekDayShortName(l10n, clipboardSource))),
                    onTap: () {
                      ref.read(scheduleEditProvider.notifier).pasteDay(day);
                      Navigator.pop(ctx);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.work_outline_rounded),
                    title: Text(l10n.schedulePasteToWorkDays),
                    onTap: () {
                      ref.read(scheduleEditProvider.notifier).pasteDayToWorkDays();
                      Navigator.pop(ctx);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_view_week_rounded),
                    title: Text(l10n.schedulePasteToAllDays),
                    onTap: () {
                      ref.read(scheduleEditProvider.notifier).pasteDayToAllDays();
                      Navigator.pop(ctx);
                    },
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  child: Divider(),
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: dc.danger.fg),
                  title: Text(l10n.scheduleClearDay, style: TextStyle(color: dc.danger.fg)),
                  onTap: () {
                    ref.read(scheduleEditProvider.notifier).clearDay(day);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onSlotTap(BuildContext context, WidgetRef ref, WeekDay day, TimeSlot slot) {
    onDayChanged?.call(day);
    _showEditSlotDialog(context, ref, day, slot);
  }

  void _onDayTap(BuildContext context, WidgetRef ref, WeekDay day) {
    onDayChanged?.call(day);
    _showAddSlotDialog(context, ref, day);
  }

  void _showEditSlotDialog(BuildContext context, WidgetRef ref, WeekDay day, TimeSlot slot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (ctx) => _SlotEditBottomSheet(
        schedule: schedule,
        day: day,
        slot: slot,
        onSave: (newSlot) {
          // Ajouter le nouveau créneau (gère automatiquement les chevauchements)
          ref.read(scheduleEditProvider.notifier).addTimeSlot(day, newSlot);
          Navigator.pop(ctx);
        },
        onDelete: () {
          // Supprimer le créneau (revient à "auto" / valeur par défaut du schedule)
          ref.read(scheduleEditProvider.notifier).removeTimeSlot(day, slot);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showAddSlotDialog(BuildContext context, WidgetRef ref, WeekDay day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (ctx) => _AddSlotBottomSheet(
        schedule: schedule,
        day: day,
        onSave: (newSlot) {
          // Ajouter le nouveau créneau
          ref.read(scheduleEditProvider.notifier).addTimeSlot(day, newSlot);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

/// Vue semaine compacte - tous les jours en colonnes
class _CompactWeekView extends StatefulWidget {
  final Schedule schedule;
  final bool isEditing;
  final WeekDay? clipboardSourceDay;
  final void Function(WeekDay day, TimeSlot slot)? onSlotTap;
  final void Function(WeekDay day)? onDayTap;
  final void Function(WeekDay day)? onDayHeaderTap;

  // Hauteur réduite pour afficher plus d'heures
  static const double hourHeight = 30.0;
  static const double headerHeight = 44.0;
  static const double timeColumnWidth = 44.0;
  static const int startHour = 0;
  static const int endHour = 24;

  const _CompactWeekView({
    required this.schedule,
    required this.isEditing,
    this.clipboardSourceDay,
    this.onSlotTap,
    this.onDayTap,
    this.onDayHeaderTap,
  });

  @override
  State<_CompactWeekView> createState() => _CompactWeekViewState();
}

class _CompactWeekViewState extends State<_CompactWeekView> {
  @override
  Widget build(BuildContext context) {
    final dc = context.dc;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: dc.surface,
        borderRadius: BorderRadius.circular(DcRadius.lg),
        border: Border.all(color: dc.border),
        boxShadow: dc.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // En-tête avec les jours
          _buildDaysHeader(context),

          // Grille scrollable
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                height: (_CompactWeekView.endHour - _CompactWeekView.startHour) * _CompactWeekView.hourHeight + 8,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Colonne des heures
                      _buildTimeColumn(context),

                      // Colonnes des jours
                      Expanded(
                        child: Row(
                          children: WeekDay.values.map((day) {
                            return Expanded(
                              child: _buildDayColumn(context, day),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dc = context.dc;
    final today = _getCurrentWeekDay();

    return Container(
      height: _CompactWeekView.headerHeight,
      decoration: BoxDecoration(
        color: dc.surface,
        border: Border(bottom: BorderSide(color: dc.border)),
      ),
      child: Row(
        children: [
          // Espace pour la colonne des heures
          const SizedBox(width: _CompactWeekView.timeColumnWidth),

          // Labels des jours
          ...WeekDay.values.map((day) {
            final isToday = day == today;
            final isWeekend = day == WeekDay.saturday || day == WeekDay.sunday;
            final hasClipboard = widget.clipboardSourceDay == day;
            final tone = isToday ? dc.accentTone : (hasClipboard ? dc.violet : null);

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                child: Material(
                  color: tone?.bg ?? Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DcRadius.sm + 2),
                    side: BorderSide(color: tone?.border ?? Colors.transparent),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: widget.isEditing ? () => widget.onDayHeaderTap?.call(day) : null,
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              weekDayShortName(l10n, day).toUpperCase(),
                              overflow: TextOverflow.clip,
                              maxLines: 1,
                              style: AppTextStyles.overline.copyWith(
                                letterSpacing: 0.8,
                                color: tone?.fg ?? (isWeekend ? dc.textMuted : dc.textSecondary),
                              ),
                            ),
                          ),
                          if (hasClipboard) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.content_copy_rounded, size: 11, color: dc.violet.fg),
                          ] else if (widget.isEditing) ...[
                            const SizedBox(width: 2),
                            Icon(Icons.expand_more_rounded, size: 13, color: tone?.fg ?? dc.textMuted),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(BuildContext context) {
    final dc = context.dc;
    return SizedBox(
      width: _CompactWeekView.timeColumnWidth,
      child: Column(
        children: List.generate(_CompactWeekView.endHour - _CompactWeekView.startHour, (index) {
          final hour = _CompactWeekView.startHour + index;
          // Afficher seulement les heures paires pour gagner de la place
          final showLabel = hour % 2 == 0;

          return SizedBox(
            height: _CompactWeekView.hourHeight,
            child: Align(
              alignment: Alignment.topRight,
              child: Transform.translate(
                offset: const Offset(0, -6),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    showLabel ? '${hour.toString().padLeft(2, '0')}:00' : '',
                    style: AppTextStyles.monospacedValue.copyWith(
                      color: dc.textMuted,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayColumn(BuildContext context, WeekDay day) {
    final dc = context.dc;
    final daySchedule = widget.schedule.weeklySchedule.getDay(day);
    final slots = TimeSlotConverter.transitionsToSlots(daySchedule.sortedTransitions);
    final isWeekend = day == WeekDay.saturday || day == WeekDay.sunday;
    final isToday = day == _getCurrentWeekDay();

    return GestureDetector(
      onTap: widget.isEditing ? () => widget.onDayTap?.call(day) : null,
      child: MouseRegion(
        cursor: widget.isEditing ? SystemMouseCursors.click : MouseCursor.defer,
        child: Container(
          decoration: BoxDecoration(
            color: isToday
                ? dc.accentTone.bg.withValues(alpha: 0.35)
                : (isWeekend ? dc.surfaceSunken : null),
            border: Border(left: BorderSide(color: dc.border)),
          ),
          child: Stack(
            children: [
              // Lignes horizontales des heures (plus marquées toutes les 6 h)
              ...List.generate(_CompactWeekView.endHour - _CompactWeekView.startHour, (index) {
                final major = index % 6 == 0;
                return Positioned(
                  top: index * _CompactWeekView.hourHeight,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    color: major ? dc.border : dc.border.withValues(alpha: 0.45),
                  ),
                );
              }),

              // Créneaux
              ...slots.map((slot) => _buildSlotBlock(context, day, slot)),

              // Indicateur heure actuelle
              if (isToday) _buildCurrentTimeIndicator(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotBlock(BuildContext context, WeekDay day, TimeSlot slot) {
    final dc = context.dc;
    final tone = ScheduleColors.blockTone(context, slot.value, widget.schedule.valueType);
    final solid = ScheduleColors.solidColor(context, slot.value, widget.schedule.valueType);
    final startY = (slot.startMinutes / 60) * _CompactWeekView.hourHeight;
    final height = ((slot.endMinutes - slot.startMinutes) / 60) * _CompactWeekView.hourHeight;

    if (height < 2) return const SizedBox.shrink();

    final label = height > 18
        ? Text(
            _getShortStateText(slot.value),
            style: context.text.labelSmall?.copyWith(
              color: tone.fg,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          )
        : null;
    final times = height > 44
        ? Text(
            '${formatMinutesOfDay(slot.startMinutes)}–${formatMinutesOfDay(slot.endMinutes)}',
            style: AppTextStyles.monospacedValue.copyWith(
              color: tone.fg.withValues(alpha: 0.8),
              fontSize: 9,
              height: 1.2,
            ),
            overflow: TextOverflow.clip,
            maxLines: 1,
          )
        : null;

    return Positioned(
      left: 2,
      right: 2,
      top: startY,
      height: height,
      child: GestureDetector(
        onTap: widget.isEditing ? () => widget.onSlotTap?.call(day, slot) : null,
        child: Tooltip(
          message: '${widget.schedule.localizedStateText(AppLocalizations.of(context)!, slot.value)}  '
              '${formatMinutesOfDay(slot.startMinutes)}–${formatMinutesOfDay(slot.endMinutes)}',
          waitDuration: const Duration(milliseconds: 500),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 1),
            decoration: BoxDecoration(
              color: tone.bg,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: widget.isEditing ? tone.border : tone.border.withValues(alpha: 0.5),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: slot.value == null ? dc.borderStrong : solid),
                if (label != null)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 3, 3, 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [label, ?times],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getShortStateText(dynamic value) {
    return widget.schedule.localizedStateText(AppLocalizations.of(context)!, value);
  }

  Widget _buildCurrentTimeIndicator(BuildContext context) {
    final color = context.dc.danger.fg;
    final now = DateTime.now();
    final minutesSinceMidnight = now.hour * 60 + now.minute;
    final y = (minutesSinceMidnight / 60) * _CompactWeekView.hourHeight;

    return Positioned(
      left: 0,
      right: 0,
      top: y - 4,
      height: 8,
      child: IgnorePointer(
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
              ),
            ),
            Expanded(child: Container(height: 2, color: color)),
          ],
        ),
      ),
    );
  }

  WeekDay _getCurrentWeekDay() {
    final now = DateTime.now();
    return WeekDay.values[(now.weekday - 1) % 7];
  }
}

// ---------------------------------------------------------------------------
// Éléments communs des feuilles d'édition de créneau
// ---------------------------------------------------------------------------

/// En-tête d'une feuille d'édition : icône, titre, action optionnelle.
class _SheetHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const _SheetHeader({required this.icon, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DcIconBox(icon: icon, size: 36),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: context.text.titleMedium)),
        ?trailing,
      ],
    );
  }
}

/// Champ d'heure cliquable (début / fin) avec réglage rapide ±15 min.
class _TimeField extends StatelessWidget {
  final String label;
  final int minutes;
  final VoidCallback onTap;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final bool highlight;

  const _TimeField({
    required this.label,
    required this.minutes,
    required this.onTap,
    required this.onMinus,
    required this.onPlus,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final tone = highlight ? dc.accentTone : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: tone?.bg ?? dc.surfaceSunken,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DcRadius.md),
            side: BorderSide(color: tone?.border ?? dc.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label.toUpperCase(),
                          style: AppTextStyles.overline.copyWith(color: dc.textMuted, fontSize: 10),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatMinutesOfDay(minutes),
                          style: AppTextStyles.monospacedValue.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: tone?.fg ?? dc.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.schedule_rounded, size: 18, color: tone?.fg ?? dc.textMuted),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _QuickButton(icon: Icons.remove_rounded, label: '15', onTap: onMinus)),
            const SizedBox(width: 6),
            Expanded(child: _QuickButton(icon: Icons.add_rounded, label: '15', onTap: onPlus)),
          ],
        ),
      ],
    );
  }
}

/// Bouton de réglage rapide (−15 / +15 min).
class _QuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        foregroundColor: dc.textSecondary,
        side: BorderSide(color: dc.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 2),
          Text(label, style: AppTextStyles.monospacedValue.copyWith(fontSize: 12, color: dc.textSecondary)),
        ],
      ),
    );
  }
}

/// Ligne « Début → Fin ».
class _TimeRangeRow extends StatelessWidget {
  final Widget start;
  final Widget end;

  const _TimeRangeRow({required this.start, required this.end});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: start),
        Padding(
          padding: const EdgeInsets.only(top: 22, left: 8, right: 8),
          child: Icon(Icons.arrow_forward_rounded, color: context.dc.textMuted, size: 18),
        ),
        Expanded(child: end),
      ],
    );
  }
}

/// Sélecteur d'état (pastilles colorées selon la légende).
class _StateChips extends StatelessWidget {
  final Schedule schedule;
  final dynamic selectedValue;
  final ValueChanged<dynamic> onSelected;

  const _StateChips({required this.schedule, required this.selectedValue, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dc = context.dc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.state.toUpperCase(), style: AppTextStyles.overline.copyWith(color: dc.textMuted)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: schedule.localizedPossibleValues(l10n).map((pv) {
            final isSelected = pv.value == selectedValue;
            final tone = ScheduleColors.blockTone(context, pv.value, schedule.valueType);

            return ChoiceChip(
              avatar: ScheduleSwatch(value: pv.value, valueType: schedule.valueType),
              label: Text(pv.text),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: tone.bg,
              side: BorderSide(color: isSelected ? tone.border : dc.border),
              labelStyle: context.text.labelMedium?.copyWith(
                color: isSelected ? tone.fg : dc.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              onSelected: (_) => onSelected(pv.value),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Boutons Annuler / Valider en bas de feuille.
class _SheetActions extends StatelessWidget {
  final String confirmLabel;
  final VoidCallback onConfirm;

  const _SheetActions({required this.confirmLabel, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(onPressed: onConfirm, child: Text(confirmLabel)),
        ),
      ],
    );
  }
}

/// Bottom sheet pour éditer un créneau existant
class _SlotEditBottomSheet extends StatefulWidget {
  final Schedule schedule;
  final WeekDay day;
  final TimeSlot slot;
  final void Function(TimeSlot) onSave;
  final VoidCallback onDelete;

  const _SlotEditBottomSheet({
    required this.schedule,
    required this.day,
    required this.slot,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_SlotEditBottomSheet> createState() => _SlotEditBottomSheetState();
}

class _SlotEditBottomSheetState extends State<_SlotEditBottomSheet> {
  late int _startMinutes;
  late int _endMinutes;
  late dynamic _selectedValue;

  @override
  void initState() {
    super.initState();
    _startMinutes = widget.slot.startMinutes;
    _endMinutes = widget.slot.endMinutes;
    _selectedValue = widget.slot.value;
  }

  Future<void> _selectStartTime() async {
    final result = await CustomTimePickerDialog.show(
      context: context,
      initialMinutes: _startMinutes,
      allowMidnight: false,
    );
    if (result != null) {
      setState(() => _startMinutes = result);
    }
  }

  Future<void> _selectEndTime() async {
    final result = await CustomTimePickerDialog.show(
      context: context,
      initialMinutes: _endMinutes,
      allowMidnight: true,
    );
    if (result != null) {
      setState(() => _endMinutes = result);
    }
  }

  void _adjustStartTime(int delta) {
    setState(() {
      _startMinutes = (_startMinutes + delta).clamp(0, _endMinutes - 15);
    });
  }

  void _adjustEndTime(int delta) {
    setState(() {
      _endMinutes = (_endMinutes + delta).clamp(_startMinutes + 15, 1440);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dc = context.dc;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHeader(
              icon: Icons.edit_calendar_rounded,
              title: l10n.scheduleEditDayTitle(weekDayName(l10n, widget.day)),
              trailing: IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: dc.danger.fg),
                tooltip: l10n.delete,
                onPressed: widget.onDelete,
              ),
            ),
            const SizedBox(height: 20),

            // Sélecteur d'heures avec boutons rapides
            _TimeRangeRow(
              start: _TimeField(
                label: l10n.start,
                minutes: _startMinutes,
                onTap: _selectStartTime,
                onMinus: () => _adjustStartTime(-15),
                onPlus: () => _adjustStartTime(15),
              ),
              end: _TimeField(
                label: l10n.end,
                minutes: _endMinutes,
                onTap: _selectEndTime,
                onMinus: () => _adjustEndTime(-15),
                onPlus: () => _adjustEndTime(15),
                highlight: _endMinutes >= 1440,
              ),
            ),
            const SizedBox(height: 20),

            // Sélecteur d'état
            _StateChips(
              schedule: widget.schedule,
              selectedValue: _selectedValue,
              onSelected: (v) => setState(() => _selectedValue = v),
            ),
            const SizedBox(height: 24),

            _SheetActions(
              confirmLabel: l10n.save,
              onConfirm: () {
                final newSlot = TimeSlot(
                  startMinutes: _startMinutes,
                  endMinutes: _endMinutes,
                  value: _selectedValue,
                );
                widget.onSave(newSlot);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet pour ajouter un nouveau créneau
class _AddSlotBottomSheet extends StatefulWidget {
  final Schedule schedule;
  final WeekDay day;
  final void Function(TimeSlot) onSave;

  const _AddSlotBottomSheet({
    required this.schedule,
    required this.day,
    required this.onSave,
  });

  @override
  State<_AddSlotBottomSheet> createState() => _AddSlotBottomSheetState();
}

class _AddSlotBottomSheetState extends State<_AddSlotBottomSheet> {
  int _startMinutes = 8 * 60; // 08:00
  int _endMinutes = 18 * 60; // 18:00
  dynamic _selectedValue;

  @override
  void initState() {
    super.initState();
    // Sélectionner la première valeur par défaut
    if (widget.schedule.possibleValues.isNotEmpty) {
      _selectedValue = widget.schedule.possibleValues.first.value;
    }
  }

  Future<void> _selectStartTime() async {
    final result = await CustomTimePickerDialog.show(
      context: context,
      initialMinutes: _startMinutes,
      allowMidnight: false,
    );
    if (result != null) {
      setState(() => _startMinutes = result);
    }
  }

  Future<void> _selectEndTime() async {
    final result = await CustomTimePickerDialog.show(
      context: context,
      initialMinutes: _endMinutes,
      allowMidnight: true,
    );
    if (result != null) {
      setState(() => _endMinutes = result);
    }
  }

  void _adjustStartTime(int delta) {
    setState(() {
      _startMinutes = (_startMinutes + delta).clamp(0, _endMinutes - 15);
    });
  }

  void _adjustEndTime(int delta) {
    setState(() {
      _endMinutes = (_endMinutes + delta).clamp(_startMinutes + 15, 1440);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHeader(
              icon: Icons.add_rounded,
              title: l10n.scheduleAddDayTitle(weekDayName(l10n, widget.day)),
            ),
            const SizedBox(height: 20),

            // Sélecteur d'heures avec boutons rapides
            _TimeRangeRow(
              start: _TimeField(
                label: l10n.start,
                minutes: _startMinutes,
                onTap: _selectStartTime,
                onMinus: () => _adjustStartTime(-15),
                onPlus: () => _adjustStartTime(15),
              ),
              end: _TimeField(
                label: l10n.end,
                minutes: _endMinutes,
                onTap: _selectEndTime,
                onMinus: () => _adjustEndTime(-15),
                onPlus: () => _adjustEndTime(15),
                highlight: _endMinutes >= 1440,
              ),
            ),
            const SizedBox(height: 20),

            // Sélecteur d'état
            _StateChips(
              schedule: widget.schedule,
              selectedValue: _selectedValue,
              onSelected: (v) => setState(() => _selectedValue = v),
            ),
            const SizedBox(height: 24),

            _SheetActions(
              confirmLabel: l10n.add,
              onConfirm: () {
                final newSlot = TimeSlot(
                  startMinutes: _startMinutes,
                  endMinutes: _endMinutes,
                  value: _selectedValue,
                );
                widget.onSave(newSlot);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
