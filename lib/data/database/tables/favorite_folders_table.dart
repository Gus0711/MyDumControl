import 'package:drift/drift.dart';
import 'connections_table.dart';

/// Table des dossiers de favoris
/// Chaque connexion (automate) a ses propres dossiers
class FavoriteFolders extends Table {
  /// Identifiant unique
  IntColumn get id => integer().autoIncrement()();

  /// Connexion associée (chaque automate a ses propres dossiers)
  IntColumn get connectionId => integer().references(Connections, #id)();

  /// Nom du dossier (ex: "Chaudière", "Circuit 1")
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Couleur du dossier (format hex: "#FF5722")
  TextColumn get color => text().withLength(min: 7, max: 7).withDefault(const Constant('#2196F3'))();

  /// Icône du dossier (nom de l'icône Material: "local_fire_department", "water_drop", etc.)
  TextColumn get icon => text().withLength(min: 1, max: 50).withDefault(const Constant('folder'))();

  /// Ordre de tri (pour réorganiser les dossiers)
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Date de création
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Contrainte d'unicité : un nom de dossier unique par connexion
  @override
  List<Set<Column>> get uniqueKeys => [
        {connectionId, name},
      ];
}
