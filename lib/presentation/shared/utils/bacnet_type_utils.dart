import 'package:flutter/material.dart';
import '../../../domain/models/bacnet_object.dart';

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

  /// Retourne la couleur associée à un type BACnet
  /// Chaque type a une couleur unique pour une meilleure différenciation visuelle :
  /// - AI (Analog Input)    : Vert - mesures/capteurs analogiques
  /// - BI (Binary Input)    : Bleu - états binaires en lecture
  /// - AO (Analog Output)   : Orange - commandes analogiques
  /// - BO (Binary Output)   : Rouge/Rose - commandes binaires
  /// - AV (Analog Value)    : Cyan - variables analogiques internes
  /// - BV (Binary Value)    : Violet - variables binaires internes
  /// - MSI (MultiState In)  : Indigo - états multiples en lecture
  /// - MSO (MultiState Out) : Ambre - commandes multi-états
  /// - MSV (MultiState Val) : Teal - variables multi-états
  static Color getTypeColor(BacnetObjectType type) {
    switch (type) {
      // Inputs - teintes froides (lecture seule)
      case BacnetObjectType.analogInput:
        return Colors.green;           // AI - Vert
      case BacnetObjectType.binaryInput:
        return Colors.blue;            // BI - Bleu
      case BacnetObjectType.multiStateInput:
        return Colors.indigo;          // MSI - Indigo
      // Outputs - teintes chaudes (commandes)
      case BacnetObjectType.analogOutput:
        return Colors.orange;          // AO - Orange
      case BacnetObjectType.binaryOutput:
        return Colors.pink;            // BO - Rose
      case BacnetObjectType.multiStateOutput:
        return Colors.amber;           // MSO - Ambre
      // Values - teintes intermédiaires (variables internes)
      case BacnetObjectType.analogValue:
        return Colors.cyan;            // AV - Cyan
      case BacnetObjectType.binaryValue:
        return Colors.purple;          // BV - Violet
      case BacnetObjectType.multiStateValue:
        return Colors.teal;            // MSV - Teal
      default:
        return Colors.grey;
    }
  }

  /// Vérifie si une valeur binaire est active
  static bool isBinaryActive(dynamic value) {
    if (value == null) return false;
    if (value == true) return true;
    if (value == 1) return true;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'active' || lower == 'true' || lower == '1' || lower == 'on';
    }
    return false;
  }

  /// Vérifie si un type BACnet est un type "point" (pas device, schedule, etc.)
  static bool isPointType(BacnetObjectType type) {
    return const [
      BacnetObjectType.analogInput,
      BacnetObjectType.analogOutput,
      BacnetObjectType.analogValue,
      BacnetObjectType.binaryInput,
      BacnetObjectType.binaryOutput,
      BacnetObjectType.binaryValue,
      BacnetObjectType.multiStateInput,
      BacnetObjectType.multiStateOutput,
      BacnetObjectType.multiStateValue,
    ].contains(type);
  }

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
      final formatted = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
      if (point.units != null && point.units!.isNotEmpty) {
        return '$formatted ${point.units}';
      }
      return formatted;
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
      final formatted = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
      if (point.units != null && point.units!.isNotEmpty) {
        return '$formatted ${point.units}';
      }
      return formatted;
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
  static Color getValueColor(BacnetObject point) {
    if (point.outOfService == true) return Colors.orange;

    final value = point.presentValue;
    if (value == null) return Colors.grey;

    if (point.type.isBinary) {
      return isBinaryActive(value) ? Colors.green : Colors.grey;
    }

    return Colors.blue;
  }
}
