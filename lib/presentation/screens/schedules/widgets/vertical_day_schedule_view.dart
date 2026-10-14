import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../application/providers/schedule_provider.dart';
import '../../../../domain/models/schedule.dart';
import 'schedule_colors.dart';
import 'schedule_dialogs.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                day.displayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.content_copy),
              title: const Text('Copier ce jour'),
              onTap: () {
                ref.read(scheduleEditProvider.notifier).copyDay(day);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${day.displayName} copié')),
                );
              },
            ),
            if (clipboardSource != null) ...[
              ListTile(
                leading: const Icon(Icons.content_paste),
                title: Text('Coller depuis ${clipboardSource.shortName}'),
                onTap: () {
                  ref.read(scheduleEditProvider.notifier).pasteDay(day);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.work_outline),
                title: const Text('Coller sur jours ouvrés'),
                onTap: () {
                  ref.read(scheduleEditProvider.notifier).pasteDayToWorkDays();
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_view_week),
                title: const Text('Coller sur tous les jours'),
                onTap: () {
                  ref.read(scheduleEditProvider.notifier).pasteDayToAllDays();
                  Navigator.pop(ctx);
                },
              ),
            ],
            const Divider(),
            ListTile(
              leading: Icon(Icons.delete_outline, color: colorScheme.error),
              title: Text('Effacer ce jour', style: TextStyle(color: colorScheme.error)),
              onTap: () {
                ref.read(scheduleEditProvider.notifier).clearDay(day);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
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
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
  static const double hourHeight = 28.0;
  static const double headerHeight = 36.0;
  static const double timeColumnWidth = 32.0;
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // En-tête avec les jours
        _buildDaysHeader(theme, colorScheme),

        // Grille scrollable
        Expanded(
          child: SingleChildScrollView(
            child: SizedBox(
              height: (_CompactWeekView.endHour - _CompactWeekView.startHour) * _CompactWeekView.hourHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Colonne des heures
                  _buildTimeColumn(theme, colorScheme),

                  // Colonnes des jours
                  Expanded(
                    child: Row(
                      children: WeekDay.values.map((day) {
                        return Expanded(
                          child: _buildDayColumn(context, day, colorScheme),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDaysHeader(ThemeData theme, ColorScheme colorScheme) {
    final today = _getCurrentWeekDay();

    return Container(
      height: _CompactWeekView.headerHeight,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Espace pour la colonne des heures
          SizedBox(width: _CompactWeekView.timeColumnWidth),

          // Labels des jours
          ...WeekDay.values.map((day) {
            final isToday = day == today;
            final isWeekend = day == WeekDay.saturday || day == WeekDay.sunday;
            final hasClipboard = widget.clipboardSourceDay == day;

            return Expanded(
              child: GestureDetector(
                onTap: widget.isEditing ? () => widget.onDayHeaderTap?.call(day) : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: isToday
                        ? colorScheme.primaryContainer
                        : (hasClipboard ? colorScheme.tertiaryContainer : null),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            day.shortName.substring(0, 3),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                              color: isToday
                                  ? colorScheme.onPrimaryContainer
                                  : (isWeekend ? colorScheme.outline : colorScheme.onSurface),
                              fontSize: 10,
                            ),
                          ),
                          if (hasClipboard)
                            Icon(
                              Icons.content_copy,
                              size: 12,
                              color: colorScheme.onTertiaryContainer,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(ThemeData theme, ColorScheme colorScheme) {
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
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  showLabel ? '${hour}h' : '',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayColumn(BuildContext context, WeekDay day, ColorScheme colorScheme) {
    final daySchedule = widget.schedule.weeklySchedule.getDay(day);
    final slots = TimeSlotConverter.transitionsToSlots(daySchedule.sortedTransitions);
    final isWeekend = day == WeekDay.saturday || day == WeekDay.sunday;
    final isToday = day == _getCurrentWeekDay();

    return GestureDetector(
      onTap: widget.isEditing ? () => widget.onDayTap?.call(day) : null,
      child: Container(
        decoration: BoxDecoration(
          color: isWeekend
              ? colorScheme.surfaceContainerHighest.withAlpha(30)
              : null,
          border: Border(
            left: BorderSide(
              color: colorScheme.outlineVariant.withAlpha(50),
              width: 0.5,
            ),
          ),
        ),
        child: Stack(
          children: [
            // Lignes horizontales des heures
            ...List.generate(_CompactWeekView.endHour - _CompactWeekView.startHour, (index) {
              return Positioned(
                top: index * _CompactWeekView.hourHeight,
                left: 0,
                right: 0,
                child: Container(
                  height: 0.5,
                  color: colorScheme.outlineVariant.withAlpha(40),
                ),
              );
            }),

            // Créneaux
            ...slots.map((slot) => _buildSlotBlock(context, day, slot, colorScheme)),

            // Indicateur heure actuelle
            if (isToday) _buildCurrentTimeIndicator(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotBlock(BuildContext context, WeekDay day, TimeSlot slot, ColorScheme colorScheme) {
    final color = ScheduleColors.getColorForValue(slot.value, widget.schedule.valueType, colorScheme);
    final startY = (slot.startMinutes / 60) * _CompactWeekView.hourHeight;
    final height = ((slot.endMinutes - slot.startMinutes) / 60) * _CompactWeekView.hourHeight;

    if (height < 2) return const SizedBox.shrink();

    return Positioned(
      left: 1,
      right: 1,
      top: startY,
      height: height,
      child: GestureDetector(
        onTap: widget.isEditing ? () => widget.onSlotTap?.call(day, slot) : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 0.5),
          decoration: BoxDecoration(
            color: color.withAlpha(220),
            borderRadius: BorderRadius.circular(3),
            border: widget.isEditing
                ? Border.all(color: colorScheme.primary.withAlpha(100), width: 1)
                : null,
          ),
          child: height > 20
              ? Center(
                  child: Text(
                    _getShortStateText(slot.value),
                    style: TextStyle(
                      color: _getContrastColor(color),
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.clip,
                    maxLines: 1,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  String _getShortStateText(dynamic value) {
    final text = widget.schedule.getStateText(value);
    // Raccourcir le texte pour les petits blocs
    if (text.length > 6) {
      return text.substring(0, 5) + '.';
    }
    return text;
  }

  Widget _buildCurrentTimeIndicator(ColorScheme colorScheme) {
    final now = DateTime.now();
    final minutesSinceMidnight = now.hour * 60 + now.minute;
    final y = (minutesSinceMidnight / 60) * _CompactWeekView.hourHeight;

    return Positioned(
      left: 0,
      right: 0,
      top: y - 1,
      child: Container(
        height: 2,
        decoration: BoxDecoration(
          color: colorScheme.error,
          boxShadow: [
            BoxShadow(
              color: colorScheme.error.withAlpha(100),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  WeekDay _getCurrentWeekDay() {
    final now = DateTime.now();
    return WeekDay.values[(now.weekday - 1) % 7];
  }

  Color _getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
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

  Widget _buildQuickAdjustButtons({
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildQuickButton(
          icon: Icons.remove,
          label: '-15',
          onTap: onMinus,
          colorScheme: colorScheme,
        ),
        const SizedBox(width: 8),
        _buildQuickButton(
          icon: Icons.add,
          label: '+15',
          onTap: onPlus,
          colorScheme: colorScheme,
        ),
      ],
    );
  }

  Widget _buildQuickButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: colorScheme.primary),
              const SizedBox(width: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.edit_calendar, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Modifier - ${widget.day.displayName}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: colorScheme.error),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sélecteur d'heures avec boutons rapides
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colonne Début
                Expanded(
                  child: Column(
                    children: [
                      _buildTimeButton(
                        label: 'Début',
                        time: formatMinutesOfDay(_startMinutes),
                        onTap: _selectStartTime,
                      ),
                      const SizedBox(height: 6),
                      _buildQuickAdjustButtons(
                        onMinus: () => _adjustStartTime(-15),
                        onPlus: () => _adjustStartTime(15),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 4, right: 4),
                  child: Icon(Icons.arrow_forward, color: colorScheme.outline, size: 20),
                ),
                // Colonne Fin
                Expanded(
                  child: Column(
                    children: [
                      _buildTimeButton(
                        label: 'Fin',
                        time: formatMinutesOfDay(_endMinutes),
                        onTap: _selectEndTime,
                        highlight: _endMinutes >= 1440,
                      ),
                      const SizedBox(height: 6),
                      _buildQuickAdjustButtons(
                        onMinus: () => _adjustEndTime(-15),
                        onPlus: () => _adjustEndTime(15),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sélecteur d'état
            Text('État', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.schedule.possibleValues.map((pv) {
                final isSelected = pv.value == _selectedValue;
                final color = ScheduleColors.getColorForValue(
                  pv.value,
                  widget.schedule.valueType,
                  colorScheme,
                );

                return ChoiceChip(
                  label: Text(pv.text),
                  selected: isSelected,
                  selectedColor: color,
                  onSelected: (_) => setState(() => _selectedValue = pv.value),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Boutons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final newSlot = TimeSlot(
                        startMinutes: _startMinutes,
                        endMinutes: _endMinutes,
                        value: _selectedValue,
                      );
                      widget.onSave(newSlot);
                    },
                    child: const Text('Enregistrer'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeButton({
    required String label,
    required String time,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: highlight ? colorScheme.primary : colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(8),
          color: highlight ? colorScheme.primaryContainer.withAlpha(50) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.outline,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: highlight ? colorScheme.primary : null,
              ),
            ),
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

  Widget _buildQuickAdjustButtons({
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildQuickButton(
          icon: Icons.remove,
          label: '-15',
          onTap: onMinus,
          colorScheme: colorScheme,
        ),
        const SizedBox(width: 8),
        _buildQuickButton(
          icon: Icons.add,
          label: '+15',
          onTap: onPlus,
          colorScheme: colorScheme,
        ),
      ],
    );
  }

  Widget _buildQuickButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: colorScheme.primary),
              const SizedBox(width: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.add_circle_outline, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Ajouter - ${widget.day.displayName}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sélecteur d'heures avec boutons rapides
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colonne Début
                Expanded(
                  child: Column(
                    children: [
                      _buildTimeButton(
                        label: 'Début',
                        time: formatMinutesOfDay(_startMinutes),
                        onTap: _selectStartTime,
                      ),
                      const SizedBox(height: 6),
                      _buildQuickAdjustButtons(
                        onMinus: () => _adjustStartTime(-15),
                        onPlus: () => _adjustStartTime(15),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 4, right: 4),
                  child: Icon(Icons.arrow_forward, color: colorScheme.outline, size: 20),
                ),
                // Colonne Fin
                Expanded(
                  child: Column(
                    children: [
                      _buildTimeButton(
                        label: 'Fin',
                        time: formatMinutesOfDay(_endMinutes),
                        onTap: _selectEndTime,
                        highlight: _endMinutes >= 1440,
                      ),
                      const SizedBox(height: 6),
                      _buildQuickAdjustButtons(
                        onMinus: () => _adjustEndTime(-15),
                        onPlus: () => _adjustEndTime(15),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sélecteur d'état
            Text('État', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.schedule.possibleValues.map((pv) {
                final isSelected = pv.value == _selectedValue;
                final color = ScheduleColors.getColorForValue(
                  pv.value,
                  widget.schedule.valueType,
                  colorScheme,
                );

                return ChoiceChip(
                  label: Text(pv.text),
                  selected: isSelected,
                  selectedColor: color,
                  onSelected: (_) => setState(() => _selectedValue = pv.value),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Boutons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final newSlot = TimeSlot(
                        startMinutes: _startMinutes,
                        endMinutes: _endMinutes,
                        value: _selectedValue,
                      );
                      widget.onSave(newSlot);
                    },
                    child: const Text('Ajouter'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeButton({
    required String label,
    required String time,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: highlight ? colorScheme.primary : colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(8),
          color: highlight ? colorScheme.primaryContainer.withAlpha(50) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.outline,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: highlight ? colorScheme.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
