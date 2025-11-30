import 'package:drift/drift.dart';
import 'connections_table.dart';

/// Table pour cache des propriétés statiques des points BACnet
/// Ces données ne changent pratiquement jamais (nom, unité, description)
class CachedPoints extends Table {
  /// Connexion associée
  IntColumn get connectionId => integer().references(Connections, #id)();

  /// Référence du point (ex: "AV:1", "BI:5")
  TextColumn get pointRef => text().withLength(min: 1, max: 50)();

  /// Type d'objet BACnet (ex: "analog-value")
  TextColumn get objectType => text().withLength(min: 1, max: 50)();

  /// Instance du point
  IntColumn get instance => integer()();

  /// Nom de l'objet
  TextColumn get objectName => text()();

  /// Unité (ex: "°C", "%")
  TextColumn get units => text().nullable()();

  /// Description
  TextColumn get description => text().nullable()();

  /// Texte pour valeur active (binaires)
  TextColumn get activeText => text().nullable()();

  /// Texte pour valeur inactive (binaires)
  TextColumn get inactiveText => text().nullable()();

  /// Date de mise en cache
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {connectionId, pointRef};
}

/// Table pour cache des infos de l'appareil
class CachedDeviceInfo extends Table {
  /// Connexion associée (clé primaire)
  IntColumn get connectionId => integer().references(Connections, #id)();

  /// Nom de l'objet device
  TextColumn get objectName => text()();

  /// Nom du modèle
  TextColumn get modelName => text().nullable()();

  /// Type de modèle
  TextColumn get modelType => text().nullable()();

  /// Version du firmware
  TextColumn get softwareVersion => text().nullable()();

  /// Host ID
  TextColumn get hostId => text().nullable()();

  /// Host Name
  TextColumn get hostName => text().nullable()();

  /// Nom du vendeur
  TextColumn get vendorName => text().nullable()();

  /// Description
  TextColumn get description => text().nullable()();

  /// Localisation
  TextColumn get location => text().nullable()();

  /// Instance device
  IntColumn get deviceInstance => integer().nullable()();

  /// Date de mise en cache
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {connectionId};
}

/// Table pour cache du mapping Trend Log
/// Associe chaque point à son trend log (si existant)
class CachedTrendLogMapping extends Table {
  /// Connexion associée (clé primaire)
  IntColumn get connectionId => integer().references(Connections, #id)();

  /// Mapping JSON sérialisé (Map<String, int> : pointKey -> trendLogInstance)
  TextColumn get mappingJson => text()();

  /// Nombre d'entrées dans le mapping
  IntColumn get entryCount => integer().withDefault(const Constant(0))();

  /// Date de mise en cache
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {connectionId};
}

/// Table pour cache du résumé des objets (compteurs par type)
class CachedObjectsSummary extends Table {
  /// Connexion associée (clé primaire)
  IntColumn get connectionId => integer().references(Connections, #id)();

  /// Compteurs par type
  IntColumn get analogInputs => integer().withDefault(const Constant(0))();
  IntColumn get analogOutputs => integer().withDefault(const Constant(0))();
  IntColumn get analogValues => integer().withDefault(const Constant(0))();
  IntColumn get binaryInputs => integer().withDefault(const Constant(0))();
  IntColumn get binaryOutputs => integer().withDefault(const Constant(0))();
  IntColumn get binaryValues => integer().withDefault(const Constant(0))();
  IntColumn get multiStateInputs => integer().withDefault(const Constant(0))();
  IntColumn get multiStateOutputs => integer().withDefault(const Constant(0))();
  IntColumn get multiStateValues => integer().withDefault(const Constant(0))();
  IntColumn get schedules => integer().withDefault(const Constant(0))();

  /// Date de mise en cache
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {connectionId};
}
