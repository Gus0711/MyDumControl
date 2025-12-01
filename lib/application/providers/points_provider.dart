import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../domain/models/bacnet_object.dart';
import 'active_connection_provider.dart';
import 'cache_provider.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

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
    );
  }

  /// Points filtrés selon la catégorie, la recherche et triés
  List<BacnetObject> getFilteredAndSortedPoints({PointCategory? category}) {
    final cat = category ?? selectedCategory;
    var result = cat.filterPoints(points);

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

  /// Réinitialise l'état (appelé lors du changement d'automate)
  void reset() {
    state = PointsState();
    _logger.i('PointsNotifier: reset');
  }

  /// Charge tous les points depuis l'automate
  /// Utilise le cache local pour les propriétés statiques (nom, unité, description)
  Future<void> loadPoints({bool forceRefresh = false}) async {
    final connectionState = _ref.read(activeConnectionProvider);
    if (!connectionState.isConnected || connectionState.client == null) {
      state = state.copyWith(
        error: 'Non connecté',
        isLoading: false,
      );
      return;
    }

    final connectionId = connectionState.connection!.id;
    final cacheService = _ref.read(cacheServiceProvider);

    // ÉTAPE 1: Charger immédiatement depuis le cache (si disponible et non forcé)
    if (!forceRefresh && state.points.isEmpty) {
      final cachedPoints = await cacheService.getStaticPointsCache(connectionId);
      if (cachedPoints != null && cachedPoints.isNotEmpty) {
        // Créer des BacnetObject à partir du cache (sans valeurs live)
        final pointsFromCache = cacheService.createFromCache(cachedPoints);

        // Trier par type puis par nom
        pointsFromCache.sort((a, b) {
          final typeCompare = a.type.index.compareTo(b.type.index);
          if (typeCompare != 0) return typeCompare;
          return a.objectName.compareTo(b.objectName);
        });

        _logger.i('loadPoints: ${pointsFromCache.length} points loaded from cache (instant!)');

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
      final points = await connectionState.client!.getAllPointsOptimized();

      // Trier par type puis par nom
      points.sort((a, b) {
        final typeCompare = a.type.index.compareTo(b.type.index);
        if (typeCompare != 0) return typeCompare;
        return a.objectName.compareTo(b.objectName);
      });

      _logger.i('loadPoints: ${points.length} points loaded from API');

      // ÉTAPE 3: Mettre à jour le cache des propriétés statiques (en arrière-plan)
      cacheService.cacheStaticPoints(connectionId, points);

      state = state.copyWith(
        points: points,
        isLoading: false,
        fromCache: false, // Données fraîches
      );
    } catch (e) {
      _logger.e('loadPoints error: $e');

      // En cas d'erreur, garder les données du cache si disponibles
      if (state.points.isNotEmpty && state.fromCache) {
        _logger.w('loadPoints: keeping cached data due to API error');
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

  /// Rafraîchit les valeurs des points
  Future<void> refresh() async {
    await loadPoints();
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
  void setCategory(PointCategory category) {
    state = state.copyWith(selectedCategory: category);
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
    if (!connectionState.isConnected || connectionState.client == null) {
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
      return false;
    }
  }

  /// Force une valeur sur un point avec une priorité
  /// Utilisable sur les Outputs et Values (AO, BO, MSO, AV, BV, MSV)
  Future<bool> writeOverride(BacnetObject point, dynamic value, {int priority = 8}) async {
    final connectionState = _ref.read(activeConnectionProvider);
    if (!connectionState.isConnected || connectionState.client == null) {
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
      return false;
    }
  }

  /// Libère le forçage d'un point (retour en mode auto)
  Future<bool> releaseOverride(BacnetObject point, {int priority = 8}) async {
    final connectionState = _ref.read(activeConnectionProvider);
    if (!connectionState.isConnected || connectionState.client == null) {
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
      return false;
    }
  }

  /// Libération d'urgence - libère TOUTES les priorités
  Future<bool> emergencyRelease(BacnetObject point) async {
    final connectionState = _ref.read(activeConnectionProvider);
    if (!connectionState.isConnected || connectionState.client == null) {
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
      return false;
    }
  }

  /// Force une entrée (AI, BI, MSI) via out-of-service + present-value
  Future<bool> forceInput(BacnetObject point, dynamic value) async {
    final connectionState = _ref.read(activeConnectionProvider);
    if (!connectionState.isConnected || connectionState.client == null) {
      return false;
    }

    try {
      final success = await connectionState.client!.forceInput(
        point.type,
        point.instance,
        value,
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
      return false;
    }
  }

  /// Libère une entrée forcée (remet out-of-service à false)
  Future<bool> releaseInput(BacnetObject point) async {
    final connectionState = _ref.read(activeConnectionProvider);
    if (!connectionState.isConnected || connectionState.client == null) {
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
  }) {
    final updatedPoints = state.points.map((p) {
      if (p.type == point.type && p.instance == point.instance) {
        return p.copyWith(
          presentValue: presentValue ?? p.presentValue,
          isOverridden: isOverridden ?? p.isOverridden,
          overridePriority: isOverridden == false ? null : (overridePriority ?? p.overridePriority),
          overrideValue: isOverridden == false ? null : (overrideValue ?? p.overrideValue),
          outOfService: outOfService ?? p.outOfService,
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

/// Provider pour un point spécifique
final pointDetailProvider = Provider.family<BacnetObject?, (BacnetObjectType, int)>((ref, params) {
  final state = ref.watch(pointsProvider);
  final (type, instance) = params;

  try {
    return state.points.firstWhere(
      (p) => p.type == type && p.instance == instance,
    );
  } catch (e) {
    return null;
  }
});
