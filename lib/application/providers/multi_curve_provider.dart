import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../domain/models/multi_curve_chart.dart';
import '../../domain/models/trend_log.dart';
import '../../domain/models/bacnet_object.dart';
import 'active_connection_provider.dart';
import 'trend_log_provider.dart';
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

  /// Load error per trend log instance (curves missing from [data])
  final Map<int, String> curveErrors;

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
    this.curveErrors = const {},
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
    Map<int, String>? curveErrors,
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
      curveErrors: curveErrors ?? this.curveErrors,
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

  /// Max number of trend log buffers downloaded at the same time
  static const _maxConcurrentLoads = 3;

  // Cache des données (filtrées sur la période) par instance de trend log
  final Map<int, TrendLogData> _cachedTrendLogData = {};

  // Private loaders, one per curve: the multi-curve chart does not share
  // period/state with the single trend log screens (no side effects), and
  // the buffers are released with this notifier.
  final Map<int, TrendLogViewerNotifier> _loaders = {};

  // Type de connexion utilisé lors du dernier chargement
  bool? _lastConnectionWasBacnet;
  int? _lastConnectionId;

  // Incremented on every loadData: older loads are ignored on completion
  int _requestId = 0;

  MultiCurveViewerNotifier(this._ref, this.chartId)
      : super(const MultiCurveViewerState());

  TrendLogViewerNotifier _loaderFor(int instance) =>
      _loaders.putIfAbsent(instance, () => TrendLogViewerNotifier(_ref, instance));

  void _disposeLoader(int instance) {
    _loaders.remove(instance)?.dispose();
  }

  @override
  void dispose() {
    for (final loader in _loaders.values) {
      loader.dispose();
    }
    _loaders.clear();
    super.dispose();
  }

  /// Initialise avec une liste d'instances de trend log
  Future<void> initialize(List<int> trendLogInstances,
      {Map<int, String>? names, Map<int, String?>? units}) async {
    if (trendLogInstances.isEmpty) return;

    // Limiter à 8 courbes max
    final instances = trendLogInstances.take(8).toList();

    // Générer les noms par défaut si non fournis (copie : ne pas muter la map de l'appelant)
    final curveNames = Map<int, String>.of(names ?? const {});
    for (int i = 0; i < instances.length; i++) {
      curveNames.putIfAbsent(instances[i], () => 'Courbe ${i + 1}');
    }

    // Initialiser la visibilité (toutes visibles par défaut)
    final visibility = <int, bool>{};
    for (final instance in instances) {
      visibility[instance] = true;
    }

    // Oublier les courbes précédentes (réutilisation du même chartId)
    _cachedTrendLogData.clear();
    for (final instance in _loaders.keys.toList()) {
      if (!instances.contains(instance)) _disposeLoader(instance);
    }

    state = MultiCurveViewerState(
      selectedPeriod: state.selectedPeriod,
      selectedTrendLogInstances: instances,
      curveNames: curveNames,
      curveUnits: Map<int, String?>.of(units ?? const {}),
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
    final requestId = _requestId;
    final error = await _loadSingleCurveData(trendLogInstance);
    if (!mounted || requestId != _requestId) return;
    _setCurveError(trendLogInstance, error);
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

    final newErrors = Map<int, String>.from(state.curveErrors);
    newErrors.remove(trendLogInstance);

    _cachedTrendLogData.remove(trendLogInstance);
    _disposeLoader(trendLogInstance);

    state = state.copyWith(
      selectedTrendLogInstances: newInstances,
      curveNames: newNames,
      curveUnits: newUnits,
      curveVisibility: newVisibility,
      curveErrors: newErrors,
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
  /// Each curve is re-filtered on the new period, and re-downloaded when its
  /// cached buffer does not cover it (longer period, or "Tout").
  Future<void> setPeriod(TrendPeriod period) async {
    if (period == state.selectedPeriod) return;

    state = state.copyWith(selectedPeriod: period);
    await loadData(reloadCurves: true);
  }

  /// Charge les données pour toutes les courbes
  /// [forceRefresh]: re-download every buffer from the controller.
  /// [reloadCurves]: ask every curve loader again (period change), which
  /// only downloads when its cache does not cover the period.
  Future<void> loadData({bool forceRefresh = false, bool reloadCurves = false}) async {
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

    // Si pas de force refresh et toutes les courbes en cache, utiliser le cache
    final allCached = state.selectedTrendLogInstances.every(_cachedTrendLogData.containsKey);
    if (!forceRefresh && !reloadCurves && allCached) {
      _rebuildMultiCurveData();
      return;
    }

    final requestId = ++_requestId;
    final instances = List<int>.from(state.selectedTrendLogInstances);
    final total = instances.length;

    state = state.copyWith(
      isLoading: true,
      error: null,
      loadingMessage: 'Chargement des courbes...',
    );

    try {
      // Charger les courbes en parallèle (concurrence limitée)
      final errors = <int, String>{};
      var done = 0;
      var next = 0;

      Future<void> worker() async {
        while (next < instances.length) {
          final instance = instances[next++];
          final error = await _loadSingleCurveData(instance, forceRefresh: forceRefresh);
          if (!mounted || requestId != _requestId) return;
          if (error != null) errors[instance] = error;
          done++;
          state = state.copyWith(
            isLoading: true,
            loadingMessage: 'Chargement courbe $done/$total...',
          );
        }
      }

      await Future.wait([
        for (var i = 0; i < _maxConcurrentLoads && i < total; i++) worker(),
      ]);
      if (!mounted || requestId != _requestId) return;

      state = state.copyWith(curveErrors: errors);
      _rebuildMultiCurveData();

      state = state.copyWith(
        isLoading: false,
        error: errors.isEmpty ? null : _errorSummary(errors),
        loadingMessage: null,
      );
    } catch (e) {
      _logger.e('loadData error: $e');
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur: $e',
        loadingMessage: null,
      );
    }
  }

  String _errorSummary(Map<int, String> errors) {
    final names = errors.keys.map((i) => state.curveNames[i] ?? 'TL $i').join(', ');
    return '${errors.length} courbe(s) non chargée(s) : $names';
  }

  void _setCurveError(int instance, String? error) {
    final newErrors = Map<int, String>.from(state.curveErrors);
    if (error == null) {
      newErrors.remove(instance);
    } else {
      newErrors[instance] = error;
    }
    state = state.copyWith(
      curveErrors: newErrors,
      error: newErrors.isEmpty ? null : _errorSummary(newErrors),
    );
  }

  /// Charge les données d'une seule courbe via son loader privé
  /// Returns an error message, or null on success.
  Future<String?> _loadSingleCurveData(int trendLogInstance, {bool forceRefresh = false}) async {
    final period = state.selectedPeriod;
    _logger.i('_loadSingleCurveData: loading instance $trendLogInstance (period=$period, forceRefresh=$forceRefresh)');

    try {
      final loader = _loaderFor(trendLogInstance);

      await loader.loadData(
        period: period,
        forceRefresh: forceRefresh,
        allData: period == TrendPeriod.all,
      );

      final viewerState = loader.currentState;

      if (viewerState.error != null || viewerState.data == null) {
        _cachedTrendLogData.remove(trendLogInstance);
        final error = viewerState.error ?? 'Aucune donnée';
        _logger.w('_loadSingleCurveData: instance $trendLogInstance -> error: $error');
        return error;
      }

      _cachedTrendLogData[trendLogInstance] = viewerState.data!;
      return null;
    } catch (e, stack) {
      _logger.e('_loadSingleCurveData error for instance $trendLogInstance: $e\n$stack');
      _cachedTrendLogData.remove(trendLogInstance);
      return 'Erreur: $e';
    }
  }

  /// Reconstruit le MultiCurveData à partir des données en cache
  void _rebuildMultiCurveData() {
    if (!mounted) return;

    if (_cachedTrendLogData.isEmpty) {
      _logger.w('_rebuildMultiCurveData: cache is empty!');
      // copyWith cannot reset data to null: rebuild the state explicitly
      state = MultiCurveViewerState(
        isLoading: state.isLoading,
        error: state.error,
        selectedPeriod: state.selectedPeriod,
        loadingMessage: state.loadingMessage,
        selectedTrendLogInstances: state.selectedTrendLogInstances,
        curveVisibility: state.curveVisibility,
        curveNames: state.curveNames,
        curveUnits: state.curveUnits,
        curveErrors: state.curveErrors,
      );
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
      if (cachedData != null) {
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

    final multiCurveData = MultiCurveData.fromTrendLogDataList(
      dataList: dataList,
      visibility: state.curveVisibility,
    );

    _logger.i('_rebuildMultiCurveData: ${dataList.length} curves');

    state = state.copyWith(data: multiCurveData, error: state.error, loadingMessage: state.loadingMessage);
  }

  /// Rafraîchit toutes les données (re-télécharge tous les buffers)
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
/// Chaque chartId a son propre état ; autoDispose avec keep-alive limité
/// (les buffers sont libérés quand le graphique n'est plus affiché).
final multiCurveViewerProvider = StateNotifierProvider.autoDispose.family<
    MultiCurveViewerNotifier, MultiCurveViewerState, String>(
  (ref, chartId) {
    keepAliveForAWhile(ref);
    return MultiCurveViewerNotifier(ref, chartId);
  },
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
