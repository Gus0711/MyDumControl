import 'package:drift/drift.dart';
import 'connections_table.dart';

/// Forçages posés depuis l'application : heure du forçage, et échéance pour
/// les forçages temporisés (relâchés automatiquement par l'application).
///
/// BACnet ne mémorise ni l'auteur ni l'heure d'un forçage : seuls ceux posés
/// par l'application sont connus ici. Une ligne est supprimée quand le point
/// est relâché (depuis l'app, ou constaté relâché lors d'un rechargement).
class AppOverrides extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Connexion (automate) du point forcé
  IntColumn get connectionId => integer().references(Connections, #id)();

  /// Type d'objet BACnet ([BacnetObjectType.apiName], ex: "binary-value")
  TextColumn get objectType => text().withLength(min: 1, max: 50)();

  /// Instance de l'objet
  IntColumn get objectInstance => integer()();

  /// Nature du forçage : [AppOverrideKind.priority] (priority-array) ou
  /// [AppOverrideKind.outOfService] (entrée forcée)
  TextColumn get kind => text().withLength(min: 1, max: 20)();

  /// Priorité de commande (forçage priority-array uniquement)
  IntColumn get priority => integer().nullable()();

  /// Valeur forcée (JSON), pour l'affichage
  TextColumn get valueJson => text().nullable()();

  /// Heure du forçage
  DateTimeColumn get forcedAt => dateTime()();

  /// Relâchement automatique à cette heure (null = forçage permanent)
  DateTimeColumn get expiresAt => dateTime().nullable()();

  /// Dernier échec du relâchement automatique (affiché à l'utilisateur)
  TextColumn get lastError => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {connectionId, objectType, objectInstance},
      ];
}

/// Valeurs de [AppOverrides.kind]
abstract final class AppOverrideKind {
  static const priority = 'priority';
  static const outOfService = 'outOfService';
}
