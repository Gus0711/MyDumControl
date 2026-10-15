import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myglobaldc/application/providers/active_connection_provider.dart';
import 'package:myglobaldc/application/providers/bacnet_provider.dart';
import 'package:myglobaldc/application/providers/database_provider.dart';
import 'package:myglobaldc/application/providers/points_provider.dart';
import 'package:myglobaldc/application/providers/trend_log_provider.dart';
import 'package:myglobaldc/data/database/app_database.dart';
import 'package:myglobaldc/data/services/bacnet/bacnet_constants.dart';
import 'package:myglobaldc/data/services/bacnet/bacnet_decoder.dart';
import 'package:myglobaldc/data/services/bacnet_service.dart';
import 'package:myglobaldc/domain/models/bacnet_object.dart';

/// Fake BACnet transport: records writes and answers from [onWrite].
class FakeBacnetService extends BacnetService {
  final List<({int propertyId, dynamic value, int? priority})> writes = [];
  BacnetResponse Function(int propertyId, dynamic value, int? priority) onWrite =
      (_, _, _) => BacnetResponse(type: BacnetResponseType.simpleAck);
  Completer<List<BacnetObject>>? discoverCompleter;
  int discoverCalls = 0;

  /// Effective present-value held by the fake controller, per instance
  /// (null = unknown: the app keeps its local value).
  final Map<int, dynamic> controllerValues = {};

  @override
  Future<dynamic> refreshPointValue({
    required String host,
    required int port,
    required int objectType,
    required int objectInstance,
  }) async =>
      controllerValues[objectInstance];

  @override
  Future<BacnetResponse> writeProperty({
    required String host,
    required int port,
    required int objectType,
    required int objectInstance,
    required int propertyId,
    required dynamic value,
    int? priority,
    int? arrayIndex,
  }) async {
    writes.add((propertyId: propertyId, value: value, priority: priority));
    return onWrite(propertyId, value, priority);
  }

  @override
  Future<void> writePointValue({
    required String host,
    required int port,
    required int objectType,
    required int objectInstance,
    required dynamic value,
    int? priority,
  }) async {
    final r = await writeProperty(
      host: host,
      port: port,
      objectType: objectType,
      objectInstance: objectInstance,
      propertyId: BacnetPropertyId.presentValue,
      value: value,
      priority: priority,
    );
    if (!r.isSuccess) throw Exception(r.errorMessage ?? 'refused');
  }

  @override
  Future<List<BacnetObject>> discoverObjects({
    required String host,
    required int port,
    required int deviceId,
    List<int>? objectTypesFilter,
  }) {
    discoverCalls++;
    return discoverCompleter!.future;
  }
}

class FakeActiveConnectionNotifier extends ActiveConnectionNotifier {
  FakeActiveConnectionNotifier(super.ref, ActiveConnectionState initial) {
    state = initial;
  }

  void setState(ActiveConnectionState s) => state = s;
}

Connection _connection(int id) => Connection(
      id: id,
      name: 'Device $id',
      host: '10.0.0.$id',
      port: 47808,
      useHttps: false,
      username: '',
      passwordKey: '',
      connectionType: 'bacnet',
      bacnetDeviceId: 1000 + id,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

BacnetObject _point(BacnetObjectType type, int instance, {bool overridden = false}) => BacnetObject(
      type: type,
      instance: instance,
      objectName: 'P$instance',
      presentValue: 1.0,
      isOverridden: overridden,
      overridePriority: overridden ? 8 : null,
    );

void main() {
  late FakeBacnetService bacnet;
  late ProviderContainer container;

  setUp(() {
    bacnet = FakeBacnetService();
    container = ProviderContainer(overrides: [
      bacnetServiceProvider.overrideWithValue(bacnet),
      databaseProvider.overrideWithValue(AppDatabase(NativeDatabase.memory())),
      activeConnectionProvider.overrideWith((ref) => FakeActiveConnectionNotifier(
            ref,
            ActiveConnectionState(
              connection: _connection(1),
              isBacnetConnection: true,
              bacnetDeviceId: 1001,
            ),
          )),
    ]);
    container.read(activeBacnetConnectionProvider.notifier).state =
        ActiveBacnetConnection(connectionId: 1, host: '10.0.0.1', port: 47808, deviceId: 1001);
  });

  tearDown(() => container.dispose());

  PointsNotifier notifier() => container.read(pointsProvider.notifier);

  Future<void> seedPoints(List<BacnetObject> points) async {
    bacnet.discoverCompleter = Completer()..complete(points);
    await notifier().loadPoints();
  }

  group('BACnet writes check the device answer', () {
    test('forceInput returns false when out-of-service is refused', () async {
      final ai = _point(BacnetObjectType.analogInput, 1);
      await seedPoints([ai]);
      bacnet.onWrite = (_, _, _) => BacnetResponse.error('write-access-denied');

      expect(await notifier().forceInput(ai, 12.0), isFalse);
      expect(bacnet.writes, hasLength(1));
      expect(container.read(pointsProvider).points.single.outOfService, isNot(true));
    });

    test('forceInput rolls back out-of-service when present-value fails', () async {
      final ai = _point(BacnetObjectType.analogInput, 1);
      await seedPoints([ai]);
      bacnet.onWrite = (prop, _, _) => prop == BacnetPropertyId.presentValue
          ? BacnetResponse.error('value-out-of-range')
          : BacnetResponse(type: BacnetResponseType.simpleAck);

      expect(await notifier().forceInput(ai, 12.0), isFalse);
      expect(bacnet.writes.map((w) => (w.propertyId, w.value)).toList(), [
        (BacnetPropertyId.outOfService, true),
        (BacnetPropertyId.presentValue, 12.0),
        (BacnetPropertyId.outOfService, false),
      ]);
    });

    test('forceInput on an already forced input keeps it out-of-service on failure', () async {
      final ai = BacnetObject(
        type: BacnetObjectType.analogInput,
        instance: 1,
        objectName: 'P1',
        presentValue: 1.0,
        outOfService: true,
      );
      await seedPoints([ai]);
      bacnet.onWrite = (prop, _, _) => prop == BacnetPropertyId.presentValue
          ? BacnetResponse.error('value-out-of-range')
          : BacnetResponse(type: BacnetResponseType.simpleAck);

      expect(await notifier().forceInput(ai, 12.0), isFalse);
      expect(bacnet.writes.map((w) => (w.propertyId, w.value)).toList(), [
        (BacnetPropertyId.outOfService, true),
        (BacnetPropertyId.presentValue, 12.0),
      ]);
    });

    test('releaseInput / writeDescription return false when refused', () async {
      final ai = _point(BacnetObjectType.analogInput, 1);
      await seedPoints([ai]);
      bacnet.onWrite = (_, _, _) => BacnetResponse.error('denied');

      expect(await notifier().releaseInput(ai), isFalse);
      expect(await notifier().writeDescription(ai, 'x'), isFalse);
      expect(container.read(pointsProvider).points.single.description, isNull);
    });

    test('forceInput succeeds when both writes are acknowledged', () async {
      final ai = _point(BacnetObjectType.analogInput, 1);
      await seedPoints([ai]);

      expect(await notifier().forceInput(ai, 12.0), isTrue);
      final p = container.read(pointsProvider).points.single;
      expect(p.outOfService, isTrue);
      expect(p.presentValue, 12.0);
    });
  });

  group('emergencyRelease (BACnet)', () {
    test('releases priorities 1..16 and returns true when all succeed', () async {
      final av = _point(BacnetObjectType.analogValue, 2, overridden: true);
      await seedPoints([av]);

      expect(await notifier().emergencyRelease(av), isTrue);
      final priorities = bacnet.writes.map((w) => w.priority).toList()..sort();
      expect(priorities, List.generate(16, (i) => i + 1));
      expect(container.read(pointsProvider).points.single.isOverridden, isFalse);
    });

    test('returns false and keeps the override when one priority fails', () async {
      final av = _point(BacnetObjectType.analogValue, 2, overridden: true);
      await seedPoints([av]);
      bacnet.onWrite = (_, _, priority) => priority == 8
          ? BacnetResponse.error('timeout')
          : BacnetResponse(type: BacnetResponseType.simpleAck);

      expect(await notifier().emergencyRelease(av), isFalse);
      expect(container.read(pointsProvider).points.single.isOverridden, isTrue);
    });
  });

  group('re-read after a write (BACnet)', () {
    test('release shows the value the controller went back to', () async {
      final bv = _point(BacnetObjectType.binaryValue, 3, overridden: true)
          .copyWith(presentValue: 'inactive', overrideValue: 'inactive');
      await seedPoints([bv]);
      // Forced OFF at priority 8, the program still commands ON below it
      bacnet.controllerValues[3] = 'active';

      expect(await notifier().releaseOverride(bv, priority: 8), isTrue);
      final p = container.read(pointsProvider).points.single;
      expect(p.isOverridden, isFalse);
      expect(p.presentValue, 'active');
    });

    test('an override masked by a higher priority shows the effective value', () async {
      final av = _point(BacnetObjectType.analogValue, 4);
      await seedPoints([av]);
      bacnet.controllerValues[4] = 21.0; // priority 1 holds 21.0

      expect(await notifier().writeOverride(av, 30.0, priority: 8), isTrue);
      final p = container.read(pointsProvider).points.single;
      expect(p.isOverridden, isTrue);
      expect(p.presentValue, 21.0);
    });
  });

  test('a load started before reset() does not overwrite the new state', () async {
    bacnet.discoverCompleter = Completer();
    final pending = notifier().loadPoints();

    // Connection change: the data providers are reset
    notifier().reset();
    bacnet.discoverCompleter!.complete([_point(BacnetObjectType.analogInput, 1)]);
    await pending;

    expect(container.read(pointsProvider).points, isEmpty);
  });

  test('a load is ignored when the active connection changed meanwhile', () async {
    bacnet.discoverCompleter = Completer();
    final pending = notifier().loadPoints();

    (container.read(activeConnectionProvider.notifier) as FakeActiveConnectionNotifier).setState(
      ActiveConnectionState(connection: _connection(2), isBacnetConnection: true, bacnetDeviceId: 1002),
    );
    bacnet.discoverCompleter!.complete([_point(BacnetObjectType.analogInput, 1)]);
    await pending;

    expect(container.read(pointsProvider).points, isEmpty);
  });

  test('pointDetailProvider ignores search changes', () async {
    await seedPoints([_point(BacnetObjectType.analogInput, 1)]);
    var notifications = 0;
    container.listen(pointDetailProvider((BacnetObjectType.analogInput, 1)), (_, _) => notifications++);

    notifier().setSearchQuery('abc');
    notifier().setSortOption(PointSortOption.nameDesc);
    expect(notifications, 0);
    expect(container.read(pointDetailProvider((BacnetObjectType.analogInput, 2))), isNull);
  });

  group('parseTrendLogBuffer', () {
    test('parses V1 text when the buffer is not JSON', () {
      final data = parseTrendLogBuffer('not json at all');
      expect(data, isNotNull);
    });
  });

  test('loadPoints(forceRefresh) during an in-flight load reloads afterwards', () async {
    final first = Completer<List<BacnetObject>>();
    bacnet.discoverCompleter = first;
    final initial = notifier().loadPoints();
    final forced1 = notifier().loadPoints(forceRefresh: true);
    final forced2 = notifier().loadPoints(forceRefresh: true);
    expect(bacnet.discoverCalls, 1);

    bacnet.discoverCompleter = Completer()..complete([_point(BacnetObjectType.analogValue, 2)]);
    first.complete([_point(BacnetObjectType.analogValue, 1)]);
    await Future.wait([initial, forced1, forced2]);

    // One shared forced reload after the in-flight one, with fresh data
    expect(bacnet.discoverCalls, 2);
    expect(container.read(pointsProvider).points.single.instance, 2);
  });

  test('loadPoints without forceRefresh joins the in-flight load', () async {
    final first = Completer<List<BacnetObject>>();
    bacnet.discoverCompleter = first;
    final a = notifier().loadPoints();
    final b = notifier().loadPoints();
    first.complete([_point(BacnetObjectType.analogValue, 1)]);
    await Future.wait([a, b]);
    expect(bacnet.discoverCalls, 1);
  });
}
