import 'package:flutter/material.dart';
import '../../../../domain/models/schedule.dart';
import 'schedule_colors.dart';

/// Vue hebdomadaire du planning avec timeline visuelle
class WeeklyScheduleView extends StatefulWidget {
  final Schedule schedule;

  const WeeklyScheduleView({
    super.key,
    required this.schedule,
  });

  @override
  State<WeeklyScheduleView> createState() => _WeeklyScheduleViewState();
}

class _WeeklyScheduleViewState extends State<WeeklyScheduleView> {
  WeekDay? _selectedDay;
  final ScrollController _scrollController = ScrollController();

  // Heures à afficher (0-24)
  static const int startHour = 0;
  static const int endHour = 24;
  static const double hourWidth = 60.0;
  static const double dayLabelWidth = 50.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Vue principale scrollable
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: dayLabelWidth + (endHour - startHour) * hourWidth,
              child: Column(
                children: [
                  // En-tête avec les heures
                  _buildTimeHeader(theme, colorScheme),

                  // Grille des jours
                  Expanded(
                    child: ListView.builder(
                      itemCount: WeekDay.values.length,
                      itemBuilder: (context, index) {
                        final day = WeekDay.values[index];
                        return _buildDayRow(context, day, theme, colorScheme);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Détails du jour sélectionné
        if (_selectedDay != null)
          _buildDayDetails(context, _selectedDay!, theme, colorScheme),
      ],
    );
  }

  Widget _buildTimeHeader(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          // Espace pour les labels des jours
          SizedBox(width: dayLabelWidth),

          // Labels des heures
          for (int hour = startHour; hour < endHour; hour++)
            SizedBox(
              width: hourWidth,
              child: Text(
                '${hour.toString().padLeft(2, '0')}h',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayRow(
    BuildContext context,
    WeekDay day,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final daySchedule = widget.schedule.weeklySchedule.getDay(day);
    final isSelected = _selectedDay == day;
    final isWeekend = day == WeekDay.saturday || day == WeekDay.sunday;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDay = _selectedDay == day ? null : day;
        });
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
              : (isWeekend
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                  : null),
          border: Border(
            bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
        ),
        child: Row(
          children: [
            // Label du jour
            Container(
              width: dayLabelWidth,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                day.shortName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isWeekend ? colorScheme.outline : null,
                ),
              ),
            ),

            // Timeline du jour
            Expanded(
              child: CustomPaint(
                painter: _DayTimelinePainter(
                  schedule: widget.schedule,
                  daySchedule: daySchedule,
                  colorScheme: colorScheme,
                  hourWidth: hourWidth,
                  startHour: startHour,
                  endHour: endHour,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayDetails(
    BuildContext context,
    WeekDay day,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final daySchedule = widget.schedule.weeklySchedule.getDay(day);
    final transitions = daySchedule.sortedTransitions;

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
          Row(
            children: [
              Icon(Icons.calendar_today, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                day.displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _selectedDay = null),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Fermer'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (transitions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Aucune transition programmée',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: transitions.length,
                itemBuilder: (context, index) {
                  final transition = transitions[index];
                  return _buildTransitionTile(
                    context,
                    transition,
                    index,
                    theme,
                    colorScheme,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransitionTile(
    BuildContext context,
    ScheduleTransition transition,
    int index,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final stateText = widget.schedule.getStateText(transition.value);
    final color = _getColorForValue(transition.value, colorScheme);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Heure
          SizedBox(
            width: 70,
            child: Text(
              transition.formattedTime,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
              ),
            ),
          ),

          // Flèche
          Icon(
            Icons.arrow_forward,
            size: 16,
            color: colorScheme.outline,
          ),
          const SizedBox(width: 8),

          // Indicateur de couleur
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: transition.value == null
                  ? Border.all(color: colorScheme.outline)
                  : null,
            ),
          ),
          const SizedBox(width: 8),

          // Texte de l'état
          Expanded(
            child: Text(
              stateText,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForValue(dynamic value, ColorScheme colorScheme) {
    return ScheduleColors.getColorForValue(value, widget.schedule.valueType, colorScheme);
  }
}

/// Painter pour dessiner la timeline d'un jour
class _DayTimelinePainter extends CustomPainter {
  final Schedule schedule;
  final DaySchedule daySchedule;
  final ColorScheme colorScheme;
  final double hourWidth;
  final int startHour;
  final int endHour;

  _DayTimelinePainter({
    required this.schedule,
    required this.daySchedule,
    required this.colorScheme,
    required this.hourWidth,
    required this.startHour,
    required this.endHour,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dessiner le fond par défaut (état null/auto)
    final bgPaint = Paint()
      ..color = colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 4, size.width, size.height - 8),
      bgPaint,
    );

    // Dessiner les lignes verticales pour chaque heure
    final gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    for (int hour = startHour; hour <= endHour; hour++) {
      final x = (hour - startHour) * hourWidth;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    // Convertir les transitions en créneaux pour un affichage correct
    // (gère les chevauchements et le découpage)
    final slots = TimeSlotConverter.transitionsToSlots(daySchedule.sortedTransitions);
    if (slots.isEmpty) return;

    // Dessiner chaque créneau
    for (final slot in slots) {
      final startX = _timeToX(slot.startMinutes, size.width);
      final endX = _timeToX(slot.endMinutes, size.width);
      _drawSegment(canvas, startX, endX, size.height, slot.value);
    }

    // Dessiner les marqueurs aux limites des créneaux
    for (final slot in slots) {
      final startX = _timeToX(slot.startMinutes, size.width);
      final endX = _timeToX(slot.endMinutes, size.width);
      _drawTransitionMarker(canvas, startX, size.height, slot.value);
      // Marqueur de fin (optionnel, pour voir la limite)
      if (slot.endMinutes < 1440) {
        _drawTransitionMarker(canvas, endX, size.height, null);
      }
    }
  }

  void _drawSegment(Canvas canvas, double startX, double endX, double height, dynamic value) {
    final color = _getColorForValue(value);
    if (color == null) return;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(startX, 4, endX - startX, height - 8),
      const Radius.circular(4),
    );

    canvas.drawRRect(rect, paint);
  }

  void _drawTransitionMarker(Canvas canvas, double x, double height, dynamic value) {
    final color = _getColorForValue(value) ?? colorScheme.outline;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Ligne verticale
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, height),
      paint,
    );

    // Petit cercle en haut
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x, 8), 4, circlePaint);
  }

  double _timeToX(int timeInMinutes, double totalWidth) {
    final totalMinutes = (endHour - startHour) * 60;
    return (timeInMinutes / totalMinutes) * totalWidth;
  }

  Color? _getColorForValue(dynamic value) {
    if (value == null) return null;
    return ScheduleColors.getColorForValue(value, schedule.valueType, colorScheme);
  }

  @override
  bool shouldRepaint(covariant _DayTimelinePainter oldDelegate) {
    return oldDelegate.daySchedule != daySchedule ||
        oldDelegate.colorScheme != colorScheme;
  }
}
