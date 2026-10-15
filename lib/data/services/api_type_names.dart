import '../../domain/models/bacnet_object.dart';

/// Single source of truth for the BACnet object type names used by the
/// Distech REST API.
///
/// - V1 request bodies (read/write-property-multiple) use camelCase names,
///   with a lower-case "s" for multi-state types: `multistateValue`
///   (see docs/docs_API_Distech/v1/Protocols.md).
/// - V1 URL paths use the kebab-case singular name (`analog-value`), which is
///   [BacnetObjectType.apiName].
/// - V2 URL paths use the kebab-case plural name (`analog-values`).
class ApiTypeNames {
  ApiTypeNames._();

  static const Map<BacnetObjectType, String> _v1Names = {
    BacnetObjectType.analogInput: 'analogInput',
    BacnetObjectType.analogOutput: 'analogOutput',
    BacnetObjectType.analogValue: 'analogValue',
    BacnetObjectType.binaryInput: 'binaryInput',
    BacnetObjectType.binaryOutput: 'binaryOutput',
    BacnetObjectType.binaryValue: 'binaryValue',
    BacnetObjectType.multiStateInput: 'multistateInput',
    BacnetObjectType.multiStateOutput: 'multistateOutput',
    BacnetObjectType.multiStateValue: 'multistateValue',
    BacnetObjectType.schedule: 'schedule',
    BacnetObjectType.calendar: 'calendar',
    BacnetObjectType.trendLog: 'trendLog',
    BacnetObjectType.notificationClass: 'notificationClass',
    BacnetObjectType.device: 'device',
  };

  static const Map<BacnetObjectType, String> _v2Paths = {
    BacnetObjectType.analogInput: 'analog-inputs',
    BacnetObjectType.analogOutput: 'analog-outputs',
    BacnetObjectType.analogValue: 'analog-values',
    BacnetObjectType.binaryInput: 'binary-inputs',
    BacnetObjectType.binaryOutput: 'binary-outputs',
    BacnetObjectType.binaryValue: 'binary-values',
    BacnetObjectType.multiStateInput: 'multi-state-inputs',
    BacnetObjectType.multiStateOutput: 'multi-state-outputs',
    BacnetObjectType.multiStateValue: 'multi-state-values',
    BacnetObjectType.schedule: 'schedules',
    BacnetObjectType.calendar: 'calendars',
    BacnetObjectType.trendLog: 'trend-logs',
    BacnetObjectType.notificationClass: 'notification-classes',
    BacnetObjectType.device: 'devices',
  };

  /// Point types (inputs, outputs, values) handled by the points screens.
  static const List<BacnetObjectType> pointTypes = [
    BacnetObjectType.analogInput,
    BacnetObjectType.analogOutput,
    BacnetObjectType.analogValue,
    BacnetObjectType.binaryInput,
    BacnetObjectType.binaryOutput,
    BacnetObjectType.binaryValue,
    BacnetObjectType.multiStateInput,
    BacnetObjectType.multiStateOutput,
    BacnetObjectType.multiStateValue,
  ];

  /// V1 type name for request bodies (camelCase, e.g. `multistateValue`).
  static String v1Name(BacnetObjectType type) => _v1Names[type] ?? type.name;

  /// V1 URL path segment (kebab-case singular, e.g. `analog-value`).
  static String v1Path(BacnetObjectType type) => type.apiName;

  /// V2 URL path segment (kebab-case plural, e.g. `multi-state-values`).
  static String v2Path(BacnetObjectType type) => _v2Paths[type] ?? '${type.apiName}s';

  /// Parses a V1 type name, case-insensitively, so that both `multistateValue`
  /// (API) and `multiStateValue` (enum name) are accepted.
  static BacnetObjectType? fromV1Name(String name) {
    final lower = name.toLowerCase();
    for (final entry in _v1Names.entries) {
      if (entry.value.toLowerCase() == lower) return entry.key;
    }
    return null;
  }

  /// Parses a V2 plural path segment (e.g. `analog-inputs`).
  static BacnetObjectType? fromV2Path(String path) {
    for (final entry in _v2Paths.entries) {
      if (entry.value == path) return entry.key;
    }
    return null;
  }

  /// Normalized `type:instance` key, independent of the API naming style.
  static String objectKey(BacnetObjectType type, int instance) => '${type.apiName}:$instance';
}
