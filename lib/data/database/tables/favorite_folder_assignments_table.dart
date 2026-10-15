import 'package:drift/drift.dart';
import 'favorites_table.dart';
import 'favorite_folders_table.dart';

/// Table de liaison entre favoris et dossiers (many-to-many)
/// Permet à un favori d'appartenir à plusieurs dossiers
@TableIndex(name: 'idx_favorite_folder_assignments_folder_id', columns: {#folderId})
class FavoriteFolderAssignments extends Table {
  /// Identifiant unique
  IntColumn get id => integer().autoIncrement()();

  /// Favori concerné
  IntColumn get favoriteId => integer().references(Favorites, #id)();

  /// Dossier concerné
  IntColumn get folderId => integer().references(FavoriteFolders, #id)();

  /// Date d'assignation
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Contrainte d'unicité : un favori ne peut être assigné qu'une fois à un dossier
  @override
  List<Set<Column>> get uniqueKeys => [
        {favoriteId, folderId},
      ];
}
