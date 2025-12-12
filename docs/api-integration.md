# Intégration API

## Vue d'ensemble

L'application supporte 3 modes de connexion aux contrôleurs ECLYPSE :

| Mode | Protocole | Port | Usage |
|------|-----------|------|-------|
| API V1 | HTTPS REST | 443 | Contrôleurs legacy |
| API V2 | HTTPS REST | 443 | ECLYPSE 400/600, APEX |
| BACnet/IP | UDP | 47808 | Connexion directe sans serveur web |

## Fichiers concernés

- `lib/data/services/api_service.dart` - Client HTTP REST
- `lib/data/services/bacnet_service.dart` - Client BACnet UDP
- `lib/data/services/bacnet/bacnet_encoder.dart` - Encodage protocole
- `lib/data/services/bacnet/bacnet_decoder.dart` - Décodage protocole
- `lib/data/services/bacnet/bacnet_constants.dart` - Constantes BACnet

## ApiService

### Classe principale

**Fichier** : `lib/data/services/api_service.dart`

```dart
class ApiService {
  final String host;
  final int port;
  final bool useHttps;
  final String? username;
  final String? password;
  late Dio _dio;
}
```

### Méthodes clés

| Méthode | Description |
|---------|-------------|
| `testConnection()` | Teste la connexion et détecte version API |
| `getAllObjects()` | Récupère tous les points BACnet |
| `getObjectDetail(type, instance)` | Détail d'un point |
| `writeProperty(type, instance, value, priority)` | Écriture avec priorité |
| `getSchedules()` | Liste des schedules |
| `getScheduleDetail(instance)` | Détail d'un schedule |
| `getTrendLogBuffer(instance, start, end)` | Historique trend log |
| `getDeviceInfo()` | Infos du contrôleur |

### Détection version API

```dart
Future<ConnectionTestResult> testConnection() async {
  // Essayer V2 d'abord
  try {
    final response = await _dio.get('/api/rest/v2/services/bacnet/local/objects');
    return ConnectionTestResult(success: true, apiVersion: 'v2');
  } catch (_) {}

  // Fallback V1
  try {
    final response = await _dio.get('/api/rest/v1/protocol/bacnet/device');
    return ConnectionTestResult(success: true, apiVersion: 'v1');
  } catch (_) {}

  return ConnectionTestResult(success: false);
}
```

## Différences API V1 vs V2

### Endpoints

| Fonction | V1 | V2 |
|----------|----|----|
| Liste objets | `/api/rest/v1/protocol/bacnet/local/objects` | `/api/rest/v2/services/bacnet/local/objects` |
| Détail objet | `/api/rest/v1/protocol/bacnet/local/objects/{type}/{instance}` | `/api/rest/v2/services/bacnet/local/objects/{type}/{instance}` |
| Device info | `/api/rest/v1/protocol/bacnet/device` | `/api/rest/v2/services/bacnet/local/objects/device/0` |

### Format des types d'objets

| Type | V1 | V2 |
|------|----|----|
| Analog Input | `analog-input` | `analog-input` |
| Binary Value | `binary-value` | `binary-value` |
| Schedule | `schedule` | `schedule` |

### Format Priority Array

**V1** :
```json
{
  "priority-array": {
    "1": {"null": null},
    "8": {"real": 21.5},
    "16": {"null": null}
  }
}
```

**V2** :
```json
{
  "priority-array": [
    {"priority": 1, "value": null},
    {"priority": 8, "value": 21.5},
    {"priority": 16, "value": null}
  ]
}
```

## Authentification

### Basic Auth (par défaut)

```dart
final credentials = base64Encode(utf8.encode('$username:$password'));
_dio.options.headers['Authorization'] = 'Basic $credentials';
```

### Stockage sécurisé

Les mots de passe sont stockés via `flutter_secure_storage` :

```dart
// connection_providers.dart
final secureStorage = FlutterSecureStorage();
await secureStorage.write(key: 'pwd_$connectionId', value: password);
```

## Certificats TOFU

Les contrôleurs utilisent des certificats auto-signés. L'app implémente TOFU (Trust On First Use) :

1. **Première connexion** : Accepter et stocker l'empreinte du certificat
2. **Connexions suivantes** : Vérifier que l'empreinte correspond

```dart
// Dans ApiService
HttpClient httpClient = HttpClient()
  ..badCertificateCallback = (cert, host, port) {
    final fingerprint = sha256.convert(cert.der).toString();
    if (storedFingerprint == null) {
      // Premier contact - stocker
      return true;
    }
    // Vérifier correspondance
    return fingerprint == storedFingerprint;
  };
```

## BACnet/IP Natif

### BacnetService

**Fichier** : `lib/data/services/bacnet_service.dart`

Client UDP pour communication BACnet directe sans passer par l'API REST.

### Méthodes clés

| Méthode | Description |
|---------|-------------|
| `init()` | Initialise le socket UDP sur port 47808 |
| `dispose()` | Ferme le socket |
| `whoIs(lowLimit, highLimit)` | Découverte BACnet (broadcast) |
| `readProperty(deviceId, objectType, instance, property)` | Lecture propriété |
| `readPropertyMultiple(deviceId, requests)` | Lecture batch |
| `writeProperty(deviceId, objectType, instance, property, value, priority)` | Écriture |
| `discoverTrendLogs(deviceId)` | Mapping point → trend log |

### Format des requêtes BACnet

```dart
// Exemple readProperty
final request = BacnetEncoder.buildReadPropertyRequest(
  invokeId: nextInvokeId(),
  objectType: BacnetObjectTypes.analogInput,
  instance: 1,
  propertyId: BacnetProperties.presentValue,
);

socket.send(request, targetAddress, 47808);
```

## Cache

Le cache est géré via la base de données Drift pour fonctionnement offline :

| Table | Durée | Contenu |
|-------|-------|---------|
| `CachedPoints` | 24h | Propriétés statiques des points |
| `CachedDeviceInfo` | 1h | Infos du contrôleur |
| `CachedTrendLogMapping` | 1h | Mapping point → trend log |
| `CachedObjectsSummary` | 30min | Comptage par type d'objet |

### Utilisation

```dart
// Vérifier validité du cache
final isValid = await db.isPointsCacheValid(connectionId);

// Récupérer depuis cache
final cached = await db.getAllCachedPoints(connectionId);

// Rafraîchir le cache
await db.cachePoints(points);
```
