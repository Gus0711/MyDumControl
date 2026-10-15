import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myglobaldc/application/providers/app_overrides_provider.dart';
import 'package:myglobaldc/application/providers/bacnet_provider.dart';
import 'package:myglobaldc/application/providers/connection_providers.dart';
import 'package:myglobaldc/application/providers/database_provider.dart';
import 'package:myglobaldc/data/database/app_database.dart';
import 'package:myglobaldc/data/database/tables/app_overrides_table.dart';
import 'package:myglobaldc/data/services/bacnet/bacnet_constants.dart';
import 'package:myglobaldc/data/services/bacnet/bacnet_decoder.dart';
import 'package:myglobaldc/data/services/bacnet_service.dart';

/// Records the writes of the automatic release, answers from [onWrite].
class _FakeBacnet extends BacnetService {
  final List<({int instance, int propertyId, dynamic value, int? priority})> writes = [];
  BacnetResponse Function() onWrite = () => BacnetResponse(type: BacnetResponseType.simpleAck);

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
    writes.add((instance: objectInstance, propertyId: propertyId, value: value, priority: priority));
    return onWrite();
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
}

Future<int> _addConnection(AppDatabase db, {String type = 'bacnet'}) {
  return db.insertConnection(ConnectionsCompanion.insert(
    name: 'chaufferie',
    host: '10.0.0.7',
    port: const Value(47808),
    username: 'bacnet',
    passwordKey: generatePasswordKey(),
    connectionType: Value(type),
  ));
}

/// Service without its periodic timer: the test drives [TimedOverrideService.tick].
final _service = Provider((ref) => TimedOverrideService(ref));

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> record(int connectionId, int instance, {Duration? expiresIn, String kind = AppOverrideKind.priority}) {
    final now = DateTime.now();
    return db.recordAppOverride(
      connectionId: connectionId,
      objectType: 'binary-value',
      objectInstance: instance,
      kind: kind,
      priority: kind == AppOverrideKind.priority ? 1 : null,
      value: 'inactive',
      forcedAt: now,
      expiresAt: expiresIn == null ? null : now.add(expiresIn),
    );
  }

  group('AppOverrides table', () {
    test('recording again replaces the previous override of the point', () async {
      final id = await _addConnection(db);
      await record(id, 1, expiresIn: const Duration(minutes: 30));
      await record(id, 1); // forcé de nouveau, permanent cette fois
      final rows = await db.watchAppOverrides(id).first;
      expect(rows, hasLength(1));
      expect(rows.single.expiresAt, isNull);
    });

    test('only expired timed overrides are returned', () async {
      final id = await _addConnection(db);
      await record(id, 1, expiresIn: const Duration(minutes: -1));
      await record(id, 2, expiresIn: const Duration(minutes: 30));
      await record(id, 3);
      final expired = await db.getExpiredAppOverrides(DateTime.now());
      expect(expired.map((o) => o.objectInstance), [1]);
    });

    test('points released elsewhere are purged', () async {
      final id = await _addConnection(db);
      await record(id, 1);
      await record(id, 2);
      expect(await db.purgeReleasedAppOverrides(id, {'binary-value:2'}), 1);
      final rows = await db.watchAppOverrides(id).first;
      expect(rows.map((o) => o.objectInstance), [2]);
    });

    test('deleting the connection deletes its overrides', () async {
      final id = await _addConnection(db);
      await record(id, 1);
      await db.deleteConnectionCascade(id);
      expect(await db.select(db.appOverrides).get(), isEmpty);
    });

    test('migration 13 -> 14 creates the table and keeps data', () async {
      final dir = await Directory.systemTemp.createTemp('mdc_migration14');
      final file = File('${dir.path}/db.sqlite');
      try {
        var fileDb = AppDatabase(NativeDatabase(file));
        final id = await _addConnection(fileDb);
        await fileDb.customStatement('DROP TABLE app_overrides');
        await fileDb.customStatement('PRAGMA user_version = 13');
        await fileDb.close();

        fileDb = AppDatabase(NativeDatabase(file));
        expect(await fileDb.getConnectionById(id), isNotNull);
        await fileDb.recordAppOverride(
          connectionId: id,
          objectType: 'binary-value',
          objectInstance: 1,
          kind: AppOverrideKind.priority,
          forcedAt: DateTime.now(),
        );
        expect(await fileDb.select(fileDb.appOverrides).get(), hasLength(1));
        await fileDb.close();
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });

  group('TimedOverrideService (connection not open)', () {
    late _FakeBacnet bacnet;
    late ProviderContainer container;

    setUp(() {
      bacnet = _FakeBacnet();
      container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        bacnetServiceProvider.overrideWithValue(bacnet),
      ]);
    });
    tearDown(() => container.dispose());

    test('relinquishes an expired override and forgets it', () async {
      final id = await _addConnection(db);
      await record(id, 4, expiresIn: const Duration(seconds: -5));
      await record(id, 5, expiresIn: const Duration(hours: 1));

      await container.read(_service).tick();

      expect(bacnet.writes, hasLength(1));
      expect(bacnet.writes.single.instance, 4);
      expect(bacnet.writes.single.value, isNull); // relinquish
      expect(bacnet.writes.single.priority, 1);
      final rows = await db.watchAppOverrides(id).first;
      expect(rows.map((o) => o.objectInstance), [5]);
    });

    test('releases a forced input with out-of-service = false', () async {
      final id = await _addConnection(db);
      await record(id, 6, expiresIn: const Duration(seconds: -5), kind: AppOverrideKind.outOfService);

      await container.read(_service).tick();

      expect(bacnet.writes.single.propertyId, BacnetPropertyId.outOfService);
      expect(bacnet.writes.single.value, false);
      expect(await db.watchAppOverrides(id).first, isEmpty);
    });

    test('a refused release is kept, with its error, for the next tick', () async {
      final id = await _addConnection(db);
      await record(id, 7, expiresIn: const Duration(seconds: -5));
      bacnet.onWrite = () => BacnetResponse.error('timeout');

      await container.read(_service).tick();

      final row = (await db.watchAppOverrides(id).first).single;
      expect(row.lastError, isNotNull);

      bacnet.onWrite = () => BacnetResponse(type: BacnetResponseType.simpleAck);
      await container.read(_service).tick();
      expect(await db.watchAppOverrides(id).first, isEmpty);
    });
  });
}
