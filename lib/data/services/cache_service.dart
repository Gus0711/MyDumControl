import 'package:drift/drift.dart';
import 'package:logger/logger.dart';
import '../database/app_database.dart';
import '../../domain/models/bacnet_object.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

/// Service de gestion du cache local
/// Gère la mise en cache des données statiques pour améliorer les performances
class CacheService {
  final AppDatabase _database;

  CacheService(this._database);

  // ==========================================================================
  // === CACHE : Propriétés statiques des points ===
  // ==========================================================================

  /// Récupère les propriétés statiques des points depuis le cache
  /// Retourne null si le cache est vide ou expiré
  Future<Map<String, CachedPoint>?> getStaticPointsCache(int connectionId) async {
    try {
      final isValid = await _database.isPointsCacheValid(connectionId);
      if (!isValid) {
        _logger.d('Points cache invalid or expired for connection $connectionId');
        return null;
      }

      final cachedPoints = await _database.getAllCachedPoints(connectionId);
      if (cachedPoints.isEmpty) return null;

      _logger.i('Loaded ${cachedPoints.length} points from cache');
      return {for (var p in cachedPoints) p.pointRef: p};
    } catch (e) {
      _logger.e('Error loading points cache: $e');
      return null;
    }
  }

  /// Sauvegarde les propriétés statiques des points en cache
  Future<void> cacheStaticPoints(int connectionId, List<BacnetObject> points) async {
    try {
      final cacheEntries = points.map((p) => CachedPointsCompanion.insert(
            connectionId: connectionId,
            pointRef: p.objectId,
            objectType: p.type.apiName,
            instance: p.instance,
            objectName: p.objectName,
            units: Value(p.units),
            description: Value(p.description),
            activeText: Value(p.activeText),
            inactiveText: Value(p.inactiveText),
          )).toList();

      await _database.cachePoints(cacheEntries);
      _logger.i('Cached ${cacheEntries.length} points for connection $connectionId');
    } catch (e) {
      _logger.e('Error caching points: $e');
    }
  }

  /// Fusionne les données du cache avec les données live
  /// Les propriétés statiques viennent du cache, les valeurs live de l'API
  List<BacnetObject> mergeWithCache(
    List<BacnetObject> livePoints,
    Map<String, CachedPoint> cache,
  ) {
    return livePoints.map((point) {
      final cached = cache[point.objectId];
      if (cached == null) return point;

      // Si les données live ont déjà les propriétés statiques, on garde celles-ci
      // (elles sont peut-être plus récentes)
      return point.copyWith(
        objectName: point.objectName.isNotEmpty ? point.objectName : cached.objectName,
        units: point.units ?? cached.units,
        description: point.description ?? cached.description,
        activeText: point.activeText ?? cached.activeText,
        inactiveText: point.inactiveText ?? cached.inactiveText,
      );
    }).toList();
  }

  /// Crée des BacnetObject à partir du cache uniquement (pour affichage rapide)
  List<BacnetObject> createFromCache(Map<String, CachedPoint> cache) {
    return cache.values.map((cached) {
      final type = BacnetObjectType.fromApiName(cached.objectType);
      if (type == null) return null;

      return BacnetObject(
        type: type,
        instance: cached.instance,
        objectName: cached.objectName,
        units: cached.units,
        description: cached.description,
        activeText: cached.activeText,
        inactiveText: cached.inactiveText,
        presentValue: null, // Pas de valeur live
      );
    }).whereType<BacnetObject>().toList();
  }

  // ==========================================================================
  // === CACHE : Device Info ===
  // ==========================================================================

  /// Récupère le device info depuis le cache
  Future<DeviceInfo?> getCachedDeviceInfo(int connectionId) async {
    try {
      final isValid = await _database.isDeviceInfoCacheValid(connectionId);
      if (!isValid) return null;

      final cached = await _database.getCachedDeviceInfo(connectionId);
      if (cached == null) return null;

      _logger.i('Loaded device info from cache: ${cached.objectName}');
      return DeviceInfo(
        objectName: cached.objectName,
        modelName: cached.modelName,
        modelType: cached.modelType,
        softwareVersion: cached.softwareVersion,
        hostId: cached.hostId,
        hostName: cached.hostName,
        vendorName: cached.vendorName,
        description: cached.description,
        location: cached.location,
        deviceInstance: cached.deviceInstance,
      );
    } catch (e) {
      _logger.e('Error loading device info cache: $e');
      return null;
    }
  }

  /// Sauvegarde le device info en cache
  Future<void> cacheDeviceInfo(int connectionId, DeviceInfo info) async {
    try {
      await _database.cacheDeviceInfo(CachedDeviceInfoCompanion(
        connectionId: Value(connectionId),
        objectName: Value(info.objectName),
        modelName: Value(info.modelName),
        modelType: Value(info.modelType),
        softwareVersion: Value(info.softwareVersion),
        hostId: Value(info.hostId),
        hostName: Value(info.hostName),
        vendorName: Value(info.vendorName),
        description: Value(info.description),
        location: Value(info.location),
        deviceInstance: Value(info.deviceInstance),
        cachedAt: Value(DateTime.now()),
      ));
      _logger.i('Cached device info for connection $connectionId');
    } catch (e) {
      _logger.e('Error caching device info: $e');
    }
  }

  // ==========================================================================
  // === CACHE : Trend Log Mapping ===
  // ==========================================================================

  /// Récupère le mapping trend log depuis le cache
  Future<Map<String, int>?> getCachedTrendLogMapping(int connectionId) async {
    try {
      final mapping = await _database.getCachedTrendLogMapping(connectionId);
      if (mapping == null) return null;

      _logger.i('Loaded trend log mapping from cache: ${mapping.length} entries');
      return mapping;
    } catch (e) {
      _logger.e('Error loading trend log mapping cache: $e');
      return null;
    }
  }

  /// Sauvegarde le mapping trend log en cache
  Future<void> cacheTrendLogMapping(int connectionId, Map<String, int> mapping) async {
    try {
      await _database.cacheTrendLogMapping(connectionId, mapping);
      _logger.i('Cached trend log mapping: ${mapping.length} entries');
    } catch (e) {
      _logger.e('Error caching trend log mapping: $e');
    }
  }

  // ==========================================================================
  // === CACHE : Objects Summary ===
  // ==========================================================================

  /// Récupère le résumé des objets depuis le cache
  Future<ObjectsSummary?> getCachedObjectsSummary(int connectionId) async {
    try {
      final cached = await _database.getCachedObjectsSummary(connectionId);
      if (cached == null) return null;

      _logger.i('Loaded objects summary from cache');
      return ObjectsSummary(
        analogInputs: cached.analogInputs,
        analogOutputs: cached.analogOutputs,
        analogValues: cached.analogValues,
        binaryInputs: cached.binaryInputs,
        binaryOutputs: cached.binaryOutputs,
        binaryValues: cached.binaryValues,
        multiStateInputs: cached.multiStateInputs,
        multiStateOutputs: cached.multiStateOutputs,
        multiStateValues: cached.multiStateValues,
        schedules: cached.schedules,
      );
    } catch (e) {
      _logger.e('Error loading objects summary cache: $e');
      return null;
    }
  }

  /// Sauvegarde le résumé des objets en cache
  Future<void> cacheObjectsSummary(int connectionId, ObjectsSummary summary) async {
    try {
      await _database.cacheObjectsSummary(CachedObjectsSummaryCompanion(
        connectionId: Value(connectionId),
        analogInputs: Value(summary.analogInputs),
        analogOutputs: Value(summary.analogOutputs),
        analogValues: Value(summary.analogValues),
        binaryInputs: Value(summary.binaryInputs),
        binaryOutputs: Value(summary.binaryOutputs),
        binaryValues: Value(summary.binaryValues),
        multiStateInputs: Value(summary.multiStateInputs),
        multiStateOutputs: Value(summary.multiStateOutputs),
        multiStateValues: Value(summary.multiStateValues),
        schedules: Value(summary.schedules),
        cachedAt: Value(DateTime.now()),
      ));
      _logger.i('Cached objects summary');
    } catch (e) {
      _logger.e('Error caching objects summary: $e');
    }
  }

  // ==========================================================================
  // === Opérations globales ===
  // ==========================================================================

  /// Supprime tout le cache pour une connexion
  Future<void> clearAllCache(int connectionId) async {
    await _database.clearAllCache(connectionId);
    _logger.i('Cleared all cache for connection $connectionId');
  }

  /// Supprime le cache expiré (maintenance)
  Future<void> clearExpiredCache() async {
    await _database.clearExpiredCache();
    _logger.i('Cleared expired cache');
  }

  /// Statistiques du cache pour une connexion
  Future<CacheStats> getCacheStats(int connectionId) async {
    final pointsCount = await _database.countCachedPoints(connectionId);
    final hasDeviceInfo = await _database.isDeviceInfoCacheValid(connectionId);
    final hasTrendMapping = await _database.isTrendLogMappingCacheValid(connectionId);
    final hasSummary = await _database.isObjectsSummaryCacheValid(connectionId);

    return CacheStats(
      cachedPointsCount: pointsCount,
      hasDeviceInfo: hasDeviceInfo,
      hasTrendLogMapping: hasTrendMapping,
      hasObjectsSummary: hasSummary,
    );
  }
}

/// Statistiques du cache
class CacheStats {
  final int cachedPointsCount;
  final bool hasDeviceInfo;
  final bool hasTrendLogMapping;
  final bool hasObjectsSummary;

  const CacheStats({
    required this.cachedPointsCount,
    required this.hasDeviceInfo,
    required this.hasTrendLogMapping,
    required this.hasObjectsSummary,
  });

  bool get isEmpty =>
      cachedPointsCount == 0 &&
      !hasDeviceInfo &&
      !hasTrendLogMapping &&
      !hasObjectsSummary;

  @override
  String toString() =>
      'CacheStats(points: $cachedPointsCount, deviceInfo: $hasDeviceInfo, '
      'trendMapping: $hasTrendLogMapping, summary: $hasObjectsSummary)';
}
