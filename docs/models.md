# Modèles de domaine

## Vue d'ensemble

Les modèles sont dans `lib/domain/models/`. Ils représentent les entités métier de l'application.

## BacnetObject

**Fichier** : `lib/domain/models/bacnet_object.dart` (~700 lignes)

Représente un point BACnet (entrée, sortie, valeur, schedule, etc.).

### Classe principale

```dart
class BacnetObject {
  final BacnetObjectType type;
  final int instance;
  final String name;
  final String? description;
  final dynamic presentValue;
  final String? units;
  final bool? outOfService;
  final OverrideInfo? override;
  final bool inAlarm;
  final Map<String, dynamic>? properties;
}
```

### BacnetObjectType (enum)

| Valeur | Code BACnet | API Name |
|--------|-------------|----------|
| `analogInput` | 0 | `analog-input` |
| `analogOutput` | 1 | `analog-output` |
| `analogValue` | 2 | `analog-value` |
| `binaryInput` | 3 | `binary-input` |
| `binaryOutput` | 4 | `binary-output` |
| `binaryValue` | 5 | `binary-value` |
| `multiStateInput` | 13 | `multi-state-input` |
| `multiStateOutput` | 14 | `multi-state-output` |
| `multiStateValue` | 19 | `multi-state-value` |
| `schedule` | 17 | `schedule` |
| `calendar` | 6 | `calendar` |
| `trendLog` | 20 | `trend-log` |
| `notificationClass` | 15 | `notification-class` |
| `device` | 8 | `device` |

### Méthodes clés

| Méthode | Description |
|---------|-------------|
| `fromApiV1(json)` | Parse réponse API V1 |
| `fromApiV2(json)` | Parse réponse API V2 |
| `displayValue` | Valeur formatée pour affichage |
| `isOverridden` | Point forcé ? |
| `overridePriority` | Niveau de priorité du forçage |
| `pointRef` | Référence "type:instance" |

### OverrideInfo

```dart
class OverrideInfo {
  final int priority;      // 1-16
  final dynamic value;
  final String? source;    // 'manual', 'schedule', etc.
}
```

### PointCategory (enum)

| Valeur | Types inclus |
|--------|--------------|
| `all` | Tous |
| `inputs` | AI, BI, MSI |
| `outputs` | AO, BO, MSO |
| `values` | AV, BV, MSV |
| `others` | Schedule, Calendar, TrendLog, etc. |

### PointSortOption (enum)

- `nameAsc` / `nameDesc`
- `typeAsc` / `typeDesc`
- `valueAsc` / `valueDesc`
- `favoritesFirst`

### SubTypeFilter (enum)

- `all`
- `analog`
- `binary`
- `multiState`

---

## TrendLog

**Fichier** : `lib/domain/models/trend_log.dart` (~250 lignes)

Représente un trend log et ses enregistrements.

### TrendLog

```dart
class TrendLog {
  final int instance;
  final String name;
  final String? description;
  final String? logDeviceObjectProperty;  // "type:instance.property"
  final int bufferSize;
  final int recordCount;
  final bool enabled;
  final Duration? logInterval;
}
```

### TrendLogRecord

```dart
class TrendLogRecord {
  final DateTime timestamp;
  final TrendRecordType type;
  final dynamic value;
  final int? statusFlags;
}
```

### TrendRecordType (enum)

| Valeur | Description |
|--------|-------------|
| `real` | Valeur réelle (float) |
| `boolean` | Valeur binaire |
| `enumerated` | Valeur multi-état |
| `unsigned` | Entier non signé |
| `signed` | Entier signé |
| `bitstring` | Chaîne de bits |
| `null` | Pas de valeur |
| `failure` | Erreur |
| `timeChange` | Changement d'heure |

### TrendLogData

```dart
class TrendLogData {
  final TrendLog trendLog;
  final List<TrendLogRecord> records;
  final DateTime? startDate;
  final DateTime? endDate;
}
```

### TrendLogBufferParser

Classe utilitaire pour parser les buffers trend log API V1/V2.

---

## Schedule

**Fichier** : `lib/domain/models/schedule.dart` (~900 lignes)

Représente un schedule BACnet avec planification hebdomadaire.

### Schedule

```dart
class Schedule {
  final int instance;
  final String name;
  final String? description;
  final bool? outOfService;
  final dynamic presentValue;
  final dynamic scheduleDefault;
  final WeeklySchedule weeklySchedule;
  final List<String>? listOfObjectPropertyReferences;
  final ScheduleValueType valueType;
  final List<ScheduleStateText>? stateTexts;  // Pour multi-état
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
}
```

### DaySchedule

```dart
class DaySchedule {
  final List<ScheduleTransition> transitions;

  List<TimeSlot> toTimeSlots();  // Convertit en créneaux
}
```

### ScheduleTransition

```dart
class ScheduleTransition {
  final int hour;
  final int minute;
  final dynamic value;
}
```

### TimeSlot

```dart
class TimeSlot {
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final dynamic value;
}
```

### ScheduleValueType (enum)

- `boolean` - On/Off
- `enumerated` - Multi-état avec labels

### WeekDay (enum)

`monday`, `tuesday`, `wednesday`, `thursday`, `friday`, `saturday`, `sunday`

### BacnetScheduleConverter

Classe utilitaire pour parser/encoder les schedules depuis/vers format API.

---

## Favorite

**Fichier** : `lib/domain/models/favorite.dart`

Représente un point marqué comme favori.

### Favorite

```dart
class Favorite {
  final int id;
  final int connectionId;
  final String pointRef;        // "AV:1"
  final String pointName;
  final String? pointDescription;
  final String objectType;
  final int sortOrder;
  final bool isSuperFavorite;   // Affiché sur liste connexions
  final bool wasPromoted;       // Cycle de promotion
}
```

---

## MultiCurveChart

**Fichier** : `lib/domain/models/multi_curve_chart.dart`

Configuration pour graphiques multi-courbes.

### CurveConfig

```dart
class CurveConfig {
  final int trendLogInstance;
  final String name;
  final String? units;
  final Color color;
}
```

### MultiCurveChartConfig

```dart
class MultiCurveChartConfig {
  final String id;
  final String title;
  final List<CurveConfig> curves;  // 2-8 courbes
}
```

### CurveData

```dart
class CurveData {
  final CurveConfig config;
  final List<TrendLogRecord> records;
}
```

### MultiCurveData

```dart
class MultiCurveData {
  final MultiCurveChartConfig config;
  final Map<int, CurveData> curveData;  // trendLogInstance → data
  final DateTime startDate;
  final DateTime endDate;
}
```

---

## Modèles auxiliaires (dans bacnet_object.dart)

### DeviceInfo

```dart
class DeviceInfo {
  final String? vendorName;
  final String? modelName;
  final String? serialNumber;
  final String? firmwareRevision;
  final String? applicationSoftwareVersion;
  final String? location;
  final String? description;
  final int? deviceInstance;
}
```

### ControllerTime

```dart
class ControllerTime {
  final DateTime localTime;
  final int? utcOffset;

  Duration get offsetFromDevice;  // Décalage vs heure locale
  bool get needsSync;             // Sync nécessaire ?
}
```

### NetworkInfo

```dart
class NetworkInfo {
  final String? ipAddress;
  final String? subnetMask;
  final String? gateway;
  final String? macAddress;
  final bool? dhcpEnabled;
  final List<NetworkInterfaceInfo>? interfaces;  // V2 multi-interface
}
```

### ObjectsSummary

```dart
class ObjectsSummary {
  final int analogInputs;
  final int analogOutputs;
  final int analogValues;
  final int binaryInputs;
  final int binaryOutputs;
  final int binaryValues;
  final int multiStateInputs;
  final int multiStateOutputs;
  final int multiStateValues;
  final int schedules;
  final int trendLogs;
  // ...

  int get total;
}
```
