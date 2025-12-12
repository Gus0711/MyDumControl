# Base de données

## Vue d'ensemble

L'application utilise Drift (SQLite ORM) pour la persistance locale.

**Fichier principal** : `lib/data/database/app_database.dart`
**Version du schéma** : 11
**Nom du fichier** : `mydumcontrol.db`

## Tables

### Connections
Stocke les connexions aux contrôleurs.

| Colonne | Type | Description |
|---------|------|-------------|
| id | INTEGER | Clé primaire auto |
| name | TEXT | Nom affiché |
| host | TEXT | Adresse IP ou hostname |
| port | INTEGER | Port (défaut 443) |
| useHttps | BOOLEAN | HTTPS activé |
| username | TEXT | Identifiant |
| passwordKey | TEXT | Clé pour secure storage |
| apiVersion | TEXT? | 'v1' ou 'v2' (détecté) |
| connectionType | TEXT | 'distech_api' ou 'bacnet' |
| bacnetDeviceId | INTEGER? | Device ID BACnet |
| modelName | TEXT? | Modèle du contrôleur |
| certificateFingerprint | TEXT? | Empreinte TOFU |
| folderId | INTEGER? | FK vers Folders |
| lastConnectedAt | DATETIME? | Dernière connexion |
| createdAt | DATETIME | Date création |
| updatedAt | DATETIME | Date modification |

**Table** : `lib/data/database/tables/connections_table.dart`

### Folders
Organisation des connexions en dossiers.

| Colonne | Type | Description |
|---------|------|-------------|
| id | INTEGER | Clé primaire |
| name | TEXT | Nom du dossier |
| parentId | INTEGER? | FK parent (arborescence) |
| sortOrder | INTEGER | Ordre d'affichage |

**Table** : `lib/data/database/tables/folders_table.dart`

### Favorites
Points marqués comme favoris.

| Colonne | Type | Description |
|---------|------|-------------|
| id | INTEGER | Clé primaire |
| connectionId | INTEGER | FK vers Connections |
| pointRef | TEXT | Référence BACnet (ex: "AV:1") |
| pointName | TEXT | Nom du point |
| pointDescription | TEXT? | Description |
| objectType | TEXT | Type BACnet |
| sortOrder | INTEGER | Ordre d'affichage |
| isSuperFavorite | BOOLEAN | Affiché sur liste connexions |
| wasPromoted | BOOLEAN | Cycle de promotion |

**Table** : `lib/data/database/tables/favorites_table.dart`

### FavoriteFolders
Dossiers pour organiser les favoris.

| Colonne | Type | Description |
|---------|------|-------------|
| id | INTEGER | Clé primaire |
| connectionId | INTEGER | FK vers Connections |
| name | TEXT | Nom du dossier |
| color | TEXT? | Couleur hex |
| icon | TEXT? | Icône Material |
| sortOrder | INTEGER | Ordre d'affichage |

**Table** : `lib/data/database/tables/favorite_folders_table.dart`

### FavoriteFolderAssignments
Table de liaison favoris ↔ dossiers (many-to-many).

| Colonne | Type | Description |
|---------|------|-------------|
| id | INTEGER | Clé primaire |
| favoriteId | INTEGER | FK vers Favorites |
| folderId | INTEGER | FK vers FavoriteFolders |

**Table** : `lib/data/database/tables/favorite_folder_assignments_table.dart`

### Synoptics
Diagrammes SVG avec liaisons aux points.

| Colonne | Type | Description |
|---------|------|-------------|
| id | INTEGER | Clé primaire |
| connectionId | INTEGER? | FK (null = global) |
| name | TEXT | Nom du synoptique |
| description | TEXT? | Description |
| svgData | TEXT | Contenu SVG base64 |
| sortOrder | INTEGER | Ordre d'affichage |
| createdAt | DATETIME | Date création |
| updatedAt | DATETIME | Date modification |

**Table** : `lib/data/database/tables/synoptics_table.dart`

### SynopticBindings
Liaisons éléments SVG → points BACnet.

| Colonne | Type | Description |
|---------|------|-------------|
| id | INTEGER | Clé primaire |
| synopticId | INTEGER | FK vers Synoptics |
| svgElementId | TEXT | ID de l'élément SVG |
| pointRef | TEXT | Référence BACnet |
| pointName | TEXT? | Nom pour affichage |
| bindingType | ENUM | text, fill, visibility, animation |
| configJson | TEXT? | Configuration JSON |

**Table** : `lib/data/database/tables/synoptic_bindings_table.dart`

### Dashboards
Tableaux de bord personnalisés.

| Colonne | Type | Description |
|---------|------|-------------|
| id | INTEGER | Clé primaire |
| name | TEXT | Nom du dashboard |
| connectionId | INTEGER? | FK (null = global) |
| columns | INTEGER | Nombre de colonnes (défaut 2) |
| rows | INTEGER | Nombre de lignes (défaut 2) |
| sortOrder | INTEGER | Ordre d'affichage |
| createdAt | DATETIME | Date création |
| updatedAt | DATETIME | Date modification |

**Table** : `lib/data/database/tables/dashboard_tables.dart`

### DashboardWidgets
Widgets dans les dashboards.

| Colonne | Type | Description |
|---------|------|-------------|
| id | INTEGER | Clé primaire |
| dashboardId | INTEGER | FK vers Dashboards |
| position | INTEGER | Position dans la grille |
| widgetType | ENUM | singleTrendChart, multiCurveChart, statsCard |
| configJson | TEXT? | Configuration JSON |
| createdAt | DATETIME | Date création |

**Table** : `lib/data/database/tables/dashboard_tables.dart`

### Tables de cache

#### CachedPoints
| Colonne | Type |
|---------|------|
| connectionId | INTEGER |
| pointRef | TEXT |
| name | TEXT |
| description | TEXT? |
| objectType | TEXT |
| units | TEXT? |
| cachedAt | DATETIME |

#### CachedDeviceInfo
| Colonne | Type |
|---------|------|
| connectionId | INTEGER |
| infoJson | TEXT |
| cachedAt | DATETIME |

#### CachedTrendLogMapping
| Colonne | Type |
|---------|------|
| connectionId | INTEGER |
| mappingJson | TEXT |
| entryCount | INTEGER |
| cachedAt | DATETIME |

#### CachedObjectsSummary
| Colonne | Type |
|---------|------|
| connectionId | INTEGER |
| summaryJson | TEXT |
| cachedAt | DATETIME |

**Table** : `lib/data/database/tables/cache_tables.dart`

## Migrations

Les migrations sont gérées dans `app_database.dart` :

```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) => m.createAll(),
  onUpgrade: (m, from, to) async {
    if (from < 2) { /* Ajout folders */ }
    if (from < 3) { /* Ajout favorites */ }
    if (from < 4) { /* Ajout cache tables */ }
    if (from < 5) { /* Ajout isSuperFavorite */ }
    if (from < 6) { /* Ajout wasPromoted */ }
    if (from < 7) { /* Ajout favorite folders */ }
    if (from < 8) { /* Ajout synoptics */ }
    if (from < 9) { /* Ajout BACnet natif */ }
    if (from < 10) { /* Ajout modelName */ }
    if (from < 11) { /* Ajout dashboards */ }
  },
);
```

## Méthodes DAO principales

### Connexions
- `getAllConnections()` / `watchAllConnections()`
- `getConnectionById(id)`
- `insertConnection(companion)`
- `updateConnection(connection)`
- `deleteConnectionById(id)`
- `updateLastConnectedAt(id)`
- `updateApiVersion(id, version)`

### Favoris
- `getFavoritesByConnection(connectionId)` / `watchFavoritesByConnection()`
- `isFavorite(connectionId, pointRef)` / `watchIsFavorite()`
- `addFavorite(companion)` / `deleteFavorite(connectionId, pointRef)`
- `toggleFavorite(...)` - Ajoute ou supprime
- `toggleSuperFavorite(favoriteId)`
- `getSuperFavoritesByConnection(connectionId)`

### Dashboards
- `getDashboardsForConnection(connectionId)` / `watchDashboardsForConnection()`
- `createDashboard(name, connectionId, columns, rows)`
- `updateDashboard(id, name, columns, rows)`
- `deleteDashboard(id)`
- `getDashboardWidgets(dashboardId)` / `watchDashboardWidgets()`
- `addDashboardWidget(dashboardId, position, widgetType, configJson)`
- `updateDashboardWidget(widgetId, ...)`
- `deleteDashboardWidget(widgetId)`

### Synoptics
- `getSynopticsForConnection(connectionId)` / `watchSynopticsForConnection()`
- `createSynoptic(companion)`
- `deleteSynoptic(id)`
- `getBindingsForSynoptic(synopticId)` / `watchBindingsForSynoptic()`
- `upsertBinding(companion)`
- `deleteBinding(bindingId)`

### Cache
- `isPointsCacheValid(connectionId)`
- `getAllCachedPoints(connectionId)`
- `cachePoints(points)`
- `clearAllCache(connectionId)`
- `clearExpiredCache()`
