import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/dc_tokens.dart';
import '../../../domain/models/bacnet_object.dart';
import '../../../domain/models/display_preferences.dart';
import '../../../l10n/app_localizations.dart';

/// Utilitaires partagés pour les types BACnet
/// Élimine la duplication de code entre les différents écrans
class BacnetTypeUtils {
  BacnetTypeUtils._();

  /// Retourne l'icône associée à un type BACnet (depuis un String)
  static IconData getIconForType(String typeString) {
    final type = BacnetObjectType.fromApiName(typeString);
    if (type == null) return Icons.device_unknown;
    return getTypeIcon(type);
  }

  /// Retourne l'icône associée à un type BACnet
  static IconData getTypeIcon(BacnetObjectType type) {
    switch (type) {
      case BacnetObjectType.analogInput:
        return Icons.input;
      case BacnetObjectType.analogOutput:
        return Icons.output;
      case BacnetObjectType.analogValue:
        return Icons.speed;
      case BacnetObjectType.binaryInput:
        return Icons.toggle_off;
      case BacnetObjectType.binaryOutput:
        return Icons.toggle_on;
      case BacnetObjectType.binaryValue:
        return Icons.radio_button_checked;
      case BacnetObjectType.multiStateInput:
        return Icons.list;
      case BacnetObjectType.multiStateOutput:
        return Icons.list_alt;
      case BacnetObjectType.multiStateValue:
        return Icons.format_list_numbered;
      default:
        return Icons.device_unknown;
    }
  }

  /// Returns the localized display name of a BACnet object type
  static String getTypeDisplayName(AppLocalizations l10n, BacnetObjectType type) {
    switch (type) {
      case BacnetObjectType.analogInput:
        return l10n.bacnetTypeAnalogInput;
      case BacnetObjectType.analogOutput:
        return l10n.bacnetTypeAnalogOutput;
      case BacnetObjectType.analogValue:
        return l10n.bacnetTypeAnalogValue;
      case BacnetObjectType.binaryInput:
        return l10n.bacnetTypeBinaryInput;
      case BacnetObjectType.binaryOutput:
        return l10n.bacnetTypeBinaryOutput;
      case BacnetObjectType.binaryValue:
        return l10n.bacnetTypeBinaryValue;
      case BacnetObjectType.multiStateInput:
        return l10n.bacnetTypeMultiStateInput;
      case BacnetObjectType.multiStateOutput:
        return l10n.bacnetTypeMultiStateOutput;
      case BacnetObjectType.multiStateValue:
        return l10n.bacnetTypeMultiStateValue;
      case BacnetObjectType.schedule:
        return l10n.bacnetTypeSchedule;
      case BacnetObjectType.calendar:
        return l10n.bacnetTypeCalendar;
      case BacnetObjectType.trendLog:
        return l10n.bacnetTypeTrendLog;
      case BacnetObjectType.notificationClass:
        return l10n.bacnetTypeNotificationClass;
      case BacnetObjectType.device:
        return l10n.bacnetTypeDevice;
    }
  }

  /// Retourne la couleur associée à un type BACnet (palette de l'app).
  /// Entrées : teintes froides ; sorties : teintes chaudes ; variables :
  /// teintes intermédiaires. Pour un texte ou un fond, préférer
  /// [typeTone], qui s'adapte au thème clair/sombre.
  static Color getTypeColor(BacnetObjectType type) {
    switch (type) {
      case BacnetObjectType.analogInput:
        return AppColors.analogInput;
      case BacnetObjectType.binaryInput:
        return AppColors.binaryInput;
      case BacnetObjectType.multiStateInput:
        return AppColors.multiStateInput;
      case BacnetObjectType.analogOutput:
        return AppColors.analogOutput;
      case BacnetObjectType.binaryOutput:
        return AppColors.binaryOutput;
      case BacnetObjectType.multiStateOutput:
        return AppColors.multiStateOutput;
      case BacnetObjectType.analogValue:
        return AppColors.analogValue;
      case BacnetObjectType.binaryValue:
        return AppColors.binaryValue;
      case BacnetObjectType.multiStateValue:
        return AppColors.multiStateValue;
      default:
        return AppColors.disconnected;
    }
  }

  /// Ton (texte, fond, bordure) d'un type BACnet, lisible dans le thème courant.
  static DcTone typeTone(BuildContext context, BacnetObjectType type) =>
      context.dc.toneOf(getTypeColor(type));

  /// Ton de la valeur d'un point : entrée hors service / forçage (orange),
  /// binaire actif (vert), inactif ou absent (neutre), autre (accent).
  static DcTone valueTone(BuildContext context, BacnetObject point) {
    final dc = context.dc;
    if (point.outOfService == true) return dc.overrideTone;
    final value = point.presentValue;
    if (value == null) return dc.neutral;
    if (point.type.isBinary) {
      return isBinaryActive(value) ? dc.success : dc.neutral;
    }
    return dc.accentTone;
  }

  /// Vérifie si une valeur binaire est active
  static bool isBinaryActive(dynamic value) => BacnetObject.isBinaryValueActive(value);

  /// Formate une valeur pour l'affichage
  static String formatValue(BacnetObject point) {
    final value = point.presentValue;
    if (value == null) return '---';

    if (point.type.isBinary) {
      final isActive = isBinaryActive(value);
      if (isActive) {
        return point.activeText ?? 'ON';
      } else {
        return point.inactiveText ?? 'OFF';
      }
    }

    // Multistate : afficher "libellé (valeur)"
    if (point.type.isMultiState) {
      return formatMultiStateValue(point);
    }

    if (value is num) {
      return DisplayPreferences.formatAnalog(value, point.units);
    }

    return value.toString();
  }

  /// Formate une valeur multistate : "libellé (valeur)" ou juste "valeur" si pas de libellé
  static String formatMultiStateValue(BacnetObject point) {
    final value = point.presentValue;
    if (value == null) return '---';

    // Convertir la valeur en int
    final int stateIndex;
    if (value is int) {
      stateIndex = value;
    } else if (value is num) {
      stateIndex = value.toInt();
    } else {
      return value.toString();
    }

    // BACnet multistate est indexé à partir de 1
    // stateText[0] = état 1, stateText[1] = état 2, etc.
    if (point.stateText != null && point.stateText!.isNotEmpty) {
      final arrayIndex = stateIndex - 1;
      if (arrayIndex >= 0 && arrayIndex < point.stateText!.length) {
        final label = point.stateText![arrayIndex];
        return '$label ($stateIndex)';
      }
    }

    // Pas de libellé disponible, afficher juste la valeur
    return stateIndex.toString();
  }

  /// Formate une valeur de forçage pour l'affichage
  static String formatOverrideValue(BacnetObject point) {
    final isInputForced = point.type.isInput && point.outOfService == true;
    final value = isInputForced ? point.presentValue : point.overrideValue;
    if (value == null) return '-';

    if (point.type.isBinary) {
      final isActive = isBinaryActive(value);
      if (isActive) {
        return point.activeText ?? 'ON';
      } else {
        return point.inactiveText ?? 'OFF';
      }
    }

    // Multistate : afficher "libellé (valeur)"
    if (point.type.isMultiState) {
      return formatMultiStateValueFromRaw(value, point.stateText);
    }

    if (value is num) {
      return DisplayPreferences.formatAnalog(value, point.units);
    }

    return value.toString();
  }

  /// Formate une valeur multistate brute : "libellé (valeur)" ou juste "valeur"
  static String formatMultiStateValueFromRaw(dynamic value, List<String>? stateText) {
    if (value == null) return '-';

    // Convertir la valeur en int
    final int stateIndex;
    if (value is int) {
      stateIndex = value;
    } else if (value is num) {
      stateIndex = value.toInt();
    } else {
      return value.toString();
    }

    if (stateText != null && stateText.isNotEmpty) {
      final arrayIndex = stateIndex - 1;
      if (arrayIndex >= 0 && arrayIndex < stateText.length) {
        final label = stateText[arrayIndex];
        return '$label ($stateIndex)';
      }
    }

    return stateIndex.toString();
  }

  /// Retourne la couleur de la valeur d'un point
  /// Préférer [valueTone] (adapté au thème).
  static Color getValueColor(BacnetObject point) {
    if (point.outOfService == true) return AppColors.overrideActive;

    final value = point.presentValue;
    if (value == null) return AppColors.disconnected;

    if (point.type.isBinary) {
      return isBinaryActive(value) ? AppColors.success : AppColors.disconnected;
    }

    return AppColors.brandSky;
  }
}
