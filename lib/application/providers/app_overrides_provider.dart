import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/logger.dart';
import '../../data/database/app_database.dart';
import '../../data/database/tables/app_overrides_table.dart';
import '../../data/services/api_exceptions.dart';
import '../../data/services/bacnet/bacnet_constants.dart';
import '../../domain/models/bacnet_object.dart';
import 'active_connection_provider.dart';
import 'api_provider.dart';
import 'bacnet_provider.dart';
import 'bacnet_type_codes.dart';
import 'database_provider.dart';
import 'points_provider.dart';

/// Forçages posés depuis l'application pour une connexion, indexés par
/// "type:instance" ([BacnetObjectType.apiName]:instance).
final appOverridesProvider = StreamProvider.family<Map<String, AppOverride>, int>((ref, connectionId) {
  return ref
      .watch(databaseProvider)
      .watchAppOverrides(connectionId)
      .map((rows) => {for (final o in rows) appOverrideKey(o.objectType, o.objectInstance): o});
});

String appOverrideKey(String objectType, int instance) => '$objectType:$instance';

/// Durées proposées pour un forçage temporisé (null = permanent).
const timedOverrideDurations = <Duration?>[
  null,
  Duration(minutes: 15),
  Duration(minutes: 30),
  Duration(hours: 1),
  Duration(hours: 2),
  Duration(hours: 4),
  Duration(hours: 8),
];

/// Relâche automatiquement les forçages temporisés arrivés à échéance.
///
/// Le relâchement est fait par l'application (BACnet n'a pas de forçage à
/// durée limitée) : il a lieu tant que l'application est ouverte, et au
/// prochain démarrage pour les échéances passées pendant qu'elle était fermée.
/// Un échec (automate injoignable...) est mémorisé et retenté au tick suivant.
class TimedOverrideService {
  TimedOverrideService(this._ref);

  final Ref _ref;
  Timer? _timer;
  bool _running = false;

  static const tickInterval = Duration(seconds: 15);

  void start() {
    _timer ??= Timer.periodic(tickInterval, (_) => tick());
    // Échéances passées pendant que l'application était fermée
    Future.microtask(tick);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  /// Relâche les forçages échus. Public pour les tests.
  Future<void> tick() async {
    if (_running) return;
    _running = true;
    try {
      final database = _ref.read(databaseProvider);
      final expired = await database.getExpiredAppOverrides(DateTime.now());
      for (final row in expired) {
        await _release(database, row);
      }
    } catch (e) {
      logger.w('TimedOverrideService: tick failed: $e');
    } finally {
      _running = false;
    }
  }

  Future<void> _release(AppDatabase database, AppOverride row) async {
    final type = BacnetObjectType.fromApiName(row.objectType);
    if (type == null) {
      await database.deleteAppOverride(row.connectionId, row.objectType, row.objectInstance);
      return;
    }
    logger.i('TimedOverrideService: releasing ${row.objectType}:${row.objectInstance} '
        '(connection ${row.connectionId}, expired ${row.expiresAt})');

    String? error;
    try {
      final active = _ref.read(activeConnectionProvider);
      final bool ok;
      if (active.isConnected && active.connection?.id == row.connectionId) {
        ok = await _releaseThroughActiveConnection(row, type);
        if (!ok) error = _ref.read(pointsProvider.notifier).lastActionError;
      } else {
        ok = await _releaseStandalone(database, row, type);
      }
      if (ok) {
        // Le relâchement via le provider supprime déjà la ligne
        await database.deleteAppOverride(row.connectionId, row.objectType, row.objectInstance);
        return;
      }
    } catch (e) {
      error = describeError(e);
    }
    final message = error ?? 'Relâchement automatique refusé par l\'automate';
    logger.w('TimedOverrideService: release failed: $message');
    await database.setAppOverrideError(row.id, message);
  }

  /// Connexion ouverte : passe par le provider (mise à jour de l'écran et
  /// relecture de la valeur effective).
  Future<bool> _releaseThroughActiveConnection(AppOverride row, BacnetObjectType type) {
    final notifier = _ref.read(pointsProvider.notifier);
    final point = _ref.read(pointsProvider).points.firstWhere(
          (p) => p.type == type && p.instance == row.objectInstance,
          orElse: () => BacnetObject(type: type, instance: row.objectInstance, objectName: ''),
        );
    if (row.kind == AppOverrideKind.outOfService) return notifier.releaseInput(point);
    return notifier.releaseOverride(point, priority: row.priority ?? 8);
  }

  /// Connexion fermée : client dédié, construit pour ce seul relâchement.
  Future<bool> _releaseStandalone(AppDatabase database, AppOverride row, BacnetObjectType type) async {
    final connection = await database.getConnectionById(row.connectionId);
    if (connection == null) return true; // connexion supprimée : rien à relâcher

    if (connection.connectionType == 'bacnet') {
      final bacnet = _ref.read(bacnetServiceProvider);
      final typeCode = bacnetObjectTypeCode(type);
      if (row.kind == AppOverrideKind.outOfService) {
        final response = await bacnet.writeProperty(
          host: connection.host,
          port: connection.port,
          objectType: typeCode,
          objectInstance: row.objectInstance,
          propertyId: BacnetPropertyId.outOfService,
          value: false,
        );
        return response.isSuccess;
      }
      await bacnet.writePointValue(
        host: connection.host,
        port: connection.port,
        objectType: typeCode,
        objectInstance: row.objectInstance,
        value: null, // relinquish
        priority: row.priority ?? 8,
      );
      return true;
    }

    final factory = _ref.read(apiClientFactoryProvider);
    final client = factory.build(await factory.resolve(connection));
    try {
      return row.kind == AppOverrideKind.outOfService
          ? await client.releaseInput(type, row.objectInstance)
          : await client.releaseOverride(type, row.objectInstance, priority: row.priority ?? 8);
    } finally {
      client.dispose();
    }
  }
}

final timedOverrideServiceProvider = Provider<TimedOverrideService>((ref) {
  final service = TimedOverrideService(ref)..start();
  ref.onDispose(service.dispose);
  return service;
});
