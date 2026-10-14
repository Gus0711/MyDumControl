import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../data/database/app_database.dart';
import '../../data/services/api_client_factory.dart';
import '../../data/services/api_service.dart';
import '../../domain/models/bacnet_object.dart';
import 'active_connection_provider.dart';
import 'api_provider.dart';
import 'bacnet_provider.dart';
import 'bacnet_type_codes.dart';
import 'database_provider.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

/// État d'un super favori avec sa valeur live
class SuperFavoriteWithValue {
  final Favorite favorite;
  final BacnetObject? liveData;
  final DateTime? lastRefreshed;
  final bool isLoading;
  final String? error;

  const SuperFavoriteWithValue({
    required this.favorite,
    this.liveData,
    this.lastRefreshed,
    this.isLoading = false,
    this.error,
  });

  SuperFavoriteWithValue copyWith({
    Favorite? favorite,
    BacnetObject? liveData,
    DateTime? lastRefreshed,
    bool? isLoading,
    String? error,
  }) {
    return SuperFavoriteWithValue(
      favorite: favorite ?? this.favorite,
      liveData: liveData ?? this.liveData,
      lastRefreshed: lastRefreshed ?? this.lastRefreshed,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Retourne la valeur formatée du point
  String get displayValue {
    if (liveData == null) return '--';
    return liveData!.formattedValue;
  }
}

/// User-facing message for a super-favorites refresh failure.
String superFavoriteFailureMessage(ApiException failure) {
  if (failure is ApiAuthException) {
    return 'Identifiants invalides (${failure.statusCode ?? '401/403'})';
  }
  return failure.message;
}

/// Durée minimale entre deux refresh (anti-spam)
const superFavoriteRefreshCooldown = Duration(seconds: 30);

/// Infos de l'automate récupérées lors du refresh des super favoris
class ConnectionQuickInfo {
  /// Modèle de l'automate (ex: "ECY-S1000")
  final String? modelName;

  /// Heure de l'automate
  final ControllerTime? controllerTime;

  /// Dernière mise à jour
  final DateTime? lastUpdated;

  const ConnectionQuickInfo({
    this.modelName,
    this.controllerTime,
    this.lastUpdated,
  });

  ConnectionQuickInfo copyWith({
    String? modelName,
    ControllerTime? controllerTime,
    DateTime? lastUpdated,
  }) {
    return ConnectionQuickInfo(
      modelName: modelName ?? this.modelName,
      controllerTime: controllerTime ?? this.controllerTime,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// État global des super favoris par connexion
class SuperFavoritesState {
  /// Map `connectionId -> List<SuperFavoriteWithValue>`
  final Map<int, List<SuperFavoriteWithValue>> byConnection;

  /// Connexions en cours de refresh
  final Set<int> refreshingConnections;

  /// Infos rapides sur les connexions (modèle, heure)
  final Map<int, ConnectionQuickInfo> connectionInfos;

  const SuperFavoritesState({
    this.byConnection = const {},
    this.refreshingConnections = const {},
    this.connectionInfos = const {},
  });

  SuperFavoritesState copyWith({
    Map<int, List<SuperFavoriteWithValue>>? byConnection,
    Set<int>? refreshingConnections,
    Map<int, ConnectionQuickInfo>? connectionInfos,
  }) {
    return SuperFavoritesState(
      byConnection: byConnection ?? this.byConnection,
      refreshingConnections: refreshingConnections ?? this.refreshingConnections,
      connectionInfos: connectionInfos ?? this.connectionInfos,
    );
  }

  /// Retourne les super favoris d'une connexion
  List<SuperFavoriteWithValue> forConnection(int connectionId) {
    return byConnection[connectionId] ?? [];
  }

  /// Vérifie si une connexion est en cours de refresh
  bool isRefreshing(int connectionId) {
    return refreshingConnections.contains(connectionId);
  }

  /// Retourne le timestamp du dernier refresh d'une connexion
  DateTime? lastRefreshedAt(int connectionId) {
    final superFavs = forConnection(connectionId);
    return superFavs.firstOrNull?.lastRefreshed;
  }

  /// Retourne les secondes restantes avant le prochain refresh possible
  /// Retourne 0 si le refresh est possible maintenant
  int secondsUntilRefresh(int connectionId) {
    final lastRefresh = lastRefreshedAt(connectionId);
    if (lastRefresh == null) return 0;

    final elapsed = DateTime.now().difference(lastRefresh);
    final remaining = superFavoriteRefreshCooldown - elapsed;

    if (remaining.isNegative) return 0;
    return remaining.inSeconds;
  }

  /// Vérifie si le refresh est possible pour une connexion
  bool canRefresh(int connectionId) {
    if (isRefreshing(connectionId)) return false;
    return secondsUntilRefresh(connectionId) == 0;
  }

  /// Retourne les infos rapides d'une connexion
  ConnectionQuickInfo? getConnectionInfo(int connectionId) {
    return connectionInfos[connectionId];
  }
}

/// Applique des résultats de refresh (par pointRef) sur la liste courante.
/// Les pointRef absents des résultats gardent leur état ; les résultats dont
/// le pointRef n'est plus dans la liste sont ignorés.
List<SuperFavoriteWithValue> mergeSuperFavoriteRefresh(
  List<SuperFavoriteWithValue> current,
  Map<String, ({BacnetObject? liveData, String? error})> resultsByRef,
  DateTime now,
) {
  return current.map((sf) {
    final result = resultsByRef[sf.favorite.pointRef];
    if (result == null) return sf;
    return sf.copyWith(
      liveData: result.liveData,
      lastRefreshed: now,
      isLoading: false,
      error: result.error,
    );
  }).toList();
}

/// Provider pour les super favoris bruts depuis la DB (groupés par connexion)
final superFavoritesDbProvider = StreamProvider<Map<int, List<Favorite>>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.watchAllSuperFavoritesGrouped();
});

/// Notifier pour gérer les super favoris avec leurs valeurs live
class SuperFavoritesNotifier extends StateNotifier<SuperFavoritesState> {
  final Ref _ref;

  /// Cache des ConnectedApiClient par connexion (pour éviter de recréer)
  final Map<int, ConnectedApiClient> _apiClients = {};

  /// Empreinte (URL, version, auth) ayant servi à créer chaque client en cache :
  /// si l'utilisateur modifie hôte/port/identifiants/version, il est recréé.
  final Map<int, String> _apiClientFingerprints = {};

  SuperFavoritesNotifier(this._ref) : super(const SuperFavoritesState()) {
    // Écouter les changements de super favoris dans la DB
    _ref.listen<AsyncValue<Map<int, List<Favorite>>>>(
      superFavoritesDbProvider,
      (previous, next) {
        next.whenData((superFavsMap) {
          _updateFromDb(superFavsMap);
        });
      },
      fireImmediately: true,
    );
  }

  /// Met à jour l'état depuis les données DB
  void _updateFromDb(Map<int, List<Favorite>> superFavsMap) {
    final newByConnection = <int, List<SuperFavoriteWithValue>>{};

    for (final entry in superFavsMap.entries) {
      final connectionId = entry.key;
      final favorites = entry.value;

      // Conserver les valeurs existantes si disponibles
      final existing = state.byConnection[connectionId] ?? [];
      final existingMap = {for (final e in existing) e.favorite.pointRef: e};

      newByConnection[connectionId] = favorites.map((fav) {
        final prev = existingMap[fav.pointRef];
        return SuperFavoriteWithValue(
          favorite: fav,
          liveData: prev?.liveData,
          lastRefreshed: prev?.lastRefreshed,
        );
      }).toList();
    }

    state = state.copyWith(byConnection: newByConnection);
  }

  /// Refresh les valeurs des super favoris d'une connexion
  Future<void> refreshConnection(int connectionId) async {
    final superFavs = state.forConnection(connectionId);
    if (superFavs.isEmpty) return;

    // Vérifier si déjà en cours de refresh
    if (state.isRefreshing(connectionId)) {
      _logger.w('refreshConnection: already refreshing $connectionId');
      return;
    }

    // Vérifier le délai minimum entre refresh
    final lastRefresh = superFavs.firstOrNull?.lastRefreshed;
    if (lastRefresh != null) {
      final elapsed = DateTime.now().difference(lastRefresh);
      if (elapsed < superFavoriteRefreshCooldown) {
        _logger.i('refreshConnection: skipping, last refresh ${elapsed.inSeconds}s ago');
        return;
      }
    }

    _logger.i('refreshConnection: refreshing ${superFavs.length} points for connection $connectionId');

    // Marquer comme en cours de refresh
    state = state.copyWith(
      refreshingConnections: {...state.refreshingConnections, connectionId},
    );

    try {
      // Récupérer les infos de connexion pour connaître le type
      final database = _ref.read(databaseProvider);
      final connection = await database.getConnectionById(connectionId);
      if (connection == null) {
        _logger.e('refreshConnection: connection $connectionId not found');
        _disposeCachedClient(connectionId);
        _setError(connectionId, 'Connexion introuvable');
        return;
      }

      // Dispatcher selon le type de connexion
      if (connection.connectionType == 'bacnet') {
        await _refreshBacnetConnection(connectionId, connection, superFavs);
      } else {
        await _refreshApiConnection(connectionId, connection, superFavs);
      }
    } catch (e) {
      _logger.e('refreshConnection error: $e');
      _setError(connectionId, e.toString());
    }
  }

  /// Récupère les infos de l'appareil de manière sécurisée (retourne null en cas d'erreur)
  Future<DeviceInfo?> _safeGetDeviceInfo(ConnectedApiClient apiClient) async {
    try {
      return await apiClient.getDeviceInfo();
    } catch (e) {
      _logger.w('_safeGetDeviceInfo error: $e');
      return null;
    }
  }

  /// Récupère l'heure de l'automate de manière sécurisée (retourne null en cas d'erreur)
  Future<ControllerTime?> _safeGetControllerTime(ConnectedApiClient apiClient) async {
    try {
      return await apiClient.getControllerTime();
    } catch (e) {
      _logger.w('_safeGetControllerTime error: $e');
      return null;
    }
  }

  /// Refresh les super favoris via API REST (Distech V1/V2)
  Future<void> _refreshApiConnection(
    int connectionId,
    Connection connection,
    List<SuperFavoriteWithValue> superFavs,
  ) async {
    // Récupérer ou créer le ConnectedApiClient pour cette connexion
    final ConnectedApiClient? apiClient;
    try {
      apiClient = await _getApiClientForConnection(connection);
    } on PasswordMissingException catch (e) {
      _logger.e('_refreshApiConnection: password not found for connection $connectionId - user needs to edit the connection on this device');
      _setError(connectionId, e.message);
      return;
    }
    if (apiClient == null) {
      _logger.e('_refreshApiConnection: failed to create ApiClient for $connectionId');
      _setError(connectionId, 'Connectez-vous à cet automate');
      return;
    }
    // Sticky error state: start from a clean slate to detect this refresh's failures
    apiClient.clearLastError();

    // Collecter les pointRefs
    final pointRefs = superFavs.map((sf) => sf.favorite.pointRef).toList();

    // Faire les requêtes en parallèle : points + deviceInfo + controllerTime
    final pointsFuture = apiClient.readMultiplePoints(pointRefs);
    final deviceInfoFuture = _safeGetDeviceInfo(apiClient);
    final controllerTimeFuture = _safeGetControllerTime(apiClient);

    final results = await Future.wait([pointsFuture, deviceInfoFuture, controllerTimeFuture]);

    final pointsResults = results[0] as Map<String, BacnetObject>;
    final deviceInfo = results[1] as DeviceInfo?;
    final controllerTime = results[2] as ControllerTime?;

    // Auth / certificate failures: show the cause instead of "point not found"
    final failure = apiClient.lastError;
    if (failure is CertificateMismatchException || failure is ApiAuthException) {
      if (!mounted) return;
      _logger.w('_refreshApiConnection: $failure');
      if (failure is CertificateMismatchException) _disposeCachedClient(connectionId);
      _setError(connectionId, superFavoriteFailureMessage(failure!));
      return;
    }

    _logger.i('_refreshApiConnection: got ${pointsResults.length} points, deviceInfo=${deviceInfo?.modelName}, time=${controllerTime?.formattedTime}');

    // Mettre à jour le modelName en DB si disponible
    if (deviceInfo?.modelName != null) {
      final database = _ref.read(databaseProvider);
      await database.updateModelName(connectionId, deviceInfo!.modelName!);
      _logger.i('_refreshApiConnection: modelName saved to DB: ${deviceInfo.modelName}');
    }

    // Mettre à jour les valeurs des points
    final now = DateTime.now();
    if (!mounted) return;

    final newByConnection = Map<int, List<SuperFavoriteWithValue>>.from(state.byConnection);
    newByConnection[connectionId] = _mergeRefreshResults(
      connectionId,
      {
        for (final ref in pointRefs)
          ref: (
            liveData: pointsResults[ref],
            error: pointsResults[ref] == null ? 'Point non trouvé' : null,
          ),
      },
      now,
    );

    // Mettre à jour les infos de la connexion
    final newConnectionInfos = Map<int, ConnectionQuickInfo>.from(state.connectionInfos);
    newConnectionInfos[connectionId] = ConnectionQuickInfo(
      modelName: deviceInfo?.modelName,
      controllerTime: controllerTime,
      lastUpdated: now,
    );

    state = state.copyWith(
      byConnection: newByConnection,
      connectionInfos: newConnectionInfos,
      refreshingConnections: state.refreshingConnections.difference({connectionId}),
    );
  }

  /// Refresh les super favoris via BACnet/IP natif
  Future<void> _refreshBacnetConnection(
    int connectionId,
    Connection connection,
    List<SuperFavoriteWithValue> superFavs,
  ) async {
    final bacnetService = _ref.read(bacnetServiceProvider);

    // Parser les pointRefs BACnet (format "shortName:instance", ex: "AI:1", "AV:5")
    // une seule fois, la liste est réutilisée pour lire les résultats
    final parsedRefs = <ParsedBacnetPointRef>[];
    for (final sf in superFavs) {
      final parsed = parseBacnetPointRef(sf.favorite.pointRef);
      if (parsed != null) {
        parsedRefs.add(parsed);
      } else {
        _logger.w('_refreshBacnetConnection: failed to parse pointRef "${sf.favorite.pointRef}"');
      }
    }

    if (parsedRefs.isEmpty) {
      _logger.w('_refreshBacnetConnection: no valid points to refresh');
      _setError(connectionId, 'Aucun point valide');
      return;
    }

    _logger.i('_refreshBacnetConnection: refreshing ${parsedRefs.length} BACnet points on ${connection.host}:${connection.port}');

    // Faire la requête batch BACnet
    final results = await bacnetService.refreshMultiplePointValues(
      host: connection.host,
      port: connection.port,
      points: [
        for (final p in parsedRefs)
          (
            objectType: p.typeCode,
            objectInstance: p.instance,
            isCommandable: p.type.isCommandable,
            isInput: p.type.isInput,
          ),
      ],
    );

    _logger.i('_refreshBacnetConnection: got ${results.length} results');
    if (!mounted) return;

    // Construire les résultats par pointRef
    final now = DateTime.now();
    final nameByRef = {for (final sf in superFavs) sf.favorite.pointRef: sf.favorite.pointName};
    final byRef = <String, ({BacnetObject? liveData, String? error})>{};
    for (final sf in superFavs) {
      byRef[sf.favorite.pointRef] = (liveData: null, error: 'Type inconnu');
    }
    for (final p in parsedRefs) {
      // La clé dans les résultats BACnet est "objectType:instance" (ex: "2:5")
      final data = results['${p.typeCode}:${p.instance}'];
      if (data == null) {
        byRef[p.pointRef] = (liveData: null, error: 'Point non trouvé');
        continue;
      }
      byRef[p.pointRef] = (
        liveData: BacnetObject(
          type: p.type,
          instance: p.instance,
          objectName: nameByRef[p.pointRef] ?? p.pointRef,
          presentValue: data.presentValue,
          units: data.units,
          isOverridden: data.isOverridden,
          overridePriority: data.overridePriority,
          overrideValue: data.overrideValue,
          outOfService: data.outOfService,
          inAlarm: data.inAlarm,
        ),
        error: null,
      );
    }

    final newByConnection = Map<int, List<SuperFavoriteWithValue>>.from(state.byConnection);
    newByConnection[connectionId] = _mergeRefreshResults(connectionId, byRef, now);

    state = state.copyWith(
      byConnection: newByConnection,
      refreshingConnections: state.refreshingConnections.difference({connectionId}),
    );
  }

  /// Applique les résultats d'un refresh sur la liste COURANTE des super
  /// favoris (et non celle capturée avant les await) : un super favori retiré
  /// ou ajouté pendant le refresh n'est ni ressuscité ni perdu.
  List<SuperFavoriteWithValue> _mergeRefreshResults(
    int connectionId,
    Map<String, ({BacnetObject? liveData, String? error})> resultsByRef,
    DateTime now,
  ) {
    return mergeSuperFavoriteRefresh(state.forConnection(connectionId), resultsByRef, now);
  }

  /// Refresh les super favoris de toutes les connexions d'un dossier en parallèle
  Future<void> refreshFolder(List<int> connectionIds) async {
    _logger.i('refreshFolder: refreshing ${connectionIds.length} connections in parallel');

    await Future.wait(
      connectionIds.map((id) => refreshConnection(id)),
    );
  }

  /// Refresh tous les super favoris
  Future<void> refreshAll() async {
    final connectionIds = state.byConnection.keys.toList();
    await refreshFolder(connectionIds);
  }

  /// Met une erreur sur une connexion
  void _setError(int connectionId, String error) {
    final superFavs = state.forConnection(connectionId);
    final updatedList = superFavs.map((sf) => sf.copyWith(
      isLoading: false,
      error: error,
    )).toList();

    final newByConnection = Map<int, List<SuperFavoriteWithValue>>.from(state.byConnection);
    newByConnection[connectionId] = updatedList;

    state = state.copyWith(
      byConnection: newByConnection,
      refreshingConnections: state.refreshingConnections.difference({connectionId}),
    );
  }

  /// Ferme et retire le client en cache d'une connexion
  void _disposeCachedClient(int connectionId) {
    _apiClients.remove(connectionId)?.dispose();
    _apiClientFingerprints.remove(connectionId);
  }

  /// Récupère ou crée un ConnectedApiClient pour une connexion
  Future<ConnectedApiClient?> _getApiClientForConnection(Connection connection) async {
    final connectionId = connection.id;

    // Connexion active : réutiliser son client (identifiants à jour)
    final activeState = _ref.read(activeConnectionProvider);
    if (activeState.isConnected && activeState.connection?.id == connectionId && activeState.client != null) {
      _logger.i('_getApiClientForConnection: reusing active connection client for $connectionId');
      return activeState.client;
    }

    // Mot de passe relu à chaque fois : un mot de passe / hôte / certificat
    // modifié invalide le client en cache (clé de config).
    final factory = _ref.read(apiClientFactoryProvider);
    final ApiClientConfig config;
    try {
      config = await factory.resolve(connection);
    } on PasswordMissingException {
      _disposeCachedClient(connectionId);
      rethrow;
    }

    final cacheKey = config.cacheKey;
    final cached = _apiClients[connectionId];
    if (cached != null) {
      if (_apiClientFingerprints[connectionId] == cacheKey) return cached;
      _logger.i('_getApiClientForConnection: connection $connectionId changed, recreating client');
      _disposeCachedClient(connectionId);
    }

    try {
      final apiClient = factory.build(config);
      _apiClients[connectionId] = apiClient;
      _apiClientFingerprints[connectionId] = cacheKey;
      return apiClient;
    } catch (e) {
      _logger.e('_getApiClientForConnection error: $e');
      return null;
    }
  }

  @override
  void dispose() {
    // Fermer tous les ApiClients
    for (final client in _apiClients.values) {
      client.dispose();
    }
    _apiClients.clear();
    _apiClientFingerprints.clear();
    super.dispose();
  }
}

/// Provider pour le notifier des super favoris
final superFavoritesProvider =
    StateNotifierProvider<SuperFavoritesNotifier, SuperFavoritesState>((ref) {
  return SuperFavoritesNotifier(ref);
});
