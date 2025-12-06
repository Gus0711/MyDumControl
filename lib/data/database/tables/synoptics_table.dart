import 'package:drift/drift.dart';

/// Table des synoptiques (instances de SVG avec configuration)
class Synoptics extends Table {
  /// Identifiant unique
  IntColumn get id => integer().autoIncrement()();

  /// Nom du synoptique (donné par l'utilisateur)
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Chemin de l'asset SVG (ex: "assets/synoptics/CR_V0.1.svg")
  TextColumn get svgAssetPath => text().withLength(min: 1, max: 255)();

  /// Connexion associée (null = synoptique global réutilisable)
  IntColumn get connectionId => integer().nullable()();

  /// Description optionnelle
  TextColumn get description => text().nullable()();

  /// Ordre de tri pour l'affichage
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Date de création
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Date de dernière modification
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
