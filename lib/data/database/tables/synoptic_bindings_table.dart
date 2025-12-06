import 'package:drift/drift.dart';
import 'synoptics_table.dart';

/// Types de liaison SVG ↔ Point BACnet
enum BindingType {
  /// Affiche une valeur numérique/texte (température, %, etc.)
  value,

  /// Change la couleur selon un état (ON/OFF, alarme, etc.)
  color,

  /// Active/désactive une animation SVG (rotation, mouvement)
  animation,
}

/// Convertisseur pour stocker BindingType en texte
class BindingTypeConverter extends TypeConverter<BindingType, String> {
  const BindingTypeConverter();

  @override
  BindingType fromSql(String fromDb) {
    return BindingType.values.firstWhere(
      (e) => e.name == fromDb,
      orElse: () => BindingType.value,
    );
  }

  @override
  String toSql(BindingType value) => value.name;
}

/// Table des liaisons entre éléments SVG et points BACnet
class SynopticBindings extends Table {
  /// Identifiant unique
  IntColumn get id => integer().autoIncrement()();

  /// Synoptique parent
  IntColumn get synopticId => integer().references(Synoptics, #id)();

  /// ID de l'élément dans le SVG (ex: "val_temp_depart", "ind_pompe_etat")
  TextColumn get svgElementId => text().withLength(min: 1, max: 100)();

  /// Référence du point BACnet (ex: "AV:1", "BI:5")
  TextColumn get pointRef => text().withLength(min: 1, max: 50)();

  /// Type de liaison
  TextColumn get bindingType => text().map(const BindingTypeConverter())();

  /// Configuration JSON (format, couleurs ON/OFF, seuils, etc.)
  /// Exemple pour value: {"format": "{value}°C", "decimals": 1}
  /// Exemple pour color: {"onColor": "#27ae60", "offColor": "#e74c3c", "threshold": 0.5}
  /// Exemple pour animation: {"property": "visibility", "onValue": "visible", "offValue": "hidden"}
  TextColumn get configJson => text().nullable()();

  /// Nom du point (pour affichage même offline)
  TextColumn get pointName => text().nullable()();

  /// Date de création
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Contrainte d'unicité : un élément SVG ne peut avoir qu'une liaison par synoptique
  @override
  List<Set<Column>> get uniqueKeys => [
        {synopticId, svgElementId},
      ];
}
