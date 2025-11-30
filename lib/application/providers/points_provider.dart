import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/bacnet_object.dart';
import 'active_connection_provider.dart';

/// État des points BACnet
class PointsState {
  final List<BacnetObject> points;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final BacnetObjectType? filterType;

  const PointsState({
    this.points = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.filterType,
  });

  PointsState copyWith({
    List<BacnetObject>? points,
    bool? isLoading,
    String? error,
    String? searchQuery,
    BacnetObjectType? filterType,
    bool clearFilter = false,
    bool clearError = false,
  }) {
    return PointsState(
      points: points ?? this.points,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      filterType: clearFilter ? null : (filterType ?? this.filterType),
    );
  }

  /// Points filtrés selon la recherche et le type
  List<BacnetObject> get filteredPoints {
    var result = points;

    // Filtrer par type
    if (filterType != null) {
      result = result.where((p) => p.type == filterType).toList();
    }

    // Filtrer par recherche
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((p) {
        return p.objectName.toLowerCase().contains(query) ||
            (p.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return result;
  }

  /// Grouper les points par type
  Map<BacnetObjectType, List<BacnetObject>> get pointsByType {
    final grouped = <BacnetObjectType, List<BacnetObject>>{};
    for (final point in filteredPoints) {
      grouped.putIfAbsent(point.type, () => []);
      grouped[point.type]!.add(point);
    }
    return grouped;
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

  PointsNotifier(this._ref) : super(const PointsState());

  /// Charge tous les points depuis l'automate
  Future<void> loadPoints() async {
    final connectionState = _ref.read(activeConnectionProvider);
    if (!connectionState.isConnected || connectionState.client == null) {
      state = state.copyWith(
        error: 'Non connecté',
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final points = await connectionState.client!.getAllPointsOptimized();

      // Trier par type puis par nom
      points.sort((a, b) {
        final typeCompare = a.type.index.compareTo(b.type.index);
        if (typeCompare != 0) return typeCompare;
        return a.objectName.compareTo(b.objectName);
      });

      state = state.copyWith(
        points: points,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Erreur: $e',
        isLoading: false,
      );
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
