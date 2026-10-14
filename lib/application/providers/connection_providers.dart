import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import '../../data/database/app_database.dart';
import 'database_provider.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

/// Generates a unique secure-storage key for a connection password.
String generatePasswordKey() => 'conn_pwd_${const Uuid().v4()}';

/// True if a connection edit points it to another device, so the cached data
/// (points, device info, trend mapping, summary) must be invalidated.
bool connectionTargetChanged(
  Connection existing, {
  required String host,
  required int port,
  required String connectionType,
  required int? bacnetDeviceId,
}) {
  return existing.host != host ||
      existing.port != port ||
      existing.connectionType != connectionType ||
      existing.bacnetDeviceId != bacnetDeviceId;
}

/// True if the pinned TLS certificate must be forgotten after an edit: it
/// belongs to another endpoint (host, port or scheme changed).
bool certificateEndpointChanged(
  Connection existing, {
  required String host,
  required int port,
  required bool useHttps,
}) {
  return existing.host != host || existing.port != port || existing.useHttps != useHttps;
}

/// Provider pour le stockage sécurisé des mots de passe
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

/// Stream provider pour observer les connexions en temps réel
final connectionsStreamProvider = StreamProvider<List<Connection>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.watchAllConnections();
});

/// True if a password is stored for the connection (keyed by its
/// passwordKey). Used to flag connections imported without their secret.
final connectionHasPasswordProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, passwordKey) async {
  final password = await ref.watch(secureStorageProvider).read(key: passwordKey);
  return password != null;
});

/// Provider pour les opérations sur les connexions
final connectionRepositoryProvider = Provider<ConnectionRepository>((ref) {
  return ConnectionRepository(
    database: ref.watch(databaseProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

/// Repository pour gérer les connexions
class ConnectionRepository {
  final AppDatabase database;
  final FlutterSecureStorage secureStorage;

  ConnectionRepository({
    required this.database,
    required this.secureStorage,
  });

  /// Crée une nouvelle connexion
  Future<int> createConnection({
    required String name,
    required String host,
    required int port,
    required bool useHttps,
    required String username,
    required String password,
    String? apiVersion,
    String connectionType = 'distech_api',
    int? bacnetDeviceId,
    String? designerUrl,
    String? certificateFingerprint,
  }) async {
    // Générer une clé unique pour le mot de passe
    final passwordKey = generatePasswordKey();

    // Stocker le mot de passe de manière sécurisée (même vide pour BACnet)
    await secureStorage.write(key: passwordKey, value: password);

    // Insérer la connexion dans la base de données
    final id = await database.insertConnection(
      ConnectionsCompanion.insert(
        name: name,
        host: host,
        port: Value(port),
        useHttps: Value(useHttps),
        username: username,
        passwordKey: passwordKey,
        apiVersion: Value(apiVersion),
        connectionType: Value(connectionType),
        bacnetDeviceId: Value(bacnetDeviceId),
        designerUrl: Value(designerUrl),
        certificateFingerprint: Value(certificateFingerprint),
      ),
    );

    return id;
  }

  /// Met à jour une connexion existante
  Future<void> updateConnection({
    required int id,
    required String name,
    required String host,
    required int port,
    required bool useHttps,
    required String username,
    String? password,
    String? apiVersion,
    String? connectionType,
    int? bacnetDeviceId,
    String? designerUrl,
    String? certificateFingerprint,
  }) async {
    final existing = await database.getConnectionById(id);
    if (existing == null) return;

    // Pinned certificate (TOFU): forgotten when the endpoint changes, unless
    // the caller provides the one seen by a connection test on the new one.
    final endpointChanged = certificateEndpointChanged(
      existing,
      host: host,
      port: port,
      useHttps: useHttps,
    );
    final newFingerprint = endpointChanged
        ? certificateFingerprint
        : (existing.certificateFingerprint ?? certificateFingerprint);

    // Si un nouveau mot de passe est fourni, le mettre à jour
    if (password != null && password.isNotEmpty) {
      await secureStorage.write(key: existing.passwordKey, value: password);
    }

    final newType = connectionType ?? existing.connectionType;
    final targetChanged = connectionTargetChanged(
      existing,
      host: host,
      port: port,
      connectionType: newType,
      bacnetDeviceId: bacnetDeviceId,
    );

    // Mettre à jour les autres champs
    await database.updateConnection(
      existing.copyWith(
        name: name,
        host: host,
        port: port,
        useHttps: useHttps,
        username: username,
        apiVersion: Value(apiVersion ?? existing.apiVersion),
        connectionType: newType,
        bacnetDeviceId: Value(bacnetDeviceId),
        designerUrl: Value(designerUrl),
        certificateFingerprint: Value(useHttps ? newFingerprint : null),
        updatedAt: DateTime.now(),
      ),
    );

    // The connection now targets another device: drop the old device's cache
    if (targetChanged) {
      await database.clearAllCache(id);
    }
  }

  /// Supprime une connexion
  Future<void> deleteConnection(int id) async {
    final existing = await database.getConnectionById(id);
    if (existing == null) return;

    // Supprimer la connexion et toutes ses données liées (transaction)
    await database.deleteConnectionCascade(id);

    // Puis le mot de passe, seulement une fois la suppression DB réussie
    try {
      await secureStorage.delete(key: existing.passwordKey);
    } catch (e) {
      _logger.w('deleteConnection: failed to delete password secret: $e');
    }
  }

  /// True if a password is stored for this connection. False for connections
  /// restored from an export: the user must enter the password again.
  Future<bool> hasPassword(Connection connection) async {
    final password = await secureStorage.read(key: connection.passwordKey);
    return password != null;
  }

  /// Récupère le mot de passe d'une connexion
  Future<String?> getPassword(String passwordKey) async {
    return secureStorage.read(key: passwordKey);
  }

  /// Récupère une connexion par son ID
  Future<Connection?> getConnectionById(int id) {
    return database.getConnectionById(id);
  }

  /// Récupère toutes les connexions
  Future<List<Connection>> getAllConnections() {
    return database.getAllConnections();
  }
}
