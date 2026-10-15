import 'package:drift/drift.dart';
import 'connections_table.dart';

/// Types de widgets disponibles dans le dashboard
enum DashboardWidgetType {
  /// Graphique d'un seul trend log
  singleTrendChart,

  /// Graphique multi-courbes (comparaison de plusieurs trend logs)
  multiCurveChart,

  /// Carte de statistiques rapides (valeur actuelle, min/max/avg)
  statsCard,
}

/// Convertisseur pour stocker DashboardWidgetType en texte
class DashboardWidgetTypeConverter extends TypeConverter<DashboardWidgetType, String> {
  const DashboardWidgetTypeConverter();

  @override
  DashboardWidgetType fromSql(String fromDb) {
    return DashboardWidgetType.values.firstWhere(
      (e) => e.name == fromDb,
      orElse: () => DashboardWidgetType.singleTrendChart,
    );
  }

  @override
  String toSql(DashboardWidgetType value) => value.name;
}

/// Table des configurations de dashboard
@TableIndex(name: 'idx_dashboards_connection_id', columns: {#connectionId})
class Dashboards extends Table {
  /// Identifiant unique
  IntColumn get id => integer().autoIncrement()();

  /// Nom du dashboard (donné par l'utilisateur)
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Connexion associée (null = dashboard global)
  IntColumn get connectionId => integer().nullable().references(Connections, #id)();

  /// Nombre de colonnes de la grille (2-4)
  IntColumn get columns => integer().withDefault(const Constant(2))();

  /// Nombre de lignes de la grille (2-4)
  IntColumn get rows => integer().withDefault(const Constant(2))();

  /// Ordre de tri pour l'affichage
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Date de création
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Date de dernière modification
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Table des widgets du dashboard
@TableIndex(name: 'idx_dashboard_widgets_dashboard_id', columns: {#dashboardId})
class DashboardWidgets extends Table {
  /// Identifiant unique
  IntColumn get id => integer().autoIncrement()();

  /// Dashboard parent
  IntColumn get dashboardId => integer().references(Dashboards, #id)();

  /// Position dans la grille (index 0-based)
  IntColumn get position => integer()();

  /// Type de widget
  TextColumn get widgetType => text().map(const DashboardWidgetTypeConverter())();

  /// Configuration JSON du widget
  ///
  /// Pour singleTrendChart:
  /// {
  ///   "trendLogInstance": 300123,
  ///   "pointName": "Temperature",
  ///   "units": "°C",
  ///   "colorTheme": "blue"
  /// }
  ///
  /// Pour multiCurveChart:
  /// {
  ///   "trendLogInstances": [300123, 300124, 300125],
  ///   "curveNames": {"300123": "Temp 1", "300124": "Temp 2"},
  ///   "curveUnits": {"300123": "°C", "300124": "°C"}
  /// }
  ///
  /// Pour statsCard:
  /// {
  ///   "trendLogInstance": 300123,
  ///   "pointName": "Zone Temperature",
  ///   "units": "°C",
  ///   "showCurrent": true,
  ///   "showMin": true,
  ///   "showMax": true,
  ///   "showAvg": true
  /// }
  TextColumn get configJson => text().nullable()();

  /// Date de création
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
