# Architecture

## Clean Architecture (4 couches)

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION                              │
│  Screens, Widgets, Controllers                               │
│  lib/presentation/                                           │
└──────────────────────────┬──────────────────────────────────┘
                           │ watches
┌──────────────────────────▼──────────────────────────────────┐
│                    APPLICATION                               │
│  Riverpod Providers & StateNotifiers                         │
│  lib/application/providers/                                  │
└──────────────────────────┬──────────────────────────────────┘
                           │ uses
┌──────────────────────────▼──────────────────────────────────┐
│                      DOMAIN                                  │
│  Models, Entities (BacnetObject, TrendLog, Schedule...)      │
│  lib/domain/models/                                          │
└──────────────────────────┬──────────────────────────────────┘
                           │ implements
┌──────────────────────────▼──────────────────────────────────┐
│                       DATA                                   │
│  Services (API, BACnet), Database (Drift), Cache             │
│  lib/data/                                                   │
└─────────────────────────────────────────────────────────────┘
```

## Structure des dossiers

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart      # Noms, versions, timeouts
│   │   └── api_constants.dart      # Endpoints, propriétés BACnet
│   ├── router/
│   │   ├── app_router.dart         # Configuration GoRouter
│   │   ├── routes.dart             # Constantes de routes
│   │   └── page_transitions.dart   # Animations de transition
│   ├── theme/
│   │   ├── app_theme.dart          # ThemeData Material 3
│   │   ├── app_colors.dart         # Palette de couleurs
│   │   └── app_text_styles.dart    # Styles typographiques
│   └── utils/
│       ├── validators.dart         # Validation IP, port, etc.
│       ├── platform_info.dart      # Détection plateforme
│       └── logger.dart             # Configuration logging
├── data/
│   ├── database/
│   │   ├── app_database.dart       # Database principale + DAOs
│   │   ├── app_database.g.dart     # Code généré Drift
│   │   └── tables/                 # Définitions des tables
│   └── services/
│       ├── api_service.dart        # Client HTTP Distech
│       ├── bacnet_service.dart     # Client BACnet/IP UDP
│       ├── cache_service.dart      # Gestion du cache
│       └── bacnet/                 # Encoders/decoders BACnet
├── domain/
│   └── models/
│       ├── bacnet_object.dart      # Point BACnet complet
│       ├── trend_log.dart          # Trend logs et records
│       ├── schedule.dart           # Schedules hebdomadaires
│       ├── favorite.dart           # Favoris utilisateur
│       └── multi_curve_chart.dart  # Config multi-courbes
├── application/
│   └── providers/                  # 18+ providers Riverpod
└── presentation/
    ├── screens/                    # 14 features (écrans)
    └── widgets/                    # Composants réutilisables
```

## Patterns Riverpod

### StateNotifierProvider
Pour état mutable avec logique complexe :
```dart
// points_provider.dart
final pointsProvider = StateNotifierProvider<PointsNotifier, PointsState>((ref) {
  return PointsNotifier(ref);
});
```

### FutureProvider
Pour chargement async one-shot :
```dart
// schedule_provider.dart
final scheduleDetailProvider = FutureProvider.family<Schedule?, int>((ref, instance) async {
  final api = ref.watch(apiServiceProvider);
  return api.getScheduleDetail(instance);
});
```

### StreamProvider
Pour données temps-réel :
```dart
// connection_providers.dart
final connectionsStreamProvider = StreamProvider<List<Connection>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllConnections();
});
```

### Provider.family
Pour données paramétrées :
```dart
// trend_log_provider.dart
final trendLogViewerProvider = StateNotifierProvider.family<TrendLogViewerNotifier, TrendLogViewerState, String>(...);
```

## Flux de données typique

```
User Tap (UI)
     │
     ▼
WidgetRef.read(provider.notifier).doAction()
     │
     ▼
StateNotifier méthode
     │
     ├─► ApiService / BacnetService (réseau)
     │         │
     │         ▼
     │   Controller ECLYPSE / BACnet device
     │
     └─► AppDatabase (persistance locale)
           │
           ▼
     State update → UI rebuild
```

## Navigation (GoRouter)

**Fichier** : `lib/core/router/app_router.dart`

Routes principales :
- `/` → SplashScreen
- `/connections` → ConnectionsListScreen
- `/connections/add` → AddConnectionScreen
- `/connections/edit/:id` → AddConnectionScreen (mode édition)
- `/home?connectionId=X` → HomeScreen
- `/points` → PointsScreen
- `/points/:id` → PointDetailScreen
- `/schedules` → SchedulesListScreen
- `/schedules/:instance` → ScheduleDetailScreen
- `/favorites` → FavoritesScreen
- `/dashboards` → DashboardListScreen
- `/dashboards/:id` → DashboardScreen
- `/synoptics` → SynopticsListScreen
- `/synoptics/:id` → SynopticViewerScreen
- `/synoptics/:id/edit` → SynopticEditorScreen

## Gestion d'état connexion active

La connexion active est gérée par `activeConnectionProvider` :

```dart
// Récupérer la connexion active
final connection = ref.watch(activeConnectionProvider);

// Récupérer l'ApiService configuré
final api = ref.watch(apiServiceProvider);

// Vérifier si connecté
final isConnected = connection != null;
```

Le provider maintient :
- `Connection?` : infos de la connexion (host, port, credentials)
- `ApiService` : client HTTP configuré avec auth
- `BacnetService?` : client UDP si connexion BACnet native
