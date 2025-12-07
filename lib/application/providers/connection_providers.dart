import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/database/app_database.dart';
import 'database_provider.dart';

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
  }) async {
    // Générer une clé unique pour le mot de passe
    final passwordKey = 'conn_pwd_${DateTime.now().millisecondsSinceEpoch}';

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
  }) async {
    final existing = await database.getConnectionById(id);
    if (existing == null) return;

    // Si un nouveau mot de passe est fourni, le mettre à jour
    if (password != null && password.isNotEmpty) {
      await secureStorage.write(key: existing.passwordKey, value: password);
    }

    // Mettre à jour les autres champs
    await database.updateConnection(
      existing.copyWith(
        name: name,
        host: host,
        port: port,
        useHttps: useHttps,
        username: username,
        apiVersion: Value(apiVersion ?? existing.apiVersion),
        connectionType: connectionType ?? existing.connectionType,
        bacnetDeviceId: Value(bacnetDeviceId),
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Supprime une connexion
  Future<void> deleteConnection(int id) async {
    final existing = await database.getConnectionById(id);
    if (existing == null) return;

    // Supprimer le mot de passe du stockage sécurisé
    await secureStorage.delete(key: existing.passwordKey);

    // Supprimer la connexion de la base de données
    await database.deleteConnectionById(id);
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
