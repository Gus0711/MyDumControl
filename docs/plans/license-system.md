# Plan: Système de Licence Local avec Device-Binding (Option A)

## Objectif
Implémenter un système de licence hors-ligne qui limite le nombre de connexions.
Chaque licence est liée à un appareil spécifique (device-binding) pour éviter la duplication.

---

## Architecture Proposée

```
┌─────────────────────────────────────────────────────────────────┐
│                         FLUX UTILISATEUR                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. Première ouverture                                          │
│     └─► App génère Device ID unique (UUID)                      │
│         └─► Stocké dans flutter_secure_storage (immuable)       │
│                                                                 │
│  2. Utilisateur veut plus de connexions                         │
│     └─► Copie son Device ID depuis Settings                     │
│         └─► T'envoie par email/message                          │
│                                                                 │
│  3. Admin (toi) génère un code licence                          │
│     └─► Script CLI: dart run tool/license_generator.dart        │
│         └─► Input: Device ID + nb connexions + expiration       │
│         └─► Output: MYDC-05-2612-A7B3-XXXX (code signé)         │
│                                                                 │
│  4. Utilisateur entre le code dans Settings                     │
│     └─► App valide: signature + device ID match                 │
│         └─► Stocke licence active en secure storage             │
│         └─► Débloque les connexions supplémentaires             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Structure du Code Licence

```
MYDC-XX-YYMM-DDDD-SSSSSS
│    │   │    │    │
│    │   │    │    └─► Signature HMAC-SHA256 (6 chars)
│    │   │    └──────► Device ID tronqué (4 chars)
│    │   └───────────► Date expiration (année-mois)
│    └───────────────► Nombre connexions (01-99)
└────────────────────► Préfixe app
```

**Exemples** :
- `MYDC-05-2612-A7B3-K8M2P4` → 5 connexions, expire déc. 2026, device A7B3...
- `MYDC-99-9912-F2D1-X3N7Q1` → Illimité, expire déc. 2099

---

## Fichiers à Créer/Modifier

### 1. Nouveau Service de Licence
**Fichier**: `lib/data/services/license_service.dart`

```dart
class LicenseService {
  // Clé secrète pour signature (obfusquée)
  static const String _secretKey = '...';

  // Génère/récupère le Device ID unique
  Future<String> getDeviceId();

  // Valide un code licence
  LicenseValidationResult validateLicense(String code);

  // Stocke la licence active
  Future<void> storeLicense(License license);

  // Récupère la licence active
  Future<License?> getActiveLicense();

  // Vérifie si on peut ajouter une connexion
  Future<bool> canAddConnection(int currentCount);
}
```

### 2. Modèle License
**Fichier**: `lib/domain/models/license.dart`

```dart
@freezed
class License with _$License {
  const factory License({
    required String code,
    required int maxConnections,
    required DateTime expiresAt,
    required String deviceId,
    required DateTime activatedAt,
  }) = _License;
}

enum LicenseValidationResult {
  valid,
  invalidFormat,
  invalidSignature,
  deviceMismatch,
  expired,
}
```

### 3. Provider Licence
**Fichier**: `lib/application/providers/license_provider.dart`

```dart
// État de la licence
final licenseProvider = StateNotifierProvider<LicenseNotifier, LicenseState>;

// Nombre de connexions autorisées
final maxConnectionsProvider = Provider<int>;

// Peut ajouter une connexion?
final canAddConnectionProvider = FutureProvider<bool>;

// Device ID (pour affichage)
final deviceIdProvider = FutureProvider<String>;
```

### 4. Générateur de Licences (CLI)
**Fichier**: `tool/license_generator.dart`

Script Dart standalone pour générer des codes :
```bash
dart run tool/license_generator.dart --device=A7B3C9D2 --connections=10 --expires=2026-12
# Output: MYDC-10-2612-A7B3-XXXXXX
```

### 5. Modifications UI

**`lib/presentation/screens/settings/settings_screen.dart`**
- Nouvelle section "Licence" après "À propos"
- Affichage Device ID (avec bouton copier)
- Champ pour entrer code licence
- Statut: connexions utilisées / max
- Date d'expiration

**`lib/presentation/screens/connections/add_connection_screen.dart`**
- Vérifier `canAddConnectionProvider` avant d'autoriser l'ajout
- Afficher message si limite atteinte avec lien vers Settings

**`lib/presentation/screens/connections/connections_list_screen.dart`**
- Indicateur visuel "X/Y connexions" dans l'AppBar ou en bas

---

## Constantes et Configuration

**`lib/core/constants/license_constants.dart`**

```dart
class LicenseConstants {
  // Connexions gratuites (sans licence)
  static const int freeConnections = 1;

  // Préfixe des codes
  static const String codePrefix = 'MYDC';

  // Code spécial pour licence illimitée
  static const int unlimitedConnections = 99;  // 99 = illimité
  static const String unlimitedExpiry = '9912'; // Déc 2099 = pas d'expiration

  // Clés de stockage sécurisé
  static const String deviceIdKey = 'device_id';
  static const String licenseKey = 'active_license';
  static const String existingConnectionsCountKey = 'existing_connections_count';

  // Longueur signature
  static const int signatureLength = 6;
}
```

---

## Sécurité

### Stockage
- Device ID → `flutter_secure_storage` (généré une seule fois)
- Licence active → `flutter_secure_storage` (JSON chiffré)
- Clé secrète → Compilée dans l'app (obfuscation basique)

### Validation
- HMAC-SHA256 pour la signature
- Vérification device ID match
- Vérification date expiration
- Anti-bruteforce: 3 tentatives max, puis délai 1 min

### Limites acceptées
- Reverse-engineering possible (app locale)
- Suffisant pour usage B2B / clients de confiance

---

## Flux de Migration (Décision: Conserver tout)

### Utilisateurs existants
- Première ouverture après update : génération Device ID
- **Snapshot du nombre de connexions existantes** stocké en secure storage
- Connexions existantes conservées (pas de blocage rétroactif)
- Message informatif sur le nouveau système

### Logique de limite
```dart
int getAllowedConnections() {
  final existingCount = getExistingConnectionsCount(); // Snapshot initial
  final licenseMax = activeLicense?.maxConnections ?? 0;
  final freeMax = LicenseConstants.freeConnections; // 1

  // Le max est: existantes + max(free, licence)
  return existingCount + max(freeMax, licenseMax);
}
```

### Exemple concret
- User avait 5 connexions avant la mise à jour
- Sans licence: peut garder 5, peut en ajouter 1 (free) = **6 max**
- Avec licence 10: peut garder 5 + 10 nouvelles = **15 max**

### Mode Illimité (VIP)
- Code `MYDC-99-9912-XXXX` = 99 connexions, expire 2099
- Bypass complet de la limite

---

## Tests à Implémenter

1. **Unit tests** - `test/services/license_service_test.dart`
   - Validation format code
   - Validation signature
   - Validation device ID
   - Validation expiration

2. **Widget tests** - `test/screens/license_section_test.dart`
   - Affichage Device ID
   - Saisie code licence
   - Messages d'erreur

---

## Étapes d'Implémentation

1. [ ] Créer `license_constants.dart`
2. [ ] Créer modèle `license.dart` avec Freezed
3. [ ] Créer `license_service.dart`
4. [ ] Créer `license_provider.dart`
5. [ ] Créer script `tool/license_generator.dart`
6. [ ] Modifier `settings_screen.dart` (section Licence)
7. [ ] Modifier `add_connection_screen.dart` (vérification limite)
8. [ ] Modifier `connections_list_screen.dart` (indicateur)
9. [ ] Ajouter traductions (app_en.arb, app_fr.arb)
10. [ ] Tests unitaires
11. [ ] Run build_runner pour générer le code

---

## Questions Résolues

- **Limite gratuite**: 1 connexion par défaut (configurable)
- **Expiration**: Format année-mois (granularité mensuelle)
- **Device ID**: UUID v4 généré au premier lancement
- **Stockage**: flutter_secure_storage (déjà utilisé dans le projet)
