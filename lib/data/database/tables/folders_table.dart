import 'package:drift/drift.dart';

/// Table des dossiers pour organiser les connexions
class Folders extends Table {
  /// Identifiant unique
  IntColumn get id => integer().autoIncrement()();

  /// Nom du dossier
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Icône du dossier (nom de l'icône Material)
  TextColumn get icon => text().withDefault(const Constant('folder'))();

  /// Couleur du dossier (code hexadécimal)
  TextColumn get color => text().withDefault(const Constant('#2196F3'))();

  /// Ordre d'affichage
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Date de création
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
