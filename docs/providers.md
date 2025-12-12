# Providers Riverpod

## Vue d'ensemble

L'application utilise Riverpod 2.x pour la gestion d'état. Les providers sont dans `lib/application/providers/`.

## Liste des providers

### Infrastructure

#### databaseProvider
- **Fichier** : `database_provider.dart`
- **Type** : `Provider<AppDatabase>`
- **Rôle** : Instance singleton de la base de données Drift

```dart
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});
```

#### apiServiceProvider
- **Fichier** : `api_provider.dart`
- **Type** : `Provider<ApiService?>`
- **Rôle** : Client HTTP configuré pour la connexion active
- **Dépend de** : `activeConnectionProvider`

#### cacheProvider
- **Fichier** : `cache_provider.dart`
- **Type** : `Provider<CacheService>`
- **Rôle** : Gestion du cache local

### Connexions

#### activeConnectionProvider
- **Fichier** : `active_connection_provider.dart`
- **Type** : `StateNotifierProvider<ActiveConnectionNotifier, ActiveConnectionState>`
- **Rôle** : Gère la connexion active (credentials, ApiService, état)
- **Méthodes** :
  - `connect(connectionId)` - Se connecter à un contrôleur
  - `disconnect()` - Se déconnecter
  - `refresh()` - Rafraîchir les données

#### connectionsStreamProvider
- **Fichier** : `connection_providers.dart`
- **Type** : `StreamProvider<List<Connection>>`
- **Rôle** : Stream temps-réel de toutes les connexions

#### connectionByIdProvider
- **Fichier** : `connection_providers.dart`
- **Type** : `FutureProvider.family<Connection?, int>`
- **Rôle** : Récupère une connexion par ID

### Dossiers

#### foldersProvider
- **Fichier** : `folder_providers.dart`
- **Type** : `StreamProvider<List<Folder>>`
- **Rôle** : Stream des dossiers de connexions

### Points BACnet

#### pointsProvider
- **Fichier** : `points_provider.dart`
- **Type** : `StateNotifierProvider<PointsNotifier, PointsState>`
- **Rôle** : Liste des points avec filtres, tri, recherche
- **Méthodes** :
  - `loadPoints()` - Charger tous les points
  - `setFilter(category, subType)` - Filtrer
  - `setSearch(query)` - Rechercher
  - `setSortOption(option)` - Trier
  - `refresh()` - Rafraîchir

#### pointDetailProvider
- **Fichier** : `points_provider.dart`
- **Type** : `FutureProvider.family<BacnetObject?, String>`
- **Rôle** : Détail d'un point par ID (format "type:instance")

#### allObjectsProvider
- **Fichier** : `points_provider.dart`
- **Type** : `FutureProvider<List<BacnetObject>>`
- **Rôle** : Tous les objets BACnet bruts

### BACnet Natif

#### bacnetServiceProvider
- **Fichier** : `bacnet_provider.dart`
- **Type** : `Provider<BacnetService>`
- **Rôle** : Service BACnet UDP singleton avec `keepAlive()` pour conserver le socket entre navigations
- **Dispose** : Ferme le socket à la destruction du provider

```dart
final bacnetServiceProvider = Provider<BacnetService>((ref) {
  final service = BacnetService();
  ref.keepAlive();
  ref.onDispose(() => service.dispose());
  return service;
});
```

#### activeBacnetConnectionProvider
- **Fichier** : `bacnet_provider.dart`
- **Type** : `StateProvider<ActiveBacnetConnection?>`
- **Rôle** : Stocke les infos de connexion BACnet active (host, port, deviceId)

```dart
class ActiveBacnetConnection {
  final int connectionId;
  final String host;
  final int port;
  final int? deviceId;
}
```

### Favoris

#### favoritesByConnectionProvider
- **Fichier** : `favorites_provider.dart`
- **Type** : `StreamProvider.family<List<Favorite>, int>`
- **Rôle** : Favoris d'une connexion en temps-réel

#### isFavoriteProvider
- **Fichier** : `favorites_provider.dart`
- **Type** : `StreamProvider.family<bool, ({int connectionId, String pointRef})>`
- **Rôle** : Un point est-il en favori ?

#### superFavoritesProvider
- **Fichier** : `super_favorites_provider.dart`
- **Type** : `StreamProvider<Map<int, List<Favorite>>>`
- **Rôle** : Super-favoris groupés par connexion

### Dossiers de favoris

#### favoriteFoldersProvider
- **Fichier** : `favorite_folders_provider.dart`
- **Type** : `StreamProvider.family<List<FavoriteFolder>, int>`
- **Rôle** : Dossiers de favoris pour une connexion

#### favoritesInFolderProvider
- **Fichier** : `favorite_folders_provider.dart`
- **Type** : `StreamProvider.family<List<Favorite>, int>`
- **Rôle** : Favoris dans un dossier

#### unassignedFavoritesProvider
- **Fichier** : `favorite_folders_provider.dart`
- **Type** : `StreamProvider.family<List<Favorite>, int>`
- **Rôle** : Favoris sans dossier

### Alarmes

#### alarmsProvider
- **Fichier** : `alarms_provider.dart`
- **Type** : `StateNotifierProvider<AlarmsNotifier, AlarmsState>`
- **Rôle** : Points en état d'alarme
- **Méthodes** :
  - `loadAlarms()` - Charger les alarmes
  - `refresh()` - Rafraîchir

### Schedules

#### schedulesProvider
- **Fichier** : `schedule_provider.dart`
- **Type** : `FutureProvider<List<ScheduleSummary>>`
- **Rôle** : Liste des schedules

#### scheduleDetailProvider
- **Fichier** : `schedule_provider.dart`
- **Type** : `FutureProvider.family<Schedule?, int>`
- **Rôle** : Détail d'un schedule par instance

### Trend Logs

#### trendLogMappingProvider
- **Fichier** : `trend_log_provider.dart`
- **Type** : `FutureProvider<Map<String, int>>`
- **Rôle** : Mapping "objectType:instance" → trendLogInstance

#### trendLogViewerProvider
- **Fichier** : `trend_log_provider.dart`
- **Type** : `StateNotifierProvider.family<TrendLogViewerNotifier, TrendLogViewerState, String>`
- **Rôle** : Chargement et affichage des données trend log
- **Méthodes** :
  - `loadData(startDate, endDate)` - Charger l'historique
  - `setDateRange(start, end)` - Changer la période

### Multi-Courbes

#### multiCurveViewerProvider
- **Fichier** : `multi_curve_provider.dart`
- **Type** : `StateNotifierProvider.family<MultiCurveViewerNotifier, MultiCurveViewerState, String>`
- **Rôle** : Données pour graphique multi-courbes
- **Méthodes** :
  - `initialize(trendLogInstances)` - Initialiser avec N trend logs
  - `loadData(startDate, endDate)` - Charger les données
  - `setDateRange(start, end)` - Changer la période

### Dashboards

#### dashboardsProvider
- **Fichier** : `dashboard_provider.dart`
- **Type** : `StreamProvider<List<Dashboard>>`
- **Rôle** : Liste des dashboards pour connexion active

#### dashboardByIdProvider
- **Fichier** : `dashboard_provider.dart`
- **Type** : `StreamProvider.family<Dashboard?, int>`
- **Rôle** : Un dashboard par ID

#### dashboardWidgetsProvider
- **Fichier** : `dashboard_provider.dart`
- **Type** : `StreamProvider.family<List<DashboardWidget>, int>`
- **Rôle** : Widgets d'un dashboard

### Synoptics

#### synopticsProvider
- **Fichier** : `synoptics_provider.dart`
- **Type** : `StreamProvider<List<Synoptic>>`
- **Rôle** : Synoptiques disponibles

#### synopticBindingsProvider
- **Fichier** : `synoptics_provider.dart`
- **Type** : `StreamProvider.family<List<SynopticBinding>, int>`
- **Rôle** : Liaisons d'un synoptique

### Settings

#### settingsProvider
- **Fichier** : `settings_provider.dart`
- **Type** : `StateNotifierProvider<SettingsNotifier, SettingsState>`
- **Rôle** : Paramètres de l'application
- **Méthodes** :
  - `setThemeMode(mode)` - Changer le thème
  - `setLanguage(locale)` - Changer la langue
  - `setPollingInterval(seconds)` - Intervalle de rafraîchissement

## Dépendances entre providers

```
activeConnectionProvider
        │
        ├── apiServiceProvider
        │         │
        │         └── pointsProvider
        │         │        │
        │         │        ├── alarmsProvider
        │         │        └── pointDetailProvider
        │         │
        │         ├── schedulesProvider
        │         │
        │         └── trendLogMappingProvider
        │                    │
        │                    └── trendLogViewerProvider
        │                              │
        │                              └── multiCurveViewerProvider
        │
        └── bacnetServiceProvider

databaseProvider
        │
        ├── connectionsStreamProvider
        ├── favoritesByConnectionProvider
        ├── dashboardsProvider
        └── synopticsProvider
```

## Patterns d'utilisation

### Lecture simple
```dart
final connection = ref.watch(activeConnectionProvider);
```

### Lecture avec family
```dart
final favorites = ref.watch(favoritesByConnectionProvider(connectionId));
```

### Action via notifier
```dart
ref.read(pointsProvider.notifier).setSearch('temperature');
```

### Invalidation
```dart
ref.invalidate(pointsProvider); // Force rechargement
```
