import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/logger.dart';
import '../../domain/models/bacnet_object.dart';
import '../../data/services/bacnet/bacnet_constants.dart';
import 'active_connection_provider.dart';
import 'cache_provider.dart';
import 'bacnet_provider.dart';
import 'bacnet_type_codes.dart';

/// État des points BACnet avec cache des valeurs calculées
class PointsState {
  final List<BacnetObject> points;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final BacnetObjectType? filterType;

  /// Indique si les données statiques viennent du cache local
  final bool fromCache;

  /// Catégorie actuellement sélectionnée
  final PointCategory selectedCategory;

  /// Option de tri actuelle
  final PointSortOption sortOption;

  /// IDs des points favoris (pour le tri "Favoris d'abord")
  final Set<String> favoritePointIds;

  /// Filtre par sous-type (Analog/Binary/Multi) pour la catégorie courante
  final SubTypeFilter subTypeFilter;

  PointsState({
    this.points = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.filterType,
    this.fromCache = false,
    this.selectedCategory = PointCategory.inputs,
    this.sortOption = PointSortOption.nameAsc,
    this.favoritePointIds = const {},
    this.subTypeFilter = SubTypeFilter.all,
  });

  PointsState copyWith({
    List<BacnetObject>? points,
    bool? isLoading,
    String? error,
    String? searchQuery,
    BacnetObjectType? filterType,
    bool clearFilter = false,
    bool clearError = false,
    bool? fromCache,
    PointCategory? selectedCategory,
    PointSortOption? sortOption,
    Set<String>? favoritePointIds,
    SubTypeFilter? subTypeFilter,
  }) {
    return PointsState(
      points: points ?? this.points,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      filterType: clearFilter ? null : (filterType ?? this.filterType),
      fromCache: fromCache ?? this.fromCache,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      sortOption: sortOption ?? this.sortOption,
      favoritePointIds: favoritePointIds ?? this.favoritePointIds,
      subTypeFilter: subTypeFilter ?? this.subTypeFilter,
    );
  }

  /// Points filtrés selon la catégorie, la recherche et triés
  List<BacnetObject> getFilteredAndSortedPoints({PointCategory? category}) {
    final cat = category ?? selectedCategory;
    var result = cat.filterPoints(points);

    // Filtrer par sous-type (Analog/Binary/Multi) si pas "Tous"
    if (subTypeFilter != SubTypeFilter.all) {
      result = result.where((p) => subTypeFilter.matches(p.type)).toList();
    }

    // Filtrer par type spécifique (si défini)
    if (filterType != null) {
      result = result.where((p) => p.type == filterType).toList();
    }

    // Filtrer par recherche
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((p) {
        return p.objectName.toLowerCase().contains(query) ||
            (p.description?.toLowerCase().contains(query) ?? false) ||
            p.objectId.toLowerCase().contains(query);
      }).toList();
    }

    // Appliquer le tri
    result = _sortPoints(result);

    return result;
  }

  /// Trie les points selon l'option de tri actuelle
  List<BacnetObject> _sortPoints(List<BacnetObject> pointsToSort) {
    final sorted = List<BacnetObject>.from(pointsToSort);

    switch (sortOption) {
      case PointSortOption.nameAsc:
        sorted.sort((a, b) => a.objectName.toLowerCase().compareTo(b.objectName.toLowerCase()));
        break;
      case PointSortOption.nameDesc:
        sorted.sort((a, b) => b.objectName.toLowerCase().compareTo(a.objectName.toLowerCase()));
        break;
      case PointSortOption.typeAsc:
        sorted.sort((a, b) {
          final typeCompare = a.type.index.compareTo(b.type.index);
          if (typeCompare != 0) return typeCompare;
          return a.objectName.compareTo(b.objectName);
        });
        break;
      case PointSortOption.valueAsc:
        sorted.sort((a, b) => _compareValues(a.presentValue, b.presentValue));
        break;
      case PointSortOption.valueDesc:
        sorted.sort((a, b) => _compareValues(b.presentValue, a.presentValue));
        break;
      case PointSortOption.favoritesFirst:
        sorted.sort((a, b) {
          final aFav = favoritePointIds.contains(a.objectId);
          final bFav = favoritePointIds.contains(b.objectId);
          if (aFav && !bFav) return -1;
          if (!aFav && bFav) return 1;
          return a.objectName.toLowerCase().compareTo(b.objectName.toLowerCase());
        });
        break;
    }

    return sorted;
  }

  /// Compare deux valeurs pour le tri
  int _compareValues(dynamic a, dynamic b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;

    if (a is num && b is num) {
      return a.compareTo(b);
    }

    return a.toString().compareTo(b.toString());
  }

  /// Compte les points par catégorie
  Map<PointCategory, int> get pointCountByCategory {
    return {
      PointCategory.inputs: points.where((p) => p.type.isInput).length,
      PointCategory.outputs: points.where((p) => p.type.isOutput).length,
      PointCategory.variables: points.where((p) => p.type.isValue).length,
      PointCategory.others: points.where((p) =>
        !p.type.isInput && !p.type.isOutput && !p.type.isValue
      ).length,
      PointCategory.all: points.length,
    };
  }

  /// Compte les points par sous-type pour la catégorie donnée
  Map<SubTypeFilter, int> getSubTypeCountsForCategory(PointCategory category) {
    final categoryPoints = category.filterPoints(points);
    return {
      SubTypeFilter.all: categoryPoints.length,
      SubTypeFilter.analog: categoryPoints.where((p) => p.type.isAnalog).length,
      SubTypeFilter.binary: categoryPoints.where((p) => p.type.isBinary).length,
      SubTypeFilter.multiState: categoryPoints.where((p) => p.type.isMultiState).length,
    };
  }

  /// Retourne les sous-types disponibles (count > 0) pour une catégorie
  List<SubTypeFilter> getAvailableSubTypes(PointCategory category) {
    final counts = getSubTypeCountsForCategory(category);
    // Toujours inclure "all", puis les types qui ont des points
    final available = <SubTypeFilter>[SubTypeFilter.all];
    for (final filter in [SubTypeFilter.analog, SubTypeFilter.binary, SubTypeFilter.multiState]) {
      if ((counts[filter] ?? 0) > 0) {
        available.add(filter);
      }
    }
    return available;
  }

  /// Points forcés (overridden via priority-array OU entrées forcées via out-of-service)
  List<BacnetObject> get overriddenPoints {
    return points.where((p) =>
      p.isOverridden || (p.type.isInput && p.outOfService == true)
    ).toList();
  }

  /// Entrées forcées (via out-of-service)
  List<BacnetObject> get forcedInputs {
    return points.where((p) => p.type.isInput && p.outOfService == true).toList();
  }

  /// Nombre de points forcés (priority-array + entrées out-of-service)
  int get overriddenCount => overriddenPoints.length;

  /// Indique s'il y a au moins un point forcé
  bool get hasOverrides => overriddenPoints.isNotEmpty;
}

/// Notifier pour gérer les points BACnet
class PointsNotifier extends StateNotifier<PointsState> {
  final Ref _ref;

  PointsNotifier(this._ref) : super(PointsState());

  /// Generation token, bumped on every reset() (connection change).
  /// Background results captured with an older generation are dropped.
  int _generation = 0;

  /// In-flight guards: avoid overlapping loads/refreshes (auto-refresh +
  /// pull-to-refresh) for the same generation.
  Future<void>? _loadInFlight;
  Future<void>? _refreshInFlight;

  /// Forced reload queued behind [_loadInFlight] (see [loadPoints]).
  Future<void>? _forcedReloadPending;

  /// Connection id for which the static points cache was written during this
  /// session. The cache is only rewritten on first load or forceRefresh.
  int? _staticCacheWrittenFor;

  /// True if a result started with [generation] for [connectionId] may still
  /// be written to the state.
  bool _isCurrent(int generation, int? connectionId) {
    if (!mounted || generation != _generation) return false;
    return _ref.read(activeConnectionProvider).connection?.id == connectionId;
  }

  /// Réinitialise l'état (appelé lors du changement d'automate)
  void reset() {
    _generation++;
    _loadInFlight = null;
    _forcedReloadPending = null;
    _refreshInFlight = null;
    _staticCacheWrittenFor = null;
    state = PointsState();
    logger.i('PointsNotifier: reset');
  }

  /// The local cache was purged: loaded points stay displayed, but the static
  /// properties will be written to the cache again on the next load.
  void onCacheCleared() {
    _staticCacheWrittenFor = null;
  }

  /// Sort points by type, then by name.
  static void _sortByTypeThenName(List<BacnetObject> points) {
    points.sort((a, b) {
      final typeCompare = a.type.index.compareTo(b.type.index);
      if (typeCompare != 0) return typeCompare;
      return a.objectName.compareTo(b.objectName);
    });
  }

  /// Charge tous les points depuis l'automate
  /// Utilise le cache local pour les propriétés statiques (nom, unité, description)
  Future<void> loadPoints({bool forceRefresh = false}) {
    final inFlight = _loadInFlight;
    if (inFlight != null) {
      if (!forceRefresh) return inFlight;
      // A forced refresh must not be swallowed by a load already in flight
      // (possibly from the cache): reload once it completes. Concurrent
      // forced requests share a single reload.
      final generation = _generation;
      return _forcedReloadPending ??= inFlight.catchError((Object _) {}).then((_) {
        _forcedReloadPending = null;
        if (!mounted || generation != _generation) return null;
        return loadPoints(forceRefresh: true);
      });
    }
    final generation = _generation;
    final future = _loadPointsImpl(forceRefresh: forceRefresh, generation: generation);
    _loadInFlight = future;
    return future.whenComplete(() {
      if (_generation == generation) _loadInFlight = null;
    });
  }

  Future<void> _loadPointsImpl({required bool forceRefresh, required int generation}) async {
    final connectionState = _ref.read(activeConnectionProvider);
    if (!connectionState.isConnected) {
      state = state.copyWith(
        error: 'Non connecté',
        isLoading: false,
      );
      return;
    }

    // ========================================
    // CONNEXION BACNET NATIVE
    // ========================================
    if (connectionState.isBacnetConnection) {
      await _loadPointsBacnet(forceRefresh: forceRefresh, generation: generation);
      return;
    }

    // ========================================
    // CONNEXION API DISTECH
    // ========================================
    final client = connectionState.client;
    if (client == null) {
      state = state.copyWith(
        error: 'Client API non disponible',
        isLoading: false,
      );
      return;
    }

    final connectionId = connectionState.connection!.id;
    final cacheService = _ref.read(cacheServiceProvider);

    // ÉTAPE 1: Charger immédiatement depuis le cache (si disponible et non forcé)
    if (!forceRefresh && state.points.isEmpty) {
      final cachedPoints = await cacheService.getStaticPointsCache(connectionId);
      if (!_isCurrent(generation, connectionId)) return;
      if (cachedPoints != null && cachedPoints.isNotEmpty) {
        // Créer des BacnetObject à partir du cache (sans valeurs live)
        final pointsFromCache = cacheService.createFromCache(cachedPoints);

        // Trier par type puis par nom
        _sortByTypeThenName(pointsFromCache);

        logger.i('loadPoints: ${pointsFromCache.length} points loaded from cache (instant!)');

        state = state.copyWith(
          points: pointsFromCache,
          isLoading: true, // Continue à charger les valeurs live
          fromCache: true,
          clearError: true,
        );
      } else {
        state = state.copyWith(isLoading: true, clearError: true);
      }
    } else {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    // ÉTAPE 2: Charger les données fraîches de l'API
    try {
      final points = await client.getAllPointsOptimized();
      if (!_isCurrent(generation, connectionId)) {
        logger.w('loadPoints: stale result ignored (connection changed)');
        return;
      }

      // Trier par type puis par nom
      _sortByTypeThenName(points);

      logger.i('loadPoints: ${points.length} points loaded from API');

      // ÉTAPE 3: Mettre à jour le cache des propriétés statiques (en arrière-plan)
      // Only on first load of the session or on explicit forceRefresh:
      // static properties do not change between refreshes.
      if (forceRefresh || _staticCacheWrittenFor != connectionId) {
        _staticCacheWrittenFor = connectionId;
        cacheService.cacheStaticPoints(connectionId, points);
      }

      state = state.copyWith(
        points: points,
        isLoading: false,
        fromCache: false, // Données fraîches
      );
    } catch (e) {
      logger.e('loadPoints error: $e');
      if (!_isCurrent(generation, connectionId)) return;

      // En cas d'erreur, garder les données du cache si disponibles
      if (state.points.isNotEmpty && state.fromCache) {
        logger.w('loadPoints: keeping cached data due to API error');
        state = state.copyWith(
          error: 'Erreur API (données du cache affichées): $e',
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          error: 'Erreur: $e',
          isLoading: false,
        );
      }
    }
  }

  /// Charge les points via BACnet natif
  Future<void> _loadPointsBacnet({bool forceRefresh = false, required int generation}) async {
    final bacnetConnection = _ref.read(activeBacnetConnectionProvider);
    final connectionId = _ref.read(activeConnectionProvider).connection?.id;

    if (bacnetConnection == null) {
      state = state.copyWith(
        error: 'Connexion BACnet non établie',
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final bacnetService = _ref.read(bacnetServiceProvider);

      logger.i('_loadPointsBacnet: discovering objects from device ${bacnetConnection.deviceId}');

      // Découvrir les objets BACnet
      // Filtrer pour n'obtenir que les types de points (pas device, schedule, etc.)
      final objectTypesFilter = [
        0,  // analog-input
        1,  // analog-output
        2,  // analog-value
        3,  // binary-input
        4,  // binary-output
        5,  // binary-value
        13, // multi-state-input
        14, // multi-state-output
        19, // multi-state-value
      ];

      final points = await bacnetService.discoverObjects(
        host: bacnetConnection.host,
        port: bacnetConnection.port,
        deviceId: bacnetConnection.deviceId!,
        objectTypesFilter: objectTypesFilter,
      );
      if (!_isCurrent(generation, connectionId)) {
        logger.w('_loadPointsBacnet: stale result ignored (connection changed)');
        return;
      }

      // Trier par type puis par nom
      _sortByTypeThenName(points);

      logger.i('_loadPointsBacnet: ${points.length} points discovered via BACnet');

      state = state.copyWith(
        points: points,
        isLoading: false,
        fromCache: false,
      );
    } catch (e) {
      logger.e('_loadPointsBacnet error: $e');
      if (!_isCurrent(generation, connectionId)) return;
      state = state.copyWith(
        error: 'Erreur BACnet: $e',
        isLoading: false,
      );
    }
  }

  /// Rafraîchit les valeurs des points
  /// Pour BACnet: rafraîchit uniquement les present-value (rapide)
  /// Pour API: refetch silencieux (pas de spinner, pas de réécriture du cache)
  Future<void> refresh() {
    final inFlight = _refreshInFlight ?? _loadInFlight;
    if (inFlight != null) return inFlight;
    final generation = _generation;
    final future = _refreshImpl(generation);
    _refreshInFlight = future;
    return future.whenComplete(() {
      if (_generation == generation) _refreshInFlight = null;
    });
  }

  Future<void> _refreshImpl(int generation) async {
    final connectionState = _ref.read(activeConnectionProvider);
    if (!connectionState.isConnected) return;

    // ========================================
    // CONNEXION BACNET NATIVE - Refresh optimisé
    // ========================================
    if (connectionState.isBacnetConnection) {
      await _refreshAllValuesBacnet(generation);
      return;
    }

    // ========================================
    // CONNEXION API DISTECH
    // ========================================
    await _refreshValuesApi(generation);
  }

  /// Silent API refresh: no isLoading toggle and no static cache rewrite.
  /// The API has no values-only endpoint, so all points are fetched, but the
  /// state is only replaced if the connection is unchanged.
  Future<void> _refreshValuesApi(int generation) async {
    if (state.points.isEmpty || state.fromCache) {
      // Nothing loaded yet (or only static cache data): full load
      await loadPoints();
      return;
    }

    final connectionState = _ref.read(activeConnectionProvider);
    final client = connectionState.client;
    final connectionId = connectionState.connection?.id;
    if (client == null) return;

    try {
      final points = await client.getAllPointsOptimized();
      if (!_isCurrent(generation, connectionId)) {
        logger.w('_refreshValuesApi: stale result ignored (connection changed)');
        return;
      }
      _sortByTypeThenName(points);
      state = state.copyWith(points: points, fromCache: false, clearError: true);
    } catch (e) {
      logger.e('_refreshValuesApi error: $e');
    }
  }

  /// Rafraîchit toutes les valeurs BACnet en parallèle (optimisé)
  /// Inclut aussi les infos de forçage (priority-array) pour les objets commandables
  Future<void> _refreshAllValuesBacnet(int generation) async {
    final bacnetConnection = _ref.read(activeBacnetConnectionProvider);
    if (bacnetConnection == null) return;
    final connectionId = _ref.read(activeConnectionProvider).connection?.id;

    if (state.points.isEmpty) {
      // Pas de points chargés, faire une découverte complète
      await loadPoints();
      return;
    }

    logger.i('_refreshAllValuesBacnet: refreshing ${state.points.length} points');

    try {
      final bacnetService = _ref.read(bacnetServiceProvider);

      // Construire la liste des points à rafraîchir avec info commandable/input
      final pointsToRefresh = state.points.map((p) => (
        objectType: bacnetObjectTypeCode(p.type),
        objectInstance: p.instance,
        isCommandable: p.type.isCommandable,
        isInput: p.type.isInput,
      )).toList();

      // Rafraîchir en batch (valeurs + priority-array pour commandables)
      final refreshedData = await bacnetService.refreshMultiplePointValues(
        host: bacnetConnection.host,
        port: bacnetConnection.port,
        points: pointsToRefresh,
      );

      if (!_isCurrent(generation, connectionId)) {
        logger.w('_refreshAllValuesBacnet: stale result ignored (connection changed)');
        return;
      }

      logger.i('_refreshAllValuesBacnet: got ${refreshedData.length} points');

      // Mettre à jour les points avec les nouvelles valeurs, infos de forçage et alarmes
      final updatedPoints = state.points.map((point) {
        final key = '${bacnetObjectTypeCode(point.type)}:${point.instance}';
        final data = refreshedData[key];
        if (data != null) {
          return point.copyWith(
            presentValue: data.presentValue,
            isOverridden: data.isOverridden,
            overridePriority: data.isOverridden ? data.overridePriority : null,
            overrideValue: data.isOverridden ? data.overrideValue : null,
            outOfService: data.outOfService ?? point.outOfService,
            inAlarm: data.inAlarm,
          );
        }
        return point;
      }).toList();

      state = state.copyWith(points: updatedPoints);
    } catch (e) {
      logger.e('_refreshAllValuesBacnet error: $e');
    }
  }

  /// Rafraîchit la valeur d'un seul point
  Future<void> refreshPointValue(BacnetObject point) async {
    final connectionState = _ref.read(activeConnectionProvider);
    if (!connectionState.isConnected) return;

    // ========================================
    // CONNEXION BACNET NATIVE
    // ========================================
    if (connectionState.isBacnetConnection) {
      await _refreshPointValueBacnet(point);
      return;
    }

    // ========================================
    // CONNEXION API DISTECH
    // ========================================
    // Pour l'API, pas d'endpoint individuel : refresh silencieux de tous les points
    await refresh();
  }

  /// Rafraîchit la valeur d'un point via BACnet natif
  Future<void> _refreshPointValueBacnet(BacnetObject point) async {
    final bacnetConnection = _ref.read(activeBacnetConnectionProvider);
    if (bacnetConnection == null) return;
    final generation = _generation;
    final connectionId = _ref.read(activeConnectionProvider).connection?.id;

    try {
      final bacnetService = _ref.read(bacnetServiceProvider);
      final objectTypeCode = bacnetObjectTypeCode(point.type);

      final newValue = await bacnetService.refreshPointValue(
        host: bacnetConnection.host,
        port: bacnetConnection.port,
        objectType: objectTypeCode,
        objectInstance: point.instance,
      );

      if (!_isCurrent(generation, connectionId)) return;
      _updatePointLocally(point, presentValue: newValue);
    } catch (e) {
      logger.e('_refreshPointValueBacnet error: $e');
    }
  }

  /// Met à jour la recherche
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Met à jour le filtre par type
  void setFilterType(BacnetObjectType? type) {
    if (type == null) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(filterType: type);
    }
  }

  /// Change la catégorie sélectionnée
  /// Réinitialise le filtre de sous-type quand on change de catégorie
  void setCategory(PointCategory category) {
    state = state.copyWith(
      selectedCategory: category,
      subTypeFilter: SubTypeFilter.all, // Reset le filtre
    );
  }

  /// Change le filtre de sous-type (Analog/Binary/Multi)
  void setSubTypeFilter(SubTypeFilter filter) {
    state = state.copyWith(subTypeFilter: filter);
  }

  /// Change l'option de tri
  void setSortOption(PointSortOption option) {
    state = state.copyWith(sortOption: option);
  }

  /// Met à jour la liste des favoris (pour le tri)
  void updateFavoriteIds(Set<String> favoriteIds) {
    state = state.copyWith(favoritePointIds: favoriteIds);
  }

  /// Écrit une valeur simple sur un point (sans priorité)
  /// Utilisable uniquement sur les Values (AV, BV, MSV)
  Future<bool> writeValue(BacnetObject point, dynamic value) async {
    final connectionState = _ref.read(activeConnectionProvider);
    if (!connectionState.isConnected) {
      return false;
    }

    // ========================================
    // CONNEXION BACNET NATIVE
    // ========================================
    if (connectionState.isBacnetConnection) {
      return _writeValueBacnet(point, value);
    }

    // ========================================
    // CONNEXION API DISTECH
    // ========================================
    if (connectionState.client == null) {
      return false;
    }

    try {
      final success = await connectionState.client!.writeValue(
        point.type,
        point.instance,
        value,
      );

      if (success) {
        // Mettre à jour la valeur localement (sans forçage)
        _updatePointLocally(point, presentValue: value, isOverridden: false);
      }

      return success;
    } catch (e) {
      logger.e('writeValue (API) error: $e');
      return false;
    }
  }

  /// Écrit une valeur via BACnet natif
  Future<bool> _writeValueBacnet(BacnetObject point, dynamic value) async {
    final bacnetConnection = _ref.read(activeBacnetConnectionProvider);
    if (bacnetConnection == null) return false;

    try {
      final bacnetService = _ref.read(bacnetServiceProvider);
      final objectTypeCode = bacnetObjectTypeCode(point.type);

      await bacnetService.writePointValue(
        host: bacnetConnection.host,
        port: bacnetConnection.port,
        objectType: objectTypeCode,
        objectInstance: point.instance,
        value: value,
      );

      // Mettre à jour la valeur localement
      _updatePointLocally(point, presentValue: value, isOverridden: false);
      return true;
    } catch (e) {
      logger.e('_writeValueBacnet error: $e');
      return false;
    }
  }

  /// Force une valeur sur un point avec une priorité
  /// Utilisable sur les Outputs et Values (AO, BO, MSO, AV, BV, MSV)
  Future<bool> writeOverride(BacnetObject point, dynamic value, {int priority = 8}) async {
    final connectionState = _ref.read(activeConnectionProvider);
    if (!connectionState.isConnected) {
      return false;
    }

    // ========================================
    // CONNEXION BACNET NATIVE
    // ========================================
    if (connectionState.isBacnetConnection) {
      return _writeOverrideBacnet(point, value, priority: priority);
    }

    // ========================================
    // CONNEXION API DISTECH
    // ========================================
    if (connectionState.client == null) {
      return false;
    }

    try {
      final success = await connectionState.client!.writeOverride(
        point.type,
        point.instance,
        value,
        priority: priority,
      );

      if (success) {
        // Mettre à jour localement avec statut forcé
        _updatePointLocally(
          point,
          presentValue: value,
          isOverridden: true,
          overridePriority: priority,
          overrideValue: value,
        );
      }

      return success;
    } catch (e) {
      logger.e('writeOverride (API) error: $e');
      return false;
    }
  }

  /// Force une valeur via BACnet natif avec priorité
  Future<bool> _writeOverrideBacnet(BacnetObject point, dynamic value, {int priority = 8}) async {
    final bacnetConnection = _ref.read(activeBacnetConnectionProvider);
    if (bacnetConnection == null) return false;

    try {
      final bacnetService = _ref.read(bacnetServiceProvider);
      final objectTypeCode = bacnetObjectTypeCode(point.type);

      await bacnetService.writePointValue(
        host: bacnetConnection.host,
        port: bacnetConnection.port,
        objectType: objectTypeCode,
        objectInstance: point.instance,
        value: value,
        priority: priority,
      );

      // Mettre à jour localement avec statut forcé
      _updatePointLocally(
        point,
        presentValue: value,
        isOverridden: true,
        overridePriority: priority,
        overrideValue: value,
      );
      return true;
    } catch (e) {
      logger.e('_writeOverrideBacnet error: $e');
      return false;
    }
  }

  /// Libère le forçage d'un point (retour en mode auto)
  Future<bool> releaseOverride(BacnetObject point, {int priority = 8}) async {
    final connectionState = _ref.read(activeConnectionProvider);
    if (!connectionState.isConnected) {
      return false;
    }

    // ========================================
    // CONNEXION BACNET NATIVE
    // ========================================
    if (connectionState.isBacnetConnection) {
      return _releaseOverrideBacnet(point, priority: priority);
    }

    // ========================================
    // CONNEXION API DISTECH
    // ========================================
    if (connectionState.client == null) {
      return false;
    }

    try {
      final success = await connectionState.client!.releaseOverride(
        point.type,
        point.instance,
        priority: priority,
      );

      if (success) {
        // Mettre à jour localement (plus de forçage)
        _updatePointLocally(point, isOverridden: false);
      }

      return success;
    } catch (e) {
      logger.e('releaseOverride (API) error: $e');
      return false;
    }
  }

  /// Libère le forçage via BACnet natif (écrit null à la priorité)
  Future<bool> _releaseOverrideBacnet(BacnetObject point, {int priority = 8}) async {
    final bacnetConnection = _ref.read(activeBacnetConnectionProvider);
    if (bacnetConnection == null) return false;

    try {
      final bacnetService = _ref.read(bacnetServiceProvider);
      final objectTypeCode = bacnetObjectTypeCode(point.type);

      // En BACnet, pour libérer une priorité on écrit null à cette priorité
      await bacnetService.writePointValue(
        host: bacnetConnection.host,
        port: bacnetConnection.port,
        objectType: objectTypeCode,
        objectInstance: point.instance,
        value: null, // null = relinquish
        priority: priority,
      );

      // Mettre à jour localement (plus de forçage)
      _updatePointLocally(point, isOverridden: false);
      return true;
    } catch (e) {
      logger.e('_releaseOverrideBacnet error: $e');
      return false;
    }
  }

  /// Libération d'urgence - libère TOUTES les priorités
  Future<bool> emergencyRelease(BacnetObject point) async {
    final connectionState = _ref.read(activeConnectionProvider);
    if (!connectionState.isConnected) {
      return false;
    }

    // ========================================
    // CONNEXION BACNET NATIVE
    // ========================================
    if (connectionState.isBacnetConnection) {
      return _emergencyReleaseBacnet(point);
    }

    // ========================================
    // CONNEXION API DISTECH
    // ========================================
    if (connectionState.client == null) {
      return false;
    }

    try {
      final success = await connectionState.client!.emergencyRelease(
        point.type,
        point.instance,
      );

      if (success) {
        // Mettre à jour localement (plus de forçage)
        _updatePointLocally(point, isOverridden: false);
      }

      return success;
    } catch (e) {
      logger.e('emergencyRelease (API) error: $e');
      return false;
    }
  }

  /// Libération d'urgence via BACnet natif : relinquish des priorités 1 à 16
  /// (la 16 est la plus basse priorité de commande ; relinquish-default n'est
  /// pas une priorité). Lancées par petits lots en parallèle ; ne retourne
  /// true (et ne met à jour l'état local) que si toutes ont réussi.
  Future<bool> _emergencyReleaseBacnet(BacnetObject point) async {
    final bacnetConnection = _ref.read(activeBacnetConnectionProvider);
    if (bacnetConnection == null) return false;

    final bacnetService = _ref.read(bacnetServiceProvider);
    final objectTypeCode = bacnetObjectTypeCode(point.type);
    final failed = <int>[];

    Future<void> release(int priority) async {
      try {
        await bacnetService.writePointValue(
          host: bacnetConnection.host,
          port: bacnetConnection.port,
          objectType: objectTypeCode,
          objectInstance: point.instance,
          value: null, // null = relinquish
          priority: priority,
        );
      } catch (e) {
        logger.w('_emergencyReleaseBacnet: priority $priority failed: $e');
        failed.add(priority);
      }
    }

    const batchSize = 4;
    for (var start = 1; start <= 16; start += batchSize) {
      final end = (start + batchSize - 1).clamp(1, 16);
      await Future.wait([for (var p = start; p <= end; p++) release(p)]);
    }

    if (failed.isNotEmpty) {
      failed.sort();
      logger.e('_emergencyReleaseBacnet: failed priorities: $failed');
      return false;
    }

    _updatePointLocally(point, isOverridden: false);
    return true;
  }

  /// Force une entrée (AI, BI, MSI) via out-of-service + present-value
  Future<bool> forceInput(BacnetObject point, dynamic value) async {
    final connectionState = _ref.read(activeConnectionProvider);
    if (!connectionState.isConnected) {
      return false;
    }

    // ========================================
    // CONNEXION BACNET NATIVE
    // ========================================
    if (connectionState.isBacnetConnection) {
      return _forceInputBacnet(point, value);
    }

    // ========================================
    // CONNEXION API DISTECH
    // ========================================
    if (connectionState.client == null) {
      return false;
    }

    try {
      final success = await connectionState.client!.forceInput(
        point.type,
        point.instance,
        value,
        wasOutOfService: point.outOfService == true,
      );

      if (success) {
        // Mettre à jour localement avec out-of-service = true
        _updatePointLocally(
          point,
          presentValue: value,
          outOfService: true,
        );
      }

      return success;
    } catch (e) {
      logger.e('forceInput (API) error: $e');
      return false;
    }
  }

  /// Force une entrée via BACnet natif (out-of-service + present-value)
  Future<bool> _forceInputBacnet(BacnetObject point, dynamic value) async {
    final bacnetConnection = _ref.read(activeBacnetConnectionProvider);
    if (bacnetConnection == null) return false;

    try {
      final bacnetService = _ref.read(bacnetServiceProvider);
      final objectTypeCode = bacnetObjectTypeCode(point.type);

      // 1. Mettre out-of-service à true
      final oosResponse = await bacnetService.writeProperty(
        host: bacnetConnection.host,
        port: bacnetConnection.port,
        objectType: objectTypeCode,
        objectInstance: point.instance,
        propertyId: BacnetPropertyId.outOfService,
        value: true,
      );
      if (!oosResponse.isSuccess) {
        logger.e('_forceInputBacnet: out-of-service write refused: ${oosResponse.errorMessage ?? oosResponse.type}');
        return false;
      }

      // 2. Écrire la valeur
      try {
        await bacnetService.writePointValue(
          host: bacnetConnection.host,
          port: bacnetConnection.port,
          objectType: objectTypeCode,
          objectInstance: point.instance,
          value: value,
        );
      } catch (e) {
        // Already forced before this call: keep it forced, no rollback
        if (point.outOfService == true) {
          logger.e('_forceInputBacnet: present-value write failed (input already out-of-service): $e');
          return false;
        }
        // Rollback: do not leave the input out-of-service with a stale value
        logger.e('_forceInputBacnet: present-value write failed, rolling back out-of-service: $e');
        try {
          final rollback = await bacnetService.writeProperty(
            host: bacnetConnection.host,
            port: bacnetConnection.port,
            objectType: objectTypeCode,
            objectInstance: point.instance,
            propertyId: BacnetPropertyId.outOfService,
            value: false,
          );
          if (!rollback.isSuccess) {
            logger.e('_forceInputBacnet: rollback refused, input left out-of-service');
            _updatePointLocally(point, outOfService: true);
          }
        } catch (e2) {
          logger.e('_forceInputBacnet: rollback failed, input left out-of-service: $e2');
          _updatePointLocally(point, outOfService: true);
        }
        return false;
      }

      // Mettre à jour localement
      _updatePointLocally(
        point,
        presentValue: value,
        outOfService: true,
      );
      return true;
    } catch (e) {
      logger.e('_forceInputBacnet error: $e');
      return false;
    }
  }

  /// Libère une entrée forcée (remet out-of-service à false)
  Future<bool> releaseInput(BacnetObject point) async {
    final connectionState = _ref.read(activeConnectionProvider);
    if (!connectionState.isConnected) {
      return false;
    }

    // ========================================
    // CONNEXION BACNET NATIVE
    // ========================================
    if (connectionState.isBacnetConnection) {
      return _releaseInputBacnet(point);
    }

    // ========================================
    // CONNEXION API DISTECH
    // ========================================
    if (connectionState.client == null) {
      return false;
    }

    try {
      final success = await connectionState.client!.releaseInput(
        point.type,
        point.instance,
      );

      if (success) {
        // Mettre à jour localement
        _updatePointLocally(point, outOfService: false);
      }

      return success;
    } catch (e) {
      logger.e('releaseInput (API) error: $e');
      return false;
    }
  }

  /// Libère une entrée forcée via BACnet natif
  Future<bool> _releaseInputBacnet(BacnetObject point) async {
    final bacnetConnection = _ref.read(activeBacnetConnectionProvider);
    if (bacnetConnection == null) return false;

    try {
      final bacnetService = _ref.read(bacnetServiceProvider);
      final objectTypeCode = bacnetObjectTypeCode(point.type);

      // Remettre out-of-service à false
      final response = await bacnetService.writeProperty(
        host: bacnetConnection.host,
        port: bacnetConnection.port,
        objectType: objectTypeCode,
        objectInstance: point.instance,
        propertyId: BacnetPropertyId.outOfService,
        value: false,
      );
      if (!response.isSuccess) {
        logger.e('_releaseInputBacnet: write refused: ${response.errorMessage ?? response.type}');
        return false;
      }

      // Mettre à jour localement
      _updatePointLocally(point, outOfService: false);
      return true;
    } catch (e) {
      logger.e('_releaseInputBacnet error: $e');
      return false;
    }
  }

  /// Modifie la description d'un point
  Future<bool> writeDescription(BacnetObject point, String description) async {
    final connectionState = _ref.read(activeConnectionProvider);
    if (!connectionState.isConnected) {
      return false;
    }

    // ========================================
    // CONNEXION BACNET NATIVE
    // ========================================
    if (connectionState.isBacnetConnection) {
      return _writeDescriptionBacnet(point, description);
    }

    // ========================================
    // CONNEXION API DISTECH
    // ========================================
    if (connectionState.client == null) {
      return false;
    }

    try {
      final success = await connectionState.client!.writeDescription(
        point.type,
        point.instance,
        description,
      );

      if (success) {
        // Mettre à jour localement
        _updatePointLocally(point, description: description);
      }

      return success;
    } catch (e) {
      logger.e('writeDescription error: $e');
      return false;
    }
  }

  /// Écrit la description via BACnet natif
  Future<bool> _writeDescriptionBacnet(BacnetObject point, String description) async {
    final bacnetConnection = _ref.read(activeBacnetConnectionProvider);
    if (bacnetConnection == null) return false;

    try {
      final bacnetService = _ref.read(bacnetServiceProvider);
      final objectTypeCode = bacnetObjectTypeCode(point.type);

      final response = await bacnetService.writeProperty(
        host: bacnetConnection.host,
        port: bacnetConnection.port,
        objectType: objectTypeCode,
        objectInstance: point.instance,
        propertyId: BacnetPropertyId.description,
        value: description,
      );
      if (!response.isSuccess) {
        logger.e('_writeDescriptionBacnet: write refused: ${response.errorMessage ?? response.type}');
        return false;
      }

      // Mettre à jour localement
      _updatePointLocally(point, description: description);
      return true;
    } catch (e) {
      logger.e('_writeDescriptionBacnet error: $e');
      return false;
    }
  }

  /// Met à jour un point localement dans le state
  void _updatePointLocally(
    BacnetObject point, {
    dynamic presentValue,
    bool? isOverridden,
    int? overridePriority,
    dynamic overrideValue,
    bool? outOfService,
    String? description,
  }) {
    final updatedPoints = state.points.map((p) {
      if (p.type == point.type && p.instance == point.instance) {
        return p.copyWith(
          presentValue: presentValue ?? p.presentValue,
          isOverridden: isOverridden ?? p.isOverridden,
          overridePriority: isOverridden == false ? null : (overridePriority ?? p.overridePriority),
          overrideValue: isOverridden == false ? null : (overrideValue ?? p.overrideValue),
          outOfService: outOfService ?? p.outOfService,
          description: description ?? p.description,
        );
      }
      return p;
    }).toList();

    state = state.copyWith(points: updatedPoints);
  }
}

/// Provider pour les points BACnet
final pointsProvider = StateNotifierProvider<PointsNotifier, PointsState>((ref) {
  return PointsNotifier(ref);
});

/// Provider pour l'intervalle d'auto-refresh (en secondes, 0 = désactivé)
final autoRefreshIntervalProvider = StateProvider<int>((ref) => 0);

/// Options d'intervalle d'auto-refresh disponibles
const autoRefreshOptions = [
  (value: 0, label: 'Désactivé'),
  (value: 5, label: '5 secondes'),
  (value: 10, label: '10 secondes'),
  (value: 30, label: '30 secondes'),
  (value: 60, label: '1 minute'),
];

/// Provider pour un point spécifique
/// Only rebuilds when this point's object changes (not on search/sort/filter).
final pointDetailProvider = Provider.family<BacnetObject?, (BacnetObjectType, int)>((ref, params) {
  final (type, instance) = params;
  return ref.watch(pointsProvider.select((s) {
    for (final p in s.points) {
      if (p.type == type && p.instance == instance) return p;
    }
    return null;
  }));
});
