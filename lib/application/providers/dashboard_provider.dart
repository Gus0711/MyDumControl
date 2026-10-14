import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../data/database/app_database.dart';
import '../../data/database/tables/dashboard_tables.dart';
import 'active_connection_provider.dart';
import 'database_provider.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

// =============================================================================
// Providers pour les dashboards
// =============================================================================

/// Stream des dashboards pour la connexion active
final dashboardsProvider = StreamProvider<List<Dashboard>>((ref) {
  final database = ref.watch(databaseProvider);
  final connectionId = ref.watch(activeConnectionProvider.select((s) => s.connection?.id));

  _logger.d('dashboardsProvider: watching dashboards for connectionId=$connectionId');

  return database.watchDashboardsForConnection(connectionId);
});

/// Stream d'un dashboard par ID
final watchDashboardByIdProvider = StreamProvider.family<Dashboard?, int>((ref, id) {
  final database = ref.watch(databaseProvider);
  return database.watchDashboardById(id);
});

/// Stream des widgets d'un dashboard
final dashboardWidgetsProvider =
    StreamProvider.family<List<DashboardWidget>, int>((ref, dashboardId) {
  final database = ref.watch(databaseProvider);
  return database.watchDashboardWidgets(dashboardId);
});

// =============================================================================
// Notifier pour les opérations CRUD sur les dashboards
// =============================================================================

/// État des opérations sur les dashboards
class DashboardNotifierState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const DashboardNotifierState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  DashboardNotifierState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return DashboardNotifierState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardNotifierState> {
  final Ref _ref;

  DashboardNotifier(this._ref) : super(const DashboardNotifierState());

  AppDatabase get _database => _ref.read(databaseProvider);

  /// Crée un nouveau dashboard
  Future<int?> createDashboard({
    required String name,
    int columns = 2,
    int rows = 2,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final connectionId = _ref.read(activeConnectionProvider).connection?.id;

      final id = await _database.createDashboard(
        name: name,
        connectionId: connectionId,
        columns: columns,
        rows: rows,
      );

      _logger.i('createDashboard: created dashboard $id');

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Dashboard créé',
      );

      return id;
    } catch (e) {
      _logger.e('createDashboard error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur: $e',
      );
      return null;
    }
  }

  /// Met à jour un dashboard
  Future<bool> updateDashboard({
    required int id,
    String? name,
    int? columns,
    int? rows,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _database.updateDashboard(
        id: id,
        name: name,
        columns: columns,
        rows: rows,
      );

      _logger.i('updateDashboard: updated dashboard $id = $success');

      state = state.copyWith(
        isLoading: false,
        successMessage: success ? 'Dashboard mis à jour' : null,
      );

      return success;
    } catch (e) {
      _logger.e('updateDashboard error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur: $e',
      );
      return false;
    }
  }

  /// Supprime un dashboard
  Future<bool> deleteDashboard(int id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final deleted = await _database.deleteDashboard(id);

      _logger.i('deleteDashboard: deleted dashboard $id = $deleted');

      state = state.copyWith(
        isLoading: false,
        successMessage: deleted > 0 ? 'Dashboard supprimé' : null,
      );

      return deleted > 0;
    } catch (e) {
      _logger.e('deleteDashboard error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur: $e',
      );
      return false;
    }
  }

  /// Réorganise les dashboards
  Future<void> reorderDashboards(List<int> dashboardIds) async {
    try {
      await _database.reorderDashboards(dashboardIds);
      _logger.i('reorderDashboards: reordered ${dashboardIds.length} dashboards');
    } catch (e) {
      _logger.e('reorderDashboards error: $e');
    }
  }

  /// Ajoute un widget au dashboard
  Future<int?> addWidget({
    required int dashboardId,
    required int position,
    required DashboardWidgetType widgetType,
    Map<String, dynamic>? config,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final configJson = config != null ? jsonEncode(config) : null;

      final id = await _database.addDashboardWidget(
        dashboardId: dashboardId,
        position: position,
        widgetType: widgetType,
        configJson: configJson,
      );

      _logger.i('addWidget: added widget $id at position $position');

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Widget ajouté',
      );

      return id;
    } catch (e) {
      _logger.e('addWidget error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur: $e',
      );
      return null;
    }
  }

  /// Met à jour un widget
  Future<bool> updateWidget({
    required int widgetId,
    DashboardWidgetType? widgetType,
    Map<String, dynamic>? config,
    int? position,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final configJson = config != null ? jsonEncode(config) : null;

      final success = await _database.updateDashboardWidget(
        widgetId: widgetId,
        widgetType: widgetType,
        configJson: configJson,
        position: position,
      );

      _logger.i('updateWidget: updated widget $widgetId = $success');

      state = state.copyWith(
        isLoading: false,
        successMessage: success ? 'Widget mis à jour' : null,
      );

      return success;
    } catch (e) {
      _logger.e('updateWidget error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur: $e',
      );
      return false;
    }
  }

  /// Supprime un widget
  Future<bool> deleteWidget(int widgetId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final deleted = await _database.deleteDashboardWidget(widgetId);

      _logger.i('deleteWidget: deleted widget $widgetId = $deleted');

      state = state.copyWith(
        isLoading: false,
        successMessage: deleted > 0 ? 'Widget supprimé' : null,
      );

      return deleted > 0;
    } catch (e) {
      _logger.e('deleteWidget error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur: $e',
      );
      return false;
    }
  }

  /// Réinitialise l'état (messages)
  void clearMessages() {
    state = const DashboardNotifierState();
  }
}

/// Provider pour le notifier Dashboard
final dashboardNotifierProvider =
    StateNotifierProvider<DashboardNotifier, DashboardNotifierState>(
  (ref) => DashboardNotifier(ref),
);

// =============================================================================
// Helpers pour la configuration des widgets
// =============================================================================

/// Configuration d'un widget graphique simple
class SingleChartWidgetConfig {
  final int trendLogInstance;
  final String? title;
  final String? pointName;
  final String? units;
  final String colorTheme;

  const SingleChartWidgetConfig({
    required this.trendLogInstance,
    this.title,
    this.pointName,
    this.units,
    this.colorTheme = 'blue',
  });

  Map<String, dynamic> toJson() => {
        'trendLogInstance': trendLogInstance,
        'title': title,
        'pointName': pointName,
        'units': units,
        'colorTheme': colorTheme,
      };

  factory SingleChartWidgetConfig.fromJson(Map<String, dynamic> json) {
    return SingleChartWidgetConfig(
      trendLogInstance: (json['trendLogInstance'] as num).toInt(),
      title: json['title'] as String?,
      pointName: json['pointName'] as String?,
      units: json['units'] as String?,
      colorTheme: json['colorTheme'] as String? ?? 'blue',
    );
  }

  static SingleChartWidgetConfig? fromJsonString(String? jsonString) {
    if (jsonString == null) return null;
    try {
      return SingleChartWidgetConfig.fromJson(jsonDecode(jsonString));
    } catch (_) {
      return null;
    }
  }

  /// Titre affiché (title personnalisé ou pointName ou fallback)
  String get displayTitle => title ?? pointName ?? 'TL $trendLogInstance';
}

/// Configuration d'un widget multi-courbes
class MultiCurveWidgetConfig {
  final List<int> trendLogInstances;
  final String? title;
  final Map<String, String> curveNames;
  final Map<String, String?> curveUnits;

  const MultiCurveWidgetConfig({
    required this.trendLogInstances,
    this.title,
    this.curveNames = const {},
    this.curveUnits = const {},
  });

  Map<String, dynamic> toJson() => {
        'trendLogInstances': trendLogInstances,
        'title': title,
        'curveNames': curveNames,
        'curveUnits': curveUnits,
      };

  factory MultiCurveWidgetConfig.fromJson(Map<String, dynamic> json) {
    return MultiCurveWidgetConfig(
      trendLogInstances: (json['trendLogInstances'] as List<dynamic>)
          .whereType<num>()
          .map((e) => e.toInt())
          .toList(),
      title: json['title'] as String?,
      curveNames: (json['curveNames'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v?.toString() ?? '')) ??
          {},
      curveUnits: (json['curveUnits'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v?.toString())) ??
          {},
    );
  }

  static MultiCurveWidgetConfig? fromJsonString(String? jsonString) {
    if (jsonString == null) return null;
    try {
      return MultiCurveWidgetConfig.fromJson(jsonDecode(jsonString));
    } catch (_) {
      return null;
    }
  }

  /// Convertit les maps avec clés String vers int (clés invalides ignorées)
  Map<int, String> get curveNamesAsInt => _intKeyed(curveNames);

  Map<int, String?> get curveUnitsAsInt => _intKeyed(curveUnits);

  static Map<int, V> _intKeyed<V>(Map<String, V> source) {
    final result = <int, V>{};
    source.forEach((k, v) {
      final key = int.tryParse(k) ?? double.tryParse(k)?.toInt();
      if (key != null) result[key] = v;
    });
    return result;
  }

  /// Titre affiché (title personnalisé ou auto-généré)
  String get displayTitle => title ?? 'Comparaison (${trendLogInstances.length} courbes)';
}

/// Configuration d'un widget stats
class StatsWidgetConfig {
  final int trendLogInstance;
  final String? title;
  final String? pointName;
  final String? units;
  final bool showCurrent;
  final bool showMin;
  final bool showMax;
  final bool showAvg;

  const StatsWidgetConfig({
    required this.trendLogInstance,
    this.title,
    this.pointName,
    this.units,
    this.showCurrent = true,
    this.showMin = true,
    this.showMax = true,
    this.showAvg = true,
  });

  Map<String, dynamic> toJson() => {
        'trendLogInstance': trendLogInstance,
        'title': title,
        'pointName': pointName,
        'units': units,
        'showCurrent': showCurrent,
        'showMin': showMin,
        'showMax': showMax,
        'showAvg': showAvg,
      };

  factory StatsWidgetConfig.fromJson(Map<String, dynamic> json) {
    return StatsWidgetConfig(
      trendLogInstance: (json['trendLogInstance'] as num).toInt(),
      title: json['title'] as String?,
      pointName: json['pointName'] as String?,
      units: json['units'] as String?,
      showCurrent: json['showCurrent'] as bool? ?? true,
      showMin: json['showMin'] as bool? ?? true,
      showMax: json['showMax'] as bool? ?? true,
      showAvg: json['showAvg'] as bool? ?? true,
    );
  }

  static StatsWidgetConfig? fromJsonString(String? jsonString) {
    if (jsonString == null) return null;
    try {
      return StatsWidgetConfig.fromJson(jsonDecode(jsonString));
    } catch (_) {
      return null;
    }
  }

  /// Titre affiché (title personnalisé ou pointName ou fallback)
  String get displayTitle => title ?? pointName ?? 'Stats TL $trendLogInstance';
}
