# Synoptiques

## Vue d'ensemble

Diagrammes SVG interactifs représentant des plans de bâtiment ou schémas de régulation, avec des éléments liés à des points BACnet pour afficher les valeurs en temps réel.

## Fichiers concernés

### Écrans
- `lib/presentation/screens/synoptics/synoptics_list_screen.dart` - Liste des synoptiques
- `lib/presentation/screens/synoptics/synoptic_viewer_screen.dart` - Visualisation
- `lib/presentation/screens/synoptics/synoptic_editor_screen.dart` - Édition des liaisons

### Widgets
- `lib/presentation/widgets/circuit_regule_painter.dart` - Painter pour circuits HVAC

### Providers
- `lib/application/providers/synoptics_provider.dart` - CRUD synoptiques

### Database
- `lib/data/database/tables/synoptics_table.dart` - Table Synoptics
- `lib/data/database/tables/synoptic_bindings_table.dart` - Table SynopticBindings

## Classes/Providers clés

### SynopticsListScreen
- **Fichier** : `synoptics_list_screen.dart`
- **Rôle** : Liste des synoptiques disponibles
- **Features** :
  - Liste avec aperçu miniature
  - Import de fichier SVG
  - Création/renommage/suppression
  - Synoptiques globaux vs spécifiques à une connexion

### SynopticViewerScreen
- **Fichier** : `synoptic_viewer_screen.dart`
- **Paramètres** : `synopticId`
- **Rôle** : Affiche le synoptique avec valeurs live
- **Features** :
  - Rendu SVG avec flutter_svg
  - Valeurs dynamiques sur les bindings
  - Zoom et pan
  - Tap sur élément pour voir détail du point

### SynopticEditorScreen
- **Fichier** : `synoptic_editor_screen.dart`
- **Paramètres** : `synopticId`
- **Rôle** : Éditeur de liaisons SVG → points
- **Features** :
  - Sélection d'éléments SVG (tap)
  - Création de bindings vers points BACnet
  - Configuration du type de binding
  - Aperçu en temps réel

### synopticsProvider
- **Fichier** : `synoptics_provider.dart`
- **Type** : `StreamProvider<List<Synoptic>>`
- **Rôle** : Stream des synoptiques pour la connexion active

### synopticBindingsProvider
- **Fichier** : `synoptics_provider.dart`
- **Type** : `StreamProvider.family<List<SynopticBinding>, int>`
- **Rôle** : Liaisons d'un synoptique par ID

## Flux de données

### Import d'un SVG

```
SynopticsListScreen
        │
        │ tap "Import SVG"
        ▼
FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['svg'])
        │
        ▼
Lire le contenu du fichier
        │
        │ Encoder en base64
        ▼
db.createSynoptic(SynopticsCompanion(
  name: Value(fileName),
  svgData: Value(base64Encode(svgContent)),
  connectionId: Value(connectionId),  // ou null pour global
))
        │
        ▼
Stream update → UI rebuild
```

### Création d'un binding

```
SynopticEditorScreen
        │
        │ tap sur élément SVG
        ▼
Identifier l'élément (svgElementId)
        │
        │ Dialog: choisir point BACnet
        ▼
PointSelectionDialog
        │
        │ sélectionner point + type de binding
        ▼
db.upsertBinding(SynopticBindingsCompanion(
  synopticId: Value(synopticId),
  svgElementId: Value(elementId),
  pointRef: Value('AV:1'),
  pointName: Value('Temperature'),
  bindingType: Value(BindingType.text),
))
        │
        ▼
Stream update → Preview update
```

### Affichage avec valeurs live

```
SynopticViewerScreen
        │
        │ watches synopticBindingsProvider(synopticId)
        ▼
List<SynopticBinding>
        │
        │ Pour chaque binding, récupérer la valeur actuelle
        │ watches allObjectsProvider
        ▼
Map<String, BacnetObject> pointsMap
        │
        │ Appliquer les bindings au SVG
        ▼
flutter_svg avec transformations
```

## Types de bindings

### BindingType (enum)

| Type | Description | Usage |
|------|-------------|-------|
| `text` | Affiche la valeur comme texte | Températures, compteurs |
| `fill` | Change la couleur de remplissage | États on/off, alarmes |
| `visibility` | Montre/cache l'élément | États binaires |
| `animation` | Active/désactive animation | Ventilateurs, pompes |

### Configuration des bindings

Chaque binding peut avoir une configuration JSON pour personnaliser le comportement :

```dart
// Exemple pour binding type 'fill'
{
  "onColor": "#00FF00",   // Vert quand ON
  "offColor": "#FF0000",  // Rouge quand OFF
  "alarmColor": "#FFAA00" // Orange si alarme
}

// Exemple pour binding type 'text'
{
  "format": "%.1f",      // Format nombre
  "suffix": "°C",        // Suffixe après valeur
  "prefix": "T: "        // Préfixe avant valeur
}
```

## Patterns importants

### Structure Synoptic

```dart
class Synoptic {
  final int id;
  final int? connectionId;  // null = global, sinon spécifique
  final String name;
  final String? description;
  final String svgData;     // Contenu SVG encodé base64
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Structure SynopticBinding

```dart
class SynopticBinding {
  final int id;
  final int synopticId;
  final String svgElementId;  // ID de l'élément SVG (attribut id="...")
  final String pointRef;      // Référence BACnet "type:instance"
  final String? pointName;    // Nom pour affichage
  final BindingType bindingType;
  final String? configJson;   // Configuration spécifique
}
```

### Identification des éléments SVG

Pour qu'un élément soit bindable, il doit avoir un attribut `id` dans le SVG :

```xml
<text id="temp-bureau" x="100" y="50">--</text>
<rect id="status-chaudiere" x="200" y="100" width="20" height="20"/>
<g id="ventilateur-1">
  <circle cx="300" cy="150" r="15"/>
  <line x1="300" y1="135" x2="300" y2="165"/>
</g>
```

### Application des bindings au rendu

```dart
// Dans SynopticViewerScreen
Widget _buildSvgWithBindings(String svgData, List<SynopticBinding> bindings) {
  String processedSvg = svgData;

  for (final binding in bindings) {
    final point = pointsMap[binding.pointRef];
    if (point == null) continue;

    switch (binding.bindingType) {
      case BindingType.text:
        // Remplacer le contenu texte de l'élément
        processedSvg = _replaceTextContent(
          processedSvg,
          binding.svgElementId,
          point.displayValue,
        );
        break;

      case BindingType.fill:
        // Modifier l'attribut fill
        final color = _getColorForValue(point, binding.config);
        processedSvg = _setFillColor(
          processedSvg,
          binding.svgElementId,
          color,
        );
        break;

      // ... autres types
    }
  }

  return SvgPicture.string(processedSvg);
}
```

### Synoptiques globaux vs spécifiques

- **Global** (`connectionId = null`) : Disponible pour toutes les connexions, utile pour des schémas génériques
- **Spécifique** (`connectionId = X`) : Lié à une connexion particulière, les bindings utilisent les points de cette connexion

```dart
// Récupérer les synoptiques disponibles
final synoptics = await db.getSynopticsForConnection(connectionId);
// Retourne : globaux + spécifiques à cette connexion
```

### Circuit régulé painter

Le widget `CircuitRegulePainter` permet de dessiner des schémas HVAC standards :

```dart
CustomPaint(
  painter: CircuitRegulePainter(
    valvePosition: 75.0,      // 0-100%
    pumpRunning: true,
    supplyTemp: 45.2,
    returnTemp: 38.5,
  ),
)
```
