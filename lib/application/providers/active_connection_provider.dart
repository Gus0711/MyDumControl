import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../data/database/app_database.dart';
import '../../data/services/api_client_factory.dart';
import '../../data/services/api_service.dart';
import 'api_provider.dart';
import '../../domain/models/bacnet_object.dart';
import 'database_provider.dart';
import 'cache_provider.dart';
import 'points_provider.dart';
import 'schedule_provider.dart';
import 'bacnet_provider.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

/// État de la connexion active
class ActiveConnectionState {
  final Connection? connection;
  final ConnectedApiClient? client;
  final DeviceInfo? deviceInfo;
  final ObjectsSummary? objectsSummary;
  final ControllerTime? controllerTime;
  final NetworkInfo? networkInfo;
  final bool isConnecting;
  final bool isLoadingDeviceInfo;
  final bool isLoadingSummary;
  final String? error;

  /// Typed cause of a failed API connection, for the UI to offer the right
  /// action: [CertificateMismatchException] (trust the new certificate),
  /// [ApiAuthException] (invalid credentials) or [PasswordMissingException]
  /// (edit the connection). Reset like [error] by [copyWith].
  final ApiException? failure;

  /// Non-fatal authorization warning (HTTP 403 on some request).
  final String? authWarning;

  /// Indique si les données viennent du cache
  final bool deviceInfoFromCache;
  final bool summaryFromCache;

  /// Pour les connexions BACnet natives
  final bool isBacnetConnection;
  final int? bacnetDeviceId;

  const ActiveConnectionState({
    this.connection,
    this.client,
    this.deviceInfo,
    this.objectsSummary,
    this.controllerTime,
    this.networkInfo,
    this.isConnecting = false,
    this.isLoadingDeviceInfo = false,
    this.isLoadingSummary = false,
    this.error,
    this.failure,
    this.authWarning,
    this.deviceInfoFromCache = false,
    this.summaryFromCache = false,
    this.isBacnetConnection = false,
    this.bacnetDeviceId,
  });

  /// Connexion établie (API ou BACnet)
  bool get isConnected => (client != null || isBacnetConnection) && connection != null;
  bool get isLoading => isConnecting || isLoadingDeviceInfo || isLoadingSummary;

  ActiveConnectionState copyWith({
    Connection? connection,
    ConnectedApiClient? client,
    DeviceInfo? deviceInfo,
    ObjectsSummary? objectsSummary,
    ControllerTime? controllerTime,
    NetworkInfo? networkInfo,
    bool? isConnecting,
    bool? isLoadingDeviceInfo,
    bool? isLoadingSummary,
    String? error,
    ApiException? failure,
    String? authWarning,
    bool? deviceInfoFromCache,
    bool? summaryFromCache,
    bool? isBacnetConnection,
    int? bacnetDeviceId,
  }) {
    return ActiveConnectionState(
      connection: connection ?? this.connection,
      client: client ?? this.client,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      objectsSummary: objectsSummary ?? this.objectsSummary,
      controllerTime: controllerTime ?? this.controllerTime,
      networkInfo: networkInfo ?? this.networkInfo,
      isConnecting: isConnecting ?? this.isConnecting,
      isLoadingDeviceInfo: isLoadingDeviceInfo ?? this.isLoadingDeviceInfo,
      isLoadingSummary: isLoadingSummary ?? this.isLoadingSummary,
      error: error,
      failure: failure,
      authWarning: authWarning ?? this.authWarning,
      deviceInfoFromCache: deviceInfoFromCache ?? this.deviceInfoFromCache,
      summaryFromCache: summaryFromCache ?? this.summaryFromCache,
      isBacnetConnection: isBacnetConnection ?? this.isBacnetConnection,
      bacnetDeviceId: bacnetDeviceId ?? this.bacnetDeviceId,
    );
  }
}

/// Notifier pour gérer la connexion active
class ActiveConnectionNotifier extends StateNotifier<ActiveConnectionState> {
  final Ref _ref;

  ActiveConnectionNotifier(this._ref) : super(const ActiveConnectionState());

  /// Connection token, bumped on every connect()/disconnect(). Any async
  /// result (connect in flight, background loading) started with an older
  /// token belongs to a previous connection and must be ignored.
  int _connectionToken = 0;

  bool _isCurrent(int token) => mounted && token == _connectionToken;

  /// Se connecte à un automate (connexion rapide, données en arrière-plan)
  Future<bool> connect(int connectionId) async {
    _logger.i('connect: connectionId=$connectionId');
    final token = ++_connectionToken;

    // Dispose de l'ancien client avant de créer un nouveau (éviter les memory leaks)
    final oldClient = state.client;
    if (oldClient != null) {
      _logger.i('connect: disposing previous client');
      oldClient.dispose();
    }

    // IMPORTANT: Réinitialiser tous les providers de données
    // pour éviter d'afficher les données de l'ancien automate
    _clearDataProviders();

    state = state.copyWith(isConnecting: true, error: null);

    try {
      // Récupérer les infos de connexion
      final database = _ref.read(databaseProvider);
      final connection = await database.getConnectionById(connectionId);
      if (!_isCurrent(token)) return false;

      if (connection == null) {
        _logger.e('connect: connexion introuvable');
        state = state.copyWith(
          isConnecting: false,
          error: 'Connexion introuvable',
        );
        return false;
      }

      _logger.i('connect: connection=${connection.name}, host=${connection.host}:${connection.port}, type=${connection.connectionType}');

      // ========================================
      // CONNEXION BACNET NATIVE
      // ========================================
      if (connection.connectionType == 'bacnet') {
        return await _connectBacnet(connection, token);
      }

      // ========================================
      // CONNEXION API DISTECH (comportement existant)
      // ========================================
      return await _connectDistechApi(connection, token);
    } catch (e) {
      _logger.e('connect: error: $e');
      if (!_isCurrent(token)) return false;
      state = state.copyWith(
        isConnecting: false,
        error: 'Erreur de connexion: $e',
      );
      return false;
    }
  }

  /// Connexion BACnet native
  Future<bool> _connectBacnet(Connection connection, int token) async {
    _logger.i('_connectBacnet: connecting to ${connection.host}:${connection.port}');

    final bacnetService = _ref.read(bacnetServiceProvider);
    final database = _ref.read(databaseProvider);

    // Déterminer le Device ID (soit enregistré, soit à découvrir)
    int? deviceId = connection.bacnetDeviceId;

    if (deviceId == null) {
      // Essayer de découvrir le device ID
      _logger.i('_connectBacnet: discovering device ID via Who-Is...');
      final devices = await bacnetService.whoIs(
        host: connection.host,
        port: connection.port,
        timeout: const Duration(seconds: 3),
      );
      if (!_isCurrent(token)) return false;

      if (devices.isEmpty) {
        _logger.e('_connectBacnet: no BACnet device responded');
        state = state.copyWith(
          isConnecting: false,
          error: 'Aucun device BACnet n\'a répondu',
        );
        return false;
      }

      deviceId = devices.first.deviceId;
      _logger.i('_connectBacnet: discovered device ID: $deviceId');
    }

    // Mettre à jour la date de dernière connexion
    await database.updateLastConnectedAt(connection.id);
    if (!_isCurrent(token)) return false;

    // Mettre à jour le provider BACnet actif
    _ref.read(activeBacnetConnectionProvider.notifier).state = ActiveBacnetConnection(
      connectionId: connection.id,
      host: connection.host,
      port: connection.port,
      deviceId: deviceId,
    );

    // CONNEXION ÉTABLIE
    _logger.i('_connectBacnet: connected! Device ID: $deviceId');

    state = ActiveConnectionState(
      connection: connection,
      client: null, // Pas de client API pour BACnet
      isConnecting: false,
      isBacnetConnection: true,
      bacnetDeviceId: deviceId,
      isLoadingDeviceInfo: true,
      isLoadingSummary: true,
    );

    // Charger les données BACnet en arrière-plan
    _loadBacnetDataInBackground(connection, deviceId, token);

    return true;
  }

  /// Charge les données BACnet en arrière-plan
  /// [token] identifies the connection; results are dropped if it changed.
  void _loadBacnetDataInBackground(Connection connection, int deviceId, int token) async {
    final bacnetService = _ref.read(bacnetServiceProvider);

    try {
      // Lire les propriétés du device
      final nameResult = await bacnetService.readProperty(
        host: connection.host,
        port: connection.port,
        objectType: 8, // Device
        objectInstance: deviceId,
        propertyId: 77, // object-name
      );

      String deviceName = connection.name;
      if (nameResult.isSuccess && nameResult.value is String) {
        deviceName = nameResult.value as String;
      }

      // Lire vendor-name
      String? vendorName;
      final vendorResult = await bacnetService.readProperty(
        host: connection.host,
        port: connection.port,
        objectType: 8,
        objectInstance: deviceId,
        propertyId: 121, // vendor-name
      );
      if (vendorResult.isSuccess && vendorResult.value is String) {
        vendorName = vendorResult.value as String;
      }

      // Lire model-name
      String? modelName;
      final modelResult = await bacnetService.readProperty(
        host: connection.host,
        port: connection.port,
        objectType: 8,
        objectInstance: deviceId,
        propertyId: 70, // model-name
      );
      if (modelResult.isSuccess && modelResult.value is String) {
        modelName = modelResult.value as String;
      }

      if (_isCurrent(token)) {
        state = state.copyWith(
          deviceInfo: DeviceInfo(
            objectName: deviceName,
            vendorName: vendorName,
            modelName: modelName,
            deviceInstance: deviceId,
          ),
          isLoadingDeviceInfo: false,
        );
      }

      _logger.i('_loadBacnetDataInBackground: deviceInfo loaded: $deviceName');
    } catch (e) {
      _logger.w('_loadBacnetDataInBackground: failed to load device info: $e');
      if (_isCurrent(token)) {
        state = state.copyWith(
          deviceInfo: DeviceInfo(objectName: connection.name, deviceInstance: deviceId),
          isLoadingDeviceInfo: false,
        );
      }
    }

    // Pour l'instant, objectsSummary n'est pas disponible via BACnet natif
    // On pourrait le calculer en lisant object-list mais c'est lent
    if (_isCurrent(token)) {
      state = state.copyWith(
        objectsSummary: ObjectsSummary(), // Vide pour l'instant
        isLoadingSummary: false,
      );
    }
  }

  /// Connexion API Distech
  Future<bool> _connectDistechApi(Connection connection, int token) async {
    _logger.i('_connectDistechApi: connecting to ${connection.host}:${connection.port}');

    // Construire le client (mot de passe, auth, version, timeouts, TOFU)
    final factory = _ref.read(apiClientFactoryProvider);
    final ApiClientConfig config;
    try {
      config = await factory.resolve(connection);
    } on PasswordMissingException catch (e) {
      if (!_isCurrent(token)) return false;
      _logger.e('_connectDistechApi: mot de passe introuvable');
      state = ActiveConnectionState(connection: connection, error: e.message, failure: e);
      return false;
    }
    if (!_isCurrent(token)) return false;

    _logger.i('_connectDistechApi: baseUrl=${config.baseUrl}, apiVersion=${config.apiVersion}');

    final client = factory.build(
      config,
      onAuthError: (e) => _onAuthError(e, connection, token),
      onCertificateMismatch: (e) => _failConnection(e, connection, token),
    );

    // Not a BACnet connection: clear any previous native BACnet target
    _ref.read(activeBacnetConnectionProvider.notifier).state = null;

    try {
      // Mettre à jour la date de dernière connexion
      final database = _ref.read(databaseProvider);
      await database.updateLastConnectedAt(connection.id);
      if (!_isCurrent(token)) {
        client.dispose();
        return false;
      }
    } catch (e) {
      client.dispose();
      rethrow;
    }

    // CONNEXION IMMÉDIATE - L'UI peut naviguer maintenant!
    _logger.i('_connectDistechApi: connected! Loading cache first, then fresh data...');

    // Charger immédiatement depuis le cache (si disponible)
    final cacheService = _ref.read(cacheServiceProvider);
    final cachedDeviceInfo = await cacheService.getCachedDeviceInfo(connection.id);
    final cachedSummary = await cacheService.getCachedObjectsSummary(connection.id);
    if (!_isCurrent(token)) {
      client.dispose();
      return false;
    }

    if (cachedDeviceInfo != null) {
      _logger.i('_connectDistechApi: deviceInfo loaded from cache: ${cachedDeviceInfo.objectName}');
    }
    if (cachedSummary != null) {
      _logger.i('_connectDistechApi: objectsSummary loaded from cache: ${cachedSummary.total} objets');
    }

    // TOUJOURS afficher l'animation de chargement (même avec cache)
    // pour une UX cohérente entre V1 et V2
    state = ActiveConnectionState(
      connection: connection,
      client: client,
      isConnecting: false,
      isBacnetConnection: false,
      // Afficher les données du cache immédiatement
      deviceInfo: cachedDeviceInfo,
      objectsSummary: cachedSummary,
      deviceInfoFromCache: cachedDeviceInfo != null,
      summaryFromCache: cachedSummary != null,
      // Toujours mettre isLoading à true pour afficher l'animation
      // Le chargement en arrière-plan les passera à false
      isLoadingDeviceInfo: true,
      isLoadingSummary: true,
    );

    // CHARGER LES DONNÉES FRAÎCHES EN ARRIÈRE-PLAN (sans bloquer)
    // Cela mettra à jour le cache et l'UI
    _loadDataInBackground(client, connection.id, connection.name, token);

    return true;
  }

  /// Drops the current API connection after a fatal error (certificate
  /// mismatch, invalid credentials): the home screen shows [failure].
  void _failConnection(ApiException failure, Connection connection, int token) {
    if (!_isCurrent(token)) return;
    _logger.e('connection failed: $failure');
    _connectionToken++;
    state.client?.dispose();
    _clearDataProviders();
    state = ActiveConnectionState(
      connection: connection,
      error: failure.message,
      failure: failure,
    );
  }

  /// 401 during the initial load (device info not loaded yet): credentials
  /// are wrong for the whole controller (Basic auth), the connection is
  /// dropped. Otherwise (403, or a later 401 on a single request) a non-fatal
  /// warning is shown and the connection is kept.
  void _onAuthError(ApiAuthException e, Connection connection, int token) {
    if (!_isCurrent(token)) return;
    if (e.statusCode == 401 && state.isLoadingDeviceInfo) {
      _failConnection(e, connection, token);
    } else if (state.authWarning == null) {
      state = state.copyWith(authWarning: '${e.message} (HTTP ${e.statusCode})');
    }
  }

  /// Trusts the certificate now presented by the controller (after the user
  /// confirmed it) and reconnects.
  Future<bool> trustNewCertificate() async {
    final failure = state.failure;
    final connection = state.connection;
    if (failure is! CertificateMismatchException || connection == null) return false;
    final database = _ref.read(databaseProvider);
    await database.updateCertificateFingerprint(connection.id, failure.receivedFingerprint);
    if (!mounted) return false;
    return connect(connection.id);
  }

  /// Charge les données en arrière-plan sans bloquer l'UI
  /// Met également à jour le cache local
  /// [token] identifies the connection; results are dropped if it changed
  /// (another automate connected meanwhile, or disconnected).
  void _loadDataInBackground(ConnectedApiClient client, int connectionId, String fallbackName, int token) {
    final cacheService = _ref.read(cacheServiceProvider);

    // Charger deviceInfo (en arrière-plan)
    client.getDeviceInfo().then((deviceInfo) {
      _logger.i('Background: deviceInfo loaded: ${deviceInfo.objectName}');
      if (!_isCurrent(token)) return;

      // Mettre à jour le cache
      cacheService.cacheDeviceInfo(connectionId, deviceInfo);

      // Mettre à jour le modelName en DB si disponible
      if (deviceInfo.modelName != null) {
        final database = _ref.read(databaseProvider);
        database.updateModelName(connectionId, deviceInfo.modelName!);
        _logger.i('Background: modelName saved to DB: ${deviceInfo.modelName}');
      }

      if (_isCurrent(token)) {
        state = state.copyWith(
          deviceInfo: deviceInfo,
          isLoadingDeviceInfo: false,
          deviceInfoFromCache: false, // Données fraîches
        );
      }
    }).catchError((e) {
      _logger.w('Background: getDeviceInfo failed: $e');
      if (_isCurrent(token)) {
        // Si on a des données du cache, on les garde
        if (state.deviceInfo == null) {
          state = state.copyWith(
            deviceInfo: DeviceInfo(objectName: fallbackName),
            isLoadingDeviceInfo: false,
          );
        } else {
          state = state.copyWith(isLoadingDeviceInfo: false);
        }
      }
    });

    // Charger objectsSummary (en arrière-plan)
    client.getObjectsSummary().then((summary) {
      _logger.i('Background: objectsSummary loaded: ${summary.total} objets');
      if (!_isCurrent(token)) return;

      // Mettre à jour le cache
      cacheService.cacheObjectsSummary(connectionId, summary);

      if (_isCurrent(token)) {
        state = state.copyWith(
          objectsSummary: summary,
          isLoadingSummary: false,
          summaryFromCache: false, // Données fraîches
        );
      }
    }).catchError((e) {
      _logger.w('Background: getObjectsSummary failed: $e');
      if (_isCurrent(token)) {
        // Si on a des données du cache, on les garde
        if (state.objectsSummary == null) {
          state = state.copyWith(
            objectsSummary: ObjectsSummary(),
            isLoadingSummary: false,
          );
        } else {
          state = state.copyWith(isLoadingSummary: false);
        }
      }
    });

    // Charger l'heure de l'automate (en arrière-plan)
    client.getControllerTime().then((controllerTime) {
      _logger.i('Background: controllerTime loaded: ${controllerTime.formattedDateTime}, offset=${controllerTime.offsetDescription}');

      if (_isCurrent(token)) {
        state = state.copyWith(controllerTime: controllerTime);
      }
    }).catchError((e) {
      _logger.w('Background: getControllerTime failed: $e');
      // Pas critique, on continue sans l'heure
    });

    // Charger les infos réseau (API V1 uniquement, en arrière-plan)
    client.getNetworkInfo().then((networkInfo) {
      if (networkInfo != null) {
        _logger.i('Background: networkInfo loaded: $networkInfo');
        if (_isCurrent(token)) {
          state = state.copyWith(networkInfo: networkInfo);
        }
      }
    }).catchError((e) {
      _logger.w('Background: getNetworkInfo failed: $e');
      // Pas critique, on continue sans les infos réseau
    });
  }

  /// Se déconnecte et réinitialise tous les providers de données
  void disconnect() {
    _logger.i('disconnect: clearing all data providers');
    _connectionToken++;
    state.client?.dispose();
    _ref.read(activeBacnetConnectionProvider.notifier).state = null;

    // Réinitialiser tous les providers de données pour éviter
    // d'afficher les données de l'ancien automate
    _clearDataProviders();

    state = const ActiveConnectionState();
  }

  /// Réinitialise tous les providers de données
  /// Appelé lors de la déconnexion ou du changement d'automate
  void _clearDataProviders() {
    // Points BACnet - reset via le notifier (pas invalidate pour éviter dépendance circulaire)
    _ref.read(pointsProvider.notifier).reset();

    // Plannings - reset via le notifier
    _ref.read(scheduleEditProvider.notifier).reset();

    // Note: schedulesListProvider et trendLogMappingProvider sont des FutureProvider
    // Ils se rafraîchiront automatiquement car ils watchent activeConnectionProvider

    _logger.i('_clearDataProviders: data providers reset');
  }

  /// Rafraîchit les données (en arrière-plan)
  /// forceRefresh: si true, ignore le cache et force le rechargement
  Future<void> refresh({bool forceRefresh = false}) async {
    if (!state.isConnected) return;

    final token = _connectionToken;
    final connection = state.connection!;
    final connectionId = connection.id;

    // Si forceRefresh, vider le cache d'abord
    if (forceRefresh) {
      final cacheService = _ref.read(cacheServiceProvider);
      await cacheService.clearAllCache(connectionId);
      _logger.i('refresh: cache cleared for connection $connectionId');
      if (!_isCurrent(token)) return;
    }

    // Connexion BACnet native : pas de client API
    if (state.isBacnetConnection) {
      final deviceId = state.bacnetDeviceId;
      if (deviceId == null) return;
      state = state.copyWith(
        isLoadingDeviceInfo: true,
        isLoadingSummary: true,
        error: null,
      );
      _loadBacnetDataInBackground(connection, deviceId, token);
      return;
    }

    final client = state.client;
    if (client == null) return;

    state = state.copyWith(
      isLoadingDeviceInfo: true,
      isLoadingSummary: true,
      error: null,
    );

    // Recharger en arrière-plan
    _loadDataInBackground(client, connectionId, connection.name, token);
  }

  @override
  void dispose() {
    state.client?.dispose();
    super.dispose();
  }
}

/// Provider pour la connexion active
final activeConnectionProvider =
    StateNotifierProvider<ActiveConnectionNotifier, ActiveConnectionState>((ref) {
  return ActiveConnectionNotifier(ref);
});

/// Provider pour récupérer les objets d'un type donné
final objectsByTypeProvider =
    FutureProvider.family<List<BacnetObject>, BacnetObjectType>((ref, type) async {
  final state = ref.watch(activeConnectionProvider);
  final client = state.client;
  if (!state.isConnected || client == null) return [];

  return client.getObjectsByType(type);
});

/// Provider pour récupérer tous les objets
final allObjectsProvider = FutureProvider<List<BacnetObject>>((ref) async {
  final state = ref.watch(activeConnectionProvider);
  final client = state.client;
  if (!state.isConnected || client == null) return [];

  return client.getAllObjects();
});
