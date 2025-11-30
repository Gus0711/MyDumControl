import 'package:drift/drift.dart';
import 'connections_table.dart';

/// Table des points favoris
class Favorites extends Table {
  /// Identifiant unique
  IntColumn get id => integer().autoIncrement()();

  /// Connexion associée (chaque contrôleur a ses propres favoris)
  IntColumn get connectionId => integer().references(Connections, #id)();

  /// Référence du point BACnet (ex: "AV:1", "BI:5")
  TextColumn get pointRef => text().withLength(min: 1, max: 50)();

  /// Nom du point (pour affichage même offline)
  TextColumn get pointName => text().withLength(min: 1, max: 255)();

  /// Description du point (optionnel)
  TextColumn get pointDescription => text().nullable()();

  /// Type d'objet BACnet (ex: "analog-value", "binary-input")
  TextColumn get objectType => text().withLength(min: 1, max: 50)();

  /// Ordre de tri (pour réorganiser les favoris)
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Date d'ajout aux favoris
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Contrainte d'unicité : un point ne peut être favori qu'une fois par connexion
  @override
  List<Set<Column>> get uniqueKeys => [
        {connectionId, pointRef},
      ];
}
