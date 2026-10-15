import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myglobaldc/application/providers/connection_providers.dart';
import 'package:myglobaldc/application/providers/settings_provider.dart';
import 'package:myglobaldc/data/database/app_database.dart';
import 'package:myglobaldc/data/database/tables/dashboard_tables.dart';
import 'package:myglobaldc/data/services/cache_service.dart';
import 'package:myglobaldc/domain/models/bacnet_object.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/open.dart';

AppDatabase _memoryDb() => AppDatabase(NativeDatabase.memory());

Future<int> _addConnection(AppDatabase db, {String host = '10.0.0.1'}) {
  return db.insertConnection(ConnectionsCompanion.insert(
    name: 'c-$host',
    host: host,
    username: 'admin',
    passwordKey: generatePasswordKey(),
  ));
}

CachedPointsCompanion _point(int connectionId, String ref) {
  return CachedPointsCompanion.insert(
    connectionId: connectionId,
    pointRef: ref,
    objectType: 'analog-value',
    instance: int.parse(ref.split(':').last),
    objectName: 'Point $ref',
  );
}

Future<int> _count(AppDatabase db, String table) async {
  final row = await db.customSelect('SELECT COUNT(*) AS c FROM $table').getSingle();
  return row.read<int>('c');
}

void main() {
  // Linux hosts often only ship libsqlite3.so.0 (no dev symlink)
  if (Platform.isLinux) {
    open.overrideFor(OperatingSystem.linux, () {
      try {
        return DynamicLibrary.open('libsqlite3.so');
      } catch (_) {
        return DynamicLibrary.open('libsqlite3.so.0');
      }
    });
  }
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('points cache', () {
    late AppDatabase db;
    setUp(() => db = _memoryDb());
    tearDown(() => db.close());

    test('replaceCachedPoints purges points deleted on the controller', () async {
      final id = await _addConnection(db);
      await db.replaceCachedPoints(id, [_point(id, 'AV:1'), _point(id, 'AV:12')]);
      await db.replaceCachedPoints(id, [_point(id, 'AV:1')]);

      final cached = await db.getAllCachedPoints(id);
      expect(cached.map((p) => p.pointRef), ['AV:1']);
    });

    test('replaceCachedPoints refreshes cachedAt and keeps other connections', () async {
      final a = await _addConnection(db, host: 'a');
      final b = await _addConnection(db, host: 'b');
      await db.replaceCachedPoints(b, [_point(b, 'AV:2')]);

      // Simulate an old cache for connection a
      await db.batch((batch) => batch.insertAll(db.cachedPoints, [
            _point(a, 'AV:1').copyWith(
                cachedAt: Value(DateTime.now().subtract(const Duration(days: 3)))),
          ]));
      expect(await db.isPointsCacheValid(a), isFalse);

      await db.replaceCachedPoints(a, [_point(a, 'AV:1')]);
      expect(await db.isPointsCacheValid(a), isTrue);
      expect((await db.getAllCachedPoints(b)).length, 1);
    });

    test('cachePoints upsert refreshes cachedAt', () async {
      final id = await _addConnection(db);
      await db.batch((batch) => batch.insertAll(db.cachedPoints, [
            _point(id, 'AV:1').copyWith(
                cachedAt: Value(DateTime.now().subtract(const Duration(days: 3)))),
          ]));
      await db.cachePoints([_point(id, 'AV:1')]);
      expect(await db.isPointsCacheValid(id), isTrue);
    });

    test('cache validity uses the oldest row', () async {
      final id = await _addConnection(db);
      await db.batch((batch) => batch.insertAll(db.cachedPoints, [
            _point(id, 'AV:1'),
            _point(id, 'AV:2').copyWith(
                cachedAt: Value(DateTime.now().subtract(const Duration(days: 3)))),
          ]));
      expect(await db.isPointsCacheValid(id), isFalse);
    });

    test('CacheService round-trip and expiry', () async {
      final id = await _addConnection(db);
      final service = CacheService(db);
      await service.cacheStaticPoints(id, [
        BacnetObject(type: BacnetObjectType.analogValue, instance: 1, objectName: 'T'),
      ]);
      final cache = await service.getStaticPointsCache(id);
      expect(cache?.keys, ['AV:1']);
    });

    test('corrupted trend log mapping is dropped', () async {
      final id = await _addConnection(db);
      await db.into(db.cachedTrendLogMapping).insert(
            CachedTrendLogMappingCompanion.insert(
              connectionId: Value(id),
              mappingJson: 'not json',
            ),
          );
      expect(await db.getCachedTrendLogMapping(id), isNull);
      expect(await _count(db, 'cached_trend_log_mapping'), 0);
    });

    test('clearAllCacheGlobal also clears trend log mapping; stats count rows', () async {
      final id = await _addConnection(db);
      await db.replaceCachedPoints(id, [_point(id, 'AV:1'), _point(id, 'AV:2')]);
      await db.cacheTrendLogMapping(id, {'AV:1': 3});
      final stats = await db.getGlobalCacheStats();
      expect(stats.totalPoints, 2);
      expect(stats.totalDevices, 0);

      await db.clearAllCacheGlobal();
      expect(await _count(db, 'cached_points'), 0);
      expect(await _count(db, 'cached_trend_log_mapping'), 0);
    });

    test('isCacheFresh', () {
      final now = DateTime(2026, 1, 2);
      expect(isCacheFresh(DateTime(2026, 1, 1, 12), const Duration(hours: 24), now: now), isTrue);
      expect(isCacheFresh(DateTime(2025, 12, 31), const Duration(hours: 24), now: now), isFalse);
    });
  });

  group('deleteConnectionCascade', () {
    late AppDatabase db;
    setUp(() => db = _memoryDb());
    tearDown(() => db.close());

    test('removes every row linked to the connection only', () async {
      final id = await _addConnection(db, host: 'a');
      final other = await _addConnection(db, host: 'b');

      for (final c in [id, other]) {
        final favId = await db.addFavorite(FavoritesCompanion.insert(
          connectionId: c,
          pointRef: 'AV:1',
          pointName: 'p',
          objectType: 'analog-value',
        ));
        final folderId = await db.createFavoriteFolder(
            FavoriteFoldersCompanion.insert(connectionId: c, name: 'F'));
        await db.assignFavoriteToFolder(favId, folderId);
        await db.replaceCachedPoints(c, [_point(c, 'AV:1')]);
        await db.cacheTrendLogMapping(c, {'AV:1': 1});
        final dashId = await db.createDashboard(name: 'D', connectionId: c);
        await db.addDashboardWidget(
            dashboardId: dashId, position: 0, widgetType: DashboardWidgetType.statsCard);
        await db.createSynoptic(SynopticsCompanion.insert(
          name: 'S',
          svgAssetPath: 'a.svg',
          connectionId: Value(c),
        ));
      }

      expect(await db.deleteConnectionCascade(id), 1);

      for (final table in [
        'connections',
        'favorites',
        'favorite_folders',
        'favorite_folder_assignments',
        'cached_points',
        'cached_trend_log_mapping',
        'dashboards',
        'dashboard_widgets',
        'synoptics',
      ]) {
        expect(await _count(db, table), 1, reason: table);
      }
      expect(await db.getConnectionById(other), isNotNull);
    });
  });

  group('favorites', () {
    late AppDatabase db;
    setUp(() => db = _memoryDb());
    tearDown(() => db.close());

    test('deleting a favorite removes its folder assignments', () async {
      final id = await _addConnection(db);
      final folderId = await db.createFavoriteFolder(
          FavoriteFoldersCompanion.insert(connectionId: id, name: 'F'));
      await db.toggleFavorite(
          connectionId: id, pointRef: 'AV:1', pointName: 'p', objectType: 'analog-value');
      final fav = (await db.getFavoritesByConnection(id)).single;
      await db.assignFavoriteToFolder(fav.id, folderId);

      await db.deleteFavorite(id, 'AV:1');
      expect(await db.countFavoritesInFolder(folderId), 0);
    });

    test('concurrent toggles do not throw', () async {
      final id = await _addConnection(db);
      Future<bool> toggle() => db.toggleFavorite(
          connectionId: id, pointRef: 'AV:1', pointName: 'p', objectType: 'analog-value');
      final results = await Future.wait([toggle(), toggle()]);
      expect(results, [true, false]);
      expect(await db.countFavorites(id), 0);
    });

    test('createDashboard uses MAX(sortOrder)+1', () async {
      final a = await db.createDashboard(name: 'A');
      await db.createDashboard(name: 'B');
      await db.deleteDashboard(a);
      final c = await db.createDashboard(name: 'C');
      final orders = (await db.getDashboardsForConnection(null)).map((d) => d.sortOrder);
      expect(orders.toSet().length, orders.length);
      expect((await db.getDashboardById(c))!.sortOrder, 2);
    });
  });

  group('import JSON', () {
    late AppDatabase db;
    setUp(() => db = _memoryDb());
    tearDown(() => db.close());

    test('each imported connection gets its own passwordKey and all fields', () async {
      final json = jsonEncode({
        'folders': [
          {'name': 'Site'},
        ],
        'connections': [
          {'name': 'A', 'host': '10.0.0.1', 'port': 443, 'username': 'admin', 'folderName': 'Site'},
          {
            'name': 'B',
            'host': '10.0.0.1',
            'port': 443,
            'username': 'admin',
            'connectionType': 'api',
            'designerUrl': '/x',
          },
          {
            'name': 'C',
            'host': '10.0.0.2',
            'port': 47808,
            'username': '',
            'connectionType': 'bacnet',
            'bacnetDeviceId': 1234,
          },
        ],
      });

      final result = await importConnectionsData(db, json);
      expect(result.success, isTrue, reason: result.errors.join());
      // A and B share host:port:type -> B is skipped
      expect(result.connectionsImported, 2);
      expect(result.connectionsSkipped, 1);
      expect(result.connectionsNeedingPassword, 1);
      expect(result.summary, contains('Mot de passe à ressaisir'));

      final conns = await db.getAllConnections();
      expect(conns.map((c) => c.passwordKey).toSet().length, 2);
      expect(conns.every((c) => c.passwordKey.isNotEmpty), isTrue);
      final a = conns.firstWhere((c) => c.name == 'A');
      expect(a.connectionType, 'distech_api');
      expect(a.folderId, isNotNull);
      final c = conns.firstWhere((c) => c.name == 'C');
      expect(c.connectionType, 'bacnet');
      expect(c.bacnetDeviceId, 1234);

      // Re-import is idempotent
      final again = await importConnectionsData(db, json);
      expect(again.connectionsImported, 0);
      expect(again.foldersImported, 0);
    });

    test('invalid entries are reported without aborting the import', () async {
      final json = jsonEncode({
        'connections': [
          {'name': 'X', 'host': 'h', 'port': 'bad', 'username': 'u'},
          {'name': 'Y', 'host': 'h2', 'port': 1, 'username': 'u'},
        ],
      });
      final result = await importConnectionsData(db, json);
      expect(result.success, isTrue);
      expect(result.connectionsImported, 1);
      expect(result.errors.length, 1);
    });

    test('certificate fingerprint is imported only when well-formed', () async {
      final fp = List.filled(32, 'ab').join(':');
      final json = jsonEncode({
        'connections': [
          {'name': 'P', 'host': 'h1', 'port': 443, 'username': 'u', 'certificateFingerprint': fp},
          {'name': 'Q', 'host': 'h2', 'port': 443, 'username': 'u', 'certificateFingerprint': 'garbage'},
        ],
      });
      final result = await importConnectionsData(db, json);
      expect(result.connectionsImported, 2);
      final conns = await db.getAllConnections();
      expect(conns.firstWhere((c) => c.name == 'P').certificateFingerprint, fp.toUpperCase());
      expect(conns.firstWhere((c) => c.name == 'Q').certificateFingerprint, isNull);
    });

    test('normalizeImportedConnectionType', () {
      expect(normalizeImportedConnectionType(null), 'distech_api');
      expect(normalizeImportedConnectionType('api'), 'distech_api');
      expect(normalizeImportedConnectionType('bacnet'), 'bacnet');
    });
  });

  group('connectionTargetChanged', () {
    test('detects host/port/type/device id changes only', () async {
      final db = _memoryDb();
      final id = await _addConnection(db);
      final c = (await db.getConnectionById(id))!;
      await db.close();

      bool changed({String? host, int? port, String? type, int? dev}) =>
          connectionTargetChanged(c,
              host: host ?? c.host,
              port: port ?? c.port,
              connectionType: type ?? c.connectionType,
              bacnetDeviceId: dev ?? c.bacnetDeviceId);

      expect(changed(), isFalse);
      expect(changed(host: '10.9.9.9'), isTrue);
      expect(changed(port: 8443), isTrue);
      expect(changed(type: 'bacnet'), isTrue);
      expect(changed(dev: 5), isTrue);
    });
  });

  test('migration 12 -> 13 keeps data and creates indexes', () async {
    final dir = await Directory.systemTemp.createTemp('mdc_migration');
    final file = File('${dir.path}/db.sqlite');
    try {
      var db = AppDatabase(NativeDatabase(file));
      final id = await _addConnection(db);
      for (final idx in [
        'idx_favorite_folder_assignments_folder_id',
        'idx_dashboards_connection_id',
        'idx_dashboard_widgets_dashboard_id',
        'idx_synoptics_connection_id',
      ]) {
        await db.customStatement('DROP INDEX $idx');
      }
      await db.customStatement('PRAGMA user_version = 12');
      await db.close();

      db = AppDatabase(NativeDatabase(file));
      expect(await db.getConnectionById(id), isNotNull);
      final rows = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'idx_%'")
          .get();
      expect(rows.length, 4);
      await db.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
