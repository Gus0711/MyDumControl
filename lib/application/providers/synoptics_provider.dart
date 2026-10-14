import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../data/database/app_database.dart';
import '../../data/database/tables/synoptic_bindings_table.dart';
import 'database_provider.dart';
import 'active_connection_provider.dart';
import 'bacnet_provider.dart';
import 'bacnet_type_codes.dart';
import 'points_provider.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

/// Bibliothèque des SVG disponibles dans les assets
class SvgAssetInfo {
  final String path;
  final String name;
  final String description;
  final List<String> elementIds; // IDs des éléments dynamiques

  const SvgAssetInfo({
    required this.path,
    required this.name,
    required this.description,
    required this.elementIds,
  });
}

/// Liste des SVG intégrés à l'application
const List<SvgAssetInfo> builtInSvgAssets = [
  SvgAssetInfo(
    path: 'assets/synoptics/CR_V0.1.svg',
    name: 'Circuit Régulé',
    description: 'Circuit de chauffage/refroidissement avec pompe et V3V',
    elementIds: [
      'val_temp_depart',
      'val_v3v_position',
      'ind_pompe_etat',
      'ind_v3v_etat',
      'anim_pompe_rotation',
    ],
  ),
];

/// Provider pour la liste des synoptiques disponibles pour la connexion active
final synopticsProvider = StreamProvider<List<Synoptic>>((ref) {
  final database = ref.watch(databaseProvider);
  final connectionId = ref.watch(activeConnectionProvider.select((s) => s.connection?.id));
  return database.watchSynopticsForConnection(connectionId);
});

/// Provider pour un synoptique spécifique
final synopticByIdProvider = FutureProvider.family<Synoptic?, int>((ref, id) {
  final database = ref.watch(databaseProvider);
  return database.getSynopticById(id);
});

/// Provider pour les liaisons d'un synoptique
final synopticBindingsProvider = StreamProvider.family<List<SynopticBinding>, int>((ref, synopticId) {
  final database = ref.watch(databaseProvider);
  return database.watchBindingsForSynoptic(synopticId);
});

/// Provider pour le nombre de liaisons d'un synoptique
final bindingsCountProvider = FutureProvider.family<int, int>((ref, synopticId) {
  final database = ref.watch(databaseProvider);
  return database.countBindings(synopticId);
});

/// Configuration d'une liaison pour l'affichage
class BindingConfig {
  // Pour les valeurs
  final String? format; // ex: "{value}°C"
  final int decimals;

  // Pour les couleurs
  final String? onColor;
  final String? offColor;
  final double threshold; // Seuil pour ON/OFF (0.5 par défaut)

  // Pour les animations
  final String? animationProperty; // ex: "visibility", "opacity"
  final String? onValue;
  final String? offValue;

  const BindingConfig({
    this.format,
    this.decimals = 1,
    this.onColor,
    this.offColor,
    this.threshold = 0.5,
    this.animationProperty,
    this.onValue,
    this.offValue,
  });

  factory BindingConfig.fromJson(String? json) {
    if (json == null || json.isEmpty) return const BindingConfig();
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return BindingConfig(
        format: map['format'] as String?,
        decimals: (map['decimals'] as num?)?.toInt() ?? 1,
        onColor: map['onColor'] as String?,
        offColor: map['offColor'] as String?,
        threshold: (map['threshold'] as num?)?.toDouble() ?? 0.5,
        animationProperty: map['animationProperty'] as String?,
        onValue: map['onValue'] as String?,
        offValue: map['offValue'] as String?,
      );
    } catch (_) {
      return const BindingConfig();
    }
  }

  String toJson() {
    return jsonEncode({
      if (format != null) 'format': format,
      'decimals': decimals,
      if (onColor != null) 'onColor': onColor,
      if (offColor != null) 'offColor': offColor,
      'threshold': threshold,
      if (animationProperty != null) 'animationProperty': animationProperty,
      if (onValue != null) 'onValue': onValue,
      if (offValue != null) 'offValue': offValue,
    });
  }

  /// Formate une valeur selon la config
  String formatValue(dynamic value) {
    if (value == null) return '--';

    String strValue;
    if (value is double) {
      strValue = value.toStringAsFixed(decimals);
    } else if (value is num) {
      strValue = value.toStringAsFixed(decimals);
    } else {
      strValue = value.toString();
    }

    if (format != null) {
      return format!.replaceAll('{value}', strValue);
    }
    return strValue;
  }

  /// Détermine si ON ou OFF selon la valeur
  bool isOn(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value > threshold;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == 'on' || lower == '1' || lower == 'active';
    }
    return false;
  }
}

/// État temps réel d'un synoptique avec les valeurs des points
class SynopticLiveState {
  final int synopticId;
  final Map<String, dynamic> pointValues; // pointRef -> value
  final Map<String, SynopticBinding> bindings; // svgElementId -> binding
  final bool isLoading;
  final String? error;

  const SynopticLiveState({
    required this.synopticId,
    this.pointValues = const {},
    this.bindings = const {},
    this.isLoading = false,
    this.error,
  });

  SynopticLiveState copyWith({
    int? synopticId,
    Map<String, dynamic>? pointValues,
    Map<String, SynopticBinding>? bindings,
    bool? isLoading,
    String? error,
  }) {
    return SynopticLiveState(
      synopticId: synopticId ?? this.synopticId,
      pointValues: pointValues ?? this.pointValues,
      bindings: bindings ?? this.bindings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Récupère la valeur formatée pour un élément SVG
  String? getFormattedValue(String svgElementId) {
    final binding = bindings[svgElementId];
    if (binding == null) return null;

    final value = pointValues[binding.pointRef];
    final config = BindingConfig.fromJson(binding.configJson);
    return config.formatValue(value);
  }

  /// Récupère la couleur pour un élément SVG (indicateur)
  String? getColor(String svgElementId) {
    final binding = bindings[svgElementId];
    if (binding == null || binding.bindingType != BindingType.color) return null;

    final value = pointValues[binding.pointRef];
    final config = BindingConfig.fromJson(binding.configJson);
    final isOn = config.isOn(value);

    return isOn ? (config.onColor ?? '#27ae60') : (config.offColor ?? '#e74c3c');
  }

  /// Vérifie si une animation doit être active
  bool isAnimationActive(String svgElementId) {
    final binding = bindings[svgElementId];
    if (binding == null || binding.bindingType != BindingType.animation) return false;

    final value = pointValues[binding.pointRef];
    final config = BindingConfig.fromJson(binding.configJson);
    return config.isOn(value);
  }
}

/// Notifier pour gérer l'état temps réel d'un synoptique
/// - les liaisons sont suivies en direct depuis la DB (une liaison ajoutée
///   dans l'éditeur apparaît sans redémarrer) ;
/// - les valeurs sont relues sur l'automate actif (API batch ou BACnet) ;
/// - le timer n'existe que tant que le notifier est monté (autoDispose).
class SynopticLiveNotifier extends StateNotifier<SynopticLiveState> {
  final Ref _ref;
  final int _synopticId;
  Timer? _refreshTimer;
  StreamSubscription<List<SynopticBinding>>? _bindingsSub;
  bool _isRefreshing = false;
  static const _refreshInterval = Duration(seconds: 5);

  SynopticLiveNotifier(this._ref, this._synopticId)
      : super(SynopticLiveState(synopticId: _synopticId)) {
    _init();
  }

  void _init() {
    final database = _ref.read(databaseProvider);
    _bindingsSub = database.watchBindingsForSynoptic(_synopticId).listen(
      _onBindings,
      onError: (Object e) {
        _logger.e('Error watching synoptic bindings: $e');
        if (mounted) state = state.copyWith(error: e.toString());
      },
    );
  }

  void _onBindings(List<SynopticBinding> bindingsList) {
    if (!mounted) return;
    state = state.copyWith(bindings: {
      for (final b in bindingsList) b.svgElementId: b,
    });
    refreshValues(showLoading: state.pointValues.isEmpty);
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    if (!mounted || _refreshTimer != null) return;
    _refreshTimer = Timer.periodic(_refreshInterval, (_) => refreshValues());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _bindingsSub?.cancel();
    super.dispose();
  }

  /// Recharge les liaisons depuis la DB (le stream le fait déjà en continu)
  Future<void> loadBindings() async {
    final database = _ref.read(databaseProvider);
    final bindingsList = await database.getBindingsForSynoptic(_synopticId);
    if (!mounted) return;
    state = state.copyWith(bindings: {
      for (final b in bindingsList) b.svgElementId: b,
    });
  }

  /// Rafraîchit les valeurs des points depuis l'automate actif.
  /// Les points introuvables sont ignorés (affichés "--"), sans bloquer les
  /// autres. [showLoading] : n'afficher l'indicateur que sur une action
  /// utilisateur ou le premier chargement (pas à chaque tick du timer).
  Future<void> refreshValues({bool showLoading = false}) async {
    if (!mounted || state.bindings.isEmpty || _isRefreshing) return;
    _isRefreshing = true;

    if (showLoading) state = state.copyWith(isLoading: true);

    final pointRefs = state.bindings.values.map((b) => b.pointRef).toSet().toList();
    String? error;
    final newValues = <String, dynamic>{};

    // 1) Valeurs déjà chargées par l'écran Points (repli si lecture impossible)
    final cachedPoints = _ref.read(pointsProvider).points;
    final cachedById = {for (final p in cachedPoints) p.objectId: p};
    for (final ref in pointRefs) {
      final point = cachedById[ref];
      if (point != null) newValues[ref] = point.presentValue;
    }

    // 2) Lecture réelle sur l'automate
    try {
      newValues.addAll(await _readLiveValues(pointRefs));
    } catch (e) {
      _logger.e('Error refreshing synoptic values: $e');
      error = e.toString();
    } finally {
      _isRefreshing = false;
    }

    if (!mounted) return;
    state = state.copyWith(
      pointValues: newValues,
      isLoading: false,
      error: error,
    );
  }

  /// Lit les presentValue des points via la connexion active.
  /// Retourne pointRef -> valeur pour les points trouvés.
  Future<Map<String, dynamic>> _readLiveValues(List<String> pointRefs) async {
    final connection = _ref.read(activeConnectionProvider);
    if (!connection.isConnected) return {};

    // Connexion BACnet native
    if (connection.isBacnetConnection) {
      final bacnetConnection = _ref.read(activeBacnetConnectionProvider);
      if (bacnetConnection == null) return {};

      final parsed = pointRefs.map(parseBacnetPointRef).whereType<ParsedBacnetPointRef>().toList();
      if (parsed.isEmpty) return {};

      final results = await _ref.read(bacnetServiceProvider).refreshMultiplePointValues(
            host: bacnetConnection.host,
            port: bacnetConnection.port,
            points: [
              for (final p in parsed)
                (
                  objectType: p.typeCode,
                  objectInstance: p.instance,
                  isCommandable: p.type.isCommandable,
                  isInput: p.type.isInput,
                ),
            ],
          );

      return {
        for (final p in parsed)
          if (results['${p.typeCode}:${p.instance}'] != null)
            p.pointRef: results['${p.typeCode}:${p.instance}']!.presentValue,
      };
    }

    // Connexion API Distech (batch V1/V2)
    final client = connection.client;
    if (client == null) return {};
    final results = await client.readMultiplePoints(pointRefs);
    return {
      for (final entry in results.entries) entry.key: entry.value.presentValue,
    };
  }

  /// Force un rafraîchissement immédiat
  Future<void> forceRefresh() async {
    await refreshValues(showLoading: true);
  }
}

/// Provider famille pour l'état temps réel d'un synoptique
/// autoDispose : le timer s'arrête dès que le viewer est fermé.
final synopticLiveProvider =
    StateNotifierProvider.autoDispose.family<SynopticLiveNotifier, SynopticLiveState, int>(
  (ref, synopticId) => SynopticLiveNotifier(ref, synopticId),
);

/// Notifier pour les actions CRUD sur les synoptiques
class SynopticsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  SynopticsNotifier(this._ref) : super(const AsyncValue.data(null));

  /// Crée un nouveau synoptique
  Future<int?> createSynoptic({
    required String name,
    required String svgAssetPath,
    String? description,
    int? connectionId,
  }) async {
    final database = _ref.read(databaseProvider);

    try {
      state = const AsyncValue.loading();

      final id = await database.createSynoptic(SynopticsCompanion.insert(
        name: name,
        svgAssetPath: svgAssetPath,
        description: Value(description),
        connectionId: Value(connectionId),
      ));

      _logger.i('Created synoptic: $name (id: $id)');
      state = const AsyncValue.data(null);
      return id;
    } catch (e, st) {
      _logger.e('Error creating synoptic: $e');
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Met à jour un synoptique
  Future<bool> updateSynoptic({
    required int synopticId,
    String? name,
    String? description,
    int? connectionId,
  }) async {
    final database = _ref.read(databaseProvider);

    try {
      state = const AsyncValue.loading();

      await database.updateSynopticProperties(
        synopticId: synopticId,
        name: name,
        description: description,
        connectionId: connectionId,
      );

      _logger.i('Updated synoptic: $synopticId');
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      _logger.e('Error updating synoptic: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Supprime un synoptique
  Future<bool> deleteSynoptic(int synopticId) async {
    final database = _ref.read(databaseProvider);

    try {
      state = const AsyncValue.loading();

      await database.deleteSynoptic(synopticId);

      _logger.i('Deleted synoptic: $synopticId');
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      _logger.e('Error deleting synoptic: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Crée ou met à jour une liaison
  Future<bool> upsertBinding({
    required int synopticId,
    required String svgElementId,
    required String pointRef,
    required BindingType bindingType,
    String? configJson,
    String? pointName,
  }) async {
    final database = _ref.read(databaseProvider);

    try {
      state = const AsyncValue.loading();

      await database.upsertBinding(SynopticBindingsCompanion(
        synopticId: Value(synopticId),
        svgElementId: Value(svgElementId),
        pointRef: Value(pointRef),
        bindingType: Value(bindingType),
        configJson: Value(configJson),
        pointName: Value(pointName),
      ));

      _ref.invalidate(bindingsCountProvider(synopticId));
      _logger.i('Upserted binding: $svgElementId -> $pointRef');
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      _logger.e('Error upserting binding: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Supprime une liaison
  Future<bool> deleteBinding(int synopticId, String svgElementId) async {
    final database = _ref.read(databaseProvider);

    try {
      state = const AsyncValue.loading();

      await database.deleteBindingByElement(synopticId, svgElementId);

      _ref.invalidate(bindingsCountProvider(synopticId));
      _logger.i('Deleted binding: $svgElementId');
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      _logger.e('Error deleting binding: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Provider pour les actions sur les synoptiques
final synopticsNotifierProvider =
    StateNotifierProvider<SynopticsNotifier, AsyncValue<void>>((ref) {
  return SynopticsNotifier(ref);
});
