# Alarmes & Forçages

## Vue d'ensemble

Gestion des alarmes (points en état d'erreur) et des forçages (override) de valeurs via la priority array BACnet. Permet de surveiller les états anormaux et de contrôler manuellement les points.

## Fichiers concernés

### Écrans
- `lib/presentation/screens/alarms/alarms_screen.dart` - Liste des alarmes
- `lib/presentation/screens/overrides/overrides_screen.dart` - Liste des forçages

### Providers
- `lib/application/providers/alarms_provider.dart` - Filtrage des alarmes
- `lib/application/providers/points_provider.dart` - Données des points

### Modèles
- `lib/domain/models/bacnet_object.dart` - BacnetObject avec inAlarm, OverrideInfo

## Classes/Providers clés

### AlarmsScreen
- **Fichier** : `alarms_screen.dart`
- **Rôle** : Affiche les points actuellement en alarme
- **Features** :
  - Liste des points avec `inAlarm = true`
  - Type d'alarme (fault, alarm, overridden, out-of-service)
  - Navigation vers détail du point
  - Rafraîchissement automatique

### OverridesScreen
- **Fichier** : `overrides_screen.dart`
- **Rôle** : Affiche les points actuellement forcés
- **Features** :
  - Liste des points avec priority array non vide
  - Niveau de priorité du forçage
  - Valeur forcée
  - Bouton pour libérer le forçage

### alarmsProvider
- **Fichier** : `alarms_provider.dart`
- **Type** : `StateNotifierProvider<AlarmsNotifier, AlarmsState>`
- **State** :
  ```dart
  class AlarmsState {
    final List<BacnetObject> alarms;
    final bool isLoading;
    final String? error;
  }
  ```
- **Méthodes** :
  - `loadAlarms()` - Charge et filtre les points en alarme
  - `refresh()` - Recharge les données

## Flux de données

### Chargement des alarmes

```
AlarmsScreen
        │
        │ watches alarmsProvider
        ▼
AlarmsNotifier.loadAlarms()
        │
        │ ref.read(allObjectsProvider.future)
        ▼
List<BacnetObject> allPoints
        │
        │ filter: point.inAlarm == true
        ▼
List<BacnetObject> alarmedPoints
        │
        ▼
ListView → AlarmListTile
```

### Chargement des forçages

```
OverridesScreen
        │
        │ watches pointsProvider
        ▼
PointsState.allPoints
        │
        │ filter: point.isOverridden == true
        ▼
List<BacnetObject> overriddenPoints
        │
        ▼
ListView → OverrideListTile
```

### Forçage d'un point

```
PointDetailScreen
        │
        │ tap "Forcer valeur"
        ▼
Dialog: entrer valeur + priorité
        │
        ▼
ApiService.writeProperty(
  objectType: point.type.apiName,
  instance: point.instance,
  property: 'present-value',
  value: newValue,
  priority: 8,  // ou autre priorité choisie
)
        │
        ▼
Refresh → UI update
```

### Libération d'un forçage

```
OverridesScreen (ou PointDetailScreen)
        │
        │ tap "Libérer"
        ▼
ApiService.writeProperty(
  objectType: point.type.apiName,
  instance: point.instance,
  property: 'present-value',
  value: null,  // Relinquish
  priority: overridePriority,  // Même priorité que le forçage
)
        │
        ▼
Refresh → Point revient à valeur normale
```

## Patterns importants

### Détection d'alarme

Un point est en alarme si l'un des status-flags est actif :

```dart
// Dans BacnetObject
bool get inAlarm {
  if (statusFlags == null) return false;

  // Status flags BACnet (bit field)
  // Bit 0: IN_ALARM
  // Bit 1: FAULT
  // Bit 2: OVERRIDDEN
  // Bit 3: OUT_OF_SERVICE

  return (statusFlags! & 0x03) != 0;  // IN_ALARM ou FAULT
}
```

### Priority Array BACnet

La priority array a 16 niveaux, du plus prioritaire (1) au moins prioritaire (16) :

| Priorité | Usage standard |
|----------|----------------|
| 1 | Manual Life Safety |
| 2 | Automatic Life Safety |
| 3 | (disponible) |
| 4 | (disponible) |
| 5 | Critical Equipment Control |
| 6 | Minimum On/Off |
| 7 | (disponible) |
| 8 | Manual Operator |
| 9-14 | (disponibles) |
| 15 | Scheduling |
| 16 | Relinquish Default |

### Structure OverrideInfo

```dart
class OverrideInfo {
  final int priority;       // 1-16
  final dynamic value;      // Valeur forcée
  final String? source;     // 'manual', 'schedule', 'bms', etc.
}
```

### Parsing Priority Array

#### API V1
```json
{
  "priority-array": {
    "1": {"null": null},
    "8": {"real": 21.5},
    "16": {"null": null}
  }
}
```

#### API V2
```json
{
  "priority-array": [
    {"priority": 1, "value": null},
    {"priority": 8, "value": 21.5},
    {"priority": 16, "value": null}
  ]
}
```

#### Extraction de l'override actif

```dart
OverrideInfo? _parseOverride(Map<String, dynamic> priorityArray) {
  // Trouver la plus haute priorité non-null
  for (int p = 1; p <= 16; p++) {
    final entry = priorityArray['$p'];
    if (entry != null && entry['null'] == null) {
      // Valeur non-null trouvée
      return OverrideInfo(
        priority: p,
        value: _extractValue(entry),
      );
    }
  }
  return null;  // Pas de forçage
}
```

### Relinquish (libération)

Pour libérer un forçage, on écrit `null` à la même priorité :

```dart
await apiService.writeProperty(
  objectType: 'analog-value',
  instance: 1,
  property: 'present-value',
  value: null,  // null = relinquish
  priority: existingOverride.priority,
);
```

### Types d'états anormaux

| État | Description | Visuel |
|------|-------------|--------|
| `inAlarm` | Seuil dépassé | Rouge + icône alarme |
| `fault` | Erreur de communication | Orange + icône erreur |
| `overridden` | Forcé par une priorité | Bleu + badge priorité |
| `outOfService` | Point désactivé | Gris + barré |

### Rafraîchissement

Les écrans alarmes/overrides se rafraîchissent :
- Au chargement initial
- Sur pull-to-refresh
- Périodiquement selon `pollingInterval` (settings)

```dart
// Dans AlarmsScreen
Timer.periodic(Duration(seconds: pollingInterval), (_) {
  ref.read(alarmsProvider.notifier).refresh();
});
```

### Filtres dans AlarmsScreen

Options de filtrage possibles :
- Par type d'alarme (alarm, fault, overridden)
- Par type de point (AI, AO, AV, etc.)
- Par gravité (si disponible dans les propriétés)

```dart
// Exemple de filtrage
final filteredAlarms = alarms.where((p) {
  if (showOnlyFaults && !p.hasFault) return false;
  if (typeFilter != null && p.type != typeFilter) return false;
  return true;
}).toList();
```
