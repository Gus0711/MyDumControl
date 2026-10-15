import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myglobaldc/data/services/api_service.dart';
import 'package:myglobaldc/domain/models/bacnet_object.dart';

/// Minimal fake controller: answers each request with [handler].
class _FakeController {
  late HttpServer _server;
  final requests = <String>[];
  final bodies = <String>[];
  (int, Object?) Function(HttpRequest request, String body) handler = (_, _) => (404, null);
  Duration Function(HttpRequest request) delay = (_) => Duration.zero;

  String get baseUrl => 'http://${_server.address.host}:${_server.port}';

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      requests.add('${request.method} ${request.uri}');
      bodies.add(body);
      final (status, data) = handler(request, body);
      final wait = delay(request);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
      request.response.statusCode = status;
      if (data != null) {
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(data));
      }
      await request.response.close();
    });
  }

  Future<void> stop() => _server.close(force: true);
}

void main() {
  late _FakeController controller;

  setUp(() async {
    controller = _FakeController();
    await controller.start();
  });

  tearDown(() => controller.stop());

  ConnectedApiClient client(
    String version, {
    void Function(ApiAuthException)? onAuthError,
    Duration? receiveTimeout,
  }) =>
      ConnectedApiClient(
        baseUrl: controller.baseUrl,
        basicAuth: 'Basic dGVzdDp0ZXN0',
        apiVersion: version,
        onAuthError: onAuthError,
        receiveTimeout: receiveTimeout,
      );

  List<String> oosBodies() => [
        for (var i = 0; i < controller.requests.length; i++)
          if (controller.requests[i].endsWith('/out-of-service')) controller.bodies[i],
      ];

  test('401 is exposed as ApiAuthException without changing the return contract', () async {
    controller.handler = (_, _) => (401, null);
    ApiAuthException? seen;
    final api = client('V2', onAuthError: (e) => seen = e);

    final schedules = await api.getSchedules();

    expect(schedules, isEmpty);
    expect(api.hasAuthError, isTrue);
    expect(api.lastError, isA<ApiAuthException>());
    expect(seen, isNotNull);
    api.dispose();
  });

  test('V2 schedule detail with unreadable weekly-schedule is returned read-only', () async {
    controller.handler = (request, _) {
      if (request.uri.path.endsWith('/weekly-schedule')) return (404, null);
      return (200, {'object-name': 'Sched', 'present-value': true});
    };
    final api = client('V2');

    final schedule = await api.getScheduleDetail(1);
    expect(schedule, isNotNull);
    expect(schedule!.objectName, 'Sched');
    expect(schedule.weeklyScheduleReadable, isFalse);
    expect(schedule.weeklySchedule.days.values.every((d) => d.transitions.isEmpty), isTrue);
    api.dispose();
  });

  test('V1 schedule detail with unreadable weekly-schedule is returned read-only', () async {
    controller.handler = (request, _) {
      if (request.uri.path.endsWith('/weekly-schedule')) return (403, null);
      return (200, {'propertyReferences': <Object>[]});
    };
    final api = client('V1');

    final schedule = await api.getScheduleDetail(3);
    expect(schedule, isNotNull);
    expect(schedule!.weeklyScheduleReadable, isFalse);
    api.dispose();
  });

  test('V2 forceInput on an already forced input does not release it on failure', () async {
    controller.handler = (request, body) {
      if (request.uri.path.endsWith('/present-value')) return (400, {'error': 'bad value'});
      return (200, {});
    };
    final api = client('V2');

    final ok = await api.forceInput(BacnetObjectType.analogInput, 1, 12.5, wasOutOfService: true);

    expect(ok, isFalse);
    expect(oosBodies().map(jsonDecode), [
      {r'$value': true},
    ]);
    api.dispose();
  });

  test('V2 forceInput does not compensate on a response timeout', () async {
    controller.handler = (_, _) => (200, {});
    controller.delay = (request) => request.uri.path.endsWith('/present-value')
        ? const Duration(milliseconds: 600)
        : Duration.zero;
    final api = client('V2', receiveTimeout: const Duration(milliseconds: 200));

    final ok = await api.forceInput(BacnetObjectType.analogInput, 1, 12.5);

    expect(ok, isFalse);
    expect(oosBodies(), hasLength(1));
    api.dispose();
  });

  test('V1 forceInput compensates only when the input was not already forced', () async {
    controller.handler = (request, _) =>
        request.uri.path.endsWith('/write-property-multiple') ? (500, null) : (200, {});
    final api = client('V1');

    expect(await api.forceInput(BacnetObjectType.analogInput, 7, 3), isFalse);
    final released = controller.requests.length;
    expect(released, greaterThan(1)); // write + compensation

    controller.requests.clear();
    expect(await api.forceInput(BacnetObjectType.analogInput, 7, 3, wasOutOfService: true), isFalse);
    expect(controller.requests, hasLength(1)); // write only
    api.dispose();
  });

  test('V1 forceInput does not compensate on a response timeout', () async {
    controller.handler = (_, _) => (200, {});
    controller.delay = (_) => const Duration(milliseconds: 600);
    final api = client('V1', receiveTimeout: const Duration(milliseconds: 200));

    expect(await api.forceInput(BacnetObjectType.analogInput, 7, 3), isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    expect(controller.requests, hasLength(1));
    api.dispose();
  });

  group('objectsAccessFailure', () {
    test('ignores auth failures on annex endpoints', () async {
      controller.handler = (request, _) =>
          request.uri.path.contains('/platform') ? (401, null) : (200, <String, Object>{});
      final api = client('V2');
      api.clearLastError();

      await api.getControllerTime().then((_) {}, onError: (_) {});
      final schedules = await api.getSchedules();

      expect(schedules, isEmpty);
      expect(api.hasAuthError, isTrue); // sticky lastError polluted by the annex request
      expect(api.objectsAccessFailure(), isNull);
      api.dispose();
    });

    test('reports a 401 on the objects endpoints, even if a later error overwrote lastError', () async {
      controller.handler = (request, _) {
        if (request.uri.path.contains('/objects')) return (401, null);
        return (500, null);
      };
      final api = client('V2');
      api.clearLastError();

      await api.getSchedules();
      await api.getControllerTime().then((_) {}, onError: (_) {});

      expect(api.lastError, isNot(isA<ApiAuthException>()));
      expect(api.objectsAccessFailure(), isA<ApiAuthException>());
      api.clearLastError();
      expect(api.objectsAccessFailure(), isNull);
      api.dispose();
    });
  });

  test('V2 forceInput releases out-of-service when present-value write fails', () async {
    controller.handler = (request, body) {
      if (request.uri.path.endsWith('/present-value')) return (400, {'error': 'bad value'});
      return (200, {});
    };
    final api = client('V2');

    final ok = await api.forceInput(BacnetObjectType.analogInput, 1, 12.5);

    expect(ok, isFalse);
    final oosWrites = <String>[
      for (var i = 0; i < controller.requests.length; i++)
        if (controller.requests[i].endsWith('/out-of-service')) controller.bodies[i],
    ];
    expect(oosWrites, hasLength(2));
    expect(jsonDecode(oosWrites.first), {r'$value': true});
    expect(jsonDecode(oosWrites.last), {r'$value': false});
    api.dispose();
  });

  test('V1 forceInput sends a single write-property-multiple', () async {
    controller.handler = (_, _) => (200, {});
    final api = client('V1');

    final ok = await api.forceInput(BacnetObjectType.analogInput, 7, 3);

    expect(ok, isTrue);
    expect(controller.requests, hasLength(1));
    final refs = jsonDecode(controller.bodies.single)['propertyReferences'] as List;
    expect(refs.map((r) => r['property']), ['outOfService', 'presentValue']);
    api.dispose();
  });

  test('V2 getObjectsByType uses the plural kebab-case path', () async {
    controller.handler = (_, _) => (200, {
          '1': {'object-name': 'AV1', 'present-value': 1},
        });
    final api = client('V2');

    final objects = await api.getObjectsByType(BacnetObjectType.analogValue);

    expect(objects, hasLength(1));
    expect(controller.requests.single, contains('/objects/analog-values'));
    api.dispose();
  });

  test('V2 trend-logs collection is fetched once for list and mapping', () async {
    controller.handler = (_, _) => (200, {
          '3': {
            'source-reference': {
              'object-identifier': {'object-type': 'AnalogInput', 'object-instance': 9},
            },
          },
        });
    final api = client('V2');

    final results = await Future.wait([api.getTrendLogMapping(), api.getTrendLogs()]);

    expect(results[0], {'analog-input:9': 3});
    expect(results[1], hasLength(1));
    expect(controller.requests, hasLength(1));
    api.dispose();
  });

  test('V2 super-favorites use \$select and keep the original pointRef', () async {
    controller.handler = (request, body) => (200, {
          'responses': [
            {
              'id': 'AV:1',
              'status': 200,
              'body': {'object-name': 'Temp', 'present-value': 21.0},
            },
          ],
        });
    final api = client('V2');

    final points = await api.readMultiplePoints(['AV:1']);

    expect(points['AV:1']?.objectName, 'Temp');
    final request = (jsonDecode(controller.bodies.single)['requests'] as List).single;
    expect(request['url'], contains(r'?$select='));
    api.dispose();
  });

  test('V1 super-favorites read static properties only once', () async {
    controller.handler = (request, body) {
      final refs = jsonDecode(body)['propertyReferences'] as List;
      return (200, {
        'propertyReferences': [
          for (final r in refs) {...r, 'value': r['property'] == 'objectName' ? 'Name' : '1'},
        ],
      });
    };
    final api = client('V1');

    await api.readMultiplePoints(['MSV:2']);
    final second = await api.readMultiplePoints(['MSV:2']);

    final firstRefs = jsonDecode(controller.bodies[0])['propertyReferences'] as List;
    final secondRefs = jsonDecode(controller.bodies[1])['propertyReferences'] as List;
    expect(firstRefs.first['type'], 'multistateValue');
    expect(firstRefs.map((r) => r['property']), contains('objectName'));
    expect(secondRefs.map((r) => r['property']), ['presentValue', 'outOfService']);
    expect(second['MSV:2']?.objectName, 'Name');
    api.dispose();
  });
}
