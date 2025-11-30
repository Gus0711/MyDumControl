import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../data/database/app_database.dart';
import '../../data/services/api_service.dart';
import '../../domain/models/bacnet_object.dart';
import 'connection_providers.dart';
import 'database_provider.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

/// État de la connexion active
class ActiveConnectionState {
  final Connection? connection;
  final ConnectedApiClient? client;
  final DeviceInfo? deviceInfo;
  final ObjectsSummary? objectsSummary;
  final bool isConnecting;
  final bool isLoadingDeviceInfo;
  final bool isLoadingSummary;
  final String? error;

  const ActiveConnectionState({
    this.connection,
    this.client,
    this.deviceInfo,
    this.objectsSummary,
    this.isConnecting = false,
    this.isLoadingDeviceInfo = false,
    this.isLoadingSummary = false,
    this.error,
  });

  bool get isConnected => client != null && connection != null;
  bool get isLoading => isConnecting || isLoadingDeviceInfo || isLoadingSummary;

  ActiveConnectionState copyWith({
    Connection? connection,
    ConnectedApiClient? client,
    DeviceInfo? deviceInfo,
    ObjectsSummary? objectsSummary,
    bool? isConnecting,
    bool? isLoadingDeviceInfo,
    bool? isLoadingSummary,
    String? error,
  }) {
    return ActiveConnectionState(
      connection: connection ?? this.connection,
      client: client ?? this.client,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      objectsSummary: objectsSummary ?? this.objectsSummary,
      isConnecting: isConnecting ?? this.isConnecting,
      isLoadingDeviceInfo: isLoadingDeviceInfo ?? this.isLoadingDeviceInfo,
      isLoadingSummary: isLoadingSummary ?? this.isLoadingSummary,
      error: error,
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
      _logger.i('connect: connected! Loading data in background...');
      state = ActiveConnectionState(
        connection: connection,
        client: client,
        isConnecting: false,
        isLoadingDeviceInfo: true,
        isLoadingSummary: true,
      );

      // CHARGER LES DONNÉES EN ARRIÈRE-PLAN (sans bloquer)
      _loadDataInBackground(client, connection.name);

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
  void _loadDataInBackground(ConnectedApiClient client, String fallbackName) {
    // Charger deviceInfo
    client.getDeviceInfo().then((deviceInfo) {
      _logger.i('Background: deviceInfo loaded: ${deviceInfo.objectName}');
      if (mounted) {
        state = state.copyWith(
          deviceInfo: deviceInfo,
          isLoadingDeviceInfo: false,
        );
      }
    }).catchError((e) {
      _logger.w('Background: getDeviceInfo failed: $e');
      if (mounted) {
        state = state.copyWith(
          deviceInfo: DeviceInfo(objectName: fallbackName),
          isLoadingDeviceInfo: false,
        );
      }
    });

    // Charger objectsSummary
    client.getObjectsSummary().then((summary) {
      _logger.i('Background: objectsSummary loaded: ${summary.total} objets');
      if (mounted) {
        state = state.copyWith(
          objectsSummary: summary,
          isLoadingSummary: false,
        );
      }
    }).catchError((e) {
      _logger.w('Background: getObjectsSummary failed: $e');
      if (mounted) {
        state = state.copyWith(
          objectsSummary: ObjectsSummary(),
          isLoadingSummary: false,
        );
      }
    });
  }

  /// Se déconnecte
  void disconnect() {
    state.client?.dispose();
    state = const ActiveConnectionState();
  }

  /// Rafraîchit les données (en arrière-plan)
  Future<void> refresh() async {
    if (!state.isConnected) return;

    state = state.copyWith(
      isLoadingDeviceInfo: true,
      isLoadingSummary: true,
      error: null,
    );

    // Recharger en arrière-plan
    _loadDataInBackground(state.client!, state.connection?.name ?? 'Automate');
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
