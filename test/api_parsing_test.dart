import 'package:flutter_test/flutter_test.dart';
import 'package:myglobaldc/data/services/api_service.dart';
import 'package:myglobaldc/data/services/api_type_names.dart';
import 'package:myglobaldc/domain/models/bacnet_object.dart';
import 'package:myglobaldc/domain/models/schedule.dart';

void main() {
  group('ApiTypeNames', () {
    test('V1 names use lower-case "multistate"', () {
      expect(ApiTypeNames.v1Name(BacnetObjectType.multiStateValue), 'multistateValue');
      expect(ApiTypeNames.v1Name(BacnetObjectType.analogInput), 'analogInput');
      expect(ApiTypeNames.v1Name(BacnetObjectType.trendLog), 'trendLog');
    });

    test('fromV1Name is case-insensitive', () {
      expect(ApiTypeNames.fromV1Name('multistateValue'), BacnetObjectType.multiStateValue);
      expect(ApiTypeNames.fromV1Name('multiStateInput'), BacnetObjectType.multiStateInput);
      expect(ApiTypeNames.fromV1Name('BINARYOUTPUT'), BacnetObjectType.binaryOutput);
      expect(ApiTypeNames.fromV1Name('unknown'), isNull);
    });

    test('paths per API version', () {
      expect(ApiTypeNames.v1Path(BacnetObjectType.analogValue), 'analog-value');
      expect(ApiTypeNames.v2Path(BacnetObjectType.analogValue), 'analog-values');
      expect(ApiTypeNames.v2Path(BacnetObjectType.multiStateInput), 'multi-state-inputs');
      expect(ApiTypeNames.v2Path(BacnetObjectType.trendLog), 'trend-logs');
      expect(ApiTypeNames.fromV2Path('multi-state-values'), BacnetObjectType.multiStateValue);
    });
  });

  group('ApiException', () {
    test('401/403 map to ApiAuthException', () {
      expect(ApiException.fromStatus(401), isA<ApiAuthException>());
      expect(ApiException.fromStatus(403), isA<ApiAuthException>());
      final notFound = ApiException.fromStatus(404);
      expect(notFound, isNot(isA<ApiAuthException>()));
      expect(notFound.statusCode, 404);
    });
  });

  group('V1 read-property-multiple parsing', () {
    test('summary counts multistate objects returned as multistateValue', () {
      final summary = ConnectedApiClient.parseObjectsSummaryFromRpm({
        'propertyReferences': [
          {'type': 'multistateValue', 'instance': 1, 'property': 'objectName', 'value': 'A'},
          {'type': 'multistateValue', 'instance': 2, 'property': 'objectName', 'value': 'B'},
          {'type': 'analogInput', 'instance': 1, 'property': 'objectName', 'value': 'C'},
          // Request echo / no object: must not be counted
          {'type': 'binaryValue', 'instance': -1, 'property': 'objectName', 'message': 'err'},
        ],
      });
      expect(summary.multiStateValues, 2);
      expect(summary.analogInputs, 1);
      expect(summary.binaryValues, 0);
    });

    test('super-favorites keep the original pointRef for multistate types', () {
      final grouped = ConnectedApiClient.groupRpmPropertiesByObject([
        {'type': 'multistateValue', 'instance': 3, 'property': 'objectName', 'value': 'Mode'},
        {'type': 'multistateValue', 'instance': 3, 'property': 'presentValue', 'value': '2'},
        {'type': 'analogValue', 'instance': 1, 'property': 'presentValue', 'value': {'value': '21.5'}},
      ]);
      final points = ConnectedApiClient.buildMultiplePointsFromGrouped(
        grouped,
        ['MSV:3', 'analog-value:1'],
      );
      expect(points.keys, containsAll(['MSV:3', 'analog-value:1']));
      expect(points['MSV:3']!.objectName, 'Mode');
      expect(points['MSV:3']!.presentValue, 2);
      expect(points['analog-value:1']!.presentValue, 21.5);
    });

    test('trend-log mapping V1', () {
      final mapping = ConnectedApiClient.parseTrendLogMappingV1({
        'propertyReferences': [
          {'type': 'trendLog', 'instance': 300672, 'property': 'logDeviceObjectProperty', 'value': '[Analog Value 454,Present Value,,]'},
          {'type': 'trendLog', 'instance': -1, 'property': 'logDeviceObjectProperty', 'value': '[Analog Value 1,Present Value,,]'},
        ],
      });
      expect(mapping, {'analog-value:454': 300672});
    });

    test('trend-log mapping V2', () {
      final mapping = ConnectedApiClient.parseTrendLogMappingV2({
        '5': {
          'source-reference': {
            'object-identifier': {'object-type': 'MultiStateValue', 'object-instance': 17},
          },
        },
        'x': {},
      });
      expect(mapping, {'multi-state-value:17': 5});
    });
  });

  group('forceInput V1', () {
    test('single write-property-multiple with out-of-service then present-value', () {
      final body = ConnectedApiClient.buildForceInputV1Body(BacnetObjectType.binaryInput, 4, true);
      final refs = body['propertyReferences'] as List;
      expect(refs, hasLength(2));
      expect(refs[0], containsPair('property', 'outOfService'));
      expect(refs[0], containsPair('value', 'true'));
      expect(refs[1], containsPair('property', 'presentValue'));
      expect(refs[1], containsPair('value', 'active'));
      expect(refs[1], containsPair('type', 'binaryInput'));
    });
  });

  group('weekly-schedule response', () {
    test('never substitutes an empty planning for an unreadable one', () {
      expect(ConnectedApiClient.parseWeeklyScheduleResponse(404, null, WeeklySchedule.fromV2), isNull);
      expect(ConnectedApiClient.parseWeeklyScheduleResponse(401, {'monday': {}}, WeeklySchedule.fromV2), isNull);
      expect(ConnectedApiClient.parseWeeklyScheduleResponse(200, 'oops', WeeklySchedule.fromV2), isNull);
      expect(ConnectedApiClient.parseWeeklyScheduleResponse(200, <String, dynamic>{}, WeeklySchedule.fromV2), isNotNull);
    });
  });
}
