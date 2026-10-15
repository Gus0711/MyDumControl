import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/dc_tokens.dart';
import '../../../../domain/models/schedule.dart';
import '../../../../l10n/app_localizations.dart';

/// Localized full day name (e.g. "Lundi" / "Monday").
String weekDayName(AppLocalizations l10n, WeekDay day) {
  switch (day) {
    case WeekDay.monday:
      return l10n.monday;
    case WeekDay.tuesday:
      return l10n.tuesday;
    case WeekDay.wednesday:
      return l10n.wednesday;
    case WeekDay.thursday:
      return l10n.thursday;
    case WeekDay.friday:
      return l10n.friday;
    case WeekDay.saturday:
      return l10n.saturday;
    case WeekDay.sunday:
      return l10n.sunday;
  }
}

/// Localized short day name (e.g. "Lun" / "Mon").
String weekDayShortName(AppLocalizations l10n, WeekDay day) {
  switch (day) {
    case WeekDay.monday:
      return l10n.scheduleDayShortMonday;
    case WeekDay.tuesday:
      return l10n.scheduleDayShortTuesday;
    case WeekDay.wednesday:
      return l10n.scheduleDayShortWednesday;
    case WeekDay.thursday:
      return l10n.scheduleDayShortThursday;
    case WeekDay.friday:
      return l10n.scheduleDayShortFriday;
    case WeekDay.saturday:
      return l10n.scheduleDayShortSaturday;
    case WeekDay.sunday:
      return l10n.scheduleDayShortSunday;
  }
}

/// Couleurs des plannings, tirées de la palette de l'app.
///
/// L'état « arrêt » (faux / index 0) reste neutre ; les états actifs prennent
/// une couleur franche. Pour dessiner un créneau ou une pastille, préférer
/// [blockTone] : fond, bordure et texte restent lisibles en clair et en sombre.
class ScheduleColors {
  ScheduleColors._();

  /// Palette des états énumérés (index 0 = arrêt / défaut, neutre).
  static const List<Color> enumColors = [
    AppColors.disconnected, // index 0 - souvent "off" ou état par défaut
    AppColors.success, // index 1 - souvent "on" ou occupé
    AppColors.brandSky, // index 2
    AppColors.brandOrange, // index 3
    AppColors.brandViolet, // index 4
    AppColors.analogValue, // index 5
    AppColors.binaryOutput, // index 6
    AppColors.multiStateOutput, // index 7
    AppColors.multiStateInput, // index 8
    AppColors.multiStateValue, // index 9
    AppColors.alarmMajor, // index 10
    AppColors.binaryInput, // index 11
  ];

  /// Couleur franche d'un état actif, ou null pour l'état arrêt / défaut.
  static Color? _activeColor(dynamic value, ScheduleValueType valueType) {
    if (valueType == ScheduleValueType.boolean) {
      return (value == true || value == 1 || value == 'active') ? AppColors.success : null;
    }
    final index = value is int ? value : 0;
    if (index <= 0) return null;
    return enumColors[index % enumColors.length];
  }

  /// Récupère la couleur pour une valeur de schedule (pastilles de légende).
  static Color getColorForValue(
    dynamic value,
    ScheduleValueType valueType,
    ColorScheme colorScheme,
  ) {
    if (value == null) {
      return Colors.transparent;
    }
    return _activeColor(value, valueType) ?? colorScheme.surfaceContainerHighest;
  }

  /// Récupère la couleur pour une valeur avec possibilité de null
  static Color? getColorForValueNullable(
    dynamic value,
    ScheduleValueType valueType,
    ColorScheme colorScheme,
  ) {
    if (value == null) return null;
    return getColorForValue(value, valueType, colorScheme);
  }

  /// Ton d'un créneau (fond, bordure, texte) lisible dans le thème courant.
  /// État arrêt / défaut : ton neutre.
  static DcTone blockTone(BuildContext context, dynamic value, ScheduleValueType valueType) {
    final dc = context.dc;
    final color = value == null ? null : _activeColor(value, valueType);
    if (color == null) return dc.neutral;
    final base = dc.toneOf(color);
    return DcTone(
      fg: base.fg,
      bg: color.withValues(alpha: dc.isDark ? 0.26 : 0.18),
      border: color.withValues(alpha: dc.isDark ? 0.75 : 0.65),
    );
  }

  /// Couleur pleine d'un état (liseré des créneaux, pastilles de légende).
  static Color solidColor(BuildContext context, dynamic value, ScheduleValueType valueType) =>
      (value == null ? null : _activeColor(value, valueType)) ?? context.dc.borderStrong;

  /// Récupère la couleur de texte contrastée pour une couleur de fond
  static Color getContrastColor(Color backgroundColor) {
    // Calculer la luminosité
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

/// Petite pastille d'état (légende, sélecteurs) : fond doux et liseré plein.
/// Valeur nulle (« auto ») : contour seul.
class ScheduleSwatch extends StatelessWidget {
  final dynamic value;
  final ScheduleValueType valueType;
  final double width;
  final double height;

  const ScheduleSwatch({
    super.key,
    required this.value,
    required this.valueType,
    this.width = 14,
    this.height = 10,
  });

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    if (value == null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: dc.borderStrong),
        ),
      );
    }
    final tone = ScheduleColors.blockTone(context, value, valueType);
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Container(
        width: width,
        height: height,
        color: tone.bg,
        alignment: Alignment.centerLeft,
        child: Container(width: 3, color: ScheduleColors.solidColor(context, value, valueType)),
      ),
    );
  }
}
