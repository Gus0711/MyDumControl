# ECLYPSE Controller Management Application

## Architecture Complète et Plan de Développement

**Version:** 1.0  
**Date:** Novembre 2025  
**Objectif:** Remplacer MyDC Control avec support des API V1 et V2

---

## 1. Vue d'ensemble du projet

### 1.1 Contexte

L'application MyDC Control de Distech Controls n'est plus compatible avec la nouvelle génération d'automates ECLYPSE (séries 400, 600, APEX). Ce projet vise à créer une application alternative compatible avec :

- **API V1** : Ancienne génération ECLYPSE (ECY-S1000, ECY-VAV, etc.)
- **API V2** : Nouvelle génération ECLYPSE (400, 600 series, APEX avec Eclypse Facilities)

### 1.2 Plateformes cibles

| Plateforme | Technologie | Distribution |
|------------|-------------|--------------|
| Android | Flutter APK | Google Play Store |
| iOS | Flutter IPA | Apple App Store |
| Linux | Flutter Desktop | AppImage / .deb |
| Windows | Flutter Desktop | MSIX / .exe |
| macOS | Flutter Desktop | .dmg |
| Web (SaaS) | Flutter Web | Hébergement cloud |

### 1.3 Contraintes techniques majeures

1. **Certificats auto-signés** : Les automates ECLYPSE utilisent HTTPS avec certificats auto-signés
2. **Authentification** : HTTP Basic Authentication
3. **Mode hors ligne** : L'application doit fonctionner sans internet sur réseau local
4. **Multi-API** : Support simultané des deux versions d'API

---

## 2. Architecture technique

### 2.1 Architecture globale (Option B)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│                        APPLICATION FLUTTER UNIQUE                            │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                         PRESENTATION LAYER                              │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌────────────┐  │ │
│  │  │   Screens    │  │   Widgets    │  │ Controllers  │  │   State    │  │ │
│  │  │  (Pages)     │  │ (Components) │  │  (Riverpod)  │  │  Notifiers │  │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  └────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                      │                                       │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                         APPLICATION LAYER                               │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌────────────┐  │ │
│  │  │  Use Cases   │  │   Services   │  │  Providers   │  │  Mappers   │  │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  └────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                      │                                       │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                           DOMAIN LAYER                                  │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌────────────┐  │ │
│  │  │   Entities   │  │ Repositories │  │  Value Obj.  │  │ Exceptions │  │ │
│  │  │   (Models)   │  │ (Interfaces) │  │              │  │            │  │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  └────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                      │                                       │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                            DATA LAYER                                   │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌────────────┐  │ │
│  │  │  Remote DS   │  │  Local DS    │  │  Repository  │  │    DTOs    │  │ │
│  │  │  (API V1/V2) │  │   (Drift)    │  │    Impl.     │  │            │  │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  └────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                      │                                       │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                           CORE LAYER                                    │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌────────────┐  │ │
│  │  │   Network    │  │ Certificate  │  │   Platform   │  │   Utils    │  │ │
│  │  │   Manager    │  │   Manager    │  │   Detector   │  │            │  │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  └────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                       │
           ┌───────────────────────────┼───────────────────────────┐
           │                           │                           │
           ▼                           ▼                           ▼
    ┌─────────────┐            ┌─────────────┐            ┌─────────────┐
    │   Mobile/   │            │   Desktop   │            │     Web     │
    │   Desktop   │            │   (Linux)   │            │   (SaaS)    │
    │             │            │             │            │             │
    │  Connexion  │            │  Connexion  │            │  Connexion  │
    │   DIRECTE   │            │   DIRECTE   │            │  via PROXY  │
    └──────┬──────┘            └──────┬──────┘            └──────┬──────┘
           │                           │                           │
           ▼                           ▼                           ▼
    ┌─────────────┐            ┌─────────────┐            ┌─────────────┐
    │  Automate   │            │  Automate   │            │   Backend   │
    │  ECLYPSE    │            │  ECLYPSE    │            │   Proxy     │
    │  (HTTPS)    │            │  (HTTPS)    │            │  (Node.js)  │
    └─────────────┘            └─────────────┘            └──────┬──────┘
                                                                  │
                                                                  ▼
                                                           ┌─────────────┐
                                                           │  Automate   │
                                                           │  ECLYPSE    │
                                                           └─────────────┘
```

### 2.2 Flux de connexion selon la plateforme

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         CONNEXION MANAGER                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  if (kIsWeb) {                                                               │
│    // Version Web → Toujours via le proxy backend                            │
│    return ProxyConnectionStrategy();                                         │
│  } else {                                                                    │
│    // Version Native → Connexion directe avec gestion certificats            │
│    return DirectConnectionStrategy();                                        │
│  }                                                                           │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                    SCÉNARIOS DE CONNEXION SUPPORTÉS                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  1. RÉSEAU LOCAL (LAN)                                                       │
│     └─→ IP directe (192.168.x.x) + certificat auto-signé                    │
│                                                                              │
│  2. VPN                                                                      │
│     └─→ IP privée via tunnel VPN + certificat auto-signé                    │
│                                                                              │
│  3. INTERNET PUBLIC                                                          │
│     └─→ Domaine/IP publique + certificat (auto-signé ou valide)             │
│                                                                              │
│  4. CLOUD RELAY (Atrius)                                                     │
│     └─→ OAuth2 Bearer Token + Azure IoT Hub                                 │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Structure du projet Flutter

### 3.1 Arborescence des fichiers

```
eclypse_controller/
├── android/                          # Configuration Android
├── ios/                              # Configuration iOS
├── linux/                            # Configuration Linux Desktop
├── macos/                            # Configuration macOS Desktop
├── windows/                          # Configuration Windows Desktop
├── web/                              # Configuration Web
│
├── lib/
│   ├── main.dart                     # Point d'entrée
│   ├── app.dart                      # Configuration MaterialApp
│   │
│   ├── core/                         # Fonctionnalités transversales
│   │   ├── constants/
│   │   │   ├── api_constants.dart
│   │   │   ├── app_constants.dart
│   │   │   └── ui_constants.dart
│   │   │
│   │   ├── errors/
│   │   │   ├── exceptions.dart
│   │   │   └── failures.dart
│   │   │
│   │   ├── network/
│   │   │   ├── api_client.dart              # Client HTTP Dio configuré
│   │   │   ├── api_client_factory.dart      # Factory selon plateforme
│   │   │   ├── certificate_manager.dart     # Gestion certificats auto-signés
│   │   │   ├── network_info.dart            # Détection connectivité
│   │   │   └── interceptors/
│   │   │       ├── auth_interceptor.dart
│   │   │       ├── logging_interceptor.dart
│   │   │       └── error_interceptor.dart
│   │   │
│   │   ├── platform/
│   │   │   ├── platform_detector.dart       # Détection Web/Native
│   │   │   └── platform_config.dart
│   │   │
│   │   ├── router/
│   │   │   ├── app_router.dart              # Configuration GoRouter
│   │   │   └── routes.dart
│   │   │
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   ├── app_colors.dart
│   │   │   └── app_text_styles.dart
│   │   │
│   │   └── utils/
│   │       ├── date_utils.dart
│   │       ├── string_utils.dart
│   │       └── validators.dart
│   │
│   ├── data/                          # Couche données
│   │   ├── datasources/
│   │   │   ├── local/
│   │   │   │   ├── database/
│   │   │   │   │   ├── app_database.dart    # Configuration Drift
│   │   │   │   │   ├── tables/
│   │   │   │   │   │   ├── connections_table.dart
│   │   │   │   │   │   ├── favorites_table.dart
│   │   │   │   │   │   ├── points_cache_table.dart
│   │   │   │   │   │   └── alarms_cache_table.dart
│   │   │   │   │   └── daos/
│   │   │   │   │       ├── connections_dao.dart
│   │   │   │   │       └── cache_dao.dart
│   │   │   │   └── preferences/
│   │   │   │       └── app_preferences.dart
│   │   │   │
│   │   │   └── remote/
│   │   │       ├── eclypse_api_v1.dart      # Implémentation API V1
│   │   │       ├── eclypse_api_v2.dart      # Implémentation API V2
│   │   │       ├── api_adapter.dart         # Adaptateur unifié
│   │   │       └── dto/
│   │   │           ├── v1/
│   │   │           │   ├── point_dto.dart
│   │   │           │   ├── alarm_dto.dart
│   │   │           │   └── schedule_dto.dart
│   │   │           └── v2/
│   │   │               ├── point_dto.dart
│   │   │               ├── alarm_dto.dart
│   │   │               └── schedule_dto.dart
│   │   │
│   │   ├── models/                    # Modèles de données
│   │   │   ├── connection_model.dart
│   │   │   ├── point_model.dart
│   │   │   ├── alarm_model.dart
│   │   │   ├── schedule_model.dart
│   │   │   ├── pid_loop_model.dart
│   │   │   └── device_info_model.dart
│   │   │
│   │   └── repositories/              # Implémentations repositories
│   │       ├── connection_repository_impl.dart
│   │       ├── points_repository_impl.dart
│   │       ├── alarms_repository_impl.dart
│   │       └── schedules_repository_impl.dart
│   │
│   ├── domain/                        # Couche métier
│   │   ├── entities/
│   │   │   ├── connection.dart
│   │   │   ├── point.dart
│   │   │   ├── alarm.dart
│   │   │   ├── schedule.dart
│   │   │   ├── pid_loop.dart
│   │   │   └── device_info.dart
│   │   │
│   │   ├── repositories/              # Interfaces repositories
│   │   │   ├── connection_repository.dart
│   │   │   ├── points_repository.dart
│   │   │   ├── alarms_repository.dart
│   │   │   └── schedules_repository.dart
│   │   │
│   │   └── usecases/
│   │       ├── connection/
│   │       │   ├── connect_to_controller.dart
│   │       │   ├── disconnect_controller.dart
│   │       │   ├── test_connection.dart
│   │       │   └── save_connection.dart
│   │       ├── points/
│   │       │   ├── get_all_points.dart
│   │       │   ├── get_point_value.dart
│   │       │   ├── set_point_value.dart
│   │       │   └── override_point.dart
│   │       ├── alarms/
│   │       │   ├── get_active_alarms.dart
│   │       │   └── acknowledge_alarm.dart
│   │       └── schedules/
│   │           ├── get_schedules.dart
│   │           └── update_schedule.dart
│   │
│   ├── application/                   # Couche application (state)
│   │   ├── providers/
│   │   │   ├── core_providers.dart          # Providers de base
│   │   │   ├── connection_providers.dart
│   │   │   ├── points_providers.dart
│   │   │   ├── alarms_providers.dart
│   │   │   └── schedules_providers.dart
│   │   │
│   │   └── notifiers/
│   │       ├── connection_notifier.dart
│   │       ├── points_notifier.dart
│   │       ├── alarms_notifier.dart
│   │       └── navigation_notifier.dart
│   │
│   └── presentation/                  # Couche UI
│       ├── screens/
│       │   ├── splash/
│       │   │   └── splash_screen.dart
│       │   │
│       │   ├── connections/
│       │   │   ├── connections_list_screen.dart
│       │   │   ├── add_connection_screen.dart
│       │   │   ├── edit_connection_screen.dart
│       │   │   └── widgets/
│       │   │       ├── connection_card.dart
│       │   │       └── connection_form.dart
│       │   │
│       │   ├── home/
│       │   │   ├── home_screen.dart         # Dashboard principal
│       │   │   └── widgets/
│       │   │       ├── menu_grid.dart
│       │   │       └── menu_item.dart
│       │   │
│       │   ├── points/
│       │   │   ├── points_screen.dart
│       │   │   ├── point_detail_screen.dart
│       │   │   └── widgets/
│       │   │       ├── points_tab_bar.dart
│       │   │       ├── point_list_item.dart
│       │   │       └── point_value_editor.dart
│       │   │
│       │   ├── alarms/
│       │   │   ├── alarms_screen.dart
│       │   │   └── widgets/
│       │   │       ├── alarm_list_item.dart
│       │   │       └── alarm_detail_sheet.dart
│       │   │
│       │   ├── schedules/
│       │   │   ├── schedules_screen.dart
│       │   │   ├── schedule_detail_screen.dart
│       │   │   └── widgets/
│       │   │       ├── schedule_card.dart
│       │   │       └── weekly_schedule_view.dart
│       │   │
│       │   ├── overrides/
│       │   │   ├── overrides_screen.dart
│       │   │   └── widgets/
│       │   │       └── override_list_item.dart
│       │   │
│       │   ├── favorites/
│       │   │   ├── favorites_screen.dart
│       │   │   └── widgets/
│       │   │       └── favorite_item.dart
│       │   │
│       │   ├── pid_loops/
│       │   │   ├── pid_loops_screen.dart
│       │   │   └── widgets/
│       │   │       └── pid_loop_chart.dart
│       │   │
│       │   └── settings/
│       │       ├── settings_screen.dart
│       │       └── device_info_screen.dart
│       │
│       └── shared/
│           ├── widgets/
│           │   ├── app_drawer.dart
│           │   ├── loading_indicator.dart
│           │   ├── error_widget.dart
│           │   ├── empty_state.dart
│           │   ├── connection_status_bar.dart
│           │   └── refresh_indicator.dart
│           │
│           └── dialogs/
│               ├── confirm_dialog.dart
│               ├── error_dialog.dart
│               └── certificate_trust_dialog.dart
│
├── backend_proxy/                     # Backend proxy pour Web (SaaS)
│   ├── package.json
│   ├── src/
│   │   ├── index.ts
│   │   ├── routes/
│   │   │   └── proxy.routes.ts
│   │   ├── middleware/
│   │   │   ├── auth.middleware.ts
│   │   │   └── cors.middleware.ts
│   │   └── services/
│   │       └── eclypse-proxy.service.ts
│   └── Dockerfile
│
├── api_specs/                         # Fichiers JSON des API Distech
│   ├── eclypse_api_v1.json
│   └── eclypse_api_v2.json
│
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
│
├── docs/
│   ├── architecture.md
│   ├── api_mapping.md
│   └── deployment.md
│
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

## 4. Dépendances Flutter (pubspec.yaml)

```yaml
name: eclypse_controller
description: Application de gestion des automates ECLYPSE Distech Controls
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Navigation
  go_router: ^14.2.0

  # Network
  dio: ^5.4.3+1
  connectivity_plus: ^6.0.3

  # Local Database
  drift: ^2.18.0
  drift_flutter: ^0.1.0
  sqlite3_flutter_libs: ^0.5.21

  # Storage
  shared_preferences: ^2.2.3
  flutter_secure_storage: ^9.0.0

  # UI
  flutter_svg: ^2.0.10+1
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  fl_chart: ^0.68.0              # Pour les graphiques PID
  
  # Utils
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0
  equatable: ^2.0.5
  dartz: ^0.10.1                 # Pour Either/Option
  intl: ^0.19.0
  logger: ^2.3.0
  uuid: ^4.4.0
  
  # Platform detection
  universal_platform: ^1.0.0+1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  
  # Code generation
  build_runner: ^2.4.9
  riverpod_generator: ^2.4.0
  freezed: ^2.5.2
  json_serializable: ^6.8.0
  drift_dev: ^2.18.0
  
  # Testing
  mocktail: ^1.0.3
  bloc_test: ^9.1.7

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/icons/
    - assets/fonts/
```

---

## 5. Implémentation des composants clés

### 5.1 Gestion des certificats auto-signés

```dart
// lib/core/network/certificate_manager.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Gestionnaire de certificats pour accepter les certificats auto-signés
/// des automates ECLYPSE
class CertificateManager {
  final FlutterSecureStorage _secureStorage;
  
  // Cache des empreintes de certificats de confiance (TOFU - Trust On First Use)
  final Map<String, String> _trustedCertificates = {};

  CertificateManager({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Initialise le gestionnaire en chargeant les certificats de confiance
  Future<void> initialize() async {
    final stored = await _secureStorage.read(key: 'trusted_certificates');
    if (stored != null) {
      final Map<String, dynamic> data = jsonDecode(stored);
      _trustedCertificates.addAll(data.cast<String, String>());
    }
  }

  /// Callback pour valider les certificats
  /// Retourne true si le certificat est accepté
  bool validateCertificate(X509Certificate cert, String host, int port) {
    // Calculer l'empreinte SHA-256 du certificat
    final fingerprint = _calculateFingerprint(cert);
    final hostKey = '$host:$port';

    // Vérifier si ce certificat est déjà de confiance
    if (_trustedCertificates.containsKey(hostKey)) {
      return _trustedCertificates[hostKey] == fingerprint;
    }

    // Première connexion - Trust On First Use (TOFU)
    // Dans une vraie app, on afficherait une dialog pour confirmer
    return true;
  }

  /// Ajoute un certificat à la liste de confiance
  Future<void> trustCertificate(String host, int port, X509Certificate cert) async {
    final fingerprint = _calculateFingerprint(cert);
    final hostKey = '$host:$port';
    
    _trustedCertificates[hostKey] = fingerprint;
    await _persistTrustedCertificates();
  }

  /// Supprime un certificat de la liste de confiance
  Future<void> revokeTrust(String host, int port) async {
    final hostKey = '$host:$port';
    _trustedCertificates.remove(hostKey);
    await _persistTrustedCertificates();
  }

  /// Calcule l'empreinte SHA-256 du certificat
  String _calculateFingerprint(X509Certificate cert) {
    final bytes = cert.der;
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Persiste les certificats de confiance
  Future<void> _persistTrustedCertificates() async {
    await _secureStorage.write(
      key: 'trusted_certificates',
      value: jsonEncode(_trustedCertificates),
    );
  }
}
```

### 5.2 Client API avec support certificats

```dart
// lib/core/network/api_client_factory.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

class ApiClientFactory {
  final CertificateManager _certificateManager;

  ApiClientFactory(this._certificateManager);

  /// Crée un client Dio configuré selon la plateforme
  Dio createClient({
    required String baseUrl,
    required String username,
    required String password,
    bool acceptSelfSignedCerts = true,
  }) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    // Authentification Basic
    final credentials = base64Encode(utf8.encode('$username:$password'));
    dio.options.headers['Authorization'] = 'Basic $credentials';

    // Configuration selon la plateforme
    if (kIsWeb) {
      // Version Web - pas d'accès direct aux certificats
      // Les requêtes passent par le proxy backend
      _configureForWeb(dio);
    } else {
      // Version Native - gestion des certificats auto-signés
      _configureForNative(dio, acceptSelfSignedCerts);
    }

    // Intercepteurs communs
    dio.interceptors.addAll([
      LoggingInterceptor(),
      ErrorInterceptor(),
    ]);

    return dio;
  }

  void _configureForWeb(Dio dio) {
    // Pour le web, on préfixe les requêtes avec l'URL du proxy
    // Le proxy sera configuré dans l'environnement
    const proxyBaseUrl = String.fromEnvironment(
      'PROXY_URL',
      defaultValue: 'https://api.eclypse-controller.com/proxy',
    );
    
    dio.options.baseUrl = proxyBaseUrl;
  }

  void _configureForNative(Dio dio, bool acceptSelfSignedCerts) {
    if (acceptSelfSignedCerts) {
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) {
          return _certificateManager.validateCertificate(cert, host, port);
        };
        return client;
      };
    }
  }
}
```

### 5.3 Adaptateur API unifié (V1 et V2)

```dart
// lib/data/datasources/remote/api_adapter.dart

import 'package:dartz/dartz.dart';

/// Type d'API ECLYPSE
enum EclypseApiVersion { v1, v2 }

/// Interface unifiée pour les deux versions d'API
abstract class EclypseApiAdapter {
  /// Version de l'API
  EclypseApiVersion get version;

  /// Récupère les informations du device
  Future<Either<Failure, DeviceInfo>> getDeviceInfo();

  /// Récupère tous les points (entrées/sorties)
  Future<Either<Failure, List<Point>>> getAllPoints();

  /// Récupère la valeur d'un point spécifique
  Future<Either<Failure, PointValue>> getPointValue(String pointId);

  /// Définit la valeur d'un point
  Future<Either<Failure, void>> setPointValue(String pointId, dynamic value);

  /// Override un point
  Future<Either<Failure, void>> overridePoint(String pointId, dynamic value, {Duration? duration});

  /// Libère l'override d'un point
  Future<Either<Failure, void>> releaseOverride(String pointId);

  /// Récupère les alarmes actives
  Future<Either<Failure, List<Alarm>>> getActiveAlarms();

  /// Acquitte une alarme
  Future<Either<Failure, void>> acknowledgeAlarm(String alarmId);

  /// Récupère les schedules
  Future<Either<Failure, List<Schedule>>> getSchedules();

  /// Met à jour un schedule
  Future<Either<Failure, void>> updateSchedule(Schedule schedule);

  /// Récupère les boucles PID
  Future<Either<Failure, List<PidLoop>>> getPidLoops();

  /// Récupère l'historique (trends)
  Future<Either<Failure, List<TrendData>>> getTrendData(
    String objectId,
    DateTime start,
    DateTime end,
  );
}

/// Factory pour créer l'adaptateur approprié
class ApiAdapterFactory {
  /// Détecte la version de l'API et crée l'adaptateur correspondant
  static Future<EclypseApiAdapter> createAdapter({
    required Dio client,
    required String baseUrl,
  }) async {
    // Essayer d'abord l'API V2
    try {
      final response = await client.get('/api/rest/v2/info');
      if (response.statusCode == 200) {
        return EclypseApiV2Adapter(client);
      }
    } catch (_) {}

    // Fallback sur l'API V1
    try {
      final response = await client.get('/api/rest/v1/info');
      if (response.statusCode == 200) {
        return EclypseApiV1Adapter(client);
      }
    } catch (_) {}

    throw ApiVersionDetectionException('Impossible de détecter la version de l\'API');
  }
}
```

### 5.4 Implémentation API V1

```dart
// lib/data/datasources/remote/eclypse_api_v1.dart

class EclypseApiV1Adapter implements EclypseApiAdapter {
  final Dio _client;

  EclypseApiV1Adapter(this._client);

  @override
  EclypseApiVersion get version => EclypseApiVersion.v1;

  @override
  Future<Either<Failure, DeviceInfo>> getDeviceInfo() async {
    try {
      final response = await _client.get('/api/rest/v1/info/device');
      final dto = DeviceInfoDtoV1.fromJson(response.data);
      return Right(dto.toEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    }
  }

  @override
  Future<Either<Failure, List<Point>>> getAllPoints() async {
    try {
      // API V1 : récupérer les objets BACnet locaux
      final response = await _client.get(
        '/api/rest/v1/protocols/bacnet/local/objects',
        queryParameters: {
          '\$filter': 'objectType in (analog-input, analog-output, binary-input, binary-output)',
        },
      );
      
      final List<dynamic> data = response.data;
      final points = data.map((json) => PointDtoV1.fromJson(json).toEntity()).toList();
      return Right(points);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    }
  }

  @override
  Future<Either<Failure, PointValue>> getPointValue(String pointId) async {
    try {
      // pointId format: "objectType/objectInstance" (ex: "analog-input/1")
      final parts = pointId.split('/');
      final objectType = parts[0];
      final objectInstance = parts[1];

      final response = await _client.get(
        '/api/rest/v1/protocols/bacnet/local/objects/$objectType/$objectInstance/properties/present-value',
      );

      return Right(PointValue(
        pointId: pointId,
        value: response.data['value'],
        timestamp: DateTime.now(),
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    }
  }

  @override
  Future<Either<Failure, void>> setPointValue(String pointId, dynamic value) async {
    try {
      final parts = pointId.split('/');
      final objectType = parts[0];
      final objectInstance = parts[1];

      await _client.post(
        '/api/rest/v1/protocols/bacnet/local/objects/$objectType/$objectInstance/properties/present-value',
        data: {'value': value},
      );

      return const Right(null);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    }
  }

  @override
  Future<Either<Failure, List<Alarm>>> getActiveAlarms() async {
    try {
      final response = await _client.get('/api/rest/v1/alarms');
      final List<dynamic> data = response.data['alarms'] ?? [];
      final alarms = data.map((json) => AlarmDtoV1.fromJson(json).toEntity()).toList();
      return Right(alarms);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    }
  }

  @override
  Future<Either<Failure, List<Schedule>>> getSchedules() async {
    try {
      final response = await _client.get(
        '/api/rest/v1/protocols/bacnet/local/objects',
        queryParameters: {
          '\$filter': 'objectType eq schedule',
        },
      );

      final List<dynamic> data = response.data;
      final schedules = <Schedule>[];

      for (final item in data) {
        final objectInstance = item['objectInstance'];
        
        // Récupérer le weekly-schedule
        final weeklyResponse = await _client.get(
          '/api/rest/v1/protocols/bacnet/local/objects/schedule/$objectInstance/properties/weekly-schedule',
        );
        
        schedules.add(ScheduleDtoV1.fromJson({
          ...item,
          'weeklySchedule': weeklyResponse.data,
        }).toEntity());
      }

      return Right(schedules);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    }
  }

  Failure _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutFailure();
      case DioExceptionType.connectionError:
        return ConnectionFailure();
      case DioExceptionType.badResponse:
        return ServerFailure(e.response?.statusCode ?? 500, e.message ?? '');
      default:
        return UnknownFailure(e.message ?? 'Erreur inconnue');
    }
  }
}
```

### 5.5 Base de données locale (Drift)

```dart
// lib/data/datasources/local/database/app_database.dart

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

/// Table des connexions sauvegardées
class Connections extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get host => text()();
  IntColumn get port => integer().withDefault(const Constant(443))();
  TextColumn get username => text()();
  TextColumn get password => text()(); // Sera chiffré
  TextColumn get platform => text().withDefault(const Constant('REST'))(); // REST, EC-Net
  TextColumn get mode => text().withDefault(const Constant('HTTPS'))(); // HTTPS, HTTP
  TextColumn get apiVersion => text().nullable()(); // v1, v2, null = auto-detect
  TextColumn get certificateFingerprint => text().nullable()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastConnected => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Table des favoris
class Favorites extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get connectionId => integer().references(Connections, #id)();
  TextColumn get pointId => text()();
  TextColumn get pointName => text()();
  TextColumn get pointType => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Table de cache des points
class PointsCache extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get connectionId => integer().references(Connections, #id)();
  TextColumn get pointId => text()();
  TextColumn get pointName => text()();
  TextColumn get objectType => text()();
  TextColumn get lastValue => text().nullable()();
  TextColumn get unit => text().nullable()();
  TextColumn get status => text().nullable()();
  DateTimeColumn get lastUpdated => dateTime()();
}

/// Table de cache des alarmes
class AlarmsCache extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get connectionId => integer().references(Connections, #id)();
  TextColumn get alarmId => text()();
  TextColumn get source => text()();
  TextColumn get message => text()();
  TextColumn get severity => text()();
  TextColumn get state => text()();
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get acknowledged => boolean().withDefault(const Constant(false))();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Connections, Favorites, PointsCache, AlarmsCache])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Migrations futures ici
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'eclypse_controller.db'));
    return NativeDatabase.createInBackground(file);
  });
}
```

### 5.6 Providers Riverpod

```dart
// lib/application/providers/core_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'core_providers.g.dart';

/// Provider de la base de données
@Riverpod(keepAlive: true)
AppDatabase appDatabase(AppDatabaseRef ref) {
  return AppDatabase();
}

/// Provider du gestionnaire de certificats
@Riverpod(keepAlive: true)
Future<CertificateManager> certificateManager(CertificateManagerRef ref) async {
  final manager = CertificateManager();
  await manager.initialize();
  return manager;
}

/// Provider de la factory de clients API
@riverpod
Future<ApiClientFactory> apiClientFactory(ApiClientFactoryRef ref) async {
  final certManager = await ref.watch(certificateManagerProvider.future);
  return ApiClientFactory(certManager);
}

/// Provider de vérification de la connectivité réseau
@riverpod
Stream<bool> networkConnectivity(NetworkConnectivityRef ref) {
  return Connectivity().onConnectivityChanged.map((result) {
    return result != ConnectivityResult.none;
  });
}
```

```dart
// lib/application/providers/connection_providers.dart

part 'connection_providers.g.dart';

/// État de connexion actuelle
@riverpod
class CurrentConnection extends _$CurrentConnection {
  @override
  AsyncValue<ConnectionState> build() {
    return const AsyncValue.data(ConnectionState.disconnected());
  }

  Future<void> connect(Connection connection) async {
    state = const AsyncValue.loading();
    
    try {
      final factory = await ref.read(apiClientFactoryProvider.future);
      final client = factory.createClient(
        baseUrl: 'https://${connection.host}:${connection.port}',
        username: connection.username,
        password: connection.password,
      );

      // Détecter la version de l'API
      final adapter = await ApiAdapterFactory.createAdapter(
        client: client,
        baseUrl: 'https://${connection.host}:${connection.port}',
      );

      // Vérifier la connexion
      final deviceInfo = await adapter.getDeviceInfo();
      
      deviceInfo.fold(
        (failure) => state = AsyncValue.error(failure, StackTrace.current),
        (info) => state = AsyncValue.data(ConnectionState.connected(
          connection: connection,
          adapter: adapter,
          deviceInfo: info,
        )),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void disconnect() {
    state = const AsyncValue.data(ConnectionState.disconnected());
  }
}

/// Liste des connexions sauvegardées
@riverpod
Future<List<Connection>> savedConnections(SavedConnectionsRef ref) async {
  final db = ref.watch(appDatabaseProvider);
  final rows = await db.select(db.connections).get();
  return rows.map((row) => Connection.fromDb(row)).toList();
}

/// Provider pour sauvegarder une connexion
@riverpod
class ConnectionRepository extends _$ConnectionRepository {
  @override
  FutureOr<void> build() {}

  Future<void> saveConnection(Connection connection) async {
    final db = ref.read(appDatabaseProvider);
    await db.into(db.connections).insert(connection.toCompanion());
    ref.invalidate(savedConnectionsProvider);
  }

  Future<void> deleteConnection(int id) async {
    final db = ref.read(appDatabaseProvider);
    await (db.delete(db.connections)..where((t) => t.id.equals(id))).go();
    ref.invalidate(savedConnectionsProvider);
  }
}
```

```dart
// lib/application/providers/points_providers.dart

part 'points_providers.g.dart';

/// Points de l'automate connecté
@riverpod
Future<List<Point>> points(PointsRef ref) async {
  final connectionState = ref.watch(currentConnectionProvider);
  
  return connectionState.when(
    data: (state) async {
      if (!state.isConnected) return [];
      
      final result = await state.adapter!.getAllPoints();
      return result.fold(
        (failure) => throw failure,
        (points) => points,
      );
    },
    loading: () => [],
    error: (e, st) => throw e,
  );
}

/// Points filtrés par type
@riverpod
List<Point> filteredPoints(FilteredPointsRef ref, PointType type) {
  final allPoints = ref.watch(pointsProvider);
  
  return allPoints.when(
    data: (points) => points.where((p) => p.type == type).toList(),
    loading: () => [],
    error: (e, st) => [],
  );
}

/// Valeur d'un point spécifique (avec auto-refresh)
@riverpod
Stream<PointValue> pointValue(PointValueRef ref, String pointId) async* {
  final connectionState = ref.watch(currentConnectionProvider).value;
  if (connectionState == null || !connectionState.isConnected) return;

  // Polling toutes les 5 secondes
  while (true) {
    final result = await connectionState.adapter!.getPointValue(pointId);
    yield* Stream.value(result.fold(
      (failure) => throw failure,
      (value) => value,
    ));
    await Future.delayed(const Duration(seconds: 5));
  }
}
```

---

## 6. Backend Proxy (pour version Web/SaaS)

### 6.1 Structure du projet Node.js

```
backend_proxy/
├── package.json
├── tsconfig.json
├── Dockerfile
├── docker-compose.yml
├── .env.example
│
└── src/
    ├── index.ts
    ├── config/
    │   └── config.ts
    ├── routes/
    │   ├── index.ts
    │   ├── proxy.routes.ts
    │   └── health.routes.ts
    ├── middleware/
    │   ├── auth.middleware.ts
    │   ├── cors.middleware.ts
    │   ├── rate-limit.middleware.ts
    │   └── error.middleware.ts
    ├── services/
    │   └── eclypse-proxy.service.ts
    └── utils/
        └── logger.ts
```

### 6.2 Package.json

```json
{
  "name": "eclypse-controller-proxy",
  "version": "1.0.0",
  "description": "Proxy backend pour l'application ECLYPSE Controller (SaaS)",
  "main": "dist/index.js",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "lint": "eslint src/**/*.ts"
  },
  "dependencies": {
    "express": "^4.19.2",
    "axios": "^1.7.2",
    "https-proxy-agent": "^7.0.4",
    "cors": "^2.8.5",
    "helmet": "^7.1.0",
    "express-rate-limit": "^7.2.0",
    "winston": "^3.13.0",
    "dotenv": "^16.4.5"
  },
  "devDependencies": {
    "@types/express": "^4.17.21",
    "@types/cors": "^2.8.17",
    "@types/node": "^20.12.12",
    "typescript": "^5.4.5",
    "tsx": "^4.11.0",
    "eslint": "^9.3.0"
  }
}
```

### 6.3 Service Proxy

```typescript
// src/services/eclypse-proxy.service.ts

import axios, { AxiosInstance, AxiosRequestConfig } from 'axios';
import https from 'https';
import { logger } from '../utils/logger';

interface ProxyRequest {
  targetUrl: string;      // URL complète de l'automate (https://192.168.1.x:443)
  method: string;
  path: string;           // Chemin API (ex: /api/rest/v1/info)
  username: string;
  password: string;
  data?: any;
  queryParams?: Record<string, string>;
}

export class EclypseProxyService {
  private createClient(targetUrl: string, username: string, password: string): AxiosInstance {
    // Agent HTTPS qui accepte les certificats auto-signés
    const httpsAgent = new https.Agent({
      rejectUnauthorized: false, // Accepte les certificats auto-signés
    });

    const credentials = Buffer.from(`${username}:${password}`).toString('base64');

    return axios.create({
      baseURL: targetUrl,
      httpsAgent,
      timeout: 30000,
      headers: {
        'Authorization': `Basic ${credentials}`,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    });
  }

  async proxyRequest(request: ProxyRequest): Promise<any> {
    const client = this.createClient(request.targetUrl, request.username, request.password);

    const config: AxiosRequestConfig = {
      method: request.method as any,
      url: request.path,
      params: request.queryParams,
      data: request.data,
    };

    try {
      logger.info(`Proxying ${request.method} ${request.targetUrl}${request.path}`);
      const response = await client.request(config);
      return {
        status: response.status,
        data: response.data,
        headers: response.headers,
      };
    } catch (error: any) {
      logger.error(`Proxy error: ${error.message}`);
      
      if (error.response) {
        return {
          status: error.response.status,
          data: error.response.data,
          error: error.message,
        };
      }
      
      throw error;
    }
  }
}

export const eclypseProxyService = new EclypseProxyService();
```

### 6.4 Routes du Proxy

```typescript
// src/routes/proxy.routes.ts

import { Router, Request, Response, NextFunction } from 'express';
import { eclypseProxyService } from '../services/eclypse-proxy.service';
import { authMiddleware } from '../middleware/auth.middleware';

const router = Router();

// Toutes les routes du proxy nécessitent une authentification
router.use(authMiddleware);

/**
 * Route générique de proxy
 * POST /proxy
 * 
 * Body:
 * {
 *   "targetUrl": "https://192.168.1.100:443",
 *   "method": "GET",
 *   "path": "/api/rest/v1/info",
 *   "username": "admin",
 *   "password": "xxx",
 *   "data": {},          // optionnel
 *   "queryParams": {}    // optionnel
 * }
 */
router.post('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { targetUrl, method, path, username, password, data, queryParams } = req.body;

    // Validation
    if (!targetUrl || !method || !path || !username || !password) {
      return res.status(400).json({
        error: 'Missing required fields: targetUrl, method, path, username, password',
      });
    }

    const result = await eclypseProxyService.proxyRequest({
      targetUrl,
      method,
      path,
      username,
      password,
      data,
      queryParams,
    });

    res.status(result.status).json(result.data);
  } catch (error) {
    next(error);
  }
});

/**
 * Route de test de connexion
 * POST /proxy/test-connection
 */
router.post('/test-connection', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { targetUrl, username, password } = req.body;

    // Tester avec les deux versions d'API
    let apiVersion = null;
    let deviceInfo = null;

    // Essayer V2
    try {
      const v2Result = await eclypseProxyService.proxyRequest({
        targetUrl,
        method: 'GET',
        path: '/api/rest/v2/info',
        username,
        password,
      });
      if (v2Result.status === 200) {
        apiVersion = 'v2';
        deviceInfo = v2Result.data;
      }
    } catch {}

    // Essayer V1 si V2 échoue
    if (!apiVersion) {
      try {
        const v1Result = await eclypseProxyService.proxyRequest({
          targetUrl,
          method: 'GET',
          path: '/api/rest/v1/info',
          username,
          password,
        });
        if (v1Result.status === 200) {
          apiVersion = 'v1';
          deviceInfo = v1Result.data;
        }
      } catch {}
    }

    if (apiVersion) {
      res.json({
        success: true,
        apiVersion,
        deviceInfo,
      });
    } else {
      res.status(400).json({
        success: false,
        error: 'Unable to connect to the controller',
      });
    }
  } catch (error) {
    next(error);
  }
});

export default router;
```

### 6.5 Point d'entrée du serveur

```typescript
// src/index.ts

import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import dotenv from 'dotenv';

import proxyRoutes from './routes/proxy.routes';
import healthRoutes from './routes/health.routes';
import { errorMiddleware } from './middleware/error.middleware';
import { logger } from './utils/logger';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware de sécurité
app.use(helmet());

// CORS - Autoriser l'application Flutter Web
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:8080'],
  credentials: true,
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000, // limite par IP
});
app.use(limiter);

// Body parser
app.use(express.json());

// Routes
app.use('/health', healthRoutes);
app.use('/proxy', proxyRoutes);

// Error handling
app.use(errorMiddleware);

app.listen(PORT, () => {
  logger.info(`🚀 ECLYPSE Proxy Server running on port ${PORT}`);
});
```

### 6.6 Dockerfile

```dockerfile
# Dockerfile
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY dist ./dist

EXPOSE 3000

CMD ["node", "dist/index.js"]
```

---

## 7. Fonctionnalités détaillées

### 7.1 Liste des fonctionnalités (basées sur MyDC Control)

| # | Fonctionnalité | Priorité | Description |
|---|----------------|----------|-------------|
| 1 | **Gestion des connexions** | P0 | Ajouter, modifier, supprimer des connexions aux automates |
| 2 | **Points (I/O)** | P0 | Afficher entrées/sorties physiques et analogiques |
| 3 | **Lecture valeurs** | P0 | Lire les valeurs en temps réel des points |
| 4 | **Écriture valeurs** | P0 | Modifier les valeurs des points |
| 5 | **Overrides** | P1 | Forcer temporairement une valeur |
| 6 | **Alarmes** | P0 | Liste des alarmes actives |
| 7 | **Acquittement alarmes** | P1 | Acquitter les alarmes |
| 8 | **Horaires (Schedules)** | P1 | Afficher et modifier les schedules BACnet |
| 9 | **Favoris** | P2 | Accès rapide aux points favoris |
| 10 | **Boucles PID** | P2 | Visualisation des paramètres PID |
| 11 | **Trends** | P2 | Historique des valeurs (graphiques) |
| 12 | **Info appareil** | P1 | Informations sur l'automate connecté |
| 13 | **Multi-connexions** | P1 | Gérer plusieurs automates |
| 14 | **Mode hors ligne** | P1 | Cache local des données |
| 15 | **Notifications** | P3 | Push notifications pour alarmes |

### 7.2 Écrans de l'application

```
┌─────────────────────────────────────────────────────────────────┐
│                         NAVIGATION                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  SPLASH SCREEN                                                   │
│       │                                                          │
│       ▼                                                          │
│  CONNEXIONS LIST ◄────────────────────┐                         │
│       │                               │                          │
│       ├─── ADD CONNECTION             │                          │
│       │         │                     │                          │
│       │         ▼                     │                          │
│       │    CONNECTION FORM            │                          │
│       │                               │                          │
│       ▼                               │                          │
│  HOME (Dashboard) ────────────────────┘                         │
│       │                                                          │
│       ├─── POINTS ─────┬── Physical Inputs                      │
│       │                ├── Physical Outputs                      │
│       │                └── Analog Values                         │
│       │                                                          │
│       ├─── ALARMS ─────── Alarm Details                         │
│       │                                                          │
│       ├─── SCHEDULES ──── Schedule Details                      │
│       │                                                          │
│       ├─── OVERRIDES                                             │
│       │                                                          │
│       ├─── FAVORITES                                             │
│       │                                                          │
│       ├─── PID LOOPS ──── PID Details + Chart                   │
│       │                                                          │
│       └─── SETTINGS ───┬── Device Info                          │
│                        └── App Settings                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 8. Plan de développement

### Phase 1 : Foundation (2-3 semaines)

- [ ] Setup projet Flutter avec architecture clean
- [ ] Configuration des dépendances
- [ ] Implémentation du core (network, certificates, platform detection)
- [ ] Base de données locale (Drift)
- [ ] Thème et composants UI de base

### Phase 2 : Connexions (1-2 semaines)

- [ ] Écran liste des connexions
- [ ] Formulaire ajout/modification connexion
- [ ] Test de connexion
- [ ] Détection automatique version API
- [ ] Gestion des certificats auto-signés

### Phase 3 : API V1 (2-3 semaines)

- [ ] Implémentation complète de l'adaptateur V1
- [ ] Mapping des endpoints (basé sur le fichier JSON)
- [ ] Écran Points avec tabs (Entrées physiques, Sorties, Valeurs analogiques)
- [ ] Lecture/écriture des valeurs
- [ ] Écran Alarmes

### Phase 4 : API V2 (2-3 semaines)

- [ ] Implémentation complète de l'adaptateur V2
- [ ] Mapping des endpoints (basé sur le fichier JSON)
- [ ] Tests de compatibilité
- [ ] Ajustements UI si nécessaire

### Phase 5 : Fonctionnalités avancées (2-3 semaines)

- [ ] Horaires (Schedules)
- [ ] Overrides
- [ ] Favoris
- [ ] Boucles PID avec graphiques
- [ ] Info appareil

### Phase 6 : Mode hors ligne (1-2 semaines)

- [ ] Cache des points
- [ ] Cache des alarmes
- [ ] Sync automatique
- [ ] Indicateur de statut connexion

### Phase 7 : Backend Proxy (1 semaine)

- [ ] Développement du proxy Node.js
- [ ] Déploiement (Docker)
- [ ] Configuration Flutter Web pour utiliser le proxy

### Phase 8 : Tests & Polish (2 semaines)

- [ ] Tests unitaires
- [ ] Tests d'intégration
- [ ] Tests sur toutes les plateformes
- [ ] Optimisations performances
- [ ] Documentation

### Phase 9 : Déploiement (1 semaine)

- [ ] Build Android (APK, Play Store)
- [ ] Build iOS (IPA, App Store)
- [ ] Build Desktop (Linux, Windows, macOS)
- [ ] Déploiement Web (SaaS)

---

## 9. Mapping API - À compléter avec les fichiers JSON

### 9.1 Structure attendue des fichiers JSON

Claude Code aura besoin des fichiers JSON des API Distech pour :

1. **Mapper les endpoints** vers les fonctionnalités de l'app
2. **Générer les DTOs** automatiquement
3. **Documenter les différences** entre V1 et V2

### 9.2 Endpoints critiques à mapper

| Fonctionnalité | Endpoint V1 (attendu) | Endpoint V2 (attendu) |
|----------------|----------------------|----------------------|
| Info device | `/api/rest/v1/info/device` | `/api/rest/v2/info/device` |
| Liste points | `/api/rest/v1/protocols/bacnet/local/objects` | `/api/rest/v2/...` |
| Valeur point | `/api/rest/v1/protocols/bacnet/local/objects/{type}/{instance}/properties/present-value` | TBD |
| Alarmes | `/api/rest/v1/alarms` | TBD |
| Schedules | `/api/rest/v1/protocols/bacnet/local/objects/schedule/{id}/properties/weekly-schedule` | TBD |

---

## 10. Commandes pour démarrer avec Claude Code

```bash
# 1. Créer le projet Flutter
flutter create --org com.yourcompany eclypse_controller
cd eclypse_controller

# 2. Activer les plateformes desktop
flutter config --enable-linux-desktop
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop

# 3. Installer les dépendances (après avoir modifié pubspec.yaml)
flutter pub get

# 4. Générer le code (Drift, Riverpod, Freezed)
dart run build_runner build --delete-conflicting-outputs

# 5. Lancer en mode développement
flutter run -d linux  # ou chrome, android, ios, etc.
```

---

## 11. Ressources

### Documentation Distech

- Wiki API V1 : https://wiki.distech-controls.com/RestAPI
- Wiki API V2 : https://wiki.distech-controls.com/ (section V2)
- Postman Collections : https://www.postman.com/distech/distech-ecy-v2-public/

### Documentation technique

- Flutter : https://docs.flutter.dev/
- Riverpod : https://riverpod.dev/
- Drift : https://drift.simonbinder.eu/
- Go Router : https://pub.dev/packages/go_router
- Dio : https://pub.dev/packages/dio

---

**Document préparé pour le développement avec Claude Code**

*Placez les fichiers `eclypse_api_v1.json` et `eclypse_api_v2.json` dans le dossier `api_specs/` pour que Claude Code puisse mapper les endpoints.*