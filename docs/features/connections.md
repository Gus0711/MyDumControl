# Connexions

## Vue d'ensemble

Gestion des connexions aux contrôleurs ECLYPSE. Supporte les connexions API REST (V1/V2) et BACnet/IP natif. Inclut la découverte automatique via mDNS et Who-Is BACnet.

## Fichiers concernés

### Écrans
- `lib/presentation/screens/connections/connections_list_screen.dart` - Liste des connexions
- `lib/presentation/screens/connections/add_connection_screen.dart` - Ajout/édition connexion
- `lib/presentation/screens/connections/discover_eclypse_screen.dart` - Découverte mDNS
- `lib/presentation/screens/connections/discover_bacnet_screen.dart` - Découverte BACnet

### Providers
- `lib/application/providers/connection_providers.dart` - CRUD connexions
- `lib/application/providers/active_connection_provider.dart` - Connexion active
- `lib/application/providers/folder_providers.dart` - Dossiers de connexions

### Services
- `lib/data/services/api_service.dart` - Client HTTP
- `lib/data/services/mdns_discovery_service.dart` - Découverte mDNS

### Database
- `lib/data/database/tables/connections_table.dart` - Table Connections
- `lib/data/database/tables/folders_table.dart` - Table Folders

## Classes/Providers clés

### ConnectionsListScreen
- **Fichier** : `connections_list_screen.dart`
- **Rôle** : Affiche la liste des connexions organisées en dossiers
- **Features** :
  - Liste avec super-favoris sous chaque connexion
  - Création/édition/suppression de connexions
  - Organisation en dossiers (drag & drop)
  - Indicateur de dernière connexion

### AddConnectionScreen
- **Fichier** : `add_connection_screen.dart`
- **Rôle** : Formulaire d'ajout/édition de connexion
- **Paramètres** : `connectionId` (optionnel, pour mode édition)
- **Features** :
  - Validation des champs (IP, port, credentials)
  - Test de connexion avant sauvegarde
  - Choix du type : API Distech ou BACnet natif
  - Stockage sécurisé du mot de passe

### activeConnectionProvider
- **Fichier** : `active_connection_provider.dart`
- **Type** : `StateNotifierProvider<ActiveConnectionNotifier, ActiveConnectionState>`
- **Méthodes** :
  - `connect(connectionId)` - Établit la connexion
  - `disconnect()` - Ferme la connexion
  - `testConnection()` - Test sans connexion persistante

### connectionsStreamProvider
- **Fichier** : `connection_providers.dart`
- **Type** : `StreamProvider<List<Connection>>`
- **Rôle** : Stream temps-réel des connexions depuis la DB

## Flux de données

```
ConnectionsListScreen
        │
        │ watches connectionsStreamProvider
        ▼
    List<Connection>
        │
        │ onTap connection
        ▼
ref.read(activeConnectionProvider.notifier).connect(id)
        │
        ▼
ActiveConnectionNotifier.connect()
        │
        ├── Récupère Connection depuis DB
        ├── Récupère password depuis SecureStorage
        ├── Crée ApiService avec credentials
        ├── Appelle apiService.testConnection()
        │         │
        │         ├── Détecte version API (V1/V2)
        │         └── Stocke certificat fingerprint (TOFU)
        │
        └── Met à jour state → UI rebuild
        │
        ▼
GoRouter.go('/home?connectionId=$id')
```

## Patterns importants

### Stockage sécurisé des mots de passe

Les mots de passe ne sont jamais stockés en clair dans la DB. Ils sont dans `flutter_secure_storage` :

```dart
// Sauvegarde
final key = 'connection_pwd_$connectionId';
await secureStorage.write(key: key, value: password);

// Lecture
final password = await secureStorage.read(key: key);
```

### Types de connexion

```dart
enum ConnectionType {
  distechApi,  // API REST V1/V2
  bacnet,      // BACnet/IP natif UDP
}
```

### Détection automatique version API

Lors du `testConnection()` :
1. Essayer endpoint V2 `/api/rest/v2/services/bacnet/local/objects`
2. Si échec, essayer V1 `/api/rest/v1/protocol/bacnet/device`
3. Stocker la version détectée pour éviter re-détection

### Certificats TOFU (Trust On First Use)

1. Première connexion : accepter le certificat auto-signé
2. Calculer fingerprint SHA-256 du certificat
3. Stocker dans `connections.certificateFingerprint`
4. Connexions suivantes : vérifier que le fingerprint correspond

## Découverte automatique

### mDNS (ECLYPSE)

- Service : `_eclypse._tcp`
- Récupère : hostname, IP, port
- Utilisable uniquement sur réseau local

### BACnet Who-Is

- Broadcast UDP sur port 47808
- Récupère : Device ID, vendor, model
- Plage configurable : `lowLimit` - `highLimit`

## Organisation en dossiers

Les connexions peuvent être organisées en dossiers (arborescence simple) :

```dart
class Folder {
  final int id;
  final String name;
  final int? parentId;  // null = racine
  final int sortOrder;
}
```

Le provider `foldersProvider` fournit la liste des dossiers, et `connectionsByFolderProvider(folderId)` les connexions d'un dossier.
