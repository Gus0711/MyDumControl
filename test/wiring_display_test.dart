import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myglobaldc/application/providers/schedule_provider.dart';
import 'package:myglobaldc/application/providers/super_favorites_provider.dart';
import 'package:myglobaldc/application/providers/trend_log_provider.dart';
import 'package:myglobaldc/data/services/api_service.dart';
import 'package:myglobaldc/domain/models/bacnet_object.dart';
import 'package:myglobaldc/domain/models/display_preferences.dart';
import 'package:myglobaldc/domain/models/network_interface_choice.dart';
import 'package:myglobaldc/domain/models/schedule.dart';

BacnetObject _analog(num value, String? units) => BacnetObject(
      type: BacnetObjectType.analogValue,
      instance: 1,
      objectName: 'AV1',
      presentValue: value,
      units: units,
    );

void main() {
  tearDown(DisplayPreferences.reset);

  group('DisplayPreferences / formattedValue', () {
    test('defaults keep the historical format', () {
      expect(_analog(21, '°C').formattedValue, '21 °C');
      expect(_analog(21.456, '°C').formattedValue, '21.46 °C');
      expect(_analog(3.5, null).formattedValue, '3.50');
    });

    test('decimal places setting is applied', () {
      DisplayPreferences.apply(decimalPlaces: 1, temperatureUnit: 'celsius', use24HourFormat: true);
      expect(_analog(21.456, '°C').formattedValue, '21.5 °C');
      expect(_analog(40, '%').formattedValue, '40 %');
    });

    test('fahrenheit converts only °C values', () {
      DisplayPreferences.apply(decimalPlaces: 1, temperatureUnit: 'fahrenheit', use24HourFormat: true);
      expect(_analog(20, '°C').formattedValue, '68 °F');
      expect(_analog(21, '°C').formattedValue, '69.8 °F');
      expect(_analog(2, 'Δ°C').formattedValue, '2 Δ°C');
      expect(_analog(50, '%').formattedValue, '50 %');
    });

    test('12-hour clock for schedule times', () {
      final t = ScheduleTransition(time: '14:30:00.00', value: 1);
      expect(t.formattedTime, '14:30');
      final slot = TimeSlot(startMinutes: 0, endMinutes: 1440, value: 1);
      expect(slot.formattedStart, '00:00');
      expect(slot.formattedEnd, '24:00');

      DisplayPreferences.apply(decimalPlaces: 2, temperatureUnit: 'celsius', use24HourFormat: false);
      expect(t.formattedTime, '2:30 PM');
      expect(slot.formattedStart, '12:00 AM');
      expect(DisplayPreferences.formatHourMinute(12, 5), '12:05 PM');
    });
  });

  test('prefixToSubnetMask', () {
    expect(NetworkInterfaceChoice.prefixToSubnetMask(24), '255.255.255.0');
    expect(NetworkInterfaceChoice.prefixToSubnetMask(23), '255.255.254.0');
    expect(NetworkInterfaceChoice.prefixToSubnetMask(0), '0.0.0.0');
  });

  group('trend buffer data', () {
    test('empty detection', () {
      expect(isTrendLogBufferDataEmpty(null), isTrue);
      expect(isTrendLogBufferDataEmpty('  '), isTrue);
      expect(isTrendLogBufferDataEmpty(const []), isTrue);
      expect(isTrendLogBufferDataEmpty(const {}), isTrue);
      expect(isTrendLogBufferDataEmpty(const [1]), isFalse);
    });

    test('decoded JSON is parsed without re-encoding', () {
      final data = parseTrendLogBufferData([
        {'timeStamp': '2026-01-01T10:00:00Z', 'value': 21.5, 'type': 2},
        {'timeStamp': '2026-01-01T10:15:00Z', 'value': 22.0, 'type': 2},
      ]);
      expect(data.records, hasLength(2));
      expect(data.records.first.numericValue, 21.5);
    });
  });

  group('throwIfAuthFailed', () {
    late HttpServer server;
    late ConnectedApiClient client;
    // 401 on the paths matching this predicate, 200 (empty JSON) elsewhere
    var unauthorized = (String path) => true;

    setUp(() async {
      unauthorized = (_) => true;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((r) async {
        if (unauthorized(r.uri.path)) {
          r.response.statusCode = 401;
        } else {
          r.response.headers.contentType = ContentType.json;
          r.response.write('{}');
        }
        await r.response.close();
      });
      client = ConnectedApiClient(
        baseUrl: 'http://${server.address.host}:${server.port}',
        basicAuth: 'Basic dGVzdDp0ZXN0',
        apiVersion: 'V2',
      );
    });

    tearDown(() async {
      client.dispose();
      await server.close(force: true);
    });

    test('empty result caused by 401 throws an auth error', () async {
      client.clearLastError();
      final schedules = await client.getSchedules();
      expect(schedules, isEmpty);
      expect(
        () => throwIfAuthFailed(isEmpty: schedules.isEmpty, client: client),
        throwsA(isA<ApiAuthException>()),
      );
    });

    test('no error when the result is not empty or no auth failure', () {
      client.clearLastError();
      expect(() => throwIfAuthFailed(isEmpty: true, client: client), returnsNormally);
    });

    test('a 401 on a parallel annex request is not a schedules auth error', () async {
      unauthorized = (path) => path.contains('/platform');
      client.clearLastError();
      final results = await Future.wait([
        client.getSchedules(),
        client.getControllerTime().then((_) {}, onError: (_) {}),
      ]);
      final schedules = results[0] as List<ScheduleSummary>;
      expect(schedules, isEmpty);
      expect(() => throwIfAuthFailed(isEmpty: true, client: client), returnsNormally);
    });

    test('super-favorites: annex 401 is ignored, objects 401 reported only if no point read', () async {
      unauthorized = (path) => path.contains('/platform');
      client.clearLastError();
      await client.getControllerTime().then((_) {}, onError: (_) {});
      await client.readMultiplePoints(['analog-value:1']);
      expect(superFavoritesRefreshFailure(noPointRead: true, client: client), isNull);

      unauthorized = (_) => true;
      client.clearLastError();
      await client.getSchedules();
      expect(superFavoritesRefreshFailure(noPointRead: true, client: client), isA<ApiAuthException>());
      expect(superFavoritesRefreshFailure(noPointRead: false, client: client), isNull);
    });
  });
}
