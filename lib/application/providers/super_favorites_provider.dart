import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../data/database/app_database.dart';
import '../../data/services/api_service.dart';
import '../../data/services/bacnet/bacnet_constants.dart';
import '../../domain/models/bacnet_object.dart';
import 'active_connection_provider.dart';
import 'bacnet_provider.dart';
import 'connection_providers.dart';
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

/// Durée minimale entre deux refresh (anti-spam)
const superFavoriteRefreshCooldown = Duration(seconds: 30);

/// État global des super favoris par connexion
class SuperFavoritesState {
  /// Map connectionId -> List<SuperFavoriteWithValue>
  final Map<int, List<SuperFavoriteWithValue>> byConnection;

  /// Connexions en cours de refresh
  final Set<int> refreshingConnections;

  const SuperFavoritesState({
    this.byConnection = const {},
    this.refreshingConnections = const {},
  });

  SuperFavoritesState copyWith({
    Map<int, List<SuperFavoriteWithValue>>? byConnection,
    Set<int>? refreshingConnections,
  }) {
    return SuperFavoritesState(
      byConnection: byConnection ?? this.byConnection,
      refreshingConnections: refreshingConnections ?? this.refreshingConnections,
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

  /// Refresh les super favoris via API REST (Distech V1/V2)
  Future<void> _refreshApiConnection(
    int connectionId,
    Connection connection,
    List<SuperFavoriteWithValue> superFavs,
  ) async {
    // Récupérer ou créer le ConnectedApiClient pour cette connexion
    final apiClient = await _getApiClientForConnection(connectionId);
    if (apiClient == null) {
      _logger.e('_refreshApiConnection: failed to create ApiClient for $connectionId');
      _setError(connectionId, 'Connectez-vous à cet automate');
      return;
    }

    // Collecter les pointRefs
    final pointRefs = superFavs.map((sf) => sf.favorite.pointRef).toList();

    // Faire la requête batch
    final results = await apiClient.readMultiplePoints(pointRefs);
    _logger.i('_refreshApiConnection: got ${results.length} results');

    // Mettre à jour les valeurs
    final now = DateTime.now();
    final updatedList = superFavs.map((sf) {
      final liveData = results[sf.favorite.pointRef];
      return sf.copyWith(
        liveData: liveData,
        lastRefreshed: now,
        isLoading: false,
        error: liveData == null ? 'Point non trouvé' : null,
      );
    }).toList();

    final newByConnection = Map<int, List<SuperFavoriteWithValue>>.from(state.byConnection);
    newByConnection[connectionId] = updatedList;

    state = state.copyWith(
      byConnection: newByConnection,
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
    final points = <({int objectType, int objectInstance, bool isCommandable, bool isInput})>[];
    final pointRefToIndex = <String, int>{};

    for (int i = 0; i < superFavs.length; i++) {
      final sf = superFavs[i];
      final parts = sf.favorite.pointRef.split(':');
      if (parts.length == 2) {
        final shortName = parts[0];
        final objectInstance = int.tryParse(parts[1]);

        // Convertir le shortName en objectType
        final bacnetType = BacnetObjectType.fromShortName(shortName);
        final objectType = bacnetType != null ? _bacnetTypeToObjectTypeCode(bacnetType) : null;

        if (objectType != null && objectInstance != null) {
          // Déterminer si commandable (AO, BO, MSO, AV, BV, MSV) ou input (AI, BI, MSI)
          final isCommandable = [
            BacnetObjectTypeCode.analogOutput,
            BacnetObjectTypeCode.binaryOutput,
            BacnetObjectTypeCode.multiStateOutput,
            BacnetObjectTypeCode.analogValue,
            BacnetObjectTypeCode.binaryValue,
            BacnetObjectTypeCode.multiStateValue,
          ].contains(objectType);
          final isInput = [
            BacnetObjectTypeCode.analogInput,
            BacnetObjectTypeCode.binaryInput,
            BacnetObjectTypeCode.multiStateInput,
          ].contains(objectType);

          points.add((
            objectType: objectType,
            objectInstance: objectInstance,
            isCommandable: isCommandable,
            isInput: isInput,
          ));
          pointRefToIndex[sf.favorite.pointRef] = i;
          _logger.d('_refreshBacnetConnection: parsed ${sf.favorite.pointRef} -> type=$objectType, instance=$objectInstance');
        } else {
          _logger.w('_refreshBacnetConnection: failed to parse pointRef "${sf.favorite.pointRef}"');
        }
      }
    }

    if (points.isEmpty) {
      _logger.w('_refreshBacnetConnection: no valid points to refresh');
      _setError(connectionId, 'Aucun point valide');
      return;
    }

    _logger.i('_refreshBacnetConnection: refreshing ${points.length} BACnet points on ${connection.host}:${connection.port}');

    // Faire la requête batch BACnet
    final results = await bacnetService.refreshMultiplePointValues(
      host: connection.host,
      port: connection.port,
      points: points,
    );

    _logger.i('_refreshBacnetConnection: got ${results.length} results');

    // Mettre à jour les valeurs
    final now = DateTime.now();
    final updatedList = superFavs.map((sf) {
      final pointRef = sf.favorite.pointRef;
      final parts = pointRef.split(':');

      if (parts.length != 2) {
        return sf.copyWith(
          lastRefreshed: now,
          isLoading: false,
          error: 'Format invalide',
        );
      }

      final shortName = parts[0];
      final objectInstance = int.tryParse(parts[1]);
      final bacnetType = BacnetObjectType.fromShortName(shortName);
      final objectTypeCode = bacnetType != null ? _bacnetTypeToObjectTypeCode(bacnetType) : null;

      if (objectTypeCode == null || objectInstance == null) {
        return sf.copyWith(
          lastRefreshed: now,
          isLoading: false,
          error: 'Type inconnu',
        );
      }

      // La clé dans les résultats BACnet est "objectType:instance" (ex: "2:5")
      final resultKey = '$objectTypeCode:$objectInstance';
      final data = results[resultKey];

      if (data != null) {
        // Créer un BacnetObject à partir des données rafraîchies
        final liveData = BacnetObject(
          type: bacnetType!,
          instance: objectInstance,
          objectName: sf.favorite.pointName,
          presentValue: data.presentValue,
          units: data.units,
          isOverridden: data.isOverridden,
          overridePriority: data.overridePriority,
          overrideValue: data.overrideValue,
          outOfService: data.outOfService,
          inAlarm: data.inAlarm,
        );

        return sf.copyWith(
          liveData: liveData,
          lastRefreshed: now,
          isLoading: false,
          error: null,
        );
      } else {
        return sf.copyWith(
          lastRefreshed: now,
          isLoading: false,
          error: 'Point non trouvé',
        );
      }
    }).toList();

    final newByConnection = Map<int, List<SuperFavoriteWithValue>>.from(state.byConnection);
    newByConnection[connectionId] = updatedList;

    state = state.copyWith(
      byConnection: newByConnection,
      refreshingConnections: state.refreshingConnections.difference({connectionId}),
    );
  }

  /// Convertit un BacnetObjectType en code numérique BACnet
  int? _bacnetTypeToObjectTypeCode(BacnetObjectType type) {
    switch (type) {
      case BacnetObjectType.analogInput:
        return BacnetObjectTypeCode.analogInput;
      case BacnetObjectType.analogOutput:
        return BacnetObjectTypeCode.analogOutput;
      case BacnetObjectType.analogValue:
        return BacnetObjectTypeCode.analogValue;
      case BacnetObjectType.binaryInput:
        return BacnetObjectTypeCode.binaryInput;
      case BacnetObjectType.binaryOutput:
        return BacnetObjectTypeCode.binaryOutput;
      case BacnetObjectType.binaryValue:
        return BacnetObjectTypeCode.binaryValue;
      case BacnetObjectType.multiStateInput:
        return BacnetObjectTypeCode.multiStateInput;
      case BacnetObjectType.multiStateOutput:
        return BacnetObjectTypeCode.multiStateOutput;
      case BacnetObjectType.multiStateValue:
        return BacnetObjectTypeCode.multiStateValue;
      case BacnetObjectType.schedule:
        return BacnetObjectTypeCode.schedule;
      case BacnetObjectType.calendar:
        return BacnetObjectTypeCode.calendar;
      case BacnetObjectType.trendLog:
        return BacnetObjectTypeCode.trendLog;
      case BacnetObjectType.device:
        return BacnetObjectTypeCode.device;
      default:
        return null;
    }
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

  /// Récupère ou crée un ConnectedApiClient pour une connexion
  Future<ConnectedApiClient?> _getApiClientForConnection(int connectionId) async {
    // Vérifier le cache local
    if (_apiClients.containsKey(connectionId)) {
      return _apiClients[connectionId];
    }

    // Vérifier si c'est la connexion active (réutiliser son client)
    final activeState = _ref.read(activeConnectionProvider);
    if (activeState.isConnected && activeState.connection?.id == connectionId) {
      _logger.i('_getApiClientForConnection: reusing active connection client for $connectionId');
      return activeState.client;
    }

    // Récupérer les infos de connexion depuis la DB
    final database = _ref.read(databaseProvider);
    final connection = await database.getConnectionById(connectionId);
    if (connection == null) {
      _logger.e('_getApiClientForConnection: connection $connectionId not found in DB');
      return null;
    }

    // Récupérer le mot de passe depuis le secure storage (avec les bonnes options Android)
    final secureStorage = _ref.read(secureStorageProvider);
    final password = await secureStorage.read(key: connection.passwordKey);
    if (password == null) {
      _logger.e('_getApiClientForConnection: password not found for key "${connection.passwordKey}" - user needs to reconnect on this device');
      return null;
    }

    // Construire l'URL de base et l'auth
    final protocol = connection.useHttps ? 'https' : 'http';
    final baseUrl = '$protocol://${connection.host}:${connection.port}';
    final basicAuth = 'Basic ${base64Encode(utf8.encode('${connection.username}:$password'))}';

    try {
      // Créer le ConnectedApiClient
      final apiClient = ConnectedApiClient(
        baseUrl: baseUrl,
        basicAuth: basicAuth,
        apiVersion: connection.apiVersion ?? 'V1',
      );

      _apiClients[connectionId] = apiClient;
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
    super.dispose();
  }
}

/// Provider pour le notifier des super favoris
final superFavoritesProvider =
    StateNotifierProvider<SuperFavoritesNotifier, SuperFavoritesState>((ref) {
  return SuperFavoritesNotifier(ref);
});

/// Provider pour toggle le statut super favori d'un favori
final toggleSuperFavoriteProvider = Provider<Future<bool> Function(int favoriteId)>((ref) {
  final database = ref.watch(databaseProvider);

  return (int favoriteId) async {
    try {
      final newValue = await database.toggleSuperFavorite(favoriteId);
      _logger.i('toggleSuperFavorite: $favoriteId is now ${newValue ? "super" : "normal"}');
      return newValue;
    } catch (e) {
      _logger.e('toggleSuperFavorite error: $e');
      return false;
    }
  };
});
