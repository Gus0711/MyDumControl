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

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

/// État de la connexion active
class ActiveConnectionState {
  final Connection? connection;
  final ConnectedApiClient? client;
  final DeviceInfo? deviceInfo;
  final ObjectsSummary? objectsSummary;
  final ControllerTime? controllerTime;
  final bool isConnecting;
  final bool isLoadingDeviceInfo;
  final bool isLoadingSummary;
  final String? error;

  /// Indique si les données viennent du cache
  final bool deviceInfoFromCache;
  final bool summaryFromCache;

  const ActiveConnectionState({
    this.connection,
    this.client,
    this.deviceInfo,
    this.objectsSummary,
    this.controllerTime,
    this.isConnecting = false,
    this.isLoadingDeviceInfo = false,
    this.isLoadingSummary = false,
    this.error,
    this.deviceInfoFromCache = false,
    this.summaryFromCache = false,
  });

  bool get isConnected => client != null && connection != null;
  bool get isLoading => isConnecting || isLoadingDeviceInfo || isLoadingSummary;

  ActiveConnectionState copyWith({
    Connection? connection,
    ConnectedApiClient? client,
    DeviceInfo? deviceInfo,
    ObjectsSummary? objectsSummary,
    ControllerTime? controllerTime,
    bool? isConnecting,
    bool? isLoadingDeviceInfo,
    bool? isLoadingSummary,
    String? error,
    bool? deviceInfoFromCache,
    bool? summaryFromCache,
  }) {
    return ActiveConnectionState(
      connection: connection ?? this.connection,
      client: client ?? this.client,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      objectsSummary: objectsSummary ?? this.objectsSummary,
      controllerTime: controllerTime ?? this.controllerTime,
      isConnecting: isConnecting ?? this.isConnecting,
      isLoadingDeviceInfo: isLoadingDeviceInfo ?? this.isLoadingDeviceInfo,
      isLoadingSummary: isLoadingSummary ?? this.isLoadingSummary,
      error: error,
      deviceInfoFromCache: deviceInfoFromCache ?? this.deviceInfoFromCache,
      summaryFromCache: summaryFromCache ?? this.summaryFromCache,
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

      _logger.i('connect: connection=${connection.name}, host=${connection.host}:${connection.port}, apiVersion=${connection.apiVersion}');

      // Récupérer le mot de passe
      final secureStorage = _ref.read(secureStorageProvider);
      final password = await secureStorage.read(key: connection.passwordKey);

      if (password == null) {
        _logger.e('connect: mot de passe introuvable');
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

      _logger.i('connect: baseUrl=$baseUrl, apiVersion=$apiVersion');

      // Créer le client
      final client = ConnectedApiClient(
        baseUrl: baseUrl,
        basicAuth: basicAuth,
        apiVersion: apiVersion,
      );

      // Mettre à jour la date de dernière connexion
      await database.updateLastConnectedAt(connectionId);

      // CONNEXION IMMÉDIATE - L'UI peut naviguer maintenant!
      _logger.i('connect: connected! Loading cache first, then fresh data...');

      // Charger immédiatement depuis le cache (si disponible)
      final cacheService = _ref.read(cacheServiceProvider);
      final cachedDeviceInfo = await cacheService.getCachedDeviceInfo(connectionId);
      final cachedSummary = await cacheService.getCachedObjectsSummary(connectionId);

      if (cachedDeviceInfo != null) {
        _logger.i('connect: deviceInfo loaded from cache: ${cachedDeviceInfo.objectName}');
      }
      if (cachedSummary != null) {
        _logger.i('connect: objectsSummary loaded from cache: ${cachedSummary.total} objets');
      }

      // TOUJOURS afficher l'animation de chargement (même avec cache)
      // pour une UX cohérente entre V1 et V2
      state = ActiveConnectionState(
        connection: connection,
        client: client,
        isConnecting: false,
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
      _loadDataInBackground(client, connectionId, connection.name);

      return true;
    } catch (e) {
      _logger.e('connect: error: $e');
      state = state.copyWith(
        isConnecting: false,
        error: 'Erreur de connexion: $e',
      );
      return false;
    }
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
