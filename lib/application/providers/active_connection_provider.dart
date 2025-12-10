import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../data/database/app_database.dart';
import '../../data/services/api_service.dart';
import '../../domain/models/bacnet_object.dart';
import 'connection_providers.dart';
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

  /// Se connecte à un automate (connexion rapide, données en arrière-plan)
  Future<bool> connect(int connectionId) async {
    _logger.i('connect: connectionId=$connectionId');

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
        return _connectBacnet(connection);
      }

      // ========================================
      // CONNEXION API DISTECH (comportement existant)
      // ========================================
      return _connectDistechApi(connection);
    } catch (e) {
      _logger.e('connect: error: $e');
      state = state.copyWith(
        isConnecting: false,
        error: 'Erreur de connexion: $e',
      );
      return false;
    }
  }

  /// Connexion BACnet native
  Future<bool> _connectBacnet(Connection connection) async {
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
    _loadBacnetDataInBackground(connection, deviceId);

    return true;
  }

  /// Charge les données BACnet en arrière-plan
  void _loadBacnetDataInBackground(Connection connection, int deviceId) async {
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

      if (mounted) {
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
      if (mounted) {
        state = state.copyWith(
          deviceInfo: DeviceInfo(objectName: connection.name, deviceInstance: deviceId),
          isLoadingDeviceInfo: false,
        );
      }
    }

    // Pour l'instant, objectsSummary n'est pas disponible via BACnet natif
    // On pourrait le calculer en lisant object-list mais c'est lent
    if (mounted) {
      state = state.copyWith(
        objectsSummary: ObjectsSummary(), // Vide pour l'instant
        isLoadingSummary: false,
      );
    }
  }

  /// Connexion API Distech
  Future<bool> _connectDistechApi(Connection connection) async {
    _logger.i('_connectDistechApi: connecting to ${connection.host}:${connection.port}');

    // Récupérer le mot de passe
    final secureStorage = _ref.read(secureStorageProvider);
    final password = await secureStorage.read(key: connection.passwordKey);

    if (password == null) {
      _logger.e('_connectDistechApi: mot de passe introuvable');
      state = state.copyWith(
        isConnecting: false,
        error: 'Mot de passe introuvable',
      );
      return false;
    }

    // Construire l'URL et l'auth
    final scheme = connection.useHttps ? 'https' : 'http';
    final baseUrl = '$scheme://${connection.host}:${connection.port}';
    final basicAuth = 'Basic ${base64Encode(utf8.encode('${connection.username}:$password'))}';
    final apiVersion = connection.apiVersion ?? 'V2';

    _logger.i('_connectDistechApi: baseUrl=$baseUrl, apiVersion=$apiVersion');

    // Créer le client
    final client = ConnectedApiClient(
      baseUrl: baseUrl,
      basicAuth: basicAuth,
      apiVersion: apiVersion,
    );

    // Mettre à jour la date de dernière connexion
    final database = _ref.read(databaseProvider);
    await database.updateLastConnectedAt(connection.id);

    // CONNEXION IMMÉDIATE - L'UI peut naviguer maintenant!
    _logger.i('_connectDistechApi: connected! Loading cache first, then fresh data...');

    // Charger immédiatement depuis le cache (si disponible)
    final cacheService = _ref.read(cacheServiceProvider);
    final cachedDeviceInfo = await cacheService.getCachedDeviceInfo(connection.id);
    final cachedSummary = await cacheService.getCachedObjectsSummary(connection.id);

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
    _loadDataInBackground(client, connection.id, connection.name);

    return true;
  }

  /// Charge les données en arrière-plan sans bloquer l'UI
  /// Met également à jour le cache local
  void _loadDataInBackground(ConnectedApiClient client, int connectionId, String fallbackName) {
    final cacheService = _ref.read(cacheServiceProvider);

    // Charger deviceInfo (en arrière-plan)
    client.getDeviceInfo().then((deviceInfo) {
      _logger.i('Background: deviceInfo loaded: ${deviceInfo.objectName}');

      // Mettre à jour le cache
      cacheService.cacheDeviceInfo(connectionId, deviceInfo);

      // Mettre à jour le modelName en DB si disponible
      if (deviceInfo.modelName != null) {
        final database = _ref.read(databaseProvider);
        database.updateModelName(connectionId, deviceInfo.modelName!);
        _logger.i('Background: modelName saved to DB: ${deviceInfo.modelName}');
      }

      if (mounted) {
        state = state.copyWith(
          deviceInfo: deviceInfo,
          isLoadingDeviceInfo: false,
          deviceInfoFromCache: false, // Données fraîches
        );
      }
    }).catchError((e) {
      _logger.w('Background: getDeviceInfo failed: $e');
      if (mounted) {
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

      // Mettre à jour le cache
      cacheService.cacheObjectsSummary(connectionId, summary);

      if (mounted) {
        state = state.copyWith(
          objectsSummary: summary,
          isLoadingSummary: false,
          summaryFromCache: false, // Données fraîches
        );
      }
    }).catchError((e) {
      _logger.w('Background: getObjectsSummary failed: $e');
      if (mounted) {
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

      if (mounted) {
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
        if (mounted) {
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
    state.client?.dispose();

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

    final connectionId = state.connection!.id;

    // Si forceRefresh, vider le cache d'abord
    if (forceRefresh) {
      final cacheService = _ref.read(cacheServiceProvider);
      await cacheService.clearAllCache(connectionId);
      _logger.i('refresh: cache cleared for connection $connectionId');
    }

    state = state.copyWith(
      isLoadingDeviceInfo: true,
      isLoadingSummary: true,
      error: null,
    );

    // Recharger en arrière-plan
    _loadDataInBackground(state.client!, connectionId, state.connection?.name ?? 'Automate');
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
  if (!state.isConnected) return [];

  return state.client!.getObjectsByType(type);
});

/// Provider pour récupérer tous les objets
final allObjectsProvider = FutureProvider<List<BacnetObject>>((ref) async {
  final state = ref.watch(activeConnectionProvider);
  if (!state.isConnected) return [];

  return state.client!.getAllObjects();
});
