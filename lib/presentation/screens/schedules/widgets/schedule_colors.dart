import 'package:flutter/material.dart';
import '../../../../domain/models/schedule.dart';

/// Utilitaire pour les couleurs des schedules
class ScheduleColors {
  ScheduleColors._();

  /// Palette de couleurs pour les états énumérés (10+ couleurs distinctes)
  static const List<Color> enumColors = [
    Color(0xFF90CAF9), // Bleu clair (index 0 - souvent "off" ou état par défaut)
    Color(0xFF4CAF50), // Vert (index 1 - souvent "on" ou actif)
    Color(0xFFFF9800), // Orange (index 2)
    Color(0xFF9C27B0), // Violet (index 3)
    Color(0xFF00BCD4), // Cyan (index 4)
    Color(0xFFE91E63), // Rose (index 5)
    Color(0xFF8BC34A), // Vert clair (index 6)
    Color(0xFFFF5722), // Orange foncé (index 7)
    Color(0xFF673AB7), // Violet foncé (index 8)
    Color(0xFF009688), // Teal (index 9)
    Color(0xFFFFC107), // Ambre (index 10)
    Color(0xFF3F51B5), // Indigo (index 11)
  ];

  /// Récupère la couleur pour une valeur de schedule
  static Color getColorForValue(
    dynamic value,
    ScheduleValueType valueType,
    ColorScheme colorScheme,
  ) {
    if (value == null) {
      return Colors.transparent;
    }

    if (valueType == ScheduleValueType.boolean) {
      if (value == true || value == 1 || value == 'active') {
        return colorScheme.primary;
      } else {
        return colorScheme.surfaceContainerHighest;
      }
    }

    // Pour les énumérés, utiliser la palette étendue
    final index = value is int ? value : 0;

    // Utiliser la couleur du thème pour l'index 0 si c'est l'état "off"
    if (index == 0) {
      return colorScheme.surfaceContainerHighest;
    }

    // Pour les autres indices, utiliser la palette
    // L'index 1 commence à enumColors[1] pour avoir le vert
    if (index > 0 && index < enumColors.length) {
      return enumColors[index];
    }

    // Pour les indices au-delà de la palette, cycler
    return enumColors[index % enumColors.length];
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

  /// Récupère la couleur de texte contrastée pour une couleur de fond
  static Color getContrastColor(Color backgroundColor) {
    // Calculer la luminosité
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
