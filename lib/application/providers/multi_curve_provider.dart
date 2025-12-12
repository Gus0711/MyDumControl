import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../domain/models/multi_curve_chart.dart';
import '../../domain/models/trend_log.dart';
import '../../domain/models/bacnet_object.dart';
import 'active_connection_provider.dart';
import 'trend_log_provider.dart';
import 'bacnet_provider.dart';
import 'points_provider.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

/// État du viewer multi-courbes
class MultiCurveViewerState {
  final bool isLoading;
  final String? error;
  final MultiCurveData? data;
  final TrendPeriod selectedPeriod;
  final String? loadingMessage;
  final List<int> selectedTrendLogInstances;
  final Map<int, bool> curveVisibility;
  final Map<int, String> curveNames;
  final Map<int, String?> curveUnits;

  const MultiCurveViewerState({
    this.isLoading = false,
    this.error,
    this.data,
    this.selectedPeriod = TrendPeriod.day,
    this.loadingMessage,
    this.selectedTrendLogInstances = const [],
    this.curveVisibility = const {},
    this.curveNames = const {},
    this.curveUnits = const {},
  });

  MultiCurveViewerState copyWith({
    bool? isLoading,
    String? error,
    MultiCurveData? data,
    TrendPeriod? selectedPeriod,
    String? loadingMessage,
    List<int>? selectedTrendLogInstances,
    Map<int, bool>? curveVisibility,
    Map<int, String>? curveNames,
    Map<int, String?>? curveUnits,
  }) {
    return MultiCurveViewerState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      data: data ?? this.data,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      loadingMessage: loadingMessage,
      selectedTrendLogInstances:
          selectedTrendLogInstances ?? this.selectedTrendLogInstances,
      curveVisibility: curveVisibility ?? this.curveVisibility,
      curveNames: curveNames ?? this.curveNames,
      curveUnits: curveUnits ?? this.curveUnits,
    );
  }

  /// Nombre de courbes sélectionnées
  int get curveCount => selectedTrendLogInstances.length;

  /// Vérifie si on peut ajouter une courbe (max 8)
  bool get canAddCurve => curveCount < 8;

  /// Vérifie si on peut supprimer une courbe (min 2 pour comparaison)
  bool get canRemoveCurve => curveCount > 2;
}

/// Notifier pour gérer le chargement des données multi-courbes
class MultiCurveViewerNotifier extends StateNotifier<MultiCurveViewerState> {
  final Ref _ref;
  final String chartId;

  // Cache des données brutes par instance de trend log
  final Map<int, TrendLogData> _cachedTrendLogData = {};

  // Type de connexion utilisé lors du dernier chargement
  bool? _lastConnectionWasBacnet;
  int? _lastConnectionId;

  MultiCurveViewerNotifier(this._ref, this.chartId)
      : super(const MultiCurveViewerState());

  /// Initialise avec une liste d'instances de trend log
  Future<void> initialize(List<int> trendLogInstances,
      {Map<int, String>? names, Map<int, String?>? units}) async {
    if (trendLogInstances.isEmpty) return;

    // Limiter à 8 courbes max
    final instances = trendLogInstances.take(8).toList();

    // Générer les noms par défaut si non fournis
    final curveNames = names ?? {};
    for (int i = 0; i < instances.length; i++) {
      curveNames.putIfAbsent(instances[i], () => 'Courbe ${i + 1}');
    }

    // Initialiser la visibilité (toutes visibles par défaut)
    final visibility = <int, bool>{};
    for (final instance in instances) {
      visibility[instance] = true;
    }

    state = state.copyWith(
      selectedTrendLogInstances: instances,
      curveNames: curveNames,
      curveUnits: units ?? {},
      curveVisibility: visibility,
    );

    await loadData();
  }

  /// Ajoute une courbe au graphique
  Future<void> addCurve(int trendLogInstance,
      {String? name, String? units}) async {
    if (!state.canAddCurve) {
      _logger.w('addCurve: maximum 8 curves reached');
      return;
    }

    if (state.selectedTrendLogInstances.contains(trendLogInstance)) {
      _logger.w('addCurve: instance $trendLogInstance already exists');
      return;
    }

    final newInstances = [...state.selectedTrendLogInstances, trendLogInstance];
    final newNames = Map<int, String>.from(state.curveNames);
    newNames[trendLogInstance] = name ?? 'Courbe ${newInstances.length}';

    final newUnits = Map<int, String?>.from(state.curveUnits);
    newUnits[trendLogInstance] = units;

    final newVisibility = Map<int, bool>.from(state.curveVisibility);
    newVisibility[trendLogInstance] = true;

    state = state.copyWith(
      selectedTrendLogInstances: newInstances,
      curveNames: newNames,
      curveUnits: newUnits,
      curveVisibility: newVisibility,
    );

    // Charger les données pour la nouvelle courbe
    await _loadSingleCurveData(trendLogInstance);
    _rebuildMultiCurveData();
  }

  /// Supprime une courbe du graphique
  void removeCurve(int trendLogInstance) {
    if (!state.canRemoveCurve) {
      _logger.w('removeCurve: minimum 2 curves required');
      return;
    }

    final newInstances = state.selectedTrendLogInstances
        .where((i) => i != trendLogInstance)
        .toList();

    final newNames = Map<int, String>.from(state.curveNames);
    newNames.remove(trendLogInstance);

    final newUnits = Map<int, String?>.from(state.curveUnits);
    newUnits.remove(trendLogInstance);

    final newVisibility = Map<int, bool>.from(state.curveVisibility);
    newVisibility.remove(trendLogInstance);

    _cachedTrendLogData.remove(trendLogInstance);

    state = state.copyWith(
      selectedTrendLogInstances: newInstances,
      curveNames: newNames,
      curveUnits: newUnits,
      curveVisibility: newVisibility,
    );

    _rebuildMultiCurveData();
  }

  /// Toggle la visibilité d'une courbe
  void toggleCurveVisibility(int trendLogInstance) {
    final newVisibility = Map<int, bool>.from(state.curveVisibility);
    newVisibility[trendLogInstance] =
        !(newVisibility[trendLogInstance] ?? true);

    state = state.copyWith(curveVisibility: newVisibility);

    // Mettre à jour le MultiCurveData
    if (state.data != null) {
      state = state.copyWith(
        data: state.data!.toggleCurveVisibility(trendLogInstance),
      );
    }
  }

  /// Change la période sélectionnée
  Future<void> setPeriod(TrendPeriod period) async {
    if (period == state.selectedPeriod) return;

    state = state.copyWith(selectedPeriod: period);
    await loadData(forceRefresh: true);
  }

  /// Charge les données pour toutes les courbes
  Future<void> loadData({bool forceRefresh = false}) async {
    if (state.selectedTrendLogInstances.isEmpty) return;

    final connectionState = _ref.read(activeConnectionProvider);
    final currentIsBacnet = connectionState.isBacnetConnection;
    final currentConnectionId = connectionState.connection?.id;

    // Vérifier si la connexion a changé -> invalider le cache
    if (_lastConnectionWasBacnet != null &&
        (_lastConnectionWasBacnet != currentIsBacnet ||
            _lastConnectionId != currentConnectionId)) {
      _logger.i('loadData: connection changed, invalidating cache');
      _cachedTrendLogData.clear();
      forceRefresh = true;
    }

    _lastConnectionWasBacnet = currentIsBacnet;
    _lastConnectionId = currentConnectionId;

    // Si pas de force refresh et données en cache, utiliser le cache
    if (!forceRefresh && _cachedTrendLogData.isNotEmpty) {
      _rebuildMultiCurveData();
      return;
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
      loadingMessage: 'Chargement des courbes...',
    );

    try {
      // Charger les données pour chaque courbe
      int loaded = 0;
      for (final instance in state.selectedTrendLogInstances) {
        loaded++;
        state = state.copyWith(
          loadingMessage:
              'Chargement courbe $loaded/${state.selectedTrendLogInstances.length}...',
        );
        await _loadSingleCurveData(instance);
      }

      _rebuildMultiCurveData();

      state = state.copyWith(
        isLoading: false,
        loadingMessage: null,
      );
    } catch (e) {
      _logger.e('loadData error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur: $e',
        loadingMessage: null,
      );
    }
  }

  /// Charge les données d'une seule courbe en utilisant le trendLogViewerProvider existant
  Future<void> _loadSingleCurveData(int trendLogInstance) async {
    _logger.i('_loadSingleCurveData: loading instance $trendLogInstance via trendLogViewerProvider');

    try {
      // Utiliser le provider existant qui fonctionne bien
      final notifier = _ref.read(trendLogViewerProvider(trendLogInstance).notifier);

      // Charger les données avec la période sélectionnée
      await notifier.loadData(period: state.selectedPeriod, forceRefresh: false);

      // Récupérer l'état après chargement
      final viewerState = _ref.read(trendLogViewerProvider(trendLogInstance));

      _logger.i('_loadSingleCurveData: instance $trendLogInstance -> viewerState.data = ${viewerState.data != null ? "${viewerState.data!.records.length} records" : "null"}');

      if (viewerState.data != null) {
        final data = viewerState.data!;

        // Log des types de records
        final numericCount = data.records.where((r) => r.isValueRecord && r.numericValue != null).length;
        _logger.i('_loadSingleCurveData: instance $trendLogInstance -> $numericCount records with numeric values');

        _cachedTrendLogData[trendLogInstance] = data;
      } else if (viewerState.error != null) {
        _logger.w('_loadSingleCurveData: instance $trendLogInstance -> error: ${viewerState.error}');
      }
    } catch (e, stack) {
      _logger.e('_loadSingleCurveData error for instance $trendLogInstance: $e');
      _logger.e('Stack: $stack');
    }
  }

  /// Charge depuis BACnet
  Future<TrendLogData?> _loadFromBacnet(int trendLogInstance) async {
    final bacnetConnection = _ref.read(activeBacnetConnectionProvider);
    final bacnetService = _ref.read(bacnetServiceProvider);

    if (bacnetConnection == null) {
      _logger.w('_loadFromBacnet: bacnetConnection is null');
      return null;
    }

    final maxRecords = _getMaxRecordsForPeriod(state.selectedPeriod);

    final records = await bacnetService.readTrendLogBuffer(
      host: bacnetConnection.host,
      port: bacnetConnection.port,
      trendLogInstance: trendLogInstance,
      maxRecords: maxRecords,
    );

    if (records.isEmpty) return null;

    final trendRecords = records
        .map((r) => TrendLogRecord(
              timestamp: r.timestamp,
              value: r.value,
              type: TrendRecordType.value,
              status: r.statusFlags != null ? 'flags: ${r.statusFlags}' : null,
            ))
        .toList();

    return TrendLogData.fromRecords(trendRecords);
  }

  /// Charge depuis l'API
  Future<TrendLogData?> _loadFromApi(int trendLogInstance) async {
    final connectionState = _ref.read(activeConnectionProvider);
    final client = connectionState.client;

    if (client == null) {
      _logger.w('_loadFromApi: client is null');
      return null;
    }

    // Charger toutes les données (allData=true pour récupérer l'historique complet)
    // Le filtrage par période sera fait après
    final allData = state.selectedPeriod == TrendPeriod.all ||
                    state.selectedPeriod == TrendPeriod.month;

    final buffer = await client.getTrendLogBuffer(
      trendLogInstance,
      allData: allData,
    );

    if (buffer == null || buffer.isEmpty) return null;

    return TrendLogBufferParser.parseV1(buffer);
  }

  /// Filtre les données par période
  TrendLogData _filterByPeriod(TrendLogData data, TrendPeriod period) {
    if (period == TrendPeriod.all || period == TrendPeriod.custom) {
      return data;
    }

    final now = DateTime.now();
    final cutoff = now.subtract(period.duration);

    return data.filterByTimeRange(cutoff, now);
  }

  /// Reconstruit le MultiCurveData à partir des données en cache
  void _rebuildMultiCurveData() {
    _logger.i('_rebuildMultiCurveData: cache size = ${_cachedTrendLogData.length}');
    _logger.i('_rebuildMultiCurveData: selectedInstances = ${state.selectedTrendLogInstances}');

    if (_cachedTrendLogData.isEmpty) {
      _logger.w('_rebuildMultiCurveData: cache is empty!');
      state = state.copyWith(data: null);
      return;
    }

    final dataList = <({
      int instance,
      String name,
      String? units,
      TrendLogData data,
      String colorTheme
    })>[];

    int colorIndex = 0;
    for (final instance in state.selectedTrendLogInstances) {
      final cachedData = _cachedTrendLogData[instance];
      _logger.d('_rebuildMultiCurveData: instance $instance -> cachedData = ${cachedData != null ? "${cachedData.records.length} records" : "null"}');
      if (cachedData != null) {
        // Compter les records avec valeurs numériques
        final numericRecords = cachedData.records.where((r) => r.isValueRecord && r.numericValue != null).length;
        _logger.d('_rebuildMultiCurveData: instance $instance -> $numericRecords numeric records');

        dataList.add((
          instance: instance,
          name: state.curveNames[instance] ?? 'Courbe ${colorIndex + 1}',
          units: state.curveUnits[instance],
          data: cachedData,
          colorTheme: getColorThemeByIndex(colorIndex),
        ));
        colorIndex++;
      }
    }

    _logger.i('_rebuildMultiCurveData: dataList has ${dataList.length} items');

    final multiCurveData = MultiCurveData.fromTrendLogDataList(
      dataList: dataList,
      visibility: state.curveVisibility,
    );

    _logger.i('_rebuildMultiCurveData: multiCurveData = ${multiCurveData != null ? "${multiCurveData.curves.length} curves" : "null"}');

    state = state.copyWith(data: multiCurveData);
  }

  /// Calcule le nombre max de records selon la période
  int _getMaxRecordsForPeriod(TrendPeriod period) {
    // Avec intervalle de 15 min: ~4 records/heure
    switch (period) {
      case TrendPeriod.hour:
        return 10; // ~2.5 heures de données
      case TrendPeriod.day:
        return 100; // ~25 heures
      case TrendPeriod.week:
        return 700; // ~7 jours
      case TrendPeriod.month:
        return 3000; // ~30 jours
      case TrendPeriod.all:
      case TrendPeriod.custom:
        return 10000; // Max
    }
  }

  /// Rafraîchit toutes les données
  Future<void> refresh() async {
    await loadData(forceRefresh: true);
  }

  /// Met à jour le nom d'une courbe
  void setCurveName(int trendLogInstance, String name) {
    final newNames = Map<int, String>.from(state.curveNames);
    newNames[trendLogInstance] = name;
    state = state.copyWith(curveNames: newNames);
    _rebuildMultiCurveData();
  }
}

/// Provider family pour les viewers multi-courbes
/// Chaque chartId a son propre état
final multiCurveViewerProvider = StateNotifierProvider.family<
    MultiCurveViewerNotifier, MultiCurveViewerState, String>(
  (ref, chartId) => MultiCurveViewerNotifier(ref, chartId),
);

/// Représente un trend log disponible
class AvailableTrendLog {
  final int instance;
  final String pointKey;
  final String? pointName;

  const AvailableTrendLog({
    required this.instance,
    required this.pointKey,
    this.pointName,
  });
}

/// Provider pour obtenir la liste des trend logs disponibles avec noms des points
final availableTrendLogsProvider =
    FutureProvider<List<AvailableTrendLog>>((ref) async {
  final mapping = await ref.watch(trendLogMappingProvider.future);
  final pointsState = ref.watch(pointsProvider);

  // Créer un index des points par clé (type:instance)
  // Le mapping utilise apiName (ex: "analog-input:101")
  final pointsByKey = <String, BacnetObject>{};
  for (final point in pointsState.points) {
    final key = '${point.type.apiName}:${point.instance}';
    pointsByKey[key] = point;
  }

  // Inverser le mapping: instance -> pointKey et récupérer le nom
  final result = <AvailableTrendLog>[];

  for (final entry in mapping.entries) {
    final pointKey = entry.key;
    final trendLogInstance = entry.value;

    // Chercher le point correspondant
    final point = pointsByKey[pointKey];
    final pointName = point?.objectName;

    result.add(AvailableTrendLog(
      instance: trendLogInstance,
      pointKey: pointKey,
      pointName: pointName,
    ));
  }

  // Trier par nom de point (ou pointKey si pas de nom)
  result.sort((a, b) {
    final nameA = a.pointName ?? a.pointKey;
    final nameB = b.pointName ?? b.pointKey;
    return nameA.toLowerCase().compareTo(nameB.toLowerCase());
  });

  return result;
});
