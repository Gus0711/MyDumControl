# MyGlobalDC - Documentation Technique

## Vue d'ensemble

MyGlobalDC est une application Flutter cross-platform pour la gestion des automates ECLYPSE de Distech Controls. Elle permet de se connecter aux contrôleurs via API REST (V1/V2) ou protocole BACnet/IP natif, de naviguer dans les points BACnet, de visualiser les tendances, de gérer les schedules et les favoris.

**Version** : 1.0.0
**Base de données** : Drift SQLite (schéma v11)
**Plateformes** : Android, iOS, Windows, macOS, Linux, Web

## Stack Technique

| Catégorie | Technologie |
|-----------|-------------|
| Framework | Flutter 3.x |
| State Management | Riverpod 2.x |
| Navigation | GoRouter |
| Base de données | Drift (SQLite) |
| HTTP Client | Dio |
| Sérialisation | Freezed + json_serializable |
| Stockage sécurisé | flutter_secure_storage |
| Charts | fl_chart |

## Commandes essentielles

```bash
# Installer les dépendances
flutter pub get

# Générer le code (Drift, Riverpod, Freezed)
dart run build_runner build --delete-conflicting-outputs

# Lancer l'application
flutter run -d windows  # ou linux, chrome, android

# Analyse du code
flutter analyze

# Tests
flutter test
```

## Table des matières

### Architecture & Infrastructure
- [Architecture](./architecture.md) - Clean Architecture, patterns, flux de données
- [Intégration API](./api-integration.md) - API V1/V2, BACnet, authentification
- [Base de données](./database.md) - Tables Drift, schéma v11, migrations
- [Providers](./providers.md) - Tous les providers Riverpod
- [Modèles](./models.md) - Modèles de domaine (BacnetObject, TrendLog, Schedule...)

### Fonctionnalités
- [BACnet/IP Natif](./features/bacnet-native.md) - Protocole BACnet/IP en Dart pur
- [Connexions](./features/connections.md) - Gestion connexions, découverte mDNS/BACnet
- [Navigation Points](./features/points-browsing.md) - Parcours des points BACnet
- [Favoris](./features/favorites.md) - Favoris, dossiers, super-favoris
- [Schedules](./features/schedules.md) - Horaires hebdomadaires
- [Trend Logs](./features/trend-logs.md) - Historiques, multi-courbes
- [Dashboards](./features/dashboards.md) - Tableaux de bord personnalisés
- [Synoptiques](./features/synoptics.md) - Diagrammes SVG avec bindings
- [Alarmes & Forçages](./features/alarms-overrides.md) - Alarmes, priority array

## Structure du projet

```
lib/
├── core/                  # Infrastructure
│   ├── constants/         # Constantes API, app
│   ├── router/            # GoRouter configuration
│   ├── theme/             # Couleurs, styles, thème
│   └── utils/             # Validateurs, platform info
├── data/                  # Couche données
│   ├── database/          # Drift tables et DAOs
│   └── services/          # ApiService, BacnetService, Cache
├── domain/                # Couche domaine
│   └── models/            # BacnetObject, TrendLog, Schedule...
├── application/           # Couche application
│   └── providers/         # Riverpod providers
└── presentation/          # Couche présentation
    ├── screens/           # Écrans (14 features)
    └── widgets/           # Widgets réutilisables
```

## Routes principales

| Route | Écran | Description |
|-------|-------|-------------|
| `/` | SplashScreen | Écran de démarrage |
| `/connections` | ConnectionsListScreen | Liste des connexions |
| `/home` | HomeScreen | Hub principal |
| `/points` | PointsScreen | Navigation points BACnet |
| `/points/:id` | PointDetailScreen | Détail d'un point |
| `/schedules` | SchedulesListScreen | Liste des schedules |
| `/favorites` | FavoritesScreen | Gestion favoris |
| `/dashboards` | DashboardListScreen | Liste dashboards |
| `/synoptics` | SynopticsListScreen | Liste synoptiques |
| `/alarms` | AlarmsScreen | Points en alarme |
| `/overrides` | OverridesScreen | Points forcés |
| `/settings` | SettingsScreen | Paramètres |
