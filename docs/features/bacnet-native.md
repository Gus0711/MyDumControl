# BACnet/IP Natif

## Vue d'ensemble

L'application implémente un client BACnet/IP complet en Dart pur, permettant une communication directe avec les contrôleurs sans passer par l'API REST. Ce mode est particulièrement utile pour :

- Contrôleurs sans serveur web
- Découverte réseau (broadcast Who-Is)
- Performance optimale (UDP vs HTTPS)
- Accès aux fonctionnalités BACnet avancées

## Fichiers concernés

### Service principal
- `lib/data/services/bacnet_service.dart` - Client UDP BACnet/IP

### Encodage/Décodage protocole
- `lib/data/services/bacnet/bacnet_encoder.dart` - Encodage des requêtes
- `lib/data/services/bacnet/bacnet_decoder.dart` - Décodage des réponses
- `lib/data/services/bacnet/bacnet_constants.dart` - Constantes BACnet (types, propriétés, unités)

### Providers
- `lib/application/providers/bacnet_provider.dart` - Gestion d'état Riverpod

### Modèles
- `lib/domain/models/bacnet_object.dart` - Objets BACnet

## Architecture du protocole

### Structure des paquets BACnet/IP

```
┌─────────────────────────────────────────────────────────┐
│ BVLC (4 bytes)                                          │
│ - Type: 0x81 (BACnet/IP)                                │
│ - Function: 0x0a (Unicast) ou 0x0b (Broadcast)          │
│ - Length: 2 bytes                                       │
├─────────────────────────────────────────────────────────┤
│ NPDU (2+ bytes)                                         │
│ - Version: 0x01                                         │
│ - Control: flags (DNET, SNET, expecting reply, etc.)    │
│ - [DNET, DLEN, DADR si routage]                         │
├─────────────────────────────────────────────────────────┤
│ APDU (variable)                                         │
│ - PDU Type + flags                                      │
│ - Invoke ID (pour requêtes confirmées)                  │
│ - Service Choice                                        │
│ - Données encodées                                      │
└─────────────────────────────────────────────────────────┘
```

### Services BACnet supportés

| Service | Type | Description |
|---------|------|-------------|
| Who-Is | Unconfirmed | Découverte de devices |
| I-Am | Unconfirmed | Réponse à Who-Is |
| Who-Is-Router-To-Network | Network Layer | Découverte de routeurs |
| I-Am-Router-To-Network | Network Layer | Réponse des routeurs |
| ReadProperty | Confirmed | Lecture d'une propriété |
| WriteProperty | Confirmed | Écriture d'une propriété |
| ReadPropertyMultiple | Confirmed | Lecture batch |
| ReadRange | Confirmed | Lecture de plages (trend logs) |

## BacnetService

### Initialisation

```dart
final bacnetService = BacnetService(timeout: Duration(seconds: 5));
await bacnetService.init();
```

Le service :
- Tente de se lier au port 47808 (standard BACnet) pour une meilleure compatibilité
- Fallback sur un port dynamique si 47808 est occupé
- Active le broadcast pour la découverte

### Méthodes principales

#### Test de connexion

```dart
Future<BacnetConnectionResult> testConnection({
  required String host,
  required int port,
  int? deviceId,
})
```

Teste la connexion à un device BACnet :
1. Si `deviceId` non fourni, envoie Who-Is pour le découvrir
2. Lit les propriétés du device via ReadPropertyMultiple (optimisation 3x)
3. Retourne nom, vendeur, modèle du device

**Retour** : `BacnetConnectionResult`
```dart
class BacnetConnectionResult {
  final bool success;
  final int? deviceId;
  final String? deviceName;
  final String? vendorName;
  final String? modelName;
  final String? errorMessage;
}
```

#### Découverte locale (broadcast)

```dart
Future<List<IAmInfo>> discoverLocalDevices({
  int port = 47808,
  Duration timeout = const Duration(seconds: 5),
  int sendCount = 3,
  Duration sendInterval = const Duration(milliseconds: 800),
})
```

Découverte multi-phases :
1. **Phase 1** : Who-Is-Router-To-Network pour découvrir les routeurs BACnet
2. **Phase 2** : Who-Is broadcast sur toutes les interfaces réseau (envois multiples)
3. **Phase 3** : Who-Is vers les réseaux distants découverts via les routeurs

**Retour** : `List<IAmInfo>`
```dart
class IAmInfo {
  final InternetAddress address;
  final int deviceId;
  final int? networkNumber;  // Si routé
}
```

#### Scan de plage IP

```dart
Future<List<IAmInfo>> scanIpRange({
  required String startIp,
  required String endIp,
  int port = 47808,
  Duration timeout = const Duration(milliseconds: 500),
  void Function(int current, int total)? onProgress,
  void Function(IAmInfo device)? onDeviceFound,
})
```

Scan unicast d'une plage d'adresses IP (même sous-réseau /24).
- Traitement par batch de 10 pour éviter la surcharge réseau
- Callbacks pour progression et découverte en temps réel

#### Lecture de propriété

```dart
Future<BacnetResponse> readProperty({
  required String host,
  required int port,
  required int objectType,
  required int objectInstance,
  required int propertyId,
  int? arrayIndex,
})
```

Lit une propriété BACnet. Utiliser les constantes de `bacnet_constants.dart` :

```dart
final result = await bacnetService.readProperty(
  host: '192.168.1.100',
  port: 47808,
  objectType: BacnetObjectTypeCode.analogValue,  // 2
  objectInstance: 1,
  propertyId: BacnetPropertyId.presentValue,     // 85
);

if (result.isSuccess) {
  print('Value: ${result.value}');
}
```

#### Lecture multiple (batch)

```dart
Future<BacnetResponse> readPropertyMultiple({
  required String host,
  required int port,
  required List<ReadPropertyMultipleItem> items,
})
```

Lit plusieurs propriétés en une seule requête (optimisation réseau 3x+) :

```dart
final result = await bacnetService.readPropertyMultiple(
  host: '192.168.1.100',
  port: 47808,
  items: [
    ReadPropertyMultipleItem(
      objectType: BacnetObjectTypeCode.analogValue,
      objectInstance: 1,
      propertyIds: [
        BacnetPropertyId.presentValue,
        BacnetPropertyId.units,
        BacnetPropertyId.statusFlags,
      ],
    ),
  ],
);

if (result.isSuccess && result.multipleResults != null) {
  for (final prop in result.multipleResults!.first.properties) {
    print('Property ${prop.propertyId}: ${prop.value}');
  }
}
```

#### Écriture de propriété

```dart
Future<BacnetResponse> writeProperty({
  required String host,
  required int port,
  required int objectType,
  required int objectInstance,
  required int propertyId,
  required dynamic value,
  int? priority,
  int? arrayIndex,
})
```

Écrit une valeur avec priorité optionnelle (1-16) :

```dart
// Forcer une valeur à priorité 8 (Manual Operator)
await bacnetService.writeProperty(
  host: '192.168.1.100',
  port: 47808,
  objectType: BacnetObjectTypeCode.analogValue,
  objectInstance: 1,
  propertyId: BacnetPropertyId.presentValue,
  value: 21.5,
  priority: 8,
);

// Libérer le forçage (relinquish)
await bacnetService.writeProperty(
  // ...mêmes paramètres...
  value: null,  // null = relinquish
  priority: 8,
);
```

#### Découverte des objets

```dart
Future<List<BacnetObject>> discoverObjects({
  required String host,
  required int port,
  required int deviceId,
  List<int>? objectTypesFilter,
})
```

Découvre tous les objets d'un device :
1. Lit `object-list` du device
2. Filtre par types si spécifié
3. Lit les propriétés de chaque objet via RPM

#### Rafraîchissement batch

```dart
Future<Map<String, RefreshedPointData>> refreshMultiplePointValues({
  required String host,
  required int port,
  required List<({int objectType, int objectInstance, bool isCommandable, bool isInput})> points,
  int batchSize = 10,
})
```

Rafraîchit plusieurs points en parallèle avec :
- `present-value`
- `status-flags` (alarmes)
- `priority-array` (forçages, si commandable)
- `out-of-service` (si entrée)
- `units`

**Retour** : `Map<String, RefreshedPointData>`
```dart
class RefreshedPointData {
  final dynamic presentValue;
  final bool isOverridden;
  final int? overridePriority;
  final dynamic overrideValue;
  final bool? outOfService;
  final bool inAlarm;
  final String? units;
}
```

## Trend Logs

### Découverte

```dart
Future<List<BacnetTrendLog>> discoverTrendLogs({
  required String host,
  required int port,
  required int deviceId,
})
```

Découvre les trend logs et leurs objets trackés :

```dart
class BacnetTrendLog {
  final int instance;
  final String objectName;
  final String? trackedObjectType;   // "analog-value"
  final int? trackedObjectInstance;  // 1
  final int? totalRecordCount;       // Pour pagination

  String? get trackedObjectKey => '$trackedObjectType:$trackedObjectInstance';
}
```

### Lecture du buffer

```dart
Future<List<TrendLogRecordData>> readTrendLogBuffer({
  required String host,
  required int port,
  required int trendLogInstance,
  int? maxRecords,
  int? totalRecordCount,
})
```

Lit l'historique avec pagination `bySequenceNumber` :
- Utilise `count` négatif pour lire vers le passé
- Chunks de 65 records max (limite Distech)
- Part de `totalRecordCount` (dernier record) vers le passé

```dart
class TrendLogRecordData {
  final DateTime timestamp;
  final dynamic value;      // double, bool, int
  final int? statusFlags;
  final int sequenceNumber;
}
```

### ReadRange

```dart
Future<BacnetResponse> readRange({
  required String host,
  required int port,
  required int objectType,
  required int objectInstance,
  required int propertyId,
  ReadRangeType rangeType = ReadRangeType.all,
  int? referenceIndex,
  int? count,
  DateTime? referenceTime,
})
```

Types de plages :
- `ReadRangeType.all` - Tous les records
- `ReadRangeType.byPosition` - Par index
- `ReadRangeType.bySequenceNumber` - Par numéro de séquence (recommandé)
- `ReadRangeType.byTime` - Par timestamp

## Schedules

### Découverte

```dart
Future<List<BacnetScheduleInfo>> discoverSchedules({
  required String host,
  required int port,
  required int deviceId,
})
```

### Lecture complète

```dart
Future<BacnetScheduleInfo?> readScheduleFull({
  required String host,
  required int port,
  required int scheduleInstance,
  int? deviceId,
})
```

Lit un schedule complet avec :
- Infos de base (nom, description, present-value, schedule-default)
- Weekly-schedule (7 jours de transitions)
- State-texts (depuis schedule ou objet référencé)

```dart
class BacnetScheduleInfo {
  final int instance;
  final String objectName;
  final DecodedWeeklySchedule? weeklySchedule;
  final dynamic presentValue;
  final dynamic scheduleDefault;
  final List<String>? stateTexts;
}
```

### Lecture du weekly-schedule

```dart
Future<DecodedWeeklySchedule?> readWeeklySchedule({
  required String host,
  required int port,
  required int scheduleInstance,
})
```

```dart
class DecodedWeeklySchedule {
  final List<DecodedDailySchedule> days;  // 7 jours
}

class DecodedDailySchedule {
  final List<DecodedTimeValue> timeValues;  // Transitions du jour
}

class DecodedTimeValue {
  final int hour;
  final int minute;
  final int second;
  final dynamic value;  // bool, int, double
}
```

### Écriture du weekly-schedule

```dart
Future<bool> writeWeeklySchedule({
  required String host,
  required int port,
  required int scheduleInstance,
  required BacnetWeeklySchedule weeklySchedule,
})
```

Construire un schedule pour écriture :

```dart
final weeklySchedule = BacnetWeeklySchedule(
  days: [
    // Lundi
    BacnetDailySchedule(timeValues: [
      BacnetTimeValue(hour: 8, minute: 0, value: true, valueTag: ScheduleValueTag.boolean),
      BacnetTimeValue(hour: 18, minute: 0, value: false, valueTag: ScheduleValueTag.boolean),
    ]),
    // Mardi ... Dimanche
    // ...
  ],
);

await bacnetService.writeWeeklySchedule(
  host: '192.168.1.100',
  port: 47808,
  scheduleInstance: 1,
  weeklySchedule: weeklySchedule,
);
```

### Écriture d'un jour spécifique

```dart
Future<bool> writeDailySchedule({
  required String host,
  required int port,
  required int scheduleInstance,
  required int dayIndex,  // 1-7 (1=Lundi)
  required BacnetDailySchedule dailySchedule,
})
```

## Parsing des status-flags

Les status-flags BACnet sont un bitstring de 4 bits :

| Bit | Flag | Description |
|-----|------|-------------|
| 0 | in-alarm | Point en alarme |
| 1 | fault | Défaut détecté |
| 2 | overridden | Valeur forcée |
| 3 | out-of-service | Hors service |

Le service parse automatiquement les différents formats :
- Liste de booléens `[true, false, false, false]`
- Map `{"in-alarm": true, "fault": false, ...}`
- Entier (bitfield) `0x01`
- String `"1000"` ou `"{in-alarm=true, ...}"`

## Parsing du priority-array

Le priority-array BACnet a 16 positions (1 = plus haute priorité) :

| Priorité | Usage typique |
|----------|---------------|
| 1 | Manual Life Safety |
| 2 | Automatic Life Safety |
| 5 | Critical Equipment Control |
| 8 | Manual Operator |
| 16 | Default / Relinquish |

Le service détecte automatiquement les forçages (positions 1-15 non null).

## Providers Riverpod

### bacnetServiceProvider

```dart
final bacnetServiceProvider = Provider<BacnetService>((ref) {
  final service = BacnetService();
  ref.keepAlive();  // Conserve le socket entre navigations
  ref.onDispose(() => service.dispose());
  return service;
});
```

### activeBacnetConnectionProvider

```dart
final activeBacnetConnectionProvider = StateProvider<ActiveBacnetConnection?>((ref) {
  return null;
});

class ActiveBacnetConnection {
  final int connectionId;
  final String host;
  final int port;
  final int? deviceId;
}
```

## Constantes BACnet

### Types d'objets (`BacnetObjectTypeCode`)

| Constante | Code | Description |
|-----------|------|-------------|
| `analogInput` | 0 | Entrée analogique |
| `analogOutput` | 1 | Sortie analogique |
| `analogValue` | 2 | Valeur analogique |
| `binaryInput` | 3 | Entrée binaire |
| `binaryOutput` | 4 | Sortie binaire |
| `binaryValue` | 5 | Valeur binaire |
| `multiStateInput` | 13 | Entrée multi-états |
| `multiStateOutput` | 14 | Sortie multi-états |
| `schedule` | 17 | Schedule |
| `multiStateValue` | 19 | Valeur multi-états |
| `trendLog` | 20 | Trend log |
| `device` | 8 | Device |

### Propriétés (`BacnetPropertyId`)

| Constante | Code | Description |
|-----------|------|-------------|
| `presentValue` | 85 | Valeur actuelle |
| `objectName` | 77 | Nom de l'objet |
| `description` | 28 | Description |
| `units` | 117 | Unités |
| `statusFlags` | 111 | Flags d'état |
| `priorityArray` | 87 | Tableau de priorités |
| `outOfService` | 81 | Hors service |
| `objectList` | 76 | Liste des objets |
| `weeklySchedule` | 123 | Schedule hebdomadaire |
| `scheduleDefault` | 174 | Valeur par défaut |
| `logBuffer` | 131 | Buffer du trend log |
| `totalRecordCount` | 145 | Nb total de records |

### Unités (`BacnetUnits`)

La classe `BacnetUnits` convertit les codes BACnet en symboles lisibles :

| Code | Symbole |
|------|---------|
| 62 | °C |
| 64 | °F |
| 95 | % |
| 98 | ppm |
| 19 | kW |
| 18 | W |

## Gestion des erreurs

### BacnetResponse

```dart
class BacnetResponse {
  final BacnetResponseType type;
  final dynamic value;
  final bool isError;
  final int? errorClass;
  final int? errorCode;
  final String? errorMessage;

  bool get isSuccess => !isError && type != BacnetResponseType.timeout;
}
```

### Codes d'erreur courants

| Class | Code | Description |
|-------|------|-------------|
| 2 | 31 | Unknown property |
| 2 | 32 | Value out of range |
| 4 | 42 | Write access denied |
| 5 | 25 | Timeout |

## Bonnes pratiques

1. **Utiliser RPM** : Préférer `readPropertyMultiple` pour réduire le trafic réseau
2. **Batch refresh** : Utiliser `refreshMultiplePointValues` pour rafraîchir plusieurs points
3. **Timeout approprié** : Ajuster selon la qualité du réseau (défaut 5s)
4. **Gestion du socket** : Utiliser `keepAlive()` dans le provider pour éviter les reconnexions
5. **Découverte multi-phases** : `discoverLocalDevices` gère automatiquement les routeurs BACnet
