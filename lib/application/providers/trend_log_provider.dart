import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../domain/models/trend_log.dart';
import 'active_connection_provider.dart';
import 'cache_provider.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

/// Provider pour le mapping trend-log -> point
/// Clé: "objectType:objectInstance" (ex: "analog-value:454")
/// Valeur: instance du trend-log (ex: 300454)
///
/// Utilise le cache local pour éviter de recharger à chaque navigation
final trendLogMappingProvider = FutureProvider<Map<String, int>>((ref) async {
  final connectionState = ref.watch(activeConnectionProvider);
  final client = connectionState.client;
  final connection = connectionState.connection;

  if (client == null || connection == null) {
    return {};
  }

  final connectionId = connection.id;
  final cacheService = ref.read(cacheServiceProvider);

  // ÉTAPE 1: Essayer de charger depuis le cache d'abord
  final cachedMapping = await cacheService.getCachedTrendLogMapping(connectionId);
  if (cachedMapping != null) {
    _logger.i('trendLogMappingProvider: loaded ${cachedMapping.length} mappings from cache');

    // Rafraîchir en arrière-plan (sans bloquer)
    _refreshMappingInBackground(client, connectionId, cacheService);

    return cachedMapping;
  }

  // ÉTAPE 2: Charger depuis l'API si pas de cache
  _logger.i('trendLogMappingProvider: loading from API...');
  final mapping = await client.getTrendLogMapping();
  _logger.i('trendLogMappingProvider: loaded ${mapping.length} mappings from API');

  // Sauvegarder en cache
  await cacheService.cacheTrendLogMapping(connectionId, mapping);

  return mapping;
});

/// Rafraîchit le mapping en arrière-plan
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
    this.selectedPeriod = TrendPeriod.day,
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

  TrendLogViewerNotifier(this._ref, this.trendLogInstance)
      : super(const TrendLogViewerState());

  /// Charge les données du trend log
  Future<void> loadData({TrendPeriod? period, bool forceRefresh = false}) async {
    final selectedPeriod = period ?? state.selectedPeriod;

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
      final connectionState = _ref.read(activeConnectionProvider);
      final client = connectionState.client;
      if (client == null) {
        state = state.copyWith(isLoading: false, error: 'Non connecté', loadingMessage: null);
        return;
      }

      state = state.copyWith(loadingMessage: 'Téléchargement de l\'historique...\n(peut prendre quelques minutes)');

      // Récupérer le buffer
      final bufferData = await client.getTrendLogBuffer(trendLogInstance);

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

      if (client.apiVersion == 'V2') {
        // Essayer de parser comme JSON
        try {
          if (bufferData.startsWith('[')) {
            trendData = TrendLogBufferParser.parseV1(bufferData);
          } else {
            trendData = TrendLogBufferParser.parseV1(bufferData);
          }
        } catch (e) {
          trendData = TrendLogBufferParser.parseV1(bufferData);
        }
      } else {
        // Parser V1
        trendData = TrendLogBufferParser.parseV1(bufferData);
      }

      // Mettre en cache les données complètes
      _cachedFullData = trendData;

      // Appliquer le filtre de période
      _applyPeriodFilter(selectedPeriod);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur: $e',
        loadingMessage: null,
      );
    }
  }

  /// Applique le filtre de période sur les données cachées
  void _applyPeriodFilter(TrendPeriod period) {
    if (_cachedFullData == null) return;

    TrendLogData filteredData = _cachedFullData!;

    // Filtrer par période si nécessaire
    if (period != TrendPeriod.custom && period.duration != Duration.zero) {
      final now = DateTime.now();
      final start = now.subtract(period.duration);
      filteredData = _cachedFullData!.filterByTimeRange(start, now);
    }

    state = state.copyWith(
      isLoading: false,
      data: filteredData,
      selectedPeriod: period,
      loadingMessage: null,
    );
  }

  /// Change la période (utilise le cache si disponible)
  void setPeriod(TrendPeriod period) {
    if (_cachedFullData != null) {
      // Utiliser le cache
      _applyPeriodFilter(period);
    } else {
      // Charger les données
      loadData(period: period);
    }
  }

  /// Force le rechargement des données
  Future<void> refresh() async {
    _cachedBuffer = null;
    _cachedFullData = null;
    await loadData(forceRefresh: true);
  }
}

/// Provider family pour le viewer de trend log
final trendLogViewerProvider = StateNotifierProvider.family<
    TrendLogViewerNotifier, TrendLogViewerState, int>(
  (ref, trendLogInstance) => TrendLogViewerNotifier(ref, trendLogInstance),
);
