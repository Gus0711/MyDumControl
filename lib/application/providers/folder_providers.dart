import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import 'database_provider.dart';

/// Stream provider pour observer les dossiers en temps réel
final foldersStreamProvider = StreamProvider<List<Folder>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.watchAllFolders();
});

/// Provider pour les opérations sur les dossiers
final folderRepositoryProvider = Provider<FolderRepository>((ref) {
  return FolderRepository(database: ref.watch(databaseProvider));
});

/// Repository pour gérer les dossiers
class FolderRepository {
  final AppDatabase database;

  FolderRepository({required this.database});

  /// Crée un nouveau dossier
  Future<int> createFolder({
    required String name,
    String icon = 'folder',
    String color = '#2196F3',
  }) async {
    final sortOrder = await database.getNextFolderSortOrder();

    final id = await database.insertFolder(
      FoldersCompanion.insert(
        name: name,
        icon: Value(icon),
        color: Value(color),
        sortOrder: Value(sortOrder),
      ),
    );

    return id;
  }

  /// Met à jour un dossier existant
  Future<void> updateFolder({
    required int id,
    required String name,
    required String icon,
    required String color,
  }) async {
    final existing = await database.getFolderById(id);
    if (existing == null) return;

    await database.updateFolder(
      existing.copyWith(
        name: name,
        icon: icon,
        color: color,
      ),
    );
  }

  /// Supprime un dossier (les connexions sont déplacées à la racine)
  Future<void> deleteFolder(int id) async {
    await database.deleteFolderById(id);
  }

  /// Récupère tous les dossiers
  Future<List<Folder>> getAllFolders() {
    return database.getAllFolders();
  }

  /// Récupère un dossier par son ID
  Future<Folder?> getFolderById(int id) {
    return database.getFolderById(id);
  }

  /// Déplace une connexion dans un dossier
  Future<void> moveConnectionToFolder(int connectionId, int? folderId) {
    return database.updateConnectionFolder(connectionId, folderId);
  }

  /// Récupère les connexions d'un dossier
  Future<List<Connection>> getConnectionsByFolder(int? folderId) {
    return database.getConnectionsByFolder(folderId);
  }

  /// Stream des connexions d'un dossier
  Stream<List<Connection>> watchConnectionsByFolder(int? folderId) {
    return database.watchConnectionsByFolder(folderId);
  }
}

/// Provider pour les connexions groupées par dossier
final connectionsByFolderProvider = StreamProvider<Map<int?, List<Connection>>>((ref) async* {
  final database = ref.watch(databaseProvider);

  await for (final connections in database.watchAllConnections()) {
    final grouped = <int?, List<Connection>>{};

    for (final connection in connections) {
      final folderId = connection.folderId;
      grouped.putIfAbsent(folderId, () => []);
      grouped[folderId]!.add(connection);
    }

    yield grouped;
  }
});

/// Provider pour les connexions d'un dossier spécifique
final connectionsByFolderIdProvider = StreamProvider.family<List<Connection>, int?>((ref, folderId) {
  final database = ref.watch(databaseProvider);
  return database.watchConnectionsByFolder(folderId);
});
