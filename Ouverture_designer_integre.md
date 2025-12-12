# Intégration WebView du Designer Envysion

## Contexte

L'objectif était d'afficher le synoptique Envysion (Designer intégré aux contrôleurs ECLYPSE) directement dans l'application via une WebView, plutôt que d'ouvrir le navigateur externe.

**Statut actuel** : Abandonné temporairement - ouverture dans le navigateur externe sur toutes les plateformes.

## Problème rencontré

### Symptômes observés

1. Erreurs SSL répétées : `net_error -202 (ERR_CERT_AUTHORITY_INVALID)`
2. Après login sur `/j_security_check`, redirection en boucle vers `/login.html`
3. Les cookies de session OIDC ne sont pas maintenus

### Cause racine : Certificat auto-signé + OIDC

Les contrôleurs ECLYPSE utilisent :
- Un **certificat SSL auto-signé** (non reconnu par Android)
- Une **authentification OIDC/J2EE** (pas simple HTTP Basic Auth)

#### Flux d'authentification OIDC

```
1. GET /envysion/viewer.html
   → 302 Redirect vers /login.html

2. POST /j_security_check (username/password)
   → Set-Cookie: JSESSIONID=xxx; Secure; HttpOnly
   → 302 Redirect vers /envysion/viewer.html

3. GET /envysion/viewer.html (avec cookie JSESSIONID)
   → 200 OK (page chargée)
```

#### Pourquoi les cookies sont rejetés

Le cookie `JSESSIONID` a les flags :
- **`Secure`** : Transmis uniquement sur HTTPS "valide" → certificat auto-signé = invalide pour Android
- **`HttpOnly`** : Non accessible en JavaScript (normal)
- **`SameSite`** : Peut bloquer les contextes WebView

Même si `onReceivedServerTrustAuthRequest` accepte le certificat pour le chargement de page, le **CookieManager Android** ne stocke pas les cookies venant d'une connexion SSL "non fiable".

```
┌─────────────────────────────────────────────────────────────┐
│                    WebView Android                          │
├─────────────────────────────────────────────────────────────┤
│  1. Charge /login.html         ✓ (certificat accepté)       │
│  2. POST /j_security_check     ✓ (formulaire envoyé)        │
│  3. Reçoit Set-Cookie          ✗ (SSL invalide → ignoré)    │
│  4. Redirect /envysion/        → Pas de cookie → /login.html│
└─────────────────────────────────────────────────────────────┘
```

### Pourquoi ça marche dans le navigateur externe

Chrome/Edge/Firefox ont un **magasin de certificats utilisateur** :
- L'utilisateur peut accepter le certificat une fois ("Continuer malgré le risque")
- Le navigateur mémorise cette exception
- Les cookies sont ensuite acceptés normalement

---

## Solutions possibles pour avoir un certificat valide

### Option 1 : Certificat CA d'entreprise (recommandé en entreprise)

Si l'organisation a une **PKI interne** (Active Directory Certificate Services, etc.) :

1. Générer un certificat signé par la CA d'entreprise pour l'ECLYPSE
2. Uploader le certificat sur le contrôleur (via EC-NetAX)
3. Déployer le certificat racine CA sur tous les appareils (GPO, MDM)

**Avantages** : Solution propre, tous les appareils du réseau font confiance
**Inconvénients** : Nécessite une infrastructure PKI, gestion des renouvellements

### Option 2 : Let's Encrypt (si accessible depuis Internet)

Si le contrôleur a un **nom DNS public** :

1. Configurer un DNS pointant vers l'ECLYPSE (ex: `eclypse-batiment-a.votredomaine.com`)
2. Utiliser certbot ou un reverse proxy pour obtenir un certificat Let's Encrypt
3. Uploader le certificat sur l'ECLYPSE

**Avantages** : Gratuit, reconnu par tous les navigateurs
**Inconvénients** :
- L'ECLYPSE doit être accessible depuis Internet (ou utiliser DNS-01 challenge)
- Renouvellement tous les 90 jours
- **Impossible pour les IP privées (192.168.x.x)**

### Option 3 : Reverse Proxy avec terminaison SSL

Mettre un **proxy** (nginx, Traefik, HAProxy) devant l'ECLYPSE :

```
┌─────────┐      HTTPS (cert valide)      ┌─────────────┐      HTTP/HTTPS      ┌─────────┐
│  Client │ ─────────────────────────────→│ Reverse     │ ───────────────────→ │ ECLYPSE │
│         │                               │ Proxy       │                      │         │
└─────────┘                               └─────────────┘                      └─────────┘
```

**Avantages** : L'ECLYPSE reste inchangé, centralisation des certificats
**Inconvénients** : Infrastructure supplémentaire à maintenir

### Option 4 : Atrius/Cloud Distech

Si vous utilisez **Atrius Building Insights** :
- La connexion passe par le cloud Distech (certificat valide)
- L'app se connecte au cloud → le cloud se connecte à l'ECLYPSE

**Avantages** : Pas de gestion de certificat, accès distant
**Inconvénients** : Dépendance au cloud, latence, abonnement

### Limitation des CA publiques

Les **CA publiques** (DigiCert, Comodo, Let's Encrypt) ne délivrent plus de certificats pour :
- Adresses IP privées (192.168.x.x, 10.x.x.x, 172.16-31.x.x)
- Noms d'hôtes locaux (.local, .lan)

Depuis 2015, c'est interdit par le CA/Browser Forum.

---

## Solution alternative : Installer le certificat sur Android

### Étape 1 : Récupérer le certificat de l'ECLYPSE

Depuis un PC, avec OpenSSL :

```bash
openssl s_client -connect 192.168.1.7:443 -showcerts </dev/null 2>/dev/null | openssl x509 -outform PEM > eclypse.crt
```

Ou via Chrome :
1. Aller sur `https://192.168.1.7`
2. Cliquer sur le cadenas → "Certificat non valide"
3. Onglet "Détails" → "Exporter" → Format PEM (.crt)

### Étape 2 : Transférer sur le mobile

- Par email (pièce jointe)
- Google Drive
- Câble USB

### Étape 3 : Installer sur Android

```
Paramètres
  → Sécurité (ou "Sécurité et confidentialité")
    → Autres paramètres de sécurité
      → Installer depuis stockage
        → Certificat CA
          → Sélectionner eclypse.crt
```

### Limitation Android 7+

Depuis **Android 7 (Nougat)**, les certificats CA installés par l'utilisateur ne sont **PAS** reconnus par défaut par les applications. Ils sont seulement reconnus par :
- Le navigateur Chrome
- Les apps qui ont explicitement activé le support via `networkSecurityConfig`

### Configuration requise dans l'app Flutter

#### 1. Créer le fichier `android/app/src/main/res/xml/network_security_config.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config>
        <trust-anchors>
            <certificates src="system"/>
            <certificates src="user"/>  <!-- Accepter les certificats utilisateur -->
        </trust-anchors>
    </base-config>
</network-security-config>
```

#### 2. Modifier `android/app/src/main/AndroidManifest.xml`

```xml
<application
    android:networkSecurityConfig="@xml/network_security_config"
    android:label="myglobaldc"
    ...>
```

#### 3. Rebuild l'application

```bash
flutter clean
flutter pub get
flutter run -d android
```

### Résumé de cette solution

| Avantage | Inconvénient |
|----------|--------------|
| WebView fonctionnerait | Config à faire sur chaque téléphone |
| Plus propre que navigateur externe | Certificat à installer manuellement |
| Session OIDC maintenue | Certificat à renouveler si l'ECLYPSE change |
| | Modification app + rebuild nécessaire |

---

## Fichiers concernés dans le projet

### Fichier WebView (existant mais non utilisé)

`lib/presentation/screens/synoptics/envysion_viewer_screen.dart`

Ce fichier contient l'implémentation complète de la WebView avec :
- Gestion de l'authentification HTTP Basic
- Acceptation des certificats auto-signés (`onReceivedServerTrustAuthRequest`)
- Gestion des cookies
- Indicateur de progression
- Fallback vers navigateur externe

### Navigation actuelle

`lib/presentation/screens/home/home_screen.dart`

La tuile "Synoptique Envysion" ouvre maintenant le navigateur externe via `url_launcher` au lieu de naviguer vers `EnvysionViewerScreen`.

---

## Pour réactiver la WebView intégrée

Si les certificats sont résolus (via une des solutions ci-dessus) :

1. Modifier `home_screen.dart` pour utiliser la route WebView :

```dart
// Dans _buildMenuGrid, changer :
_MenuItem(
  icon: hasEnvysion ? Icons.web : Icons.dashboard,
  title: hasEnvysion ? l10n.synopticEnvysion : 'Synoptique',
  color: Colors.teal.shade600,
  route: hasEnvysion ? Routes.envysionViewerPath(state.connection!.id) : Routes.synoptics,
  onTap: null,  // Supprimer le onTap
),
```

2. Faire de même dans le drawer

3. Tester sur Android avec le certificat installé + `network_security_config`

---

## Références

- [Android Network Security Configuration](https://developer.android.com/training/articles/security-config)
- [CA/Browser Forum Baseline Requirements](https://cabforum.org/baseline-requirements/)
- [flutter_inappwebview documentation](https://inappwebview.dev/docs/)
- [Distech Controls ECLYPSE API Documentation](docs_API_Distech/)
