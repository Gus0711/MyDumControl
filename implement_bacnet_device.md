# Plan d'implémentation BACnet Device

## Objectif

Ajouter le support des devices BACnet natifs (BACnet/IP) en plus de l'API REST Distech existante.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        MyDumControl                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────┐    ┌──────────────────────┐          │
│  │   API Distech        │    │   BACnet/IP natif    │          │
│  │   (REST HTTP/HTTPS)  │    │   (UDP port 47808+)  │          │
│  │                      │    │                      │          │
│  │   ApiService         │    │   BacnetService      │          │
│  │   (existant)         │    │   (nouveau)          │          │
│  └──────────┬───────────┘    └──────────┬───────────┘          │
│             │                           │                       │
│             └───────────┬───────────────┘                       │
│                         │                                       │
│              ┌──────────▼──────────┐                           │
│              │   BacnetObject      │                           │
│              │   (modèle unifié)   │                           │
│              └─────────────────────┘                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Fonctionnalités

| Fonctionnalité | API Distech | BACnet natif |
|----------------|-------------|--------------|
| Test connexion | REST /api/rest/v1/info | Who-Is ou Read device object |
| Liste des points | REST /protocols/bacnet/local/objects | Read object-list + RPM |
| Lecture valeur | REST /properties/present-value | ReadProperty |
| Écriture valeur | REST POST | WriteProperty |
| Découverte | Automatique via API | Who-Is broadcast ou unicast |

## Cas d'usage

1. **Connexion locale** : IP sur le même subnet, port 47808
2. **Connexion via NAT/Port forward** : IP publique, port custom (ex: 8083 → 47808)
3. **Connexion VPN** : IP privée via tunnel, port 47808

---

## Phase 1 : Modification de la base de données

### Fichier : `lib/data/database/tables/connections_table.dart`

Ajouter deux colonnes :

```dart
/// Type de connexion : 'distech_api' ou 'bacnet'
TextColumn get connectionType =>
    text().withDefault(const Constant('distech_api'))();

/// Device ID BACnet (instance number, optionnel)
/// Utilisé pour adresser un device spécifique derrière un routeur BACnet
IntColumn get bacnetDeviceId => integer().nullable()();
```

### Migration de la base

Incrémenter `schemaVersion` et ajouter la migration :

```dart
@override
int get schemaVersion => 3; // ou version actuelle + 1

@override
MigrationStrategy get migration => MigrationStrategy(
  onUpgrade: (m, from, to) async {
    if (from < 3) {
      await m.addColumn(connections, connections.connectionType);
      await m.addColumn(connections, connections.bacnetDeviceId);
    }
  },
);
```

---

## Phase 2 : BacnetService - Structure des paquets

### Format d'un paquet BACnet/IP (unicast)

```
┌────────────────────────────────────────────────────────────────┐
│ UDP Datagram                                                    │
├────────────────────────────────────────────────────────────────┤
│ BVLC Header (4 bytes)                                          │
│   Byte 0: 0x81 = BACnet/IP                                     │
│   Byte 1: 0x0a = Original-Unicast-NPDU                         │
│   Bytes 2-3: Length (big endian, total packet length)          │
├────────────────────────────────────────────────────────────────┤
│ NPDU Header (2+ bytes)                                         │
│   Byte 0: 0x01 = Version 1                                     │
│   Byte 1: Control flags                                        │
│           0x00 = No routing, no reply expected                 │
│           0x04 = No routing, reply expected                    │
│           0x20 = DNET/DADR present (routing)                   │
│   [Optional: DNET, DLEN, DADR if routing]                      │
├────────────────────────────────────────────────────────────────┤
│ APDU (variable)                                                │
│   Confirmed Request (ReadProperty, WriteProperty)              │
│   Unconfirmed Request (Who-Is)                                 │
│   Simple/Complex ACK (responses)                               │
└────────────────────────────────────────────────────────────────┘
```

### BVLC Functions (Byte 1)

| Code | Nom | Usage |
|------|-----|-------|
| 0x00 | BVLC-Result | Réponse |
| 0x04 | Forwarded-NPDU | Via BBMD |
| 0x0a | Original-Unicast-NPDU | **Unicast direct** |
| 0x0b | Original-Broadcast-NPDU | Broadcast (Who-Is) |

### APDU Types

| Type | Code (bits 7-4) | Usage |
|------|-----------------|-------|
| Confirmed Request | 0x0 | ReadProperty, WriteProperty |
| Unconfirmed Request | 0x1 | Who-Is, I-Am |
| Simple ACK | 0x2 | WriteProperty response |
| Complex ACK | 0x3 | ReadProperty response |
| Error | 0x5 | Erreur |
| Reject | 0x6 | Rejet |
| Abort | 0x7 | Abandon |

### Service Choices (Confirmed)

| Service | Code | Usage |
|---------|------|-------|
| ReadProperty | 12 (0x0C) | Lire une propriété |
| ReadPropertyMultiple | 14 (0x0E) | Lire plusieurs propriétés |
| WriteProperty | 15 (0x0F) | Écrire une propriété |
| WritePropertyMultiple | 16 (0x10) | Écrire plusieurs propriétés |

### Service Choices (Unconfirmed)

| Service | Code | Usage |
|---------|------|-------|
| I-Am | 0 | Réponse à Who-Is |
| Who-Is | 8 | Découverte |

### Object Types (encodage)

| Type | Code | Nom |
|------|------|-----|
| Analog Input | 0 | AI |
| Analog Output | 1 | AO |
| Analog Value | 2 | AV |
| Binary Input | 3 | BI |
| Binary Output | 4 | BO |
| Binary Value | 5 | BV |
| Device | 8 | DEV |
| Multi-state Input | 13 | MSI |
| Multi-state Output | 14 | MSO |
| Multi-state Value | 19 | MSV |

### Property IDs

| Property | Code | Type retourné |
|----------|------|---------------|
| object-name | 77 | CharacterString |
| present-value | 85 | Real/Boolean/Unsigned |
| description | 28 | CharacterString |
| units | 117 | Enumerated |
| object-list | 76 | Array of ObjectIdentifier |
| out-of-service | 81 | Boolean |
| priority-array | 87 | Array |
| status-flags | 111 | BitString |
| active-text | 4 | CharacterString |
| inactive-text | 46 | CharacterString |
| state-text | 110 | Array of CharacterString |

### Encodage Object Identifier (4 bytes)

```
┌────────────────────────────────────────┐
│ Bits 31-22 (10 bits): Object Type      │
│ Bits 21-0 (22 bits): Instance Number   │
└────────────────────────────────────────┘

Exemple: Analog Value 100
  Type = 2 (0b0000000010)
  Instance = 100 (0b0000000000000001100100)

  Object ID = (2 << 22) | 100 = 0x00800064
  Bytes: 0x00 0x80 0x00 0x64
```

### Encodage des tags (ASN.1/BER)

**Application Tags** (données primitives) :

| Tag | Type | Encodage |
|-----|------|----------|
| 0 | Null | 0x00 |
| 1 | Boolean | 0x10 (false) / 0x11 (true) |
| 2 | Unsigned Integer | 0x21-0x24 + bytes |
| 3 | Signed Integer | 0x31-0x34 + bytes |
| 4 | Real (float32) | 0x44 + 4 bytes IEEE 754 |
| 5 | Double (float64) | 0x55 + 8 bytes IEEE 754 |
| 7 | CharacterString | 0x75 + length + UTF-8 |
| 9 | Enumerated | 0x91-0x94 + bytes |
| 12 | Object Identifier | 0xC4 + 4 bytes |

**Context Tags** (paramètres de service) :

```
Tag number N, length L:
  - Si L <= 4: byte = (N << 4) | 0x08 | L
  - Si L > 4: byte = (N << 4) | 0x0D, puis length byte(s)

Exemple: Context tag [0] avec 4 bytes
  Byte: 0x0C = (0 << 4) | 0x08 | 4
```

---

## Phase 3 : Implémentation BacnetService

### Fichier : `lib/data/services/bacnet_service.dart`

```dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

/// Service BACnet/IP en Dart pur
class BacnetService {
  static const int defaultPort = 47808;
  static const Duration timeout = Duration(seconds: 5);

  RawDatagramSocket? _socket;
  int _invokeId = 0;
  final Map<int, Completer<Uint8List>> _pendingRequests = {};

  /// Initialise le socket UDP
  Future<void> init() async {
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _socket!.listen(_handleResponse);
  }

  /// Ferme le socket
  void dispose() {
    _socket?.close();
    _socket = null;
  }

  /// Test de connexion (lecture du device object)
  Future<BacnetConnectionResult> testConnection({
    required String host,
    required int port,
    int? deviceId,
  }) async { ... }

  /// Lit une propriété
  Future<dynamic> readProperty({
    required String host,
    required int port,
    required int objectType,
    required int objectInstance,
    required int propertyId,
    int? arrayIndex,
  }) async { ... }

  /// Écrit une propriété
  Future<void> writeProperty({
    required String host,
    required int port,
    required int objectType,
    required int objectInstance,
    required int propertyId,
    required dynamic value,
    int? priority,
  }) async { ... }

  /// Découvre les objets d'un device
  Future<List<BacnetObjectInfo>> discoverObjects({
    required String host,
    required int port,
    int? deviceId,
  }) async { ... }
}
```

### Classes de données

```dart
/// Résultat d'un test de connexion BACnet
class BacnetConnectionResult {
  final bool success;
  final int? deviceId;
  final String? deviceName;
  final String? vendorName;
  final String? modelName;
  final String? errorMessage;
}

/// Info minimale d'un objet découvert
class BacnetObjectInfo {
  final int objectType;
  final int objectInstance;
  String? objectName;
}
```

---

## Phase 4 : Encodeurs/Décodeurs

### Fichier : `lib/data/services/bacnet/bacnet_encoder.dart`

```dart
/// Encode un paquet ReadProperty
class BacnetEncoder {
  /// Encode le BVLC header
  static Uint8List encodeBvlc(int function, int length) { ... }

  /// Encode le NPDU header (unicast simple)
  static Uint8List encodeNpdu({bool expectingReply = true}) { ... }

  /// Encode un ReadProperty Request
  static Uint8List encodeReadPropertyRequest({
    required int invokeId,
    required int objectType,
    required int objectInstance,
    required int propertyId,
    int? arrayIndex,
  }) { ... }

  /// Encode un WriteProperty Request
  static Uint8List encodeWritePropertyRequest({
    required int invokeId,
    required int objectType,
    required int objectInstance,
    required int propertyId,
    required dynamic value,
    int? priority,
  }) { ... }

  /// Encode un Object Identifier
  static Uint8List encodeObjectId(int objectType, int instance) { ... }

  /// Encode une valeur selon son type
  static Uint8List encodeValue(dynamic value) { ... }
}
```

### Fichier : `lib/data/services/bacnet/bacnet_decoder.dart`

```dart
/// Décode les réponses BACnet
class BacnetDecoder {
  /// Décode un paquet BACnet complet
  static BacnetResponse decode(Uint8List data) { ... }

  /// Décode le BVLC header
  static BvlcHeader decodeBvlc(Uint8List data) { ... }

  /// Décode le NPDU header
  static NpduHeader decodeNpdu(Uint8List data, int offset) { ... }

  /// Décode l'APDU
  static ApduResponse decodeApdu(Uint8List data, int offset) { ... }

  /// Décode une valeur selon son tag
  static dynamic decodeValue(Uint8List data, int offset) { ... }

  /// Décode un Object Identifier
  static ObjectId decodeObjectId(Uint8List data, int offset) { ... }
}
```

---

## Phase 5 : Modification de l'UI

### Fichier : `lib/presentation/screens/connections/add_connection_screen.dart`

Ajouter en haut du formulaire :

```dart
// Type de connexion
SegmentedButton<String>(
  segments: const [
    ButtonSegment(
      value: 'distech_api',
      label: Text('API Distech'),
      icon: Icon(Icons.api),
    ),
    ButtonSegment(
      value: 'bacnet',
      label: Text('Device BACnet'),
      icon: Icon(Icons.device_hub),
    ),
  ],
  selected: {_connectionType},
  onSelectionChanged: (selected) {
    setState(() {
      _connectionType = selected.first;
      // Ajuster le port par défaut
      if (_connectionType == 'bacnet') {
        _portController.text = '47808';
      } else {
        _portController.text = _useHttps ? '443' : '80';
      }
    });
  },
),
```

Formulaire conditionnel :

```dart
if (_connectionType == 'distech_api') {
  // Formulaire actuel (HTTPS, username, password)
} else {
  // Formulaire BACnet simplifié
  // - IP
  // - Port (défaut 47808)
  // - Device ID (optionnel)
}
```

---

## Phase 6 : Intégration dans les providers

### Fichier : `lib/application/providers/bacnet_provider.dart`

```dart
/// Provider du service BACnet (singleton)
@Riverpod(keepAlive: true)
BacnetService bacnetService(BacnetServiceRef ref) {
  final service = BacnetService();
  service.init();
  ref.onDispose(() => service.dispose());
  return service;
}

/// Provider pour lire une propriété BACnet
@riverpod
Future<dynamic> bacnetReadProperty(
  BacnetReadPropertyRef ref, {
  required String host,
  required int port,
  required int objectType,
  required int objectInstance,
  required int propertyId,
}) async {
  final service = ref.watch(bacnetServiceProvider);
  return service.readProperty(
    host: host,
    port: port,
    objectType: objectType,
    objectInstance: objectInstance,
    propertyId: propertyId,
  );
}
```

### Modification de `active_connection_provider.dart`

Adapter pour supporter les deux types de connexion :

```dart
Future<void> connect(Connection connection) async {
  if (connection.connectionType == 'bacnet') {
    // Connexion BACnet
    final bacnetService = ref.read(bacnetServiceProvider);
    final result = await bacnetService.testConnection(
      host: connection.host,
      port: connection.port,
      deviceId: connection.bacnetDeviceId,
    );
    // ...
  } else {
    // Connexion API Distech (code existant)
    // ...
  }
}
```

---

## Phase 7 : Tests

### Tests unitaires

1. **Encodage BVLC** : Vérifier les bytes générés
2. **Encodage NPDU** : Vérifier les flags
3. **Encodage APDU** : Vérifier ReadProperty, WriteProperty
4. **Décodage réponses** : Parser les Complex ACK

### Tests d'intégration

1. **Test connexion** : Ping un device BACnet réel
2. **Lecture present-value** : Lire un Analog Value
3. **Écriture** : Écrire une valeur et relire
4. **Découverte** : Lister les objets d'un device

### Devices de test suggérés

- Simulateur BACnet (ex: YABE, BACnet4J)
- Device physique sur le réseau local
- Device via port forwarding

---

## Ordre d'implémentation

1. [x] Créer ce document de plan
2. [ ] Modifier `connections_table.dart` + migration
3. [ ] Créer `lib/data/services/bacnet/bacnet_constants.dart`
4. [ ] Créer `lib/data/services/bacnet/bacnet_encoder.dart`
5. [ ] Créer `lib/data/services/bacnet/bacnet_decoder.dart`
6. [ ] Créer `lib/data/services/bacnet_service.dart`
7. [ ] Modifier `add_connection_screen.dart`
8. [ ] Créer `lib/application/providers/bacnet_provider.dart`
9. [ ] Adapter `active_connection_provider.dart`
10. [ ] Adapter `points_provider.dart` pour BACnet
11. [ ] Tests sur device réel
12. [ ] Régénérer le code Drift (`dart run build_runner build`)

---

## Limitations connues

1. **Web** : Non supporté (pas d'accès UDP dans le navigateur)
2. **Broadcast** : Limité au subnet local (pas de traversée routeur)
3. **Segmentation** : Non implémentée (limite ~1400 bytes par réponse)
4. **MS/TP** : Non supporté (nécessite port série RS-485)
5. **BACnet/SC** : Non supporté (WebSocket, plus complexe)

---

## Ressources

- [BACnet Stack (C)](https://github.com/bacnet-stack/bacnet-stack)
- [bacnet_parse (Rust)](https://github.com/jtroo/bacnet_parse)
- [ASHRAE 135 Standard](https://www.ashrae.org/technical-resources/standards-and-guidelines)
- [BACnet Protocol Overview](https://www.emqx.com/en/blog/bacnet-protocol-basic-concepts-structure-obejct-model-explained)
