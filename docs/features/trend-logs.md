# Trend Logs (Historiques)

## Vue d'ensemble

Affichage des données historiques des points BACnet via les trend logs. Permet de visualiser l'évolution d'une valeur dans le temps et de comparer plusieurs courbes sur un même graphique (multi-courbes).

## Fichiers concernés

### Widgets
- `lib/presentation/widgets/trend_log_viewer.dart` - Graphique simple
- `lib/presentation/widgets/multi_curve_chart.dart` - Graphique multi-courbes
- `lib/presentation/widgets/curve_selection_dialog.dart` - Sélection des courbes

### Providers
- `lib/application/providers/trend_log_provider.dart` - Chargement des données
- `lib/application/providers/multi_curve_provider.dart` - Multi-courbes

### Modèles
- `lib/domain/models/trend_log.dart` - TrendLog, TrendLogRecord
- `lib/domain/models/multi_curve_chart.dart` - Configuration multi-courbes

## Classes/Providers clés

### TrendLogViewer (Widget)
- **Fichier** : `trend_log_viewer.dart`
- **Paramètres** :
  - `trendLogInstance` - Instance du trend log
  - `pointName` - Nom pour affichage
  - `units` - Unités (optionnel)
- **Rôle** : Affiche un graphique d'historique avec sélection de période
- **Features** :
  - Sélection date début/fin
  - Zoom et pan sur le graphique
  - Affichage min/max/moyenne
  - Export des données

### MultiCurveChart (Widget)
- **Fichier** : `multi_curve_chart.dart`
- **Paramètres** :
  - `chartId` - ID unique pour le provider
  - `trendLogInstances` - Liste des instances (2-8)
  - `title` - Titre du graphique
  - `curveNames` - Map instance → nom
  - `curveUnits` - Map instance → unités
  - `showHeader` - Afficher le header (défaut: true)
- **Rôle** : Compare plusieurs trend logs sur un même graphique
- **Features** :
  - Légende avec couleurs
  - Échelles Y multiples si unités différentes
  - Synchronisation des périodes

### trendLogMappingProvider
- **Fichier** : `trend_log_provider.dart`
- **Type** : `FutureProvider<Map<String, int>>`
- **Rôle** : Mapping `"objectType:instance"` → `trendLogInstance`
- **Exemple** : `{"analog-value:1": 5, "analog-input:3": 12}`

### trendLogViewerProvider
- **Fichier** : `trend_log_provider.dart`
- **Type** : `StateNotifierProvider.family<TrendLogViewerNotifier, TrendLogViewerState, String>`
- **Paramètre family** : `trendLogInstance` (string)
- **State** :
  ```dart
  class TrendLogViewerState {
    final List<TrendLogRecord> records;
    final DateTime startDate;
    final DateTime endDate;
    final bool isLoading;
    final String? error;
  }
  ```
- **Méthodes** :
  - `loadData(startDate, endDate)` - Charge les données
  - `setDateRange(start, end)` - Change la période

### multiCurveViewerProvider
- **Fichier** : `multi_curve_provider.dart`
- **Type** : `StateNotifierProvider.family<MultiCurveViewerNotifier, MultiCurveViewerState, String>`
- **Paramètre family** : `chartId`
- **State** :
  ```dart
  class MultiCurveViewerState {
    final Map<int, List<TrendLogRecord>> data; // instance → records
    final DateTime startDate;
    final DateTime endDate;
    final bool isLoading;
    final String? error;
  }
  ```
- **Méthodes** :
  - `initialize(List<int> instances)` - Configure les courbes
  - `loadData(startDate, endDate)` - Charge toutes les données
  - `setDateRange(start, end)` - Change la période

## Flux de données

### Affichage simple (TrendLogViewer)

```
PointDetailScreen
        │
        │ Le point a un trend log associé ?
        │ check trendLogMappingProvider
        ▼
trendLogMapping['analog-value:1'] → 5
        │
        │ render TrendLogViewer(trendLogInstance: 5)
        ▼
TrendLogViewer
        │
        │ initState → ref.read(trendLogViewerProvider('5').notifier).loadData()
        ▼
ApiService.getTrendLogBuffer(instance: 5, start, end)
        │
        ├── GET /api/rest/v2/services/bacnet/local/objects/trend-log/5/log-buffer?start=...&end=...
        ▼
JSON response
        │
        ▼
TrendLogBufferParser.parse(response, apiVersion)
        │
        ▼
List<TrendLogRecord>
        │
        ▼
fl_chart LineChart
```

### Affichage multi-courbes

```
DashboardScreen (ou autre)
        │
        │ render MultiCurveChart(
        │   chartId: 'chart-1',
        │   trendLogInstances: [5, 12, 8],
        │ )
        ▼
MultiCurveChart.initState()
        │
        │ ref.read(multiCurveViewerProvider('chart-1').notifier)
        │     .initialize([5, 12, 8])
        ▼
Pour chaque instance :
        │
        ├── trendLogViewerProvider('5').loadData()
        ├── trendLogViewerProvider('12').loadData()
        └── trendLogViewerProvider('8').loadData()
        │
        ▼
Combine les résultats dans MultiCurveViewerState.data
        │
        ▼
fl_chart LineChart avec plusieurs LineChartBarData
```

## Patterns importants

### Mapping point → trend log

Le mapping est découvert via l'API ou calculé depuis la propriété `log-device-object-property` des trend logs :

```dart
// Exemple de log-device-object-property
"analog-value,1.present-value"
// → Clé dans le mapping : "analog-value:1"
// → Valeur : instance du trend log
```

Le mapping est caché pour éviter de le recalculer :
```dart
// Dans le provider
final cached = await db.getCachedTrendLogMapping(connectionId);
if (cached != null && !isExpired) return cached;

// Sinon, découvrir
final mapping = await discoverTrendLogMapping();
await db.cacheTrendLogMapping(connectionId, mapping);
```

### Structure TrendLogRecord

```dart
class TrendLogRecord {
  final DateTime timestamp;
  final TrendRecordType type;
  final dynamic value;      // double, bool, int selon type
  final int? statusFlags;   // Flags BACnet
}
```

### Types d'enregistrements

| Type | Valeur Dart | Usage |
|------|-------------|-------|
| `real` | `double` | Valeurs analogiques |
| `boolean` | `bool` | Valeurs binaires |
| `enumerated` | `int` | Multi-états |
| `unsigned` | `int` | Compteurs |
| `null` | `null` | Pas de donnée |
| `failure` | - | Erreur de lecture |
| `timeChange` | - | Changement d'heure système |

### Couleurs des courbes

Les couleurs sont définies dans `multi_curve_provider.dart` :

```dart
final curveColorThemes = [
  Colors.blue,
  Colors.red,
  Colors.green,
  Colors.orange,
  Colors.purple,
  Colors.teal,
  Colors.pink,
  Colors.amber,
];
```

### Paramètre showHeader

Pour les widgets dans les dashboards, `showHeader: false` évite la duplication du titre :

```dart
// Dans un dashboard widget
MultiCurveChart(
  chartId: 'widget-$widgetId',
  trendLogInstances: config.instances,
  showHeader: false,  // Le titre est dans la barre du widget
)
```

### Sélection de période

Périodes prédéfinies disponibles :
- Dernière heure
- 6 dernières heures
- 24 dernières heures
- 7 derniers jours
- 30 derniers jours
- Personnalisée (date picker)
