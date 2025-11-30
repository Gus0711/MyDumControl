import 'package:flutter/material.dart';
import '../../../domain/models/bacnet_object.dart';

/// Utilitaires partagés pour les types BACnet
/// Élimine la duplication de code entre les différents écrans
class BacnetTypeUtils {
  BacnetTypeUtils._();

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
  /// - Bleu pour les Inputs
  /// - Orange pour les Outputs
  /// - Vert pour les Values
  static Color getTypeColor(BacnetObjectType type) {
    switch (type) {
      case BacnetObjectType.analogInput:
      case BacnetObjectType.binaryInput:
      case BacnetObjectType.multiStateInput:
        return Colors.blue;
      case BacnetObjectType.analogOutput:
      case BacnetObjectType.binaryOutput:
      case BacnetObjectType.multiStateOutput:
        return Colors.orange;
      case BacnetObjectType.analogValue:
      case BacnetObjectType.binaryValue:
      case BacnetObjectType.multiStateValue:
        return Colors.green;
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

    if (value is num) {
      final formatted = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
      if (point.units != null && point.units!.isNotEmpty) {
        return '$formatted ${point.units}';
      }
      return formatted;
    }

    return value.toString();
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

    if (value is num) {
      final formatted = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
      if (point.units != null && point.units!.isNotEmpty) {
        return '$formatted ${point.units}';
      }
      return formatted;
    }

    return value.toString();
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
