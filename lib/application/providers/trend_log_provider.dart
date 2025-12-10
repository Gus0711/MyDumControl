import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../domain/models/trend_log.dart';
import '../../data/services/bacnet_service.dart';
import 'active_connection_provider.dart';
import 'cache_provider.dart';
import 'bacnet_provider.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

/// Provider pour le mapping trend-log -> point
/// Clé: "objectType:objectInstance" (ex: "analog-value:454")
/// Valeur: instance du trend-log (ex: 300454)
///
/// Utilise le cache local pour éviter de recharger à chaque navigation
/// Supporte les connexions API (V1/V2) et BACnet natives
final trendLogMappingProvider = FutureProvider<Map<String, int>>((ref) async {
  final connectionState = ref.watch(activeConnectionProvider);
  final connection = connectionState.connection;

  _logger.i('trendLogMappingProvider: called, connection=${connection?.name}, isBacnet=${connectionState.isBacnetConnection}');

  if (connection == null) {
    _logger.w('trendLogMappingProvider: connection is null, returning empty');
    return {};
  }

  final connectionId = connection.id;
  final cacheService = ref.read(cacheServiceProvider);

  // ÉTAPE 1: Essayer de charger depuis le cache d'abord (seulement si non vide)
  final cachedMapping = await cacheService.getCachedTrendLogMapping(connectionId);
  _logger.d('trendLogMappingProvider: cached mapping = $cachedMapping');
  if (cachedMapping != null && cachedMapping.isNotEmpty) {
    _logger.i('trendLogMappingProvider: loaded ${cachedMapping.length} mappings from cache');

    // Rafraîchir en arrière-plan (sans bloquer)
    if (connectionState.isBacnetConnection) {
      final bacnetConnection = ref.watch(activeBacnetConnectionProvider);
      final bacnetService = ref.read(bacnetServiceProvider);
      if (bacnetConnection != null && bacnetConnection.deviceId != null) {
        _refreshBacnetMappingInBackground(
          bacnetService,
          bacnetConnection.host,
          bacnetConnection.port,
          bacnetConnection.deviceId!,
          connectionId,
          cacheService,
        );
      }
    } else if (connectionState.client != null) {
      _refreshMappingInBackground(connectionState.client!, connectionId, cacheService);
    }

    return cachedMapping;
  }

  // ÉTAPE 2: Charger depuis l'API ou BACnet
  if (connectionState.isBacnetConnection) {
    // Connexion BACnet native
    // IMPORTANT: utiliser watch pour que le provider re-évalue quand la connexion BACnet change
    final bacnetConnection = ref.watch(activeBacnetConnectionProvider);
    final bacnetService = ref.read(bacnetServiceProvider);

    _logger.i('trendLogMappingProvider: BACnet connection detected');
    _logger.i('trendLogMappingProvider: bacnetConnection=$bacnetConnection');

    if (bacnetConnection == null || bacnetConnection.deviceId == null) {
      _logger.w('trendLogMappingProvider: bacnetConnection is null or deviceId is null');
      return {};
    }

    _logger.i('trendLogMappingProvider: loading from BACnet... host=${bacnetConnection.host}, port=${bacnetConnection.port}, deviceId=${bacnetConnection.deviceId}');
    final trendLogs = await bacnetService.discoverTrendLogs(
      host: bacnetConnection.host,
      port: bacnetConnection.port,
      deviceId: bacnetConnection.deviceId!,
    );

    _logger.i('trendLogMappingProvider: discoverTrendLogs returned ${trendLogs.length} trend logs');

    // Construire le mapping à partir des TrendLogs découverts
    final mapping = <String, int>{};
    for (final tl in trendLogs) {
      final key = tl.trackedObjectKey;
      _logger.d('trendLogMappingProvider: TrendLog ${tl.instance} -> trackedKey=$key (type=${tl.trackedObjectType}, instance=${tl.trackedObjectInstance})');
      if (key != null) {
        mapping[key] = tl.instance;
      }
    }

    _logger.i('trendLogMappingProvider: loaded ${mapping.length} mappings from BACnet');

    // Sauvegarder en cache
    await cacheService.cacheTrendLogMapping(connectionId, mapping);

    return mapping;
  } else {
    // Connexion API (V1/V2)
    final client = connectionState.client;
    if (client == null) {
      return {};
    }

    _logger.i('trendLogMappingProvider: loading from API...');
    final mapping = await client.getTrendLogMapping();
    _logger.i('trendLogMappingProvider: loaded ${mapping.length} mappings from API');

    // Sauvegarder en cache
    await cacheService.cacheTrendLogMapping(connectionId, mapping);

    return mapping;
  }
});

/// Rafraîchit le mapping API en arrière-plan
Future<void> _refreshMappingInBackground(
  dynamic client,
  int connectionId,
  dynamic cacheService,
) async {
  try {
    final mapping = await client.getTrendLogMapping();
    await cacheService.cacheTrendLogMapping(connectionId, mapping);
    _logger.i('trendLogMappingProvider: background refresh completed (${mapping.length} entries)');
  } catch (e) {
    _logger.w('trendLogMappingProvider: background refresh failed: $e');
  }
}

/// Rafraîchit le mapping BACnet en arrière-plan
Future<void> _refreshBacnetMappingInBackground(
  BacnetService bacnetService,
  String host,
  int port,
  int deviceId,
  int connectionId,
  dynamic cacheService,
) async {
  try {
    final trendLogs = await bacnetService.discoverTrendLogs(
      host: host,
      port: port,
      deviceId: deviceId,
    );

    final mapping = <String, int>{};
    for (final tl in trendLogs) {
      final key = tl.trackedObjectKey;
      if (key != null) {
        mapping[key] = tl.instance;
      }
    }

    await cacheService.cacheTrendLogMapping(connectionId, mapping);
    _logger.i('trendLogMappingProvider: BACnet background refresh completed (${mapping.length} entries)');
  } catch (e) {
    _logger.w('trendLogMappingProvider: BACnet background refresh failed: $e');
  }
}

/// Provider pour vérifier si un point a un trend-log associé
final hasTrendLogProvider = Provider.family<bool, String>((ref, pointKey) {
  final mappingAsync = ref.watch(trendLogMappingProvider);

  return mappingAsync.maybeWhen(
    data: (mapping) => mapping.containsKey(pointKey),
    orElse: () => false,
  );
});

/// Provider pour récupérer l'instance du trend-log d'un point
final trendLogInstanceProvider = Provider.family<int?, String>((ref, pointKey) {
  final mappingAsync = ref.watch(trendLogMappingProvider);

  return mappingAsync.maybeWhen(
    data: (mapping) => mapping[pointKey],
    orElse: () => null,
  );
});

/// État du viewer de trend log
class TrendLogViewerState {
  final bool isLoading;
  final String? error;
  final TrendLogData? data;
  final TrendPeriod selectedPeriod;
  final String? loadingMessage;

  const TrendLogViewerState({
    this.isLoading = false,
    this.error,
    this.data,
    this.selectedPeriod = TrendPeriod.month,
    this.loadingMessage,
  });

  TrendLogViewerState copyWith({
    bool? isLoading,
    String? error,
    TrendLogData? data,
    TrendPeriod? selectedPeriod,
    String? loadingMessage,
  }) {
    return TrendLogViewerState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      data: data ?? this.data,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      loadingMessage: loadingMessage,
    );
  }
}

/// Périodes prédéfinies pour les trends
enum TrendPeriod {
  hour('1h', Duration(hours: 1)),
  day('24h', Duration(days: 1)),
  week('7j', Duration(days: 7)),
  month('30j', Duration(days: 30)),
  all('Tout', Duration.zero),
  custom('Perso.', Duration.zero);

  final String label;
  final Duration duration;

  const TrendPeriod(this.label, this.duration);
}

/// Notifier pour gérer le chargement des données de trend
class TrendLogViewerNotifier extends StateNotifier<TrendLogViewerState> {
  final Ref _ref;
  final int trendLogInstance;

  // Cache du buffer brut pour éviter de recharger
  String? _cachedBuffer;
  TrendLogData? _cachedFullData;

  // Type de connexion utilisé lors du dernier chargement (pour détecter les changements)
  bool? _lastConnectionWasBacnet;
  int? _lastConnectionId;

  // Flag pour récupérer tout l'historique (sans limite de temps)
  bool _loadAllData = false;

  TrendLogViewerNotifier(this._ref, this.trendLogInstance)
      : super(const TrendLogViewerState());

  /// Charge les données du trend log
  /// Si allData=true, récupère tout l'historique sans limite de temps
  Future<void> loadData({TrendPeriod? period, bool forceRefresh = false, bool allData = false}) async {
    var selectedPeriod = period ?? state.selectedPeriod;
    _loadAllData = allData; // Stocker pour passage aux méthodes de chargement
    final connectionState = _ref.read(activeConnectionProvider);

    // Vérifier si le type de connexion ou la connexion a changé -> invalider le cache
    final currentIsBacnet = connectionState.isBacnetConnection;
    final currentConnectionId = connectionState.connection?.id;

    if (_lastConnectionWasBacnet != null &&
        (_lastConnectionWasBacnet != currentIsBacnet || _lastConnectionId != currentConnectionId)) {
      _logger.i('loadData: connection changed (wasBacnet=$_lastConnectionWasBacnet, isBacnet=$currentIsBacnet, lastId=$_lastConnectionId, currentId=$currentConnectionId), invalidating cache and resetting period');
      _cachedBuffer = null;
      _cachedFullData = null;
      // Réinitialiser la période à la valeur par défaut quand on change d'automate
      selectedPeriod = TrendPeriod.month;
      state = state.copyWith(selectedPeriod: selectedPeriod);
    }

    // Mettre à jour le type de connexion
    _lastConnectionWasBacnet = currentIsBacnet;
    _lastConnectionId = currentConnectionId;

    // Si on a déjà les données en cache et qu'on change juste la période
    if (!forceRefresh && _cachedFullData != null) {
      _applyPeriodFilter(selectedPeriod);
      return;
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedPeriod: selectedPeriod,
      loadingMessage: 'Connexion au contrôleur...',
    );

    try {
      // Vérifier si c'est une connexion BACnet (connectionState déjà lu au début)
      if (currentIsBacnet) {
        await _loadDataFromBacnet(selectedPeriod);
      } else {
        await _loadDataFromApi(connectionState, selectedPeriod);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur: $e',
        loadingMessage: null,
      );
    }
  }

  /// Charge les données depuis une connexion BACnet native
  Future<void> _loadDataFromBacnet(TrendPeriod selectedPeriod) async {
    _logger.i('_loadDataFromBacnet: starting for trendLogInstance=$trendLogInstance');

    final bacnetConnection = _ref.read(activeBacnetConnectionProvider);
    final bacnetService = _ref.read(bacnetServiceProvider);

    _logger.d('_loadDataFromBacnet: bacnetConnection=$bacnetConnection');

    if (bacnetConnection == null) {
      _logger.w('_loadDataFromBacnet: bacnetConnection is null');
      state = state.copyWith(isLoading: false, error: 'Non connecté (BACnet)', loadingMessage: null);
      return;
    }

    state = state.copyWith(loadingMessage: 'Lecture du buffer BACnet...');

    // Calculer le nombre de records à lire selon la période
    // Avec un intervalle de ~15 min: 4/h, 96/jour
    final maxRecords = _getMaxRecordsForPeriod(selectedPeriod);
    _logger.i('_loadDataFromBacnet: calling readTrendLogBuffer for instance $trendLogInstance, maxRecords=$maxRecords');

    // Lire le buffer via ReadRange
    List<TrendLogRecordData> records;
    try {
      records = await bacnetService.readTrendLogBuffer(
        host: bacnetConnection.host,
        port: bacnetConnection.port,
        trendLogInstance: trendLogInstance,
        maxRecords: maxRecords,
      );

      _logger.i('_loadDataFromBacnet: received ${records.length} records');
    } catch (e, st) {
      _logger.e('_loadDataFromBacnet: error reading buffer: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lecture buffer: $e',
        loadingMessage: null,
      );
      return;
    }

    if (records.isEmpty) {
      _logger.w('_loadDataFromBacnet: no records returned');
      state = state.copyWith(
        isLoading: false,
        error: 'Aucune donnée disponible',
        data: TrendLogData.fromRecords([]),
        loadingMessage: null,
      );
      return;
    }

    state = state.copyWith(loadingMessage: 'Analyse des données...');

    // Debug: afficher les premiers records
    for (int i = 0; i < 5 && i < records.length; i++) {
      final r = records[i];
      _logger.d('Record[$i]: timestamp=${r.timestamp}, value=${r.value} (type=${r.value?.runtimeType}), flags=${r.statusFlags}');
    }

    // Convertir les records BACnet en TrendLogRecord
    final trendRecords = records.map((r) => TrendLogRecord(
      timestamp: r.timestamp,
      value: r.value,
      type: TrendRecordType.value,
      status: r.statusFlags != null ? 'flags: ${r.statusFlags}' : null,
    )).toList();

    final trendData = TrendLogData.fromRecords(trendRecords);
    _logger.i('TrendLogViewer: parsed ${trendData.records.length} records from BACnet');

    // Debug: afficher les stats
    final valueRecordsCount = trendData.records.where((r) => r.isValueRecord && r.numericValue != null).length;
    _logger.i('TrendLogViewer: valueRecords with numeric value: $valueRecordsCount, min=${trendData.minValue}, max=${trendData.maxValue}');

    // Mettre en cache les données complètes
    _cachedFullData = trendData;

    // Appliquer le filtre de période
    _applyPeriodFilter(selectedPeriod);
  }

  /// Charge les données depuis l'API (V1/V2)
  Future<void> _loadDataFromApi(dynamic connectionState, TrendPeriod selectedPeriod) async {
    final client = connectionState.client;
    if (client == null) {
      state = state.copyWith(isLoading: false, error: 'Non connecté', loadingMessage: null);
      return;
    }

    state = state.copyWith(loadingMessage: _loadAllData
        ? 'Téléchargement de tout l\'historique...\n(peut prendre plusieurs minutes)'
        : 'Téléchargement de l\'historique...\n(peut prendre quelques minutes)');

    // Récupérer le buffer (avec ou sans limite de temps)
    final bufferData = await client.getTrendLogBuffer(trendLogInstance, allData: _loadAllData);

    if (bufferData == null || bufferData.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: 'Aucune donnée disponible',
        data: TrendLogData.fromRecords([]),
        loadingMessage: null,
      );
      return;
    }

    // Mettre en cache
    _cachedBuffer = bufferData;

    state = state.copyWith(loadingMessage: 'Analyse des données...');

    // Parser les données selon le format
    TrendLogData trendData;

    // Essayer d'abord de parser comme JSON (format V2 ou format /trend de V1)
    try {
      final jsonData = json.decode(bufferData);
      trendData = TrendLogBufferParser.parseV2(jsonData);
      _logger.i('TrendLogViewer: parsed ${trendData.records.length} records from JSON');
    } catch (e) {
      // Si le parsing JSON échoue, c'est probablement le format texte V1
      _logger.d('TrendLogViewer: JSON parse failed, trying V1 text format: $e');
      trendData = TrendLogBufferParser.parseV1(bufferData);
      _logger.i('TrendLogViewer: parsed ${trendData.records.length} records from V1 text format');
    }

    // Mettre en cache les données complètes
    _cachedFullData = trendData;

    // Appliquer le filtre de période
    _applyPeriodFilter(selectedPeriod);
  }

  /// Applique le filtre de période sur les données cachées
  void _applyPeriodFilter(TrendPeriod period) {
    if (_cachedFullData == null) return;

    TrendLogData filteredData = _cachedFullData!;

    // Filtrer par période si nécessaire (sauf pour "all" ou "custom")
    if (period != TrendPeriod.all && period != TrendPeriod.custom && period.duration != Duration.zero) {
      final now = DateTime.now();
      final start = now.subtract(period.duration);

      // Debug: afficher les plages de temps
      _logger.d('_applyPeriodFilter: period=$period');
      _logger.d('_applyPeriodFilter: now=$now (${now.timeZoneName})');
      _logger.d('_applyPeriodFilter: start=$start');

      // Afficher les timestamps min/max des données
      if (_cachedFullData!.records.isNotEmpty) {
        final sortedRecords = List.from(_cachedFullData!.records)
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        final dataStart = sortedRecords.first.timestamp;
        final dataEnd = sortedRecords.last.timestamp;
        _logger.d('_applyPeriodFilter: data range: $dataStart -> $dataEnd');

        // Convertir en UTC pour comparaison cohérente
        final startUtc = start.toUtc();
        final nowUtc = now.toUtc();
        _logger.d('_applyPeriodFilter: filter range (UTC): $startUtc -> $nowUtc');
        _logger.d('_applyPeriodFilter: data range (UTC): ${dataStart.toUtc()} -> ${dataEnd.toUtc()}');
      }

      final filtered = _cachedFullData!.filterByTimeRange(start, now);

      // Si le filtre ne retourne aucune donnée avec des valeurs, utiliser toutes les données
      final hasNumericValues = filtered.records.any((r) => r.isValueRecord && r.numericValue != null);
      _logger.d('_applyPeriodFilter: filtered ${filtered.records.length} records, hasNumericValues=$hasNumericValues');

      if (hasNumericValues) {
        filteredData = filtered;
      } else {
        _logger.w('_applyPeriodFilter: no data in period $period, using all data');
        // Garder toutes les données mais changer la période en "all"
        filteredData = _cachedFullData!;
      }
    }

    state = state.copyWith(
      isLoading: false,
      data: filteredData,
      selectedPeriod: period,
      loadingMessage: null,
    );
  }

  /// Change la période (utilise le cache, on récupère toujours 30 jours de données)
  /// Exception : "Tout" force un rechargement sans limite de temps
  void setPeriod(TrendPeriod period) {
    // Si on passe sur "Tout", recharger sans limite de temps
    if (period == TrendPeriod.all) {
      _cachedBuffer = null;
      _cachedFullData = null;
      loadData(period: period, allData: true);
      return;
    }

    if (_cachedFullData != null) {
      // Utiliser le cache - on a déjà 30 jours de données
      _applyPeriodFilter(period);
    } else {
      // Pas de cache, charger les données
      loadData(period: period);
    }
  }

  /// Force le rechargement des données
  Future<void> refresh() async {
    _cachedBuffer = null;
    _cachedFullData = null;
    await loadData(forceRefresh: true);
  }

  /// Calcule le nombre de records à lire selon la période
  /// Basé sur un intervalle typique de 15 minutes (96 records/jour)
  int _getMaxRecordsForPeriod(TrendPeriod period) {
    switch (period) {
      case TrendPeriod.hour:
        return 10; // ~2h de marge
      case TrendPeriod.day:
        return 150; // ~1.5 jour de marge
      case TrendPeriod.week:
        return 800; // ~8 jours
      case TrendPeriod.month:
        return 3500; // ~35 jours
      case TrendPeriod.all:
        return 10000; // Maximum
      case TrendPeriod.custom:
        return 3500; // Par défaut comme month
    }
  }
}

/// Provider family pour le viewer de trend log
final trendLogViewerProvider = StateNotifierProvider.family<
    TrendLogViewerNotifier, TrendLogViewerState, int>(
  (ref, trendLogInstance) => TrendLogViewerNotifier(ref, trendLogInstance),
);
