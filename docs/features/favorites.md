# Favoris

## Vue d'ensemble

Permet aux utilisateurs de marquer des points comme favoris pour un accès rapide. Les favoris peuvent être organisés en dossiers et les "super-favoris" s'affichent directement sur la liste des connexions.

## Fichiers concernés

### Écrans
- `lib/presentation/screens/favorites/favorites_screen.dart` - Gestion des favoris

### Widgets
- `lib/presentation/widgets/favorite_button.dart` - Bouton toggle favori
- `lib/presentation/widgets/favorite_folder_dialog.dart` - Création de dossier
- `lib/presentation/widgets/assign_folders_dialog.dart` - Assignation aux dossiers

### Providers
- `lib/application/providers/favorites_provider.dart` - CRUD favoris
- `lib/application/providers/favorite_folders_provider.dart` - Dossiers de favoris
- `lib/application/providers/super_favorites_provider.dart` - Super-favoris

### Database
- `lib/data/database/tables/favorites_table.dart` - Table Favorites
- `lib/data/database/tables/favorite_folders_table.dart` - Table FavoriteFolders
- `lib/data/database/tables/favorite_folder_assignments_table.dart` - Liaisons

## Classes/Providers clés

### FavoritesScreen
- **Fichier** : `favorites_screen.dart`
- **Rôle** : Liste et gestion des favoris
- **Features** :
  - Vue par dossiers ou liste plate
  - Création/édition de dossiers
  - Assignation de favoris aux dossiers
  - Tri drag & drop
  - Toggle super-favori (long press)
  - Navigation vers détail du point

### favoritesByConnectionProvider
- **Fichier** : `favorites_provider.dart`
- **Type** : `StreamProvider.family<List<Favorite>, int>`
- **Rôle** : Stream des favoris pour une connexion

### isFavoriteProvider
- **Fichier** : `favorites_provider.dart`
- **Type** : `StreamProvider.family<bool, ({int connectionId, String pointRef})>`
- **Rôle** : Vérifie si un point est favori

### favoriteFoldersProvider
- **Fichier** : `favorite_folders_provider.dart`
- **Type** : `StreamProvider.family<List<FavoriteFolder>, int>`
- **Rôle** : Dossiers de favoris pour une connexion

### superFavoritesProvider
- **Fichier** : `super_favorites_provider.dart`
- **Type** : `StreamProvider<Map<int, List<Favorite>>>`
- **Rôle** : Super-favoris groupés par connexion

## Flux de données

### Ajout d'un favori

```
PointDetailScreen (ou PointsScreen)
        │
        │ tap sur étoile
        ▼
FavoriteButton.onPressed()
        │
        ▼
db.toggleFavorite(
  connectionId: connectionId,
  pointRef: 'AV:1',
  pointName: 'Temperature',
  objectType: 'analog-value',
)
        │
        ├── Si existe → delete
        └── Si n'existe pas → insert
        │
        ▼
Stream update → UI rebuild
```

### Organisation en dossiers

```
FavoritesScreen
        │
        │ long press sur favori
        ▼
AssignFoldersDialog
        │
        │ sélectionner dossiers
        ▼
db.setFavoriteFolders(favoriteId, [folderId1, folderId2])
        │
        ├── Supprime anciennes assignations
        └── Insère nouvelles assignations
        │
        ▼
Stream update → UI rebuild
```

## Patterns importants

### Structure Favorite

```dart
class Favorite {
  final int id;
  final int connectionId;
  final String pointRef;        // "AV:1"
  final String pointName;
  final String? pointDescription;
  final String objectType;      // "analog-value"
  final int sortOrder;
  final bool isSuperFavorite;   // Affiché sur liste connexions
  final bool wasPromoted;       // Pour le cycle de promotion
}
```

### Cycle de promotion des favoris

Le cycle permet de promouvoir/rétrograder un favori :

1. **Favori normal** → Long press → **Super-favori**
2. **Super-favori** → Long press → **Favori normal** (wasPromoted = true)
3. **Favori rétrogradé** → Long press → **Supprimé**

```dart
Future<void> cycleFavoriteStatus(Favorite favorite) async {
  if (!favorite.isSuperFavorite && !favorite.wasPromoted) {
    // Promouvoir en super-favori
    await db.setSuperFavorite(favorite.id, true);
  } else if (favorite.isSuperFavorite) {
    // Rétrograder en favori normal
    await db.demoteSuperFavorite(favorite.id);
  } else {
    // Supprimer
    await db.deleteFavoriteById(favorite.id);
  }
}
```

### Dossiers de favoris

Les favoris peuvent appartenir à plusieurs dossiers (many-to-many) :

```dart
// Créer un dossier
await db.createFavoriteFolder(FavoriteFoldersCompanion(
  connectionId: Value(connectionId),
  name: Value('Températures'),
  color: Value('#FF5722'),
  icon: Value('thermostat'),
));

// Assigner un favori à des dossiers
await db.setFavoriteFolders(favoriteId, [folder1Id, folder2Id]);

// Récupérer favoris d'un dossier
final favs = await db.getFavoritesInFolder(folderId);

// Récupérer favoris sans dossier
final unassigned = await db.getUnassignedFavorites(connectionId);
```

### Super-favoris sur ConnectionsListScreen

Les super-favoris s'affichent sous chaque connexion dans la liste :

```dart
// Dans ConnectionsListScreen
final superFavsMap = ref.watch(superFavoritesProvider);

// Pour chaque connexion
final superFavs = superFavsMap[connection.id] ?? [];
if (superFavs.isNotEmpty) {
  // Afficher les chips avec valeurs live
}
```

### Widget FavoriteButton

Bouton réutilisable pour toggle favori :

```dart
FavoriteButton(
  connectionId: connectionId,
  pointRef: point.pointRef,
  pointName: point.name,
  objectType: point.type.apiName,
)
```

Le widget :
1. Watch `isFavoriteProvider` pour l'état
2. Affiche étoile pleine/vide
3. Sur tap, appelle `db.toggleFavorite()`

### Affichage des valeurs live

Dans FavoritesScreen, les valeurs sont rafraîchies périodiquement :

```dart
// Récupérer les valeurs actuelles des favoris
final points = await ref.read(allObjectsProvider.future);
final pointsMap = {for (var p in points) p.pointRef: p};

// Afficher avec valeur live
Text('${favorite.pointName}: ${pointsMap[favorite.pointRef]?.displayValue ?? '-'}')
```
