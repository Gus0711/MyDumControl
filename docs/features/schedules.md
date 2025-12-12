# Schedules (Horaires)

## Vue d'ensemble

Gestion des schedules BACnet qui permettent de programmer des valeurs selon un planning hebdomadaire. Supporte les schedules binaires (On/Off) et multi-états.

## Fichiers concernés

### Écrans
- `lib/presentation/screens/schedules/schedules_list_screen.dart` - Liste des schedules
- `lib/presentation/screens/schedules/schedule_detail_screen.dart` - Vue/édition d'un schedule

### Providers
- `lib/application/providers/schedule_provider.dart` - Chargement des schedules

### Modèles
- `lib/domain/models/schedule.dart` - Modèles Schedule, WeeklySchedule, TimeSlot

### Services
- `lib/data/services/bacnet/bacnet_encoder.dart` - Encodage pour écriture
- `lib/data/services/bacnet/bacnet_decoder.dart` - Décodage des réponses

## Classes/Providers clés

### SchedulesListScreen
- **Fichier** : `schedules_list_screen.dart`
- **Rôle** : Affiche la liste des schedules du contrôleur
- **Features** :
  - Nom et description de chaque schedule
  - Valeur actuelle (present-value)
  - Valeur par défaut (schedule-default)
  - Navigation vers détail

### ScheduleDetailScreen
- **Fichier** : `schedule_detail_screen.dart`
- **Paramètres** : `instance` (instance BACnet du schedule)
- **Rôle** : Affiche et permet d'éditer un schedule
- **Features** :
  - Vue hebdomadaire avec créneaux par jour
  - Édition des créneaux (ajout, modification, suppression)
  - Valeur par défaut configurable
  - Points liés (list-of-object-property-references)

### schedulesProvider
- **Fichier** : `schedule_provider.dart`
- **Type** : `FutureProvider<List<ScheduleSummary>>`
- **Rôle** : Liste résumée des schedules

### scheduleDetailProvider
- **Fichier** : `schedule_provider.dart`
- **Type** : `FutureProvider.family<Schedule?, int>`
- **Rôle** : Détail complet d'un schedule par instance

## Flux de données

### Chargement de la liste

```
SchedulesListScreen
        │
        │ watches schedulesProvider
        ▼
ApiService.getSchedules()
        │
        ├── GET /api/rest/v2/services/bacnet/local/objects?type=schedule
        │   (ou V1 équivalent)
        ▼
List<ScheduleSummary>
        │
        │ parsing
        ▼
ListView → ScheduleListTile
```

### Chargement du détail

```
ScheduleDetailScreen(instance: 5)
        │
        │ watches scheduleDetailProvider(5)
        ▼
ApiService.getScheduleDetail(5)
        │
        ├── GET /api/rest/v2/services/bacnet/local/objects/schedule/5
        ▼
JSON response
        │
        ▼
BacnetScheduleConverter.fromApi(json, apiVersion)
        │
        ├── Parse weekly-schedule
        ├── Parse schedule-default
        ├── Parse list-of-object-property-references
        ▼
Schedule (avec WeeklySchedule)
```

## Patterns importants

### Structure Schedule

```dart
class Schedule {
  final int instance;
  final String name;
  final String? description;
  final bool? outOfService;
  final dynamic presentValue;       // Valeur actuelle
  final dynamic scheduleDefault;    // Valeur par défaut
  final WeeklySchedule weeklySchedule;
  final List<String>? listOfObjectPropertyReferences;
  final ScheduleValueType valueType;
  final List<ScheduleStateText>? stateTexts;
}
```

### WeeklySchedule

```dart
class WeeklySchedule {
  final DaySchedule monday;
  final DaySchedule tuesday;
  final DaySchedule wednesday;
  final DaySchedule thursday;
  final DaySchedule friday;
  final DaySchedule saturday;
  final DaySchedule sunday;

  DaySchedule getDay(WeekDay day);
}
```

### DaySchedule et transitions

Un jour est défini par une liste de transitions (changements de valeur) :

```dart
class DaySchedule {
  final List<ScheduleTransition> transitions;

  // Convertit en créneaux pour l'affichage
  List<TimeSlot> toTimeSlots() {
    // Transition à 08:00 → ON, à 18:00 → OFF
    // devient TimeSlot(08:00 - 18:00, ON)
  }
}

class ScheduleTransition {
  final int hour;
  final int minute;
  final dynamic value;  // true/false pour binaire, int pour multi-état
}
```

### TimeSlot (pour affichage)

```dart
class TimeSlot {
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final dynamic value;

  String get timeRange => '$startHour:$startMinute - $endHour:$endMinute';
}
```

### Types de schedules

#### Binaire (boolean)
- Valeurs : `true` / `false`
- Affichage : ON / OFF

#### Multi-état (enumerated)
- Valeurs : entiers (0, 1, 2...)
- Affichage : textes configurés (stateTexts)

```dart
class ScheduleStateText {
  final int value;
  final String text;  // ex: "Occupied", "Unoccupied", "Standby"
}
```

### Parsing API V1 vs V2

#### Format V1
```json
{
  "weekly-schedule": {
    "monday": [
      {"time": "08:00:00", "value": true},
      {"time": "18:00:00", "value": false}
    ]
  }
}
```

#### Format V2
```json
{
  "weekly-schedule": [
    {
      "day-of-week": "monday",
      "day-schedule": [
        {"time": {"hour": 8, "minute": 0}, "value": {"boolean": true}},
        {"time": {"hour": 18, "minute": 0}, "value": {"boolean": false}}
      ]
    }
  ]
}
```

### Écriture d'un schedule

Pour modifier un schedule, on encode et envoie le weekly-schedule complet :

```dart
// Construire les transitions
final transitions = [
  ScheduleTransition(hour: 8, minute: 0, value: true),
  ScheduleTransition(hour: 18, minute: 0, value: false),
];

// Encoder selon version API
final encoded = BacnetScheduleEncoder.encodeWeeklySchedule(
  weeklySchedule,
  apiVersion,
);

// Envoyer
await apiService.writeProperty(
  objectType: 'schedule',
  instance: scheduleInstance,
  property: 'weekly-schedule',
  value: encoded,
);
```

### Points liés

Un schedule peut contrôler plusieurs points via `list-of-object-property-references` :

```dart
// Exemple de références
[
  "analog-value,1.present-value",
  "analog-value,2.present-value",
  "binary-value,5.present-value",
]
```

Ces références indiquent quels points sont affectés par le schedule.
