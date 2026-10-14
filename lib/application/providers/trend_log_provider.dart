import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../domain/models/trend_log.dart';
import '../../data/services/api_service.dart';
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
  // Only watch the fields that matter (not deviceInfo/summary/flags), and do
  // every watch before the first await.
  final connectionId = ref.watch(activeConnectionProvider.select((s) => s.connection?.id));
  final isBacnet = ref.watch(activeConnectionProvider.select((s) => s.isBacnetConnection));
  final client = ref.watch(activeConnectionProvider.select((s) => s.client));
  final bacnetConnection = isBacnet ? ref.watch(activeBacnetConnectionProvider) : null;

  _logger.i('trendLogMappingProvider: called, connectionId=$connectionId, isBacnet=$isBacnet');

  if (connectionId == null) {
    _logger.w('trendLogMappingProvider: connection is null, returning empty');
    return {};
  }

  // True once this evaluation is obsolete (connection changed / disposed)
  var disposed = false;
  ref.onDispose(() => disposed = true);

  final cacheService = ref.read(cacheServiceProvider);

  // ÉTAPE 1: Essayer de charger depuis le cache d'abord (seulement si non vide)
  final cachedMapping = await cacheService.getCachedTrendLogMapping(connectionId);
  if (cachedMapping != null && cachedMapping.isNotEmpty) {
    _logger.i('trendLogMappingProvider: loaded ${cachedMapping.length} mappings from cache');

    // Rafraîchir en arrière-plan (sans bloquer), une seule fois par évaluation
    // (donc par connexion), puis publier le résultat s'il a changé.
    Future<Map<String, int>?>? refreshFuture;
    if (isBacnet) {
      final bacnetService = ref.read(bacnetServiceProvider);
      if (bacnetConnection != null && bacnetConnection.deviceId != null) {
        refreshFuture = _refreshBacnetMappingInBackground(
          bacnetService,
          bacnetConnection.host,
          bacnetConnection.port,
          bacnetConnection.deviceId!,
          connectionId,
          cacheService,
        );
      }
    } else if (client != null) {
      refreshFuture = _refreshMappingInBackground(client, connectionId, cacheService);
    }

    refreshFuture?.then((fresh) {
      if (disposed || fresh == null || mapEquals(fresh, cachedMapping)) return;
      ref.state = AsyncData(fresh);
    });

    return cachedMapping;
  }

  // ÉTAPE 2: Charger depuis l'API ou BACnet
  if (isBacnet) {
    // Connexion BACnet native
    final bacnetService = ref.read(bacnetServiceProvider);

    _logger.i('trendLogMappingProvider: BACnet connection detected, bacnetConnection=$bacnetConnection');

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

    final mapping = _mappingFromBacnetTrendLogs(trendLogs);

    _logger.i('trendLogMappingProvider: loaded ${mapping.length} mappings from BACnet');

    // Sauvegarder en cache
    await cacheService.cacheTrendLogMapping(connectionId, mapping);

    return mapping;
  } else {
    // Connexion API (V1/V2)
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

/// Builds the "objectType:instance" -> trend log instance mapping
Map<String, int> _mappingFromBacnetTrendLogs(List<BacnetTrendLog> trendLogs) {
  final mapping = <String, int>{};
  for (final tl in trendLogs) {
    final key = tl.trackedObjectKey;
    if (key != null) {
      mapping[key] = tl.instance;
    }
  }
  return mapping;
}

/// Rafraîchit le mapping API en arrière-plan
/// Returns the fresh mapping, or null on failure.
Future<Map<String, int>?> _refreshMappingInBackground(
  ConnectedApiClient client,
  int connectionId,
  dynamic cacheService,
) async {
  try {
    final mapping = await client.getTrendLogMapping();
    await cacheService.cacheTrendLogMapping(connectionId, mapping);
    _logger.i('trendLogMappingProvider: background refresh completed (${mapping.length} entries)');
    return mapping;
  } catch (e) {
    _logger.w('trendLogMappingProvider: background refresh failed: $e');
    return null;
  }
}

/// Rafraîchit le mapping BACnet en arrière-plan
/// Returns the fresh mapping, or null on failure.
Future<Map<String, int>?> _refreshBacnetMappingInBackground(
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

    final mapping = _mappingFromBacnetTrendLogs(trendLogs);

    await cacheService.cacheTrendLogMapping(connectionId, mapping);
    _logger.i('trendLogMappingProvider: BACnet background refresh completed (${mapping.length} entries)');
    return mapping;
  } catch (e) {
    _logger.w('trendLogMappingProvider: BACnet background refresh failed: $e');
    return null;
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

/// Parses a raw API trend buffer (JSON V2 / V1 /trend, or V1 text).
/// Top-level so it can run in a background isolate via [compute].
TrendLogData parseTrendLogBuffer(String bufferData) {
  try {
    final jsonData = json.decode(bufferData);
    return TrendLogBufferParser.parseV2(jsonData);
  } catch (_) {
    // Si le parsing JSON échoue, c'est probablement le format texte V1
    return TrendLogBufferParser.parseV1(bufferData);
  }
}

/// Notifier pour gérer le chargement des données de trend
class TrendLogViewerNotifier extends StateNotifier<TrendLogViewerState> {
  final Ref _ref;
  final int trendLogInstance;

  TrendLogData? _cachedFullData;

  // Coverage of _cachedFullData: was it loaded with allData (API), and with
  // how many records (BACnet ReadRange). Used to reload when a longer period
  // is requested than what the cache holds.
  bool _cachedIsAllData = false;
  int _cachedMaxRecords = 0;

  // Type de connexion utilisé lors du dernier chargement (pour détecter les changements)
  bool? _lastConnectionWasBacnet;
  int? _lastConnectionId;

  // Flag pour récupérer tout l'historique (sans limite de temps)
  bool _loadAllData = false;

  // Incremented on every network load: older loads are ignored on completion
  int _requestId = 0;

  TrendLogViewerNotifier(this._ref, this.trendLogInstance)
      : super(const TrendLogViewerState());

  /// Current state, readable by owners of a private notifier instance
  /// (e.g. the multi-curve viewer).
  TrendLogViewerState get currentState => state;

  /// True if a load started with [requestId] for [connectionId] is obsolete
  bool _isStale(int requestId, int? connectionId) {
    if (!mounted || requestId != _requestId) return true;
    return _ref.read(activeConnectionProvider).connection?.id != connectionId;
  }

  /// True if the cached data can serve [period] without a new download
  bool _cacheCovers(TrendPeriod period, {required bool allData, required bool isBacnet}) {
    if (_cachedFullData == null) return false;
    if (isBacnet) return _getMaxRecordsForPeriod(period) <= _cachedMaxRecords;
    return !allData || _cachedIsAllData;
  }

  /// Charge les données du trend log
  /// Si allData=true, récupère tout l'historique sans limite de temps
  Future<void> loadData({TrendPeriod? period, bool forceRefresh = false, bool allData = false}) async {
    var selectedPeriod = period ?? state.selectedPeriod;
    final connectionState = _ref.read(activeConnectionProvider);

    // Vérifier si le type de connexion ou la connexion a changé -> invalider le cache
    final currentIsBacnet = connectionState.isBacnetConnection;
    final currentConnectionId = connectionState.connection?.id;

    if (_lastConnectionWasBacnet != null &&
        (_lastConnectionWasBacnet != currentIsBacnet || _lastConnectionId != currentConnectionId)) {
      _logger.i('loadData: connection changed (wasBacnet=$_lastConnectionWasBacnet, isBacnet=$currentIsBacnet, lastId=$_lastConnectionId, currentId=$currentConnectionId), invalidating cache and resetting period');
      _cachedFullData = null;
      // Réinitialiser la période à la valeur par défaut quand on change d'automate
      selectedPeriod = TrendPeriod.month;
      state = state.copyWith(selectedPeriod: selectedPeriod);
    }

    // Mettre à jour le type de connexion
    _lastConnectionWasBacnet = currentIsBacnet;
    _lastConnectionId = currentConnectionId;

    // Si on a déjà les données en cache (couvrant la période) et qu'on change juste la période
    if (!forceRefresh && _cacheCovers(selectedPeriod, allData: allData, isBacnet: currentIsBacnet)) {
      _applyPeriodFilter(selectedPeriod);
      return;
    }

    final requestId = ++_requestId;
    _loadAllData = allData; // Stocker pour passage aux méthodes de chargement

    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedPeriod: selectedPeriod,
      loadingMessage: 'Connexion au contrôleur...',
    );

    try {
      // Vérifier si c'est une connexion BACnet (connectionState déjà lu au début)
      if (currentIsBacnet) {
        await _loadDataFromBacnet(selectedPeriod, requestId, currentConnectionId);
      } else {
        await _loadDataFromApi(connectionState, requestId, currentConnectionId);
      }
    } catch (e) {
      if (_isStale(requestId, currentConnectionId)) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur: $e',
        loadingMessage: null,
      );
    }
  }

  /// Charge les données depuis une connexion BACnet native
  Future<void> _loadDataFromBacnet(TrendPeriod selectedPeriod, int requestId, int? connectionId) async {
    _logger.i('_loadDataFromBacnet: starting for trendLogInstance=$trendLogInstance');

    final bacnetConnection = _ref.read(activeBacnetConnectionProvider);
    final bacnetService = _ref.read(bacnetServiceProvider);

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
      if (_isStale(requestId, connectionId)) return;

      _logger.i('_loadDataFromBacnet: received ${records.length} records');
    } catch (e, st) {
      _logger.e('_loadDataFromBacnet: error reading buffer: $e\n$st');
      if (_isStale(requestId, connectionId)) return;
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

    if (kDebugMode) {
      for (int i = 0; i < 5 && i < records.length; i++) {
        final r = records[i];
        _logger.d('Record[$i]: timestamp=${r.timestamp}, value=${r.value} (type=${r.value?.runtimeType}), flags=${r.statusFlags}');
      }
    }

    // Convertir les records BACnet en TrendLogRecord
    final trendRecords = records.map((r) => TrendLogRecord(
      timestamp: r.timestamp,
      value: r.value,
      type: TrendRecordType.value,
      status: r.statusFlags != null ? 'flags: ${r.statusFlags}' : null,
    )).toList();

    final trendData = TrendLogData.fromRecords(trendRecords);
    _logger.i('TrendLogViewer: parsed ${trendData.records.length} records from BACnet, min=${trendData.minValue}, max=${trendData.maxValue}');

    // Mettre en cache les données complètes
    _cachedFullData = trendData;
    _cachedMaxRecords = maxRecords;
    _cachedIsAllData = false;

    // Appliquer le filtre de période (la plus récente demandée)
    _applyPeriodFilter(state.selectedPeriod);
  }

  /// Charge les données depuis l'API (V1/V2)
  Future<void> _loadDataFromApi(ActiveConnectionState connectionState, int requestId, int? connectionId) async {
    final client = connectionState.client;
    if (client == null) {
      state = state.copyWith(isLoading: false, error: 'Non connecté', loadingMessage: null);
      return;
    }

    final allData = _loadAllData;
    state = state.copyWith(loadingMessage: allData
        ? 'Téléchargement de tout l\'historique...\n(peut prendre plusieurs minutes)'
        : 'Téléchargement de l\'historique...\n(peut prendre quelques minutes)');

    // Récupérer le buffer (avec ou sans limite de temps)
    final bufferData = await client.getTrendLogBuffer(trendLogInstance, allData: allData);
    if (_isStale(requestId, connectionId)) return;

    if (bufferData == null || bufferData.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: 'Aucune donnée disponible',
        data: TrendLogData.fromRecords([]),
        loadingMessage: null,
      );
      return;
    }

    state = state.copyWith(loadingMessage: 'Analyse des données...');

    // Parser les données (JSON V2 / V1 /trend, ou texte V1) hors du thread UI
    final trendData = await compute(parseTrendLogBuffer, bufferData);
    if (_isStale(requestId, connectionId)) return;
    _logger.i('TrendLogViewer: parsed ${trendData.records.length} records from API buffer');

    // Mettre en cache les données complètes
    _cachedFullData = trendData;
    _cachedIsAllData = allData;
    _cachedMaxRecords = 0;

    // Appliquer le filtre de période (la plus récente demandée)
    _applyPeriodFilter(state.selectedPeriod);
  }

  /// Applique le filtre de période sur les données cachées
  void _applyPeriodFilter(TrendPeriod period) {
    if (_cachedFullData == null || !mounted) return;

    TrendLogData filteredData = _cachedFullData!;

    // Filtrer par période si nécessaire (sauf pour "all" ou "custom")
    if (period != TrendPeriod.all && period != TrendPeriod.custom && period.duration != Duration.zero) {
      final now = DateTime.now();
      final start = now.subtract(period.duration);

      final filtered = _cachedFullData!.filterByTimeRange(start, now);

      // Si le filtre ne retourne aucune donnée avec des valeurs, utiliser toutes les données
      final hasNumericValues = filtered.records.any((r) => r.isValueRecord && r.numericValue != null);
      if (kDebugMode) {
        _logger.d('_applyPeriodFilter: period=$period, start=$start, filtered ${filtered.records.length} records, hasNumericValues=$hasNumericValues');
      }

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

  /// Change la période. Utilise le cache s'il couvre la période demandée
  /// (API : 30 jours ; BACnet : selon le nombre de records lus), sinon recharge.
  /// "Tout" recharge sans limite de temps si le cache ne contient pas tout.
  void setPeriod(TrendPeriod period) {
    loadData(period: period, allData: period == TrendPeriod.all);
  }

  /// Force le rechargement des données (conserve le mode "Tout")
  Future<void> refresh() async {
    _cachedFullData = null;
    await loadData(forceRefresh: true, allData: state.selectedPeriod == TrendPeriod.all);
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

/// How long an unused viewer keeps its data before being disposed
/// (navigating back and forth does not re-download the buffer).
const _viewerKeepAliveDuration = Duration(minutes: 2);

/// Keeps an autoDispose provider alive for [_viewerKeepAliveDuration] after
/// its last listener is removed, so buffers are eventually freed.
void keepAliveForAWhile(Ref ref) {
  final link = ref.keepAlive();
  Timer? timer;
  ref.onCancel(() {
    timer?.cancel();
    timer = Timer(_viewerKeepAliveDuration, link.close);
  });
  ref.onResume(() => timer?.cancel());
  ref.onDispose(() => timer?.cancel());
}

/// Provider family pour le viewer de trend log
/// autoDispose with a limited keep-alive: buffers are released when no
/// screen/widget uses this trend log anymore.
final trendLogViewerProvider = StateNotifierProvider.autoDispose.family<
    TrendLogViewerNotifier, TrendLogViewerState, int>(
  (ref, trendLogInstance) {
    keepAliveForAWhile(ref);
    return TrendLogViewerNotifier(ref, trendLogInstance);
  },
);
