# Dashboards

## Vue d'ensemble

Tableaux de bord personnalisables avec widgets affichant des données de trend logs. Supporte les graphiques simples, multi-courbes et cartes de statistiques.

## Fichiers concernés

### Écrans
- `lib/presentation/screens/dashboard/dashboard_list_screen.dart` - Liste des dashboards
- `lib/presentation/screens/dashboard/dashboard_screen.dart` - Vue d'un dashboard
- `lib/presentation/screens/dashboard/widgets/dashboard_widget_card.dart` - Carte widget

### Widgets
- `lib/presentation/widgets/multi_curve_chart.dart` - Graphique multi-courbes
- `lib/presentation/widgets/curve_selection_dialog.dart` - Sélection des trend logs

### Providers
- `lib/application/providers/dashboard_provider.dart` - State management + configs
- `lib/application/providers/multi_curve_provider.dart` - Données multi-courbes

### Database
- `lib/data/database/tables/dashboard_tables.dart` - Tables Dashboards, DashboardWidgets

## Classes/Providers clés

### DashboardListScreen
- **Fichier** : `dashboard_list_screen.dart`
- **Rôle** : Liste et création de dashboards
- **Features** :
  - Liste des dashboards existants
  - Création de nouveau dashboard
  - Renommer/supprimer dashboard
  - Configuration grille (colonnes × lignes)

### DashboardScreen
- **Fichier** : `dashboard_screen.dart`
- **Paramètres** : `dashboardId`
- **Rôle** : Affiche les widgets du dashboard
- **Features** :
  - Grille de widgets
  - Ajout de widget à un slot vide
  - Édition/suppression de widget
  - Titre éditable

### DashboardWidgetCard
- **Fichier** : `dashboard_widget_card.dart`
- **Rôle** : Enveloppe chaque widget avec titre et actions
- **Features** :
  - Barre de titre avec nom
  - Bouton éditer
  - Bouton supprimer
  - Contenu selon widgetType

### dashboardsProvider
- **Fichier** : `dashboard_provider.dart`
- **Type** : `StreamProvider<List<Dashboard>>`
- **Rôle** : Stream des dashboards pour la connexion active

### dashboardWidgetsProvider
- **Fichier** : `dashboard_provider.dart`
- **Type** : `StreamProvider.family<List<DashboardWidget>, int>`
- **Rôle** : Widgets d'un dashboard par ID

## Flux de données

### Création d'un dashboard

```
DashboardListScreen
        │
        │ tap "+" button
        ▼
Dialog: nom + grille (2×2, 3×2, etc.)
        │
        ▼
db.createDashboard(
  name: 'Mon Dashboard',
  connectionId: connectionId,
  columns: 2,
  rows: 2,
)
        │
        ▼
Stream update → UI rebuild
        │
        ▼
GoRouter.go('/dashboards/$newId')
```

### Ajout d'un widget

```
DashboardScreen
        │
        │ tap sur slot vide
        ▼
Dialog: choisir type de widget
        │
        ├── singleTrendChart
        ├── multiCurveChart
        └── statsCard
        │
        ▼
CurveSelectionDialog (pour sélectionner les trend logs)
        │
        ▼
db.addDashboardWidget(
  dashboardId: dashboardId,
  position: slotIndex,
  widgetType: DashboardWidgetType.multiCurveChart,
  configJson: config.toJson(),
)
        │
        ▼
Stream update → Widget rebuild
```

## Types de widgets

### DashboardWidgetType (enum)

| Type | Description |
|------|-------------|
| `singleTrendChart` | Graphique d'un seul trend log |
| `multiCurveChart` | Graphique comparant 2-8 trend logs |
| `statsCard` | Carte avec min/max/moyenne |

### Configurations

#### SingleChartWidgetConfig

```dart
class SingleChartWidgetConfig {
  final int trendLogInstance;
  final String? title;
  final String? pointName;
  final String? units;
  final String? colorTheme;

  String toJson();
  static SingleChartWidgetConfig fromJson(String json);

  String get displayTitle => title ?? pointName ?? 'Trend Log $trendLogInstance';
}
```

#### MultiCurveWidgetConfig

```dart
class MultiCurveWidgetConfig {
  final List<int> trendLogInstances;
  final String? title;
  final Map<int, String> curveNames;  // instance → nom
  final Map<int, String> curveUnits;  // instance → unités

  String toJson();
  static MultiCurveWidgetConfig fromJson(String json);

  String get displayTitle => title ?? 'Multi-Curve Chart';
}
```

#### StatsWidgetConfig

```dart
class StatsWidgetConfig {
  final int trendLogInstance;
  final String? title;
  final String? pointName;
  final String? units;
  final bool showMin;
  final bool showMax;
  final bool showAvg;

  String toJson();
  static StatsWidgetConfig fromJson(String json);
}
```

## Patterns importants

### Schéma base de données

```sql
-- Table Dashboards
CREATE TABLE dashboards (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  connection_id INTEGER,
  columns INTEGER DEFAULT 2,
  rows INTEGER DEFAULT 2,
  sort_order INTEGER DEFAULT 0,
  created_at DATETIME,
  updated_at DATETIME
);

-- Table DashboardWidgets
CREATE TABLE dashboard_widgets (
  id INTEGER PRIMARY KEY,
  dashboard_id INTEGER NOT NULL REFERENCES dashboards(id),
  position INTEGER NOT NULL,  -- Index dans la grille
  widget_type TEXT NOT NULL,  -- 'singleTrendChart', 'multiCurveChart', 'statsCard'
  config_json TEXT,           -- Configuration sérialisée
  created_at DATETIME
);
```

### Position dans la grille

La position est un index linéaire :
```
Grille 2×2 :
┌───┬───┐
│ 0 │ 1 │
├───┼───┤
│ 2 │ 3 │
└───┴───┘

Grille 3×2 :
┌───┬───┬───┐
│ 0 │ 1 │ 2 │
├───┼───┼───┤
│ 3 │ 4 │ 5 │
└───┴───┴───┘
```

### Barre de titre du widget

Le `DashboardWidgetCard` affiche une barre de titre avec le nom du widget et des actions :

```dart
class _WidgetHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Titre éditable (tap pour modifier)
        GestureDetector(
          onTap: _editTitle,
          child: Text(config.displayTitle),
        ),
        Spacer(),
        // Actions
        IconButton(icon: Icon(Icons.edit), onPressed: _editWidget),
        IconButton(icon: Icon(Icons.delete), onPressed: _deleteWidget),
      ],
    );
  }
}
```

### Lookup du nom de point

Pour trouver le nom d'un point à partir d'un trend log instance, utiliser le mapping inversé :

```dart
// Récupérer le mapping
final mapping = await ref.read(trendLogMappingProvider.future);

// Inverser pour trouver le point
final reversedMapping = mapping.map((k, v) => MapEntry(v, k));
final pointRef = reversedMapping[trendLogInstance];  // ex: "analog-value:1"

// Utiliser point.type.apiName (format "analog-value") pas .name (format "analogValue")
```

### showHeader dans MultiCurveChart

Quand le widget est dans un dashboard, on désactive le header interne pour éviter la duplication :

```dart
// Dans DashboardWidgetCard
MultiCurveChart(
  chartId: 'widget-$widgetId',
  trendLogInstances: config.trendLogInstances,
  title: config.displayTitle,
  showHeader: false,  // Important !
)
```

### Rafraîchissement des données

Les widgets se rafraîchissent automatiquement via les providers. Pour forcer un refresh :

```dart
ref.invalidate(multiCurveViewerProvider(chartId));
```
