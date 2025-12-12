# Navigation Points BACnet

## Vue d'ensemble

Parcours et recherche des points BACnet (objets) du contrôleur. Permet de filtrer par type, catégorie, et de rechercher par nom. Affiche les valeurs en temps réel avec possibilité de forçage.

## Fichiers concernés

### Écrans
- `lib/presentation/screens/points/points_screen.dart` - Liste des points
- `lib/presentation/screens/points/point_detail_screen.dart` - Détail d'un point

### Providers
- `lib/application/providers/points_provider.dart` - Chargement et filtrage des points

### Modèles
- `lib/domain/models/bacnet_object.dart` - Modèle BacnetObject

## Classes/Providers clés

### PointsScreen
- **Fichier** : `points_screen.dart`
- **Rôle** : Affiche la liste des points avec filtres et recherche
- **Features** :
  - Barre de recherche
  - Filtres par catégorie (Inputs, Outputs, Values, Others)
  - Filtres par sous-type (Analog, Binary, MultiState)
  - Tri (nom, type, valeur, favoris d'abord)
  - Pull-to-refresh
  - Indicateur favori et alarme

### PointDetailScreen
- **Fichier** : `point_detail_screen.dart`
- **Paramètres** : `pointId` (format "type:instance", ex: "AV:1")
- **Rôle** : Affiche le détail d'un point
- **Features** :
  - Valeur actuelle avec unités
  - Priority array (16 niveaux)
  - Forçage/libération de valeur
  - Historique (si trend log associé)
  - Propriétés BACnet complètes
  - Bouton favori

### pointsProvider
- **Fichier** : `points_provider.dart`
- **Type** : `StateNotifierProvider<PointsNotifier, PointsState>`
- **State** :
  ```dart
  class PointsState {
    final List<BacnetObject> allPoints;
    final List<BacnetObject> filteredPoints;
    final PointCategory category;
    final SubTypeFilter subTypeFilter;
    final PointSortOption sortOption;
    final String searchQuery;
    final bool isLoading;
    final String? error;
  }
  ```
- **Méthodes** :
  - `loadPoints()` - Charge tous les points depuis l'API
  - `setCategory(category)` - Filtre par catégorie
  - `setSubTypeFilter(filter)` - Filtre par sous-type
  - `setSortOption(option)` - Change le tri
  - `setSearch(query)` - Recherche textuelle
  - `refresh()` - Recharge depuis l'API

### pointDetailProvider
- **Fichier** : `points_provider.dart`
- **Type** : `FutureProvider.family<BacnetObject?, String>`
- **Rôle** : Charge le détail complet d'un point

## Flux de données

```
PointsScreen
     │
     │ watches pointsProvider
     ▼
PointsState.filteredPoints
     │
     │ applies filters (category, subType, search, sort)
     ▼
ListView.builder → PointListTile
     │
     │ onTap
     ▼
GoRouter.go('/points/$pointId')
     │
     ▼
PointDetailScreen
     │
     │ watches pointDetailProvider(pointId)
     ▼
BacnetObject (avec toutes les propriétés)
```

## Patterns importants

### Format pointId

Le pointId utilise le format `type:instance` :
- `AI:1` → Analog Input instance 1
- `BV:42` → Binary Value instance 42
- `schedule:5` → Schedule instance 5

### Parsing selon version API

Le provider détecte la version API et utilise le parser approprié :

```dart
// Dans PointsNotifier.loadPoints()
final objects = apiVersion == 'v2'
    ? response.map((j) => BacnetObject.fromApiV2(j)).toList()
    : response.map((j) => BacnetObject.fromApiV1(j)).toList();
```

### Filtrage local

Le filtrage se fait côté client sur les données chargées :

```dart
List<BacnetObject> _applyFilters(List<BacnetObject> points) {
  var result = points;

  // Filtre catégorie
  if (category != PointCategory.all) {
    result = result.where((p) => p.type.category == category).toList();
  }

  // Filtre sous-type
  if (subTypeFilter != SubTypeFilter.all) {
    result = result.where((p) => p.type.subType == subTypeFilter).toList();
  }

  // Recherche
  if (searchQuery.isNotEmpty) {
    result = result.where((p) =>
        p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
        p.description?.toLowerCase().contains(searchQuery.toLowerCase()) == true
    ).toList();
  }

  // Tri
  result.sort(_comparator(sortOption));

  return result;
}
```

### Priority Array

La priority array BACnet a 16 niveaux (1 = plus haute priorité, 16 = plus basse) :

| Priorité | Usage typique |
|----------|---------------|
| 1 | Manual Life Safety |
| 2 | Automatic Life Safety |
| 8 | Manual Operator |
| 16 | Default / Relinquish |

Pour forcer une valeur :
```dart
await apiService.writeProperty(
  objectType: 'analog-value',
  instance: 1,
  property: 'present-value',
  value: 21.5,
  priority: 8,  // Manual Operator
);
```

Pour libérer un forçage :
```dart
await apiService.writeProperty(
  objectType: 'analog-value',
  instance: 1,
  property: 'present-value',
  value: null,  // Relinquish
  priority: 8,
);
```

### Affichage des valeurs

```dart
// Dans BacnetObject
String get displayValue {
  if (presentValue == null) return '-';

  switch (type.valueType) {
    case ValueType.analog:
      return '${presentValue.toStringAsFixed(1)} ${units ?? ''}';
    case ValueType.binary:
      return presentValue == true || presentValue == 1 ? 'ON' : 'OFF';
    case ValueType.multiState:
      return stateText ?? presentValue.toString();
  }
}
```

### Indicateurs visuels

- **Favori** : Étoile jaune
- **Super-favori** : Étoile dorée avec contour
- **Alarme** : Icône rouge clignotante
- **Forcé** : Badge avec niveau de priorité
