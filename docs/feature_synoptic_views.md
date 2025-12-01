# Fonctionnalité : Vues Synoptiques

## Concept

Permettre à l'utilisateur de créer des **vues visuelles personnalisées** en associant des points BACnet à des schémas standardisés (circuit régulé, CTA, chaudière, etc.).

```
┌─────────────────────────────────────┐
│  Circuit Régulé - Chauffage Nord    │
│  ┌─────────────────────────────┐    │
│  │     [🌡️ 45.2°C]              │    │  ← Temp départ
│  │         ┃                   │    │
│  │    ═══[🔧 67%]═══           │    │  ← Vanne 3 voies
│  │         ┃                   │    │
│  │     [⚡ Marche]              │    │  ← Pompe
│  │         ┃                   │    │
│  │     [🌡️ 38.1°C]              │    │  ← Temp retour
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
```

## Approche technique : Templates avec slots prédéfinis

Chaque template SVG a des emplacements ("slots") prédéfinis où l'utilisateur associe ses points.

### Avantages
- Simple à utiliser (pas de drag & drop complexe)
- Templates professionnels prêts à l'emploi
- Slots typés (filtre les points compatibles)
- Plus rapide à développer

---

## Modèles de données

### Template de synoptique (assets statiques)

```dart
/// Définition d'un template de synoptique (statique, dans le code)
class SynopticTemplate {
  final String id;              // "circuit_regule"
  final String name;            // "Circuit régulé"
  final String description;     // "Circuit de chauffage/refroidissement avec vanne 3 voies"
  final String svgAsset;        // "assets/synoptics/circuit_regule.svg"
  final String category;        // "Hydraulique", "Aéraulique", "Production"
  final List<SlotDefinition> slots;

  const SynopticTemplate({...});
}

/// Définition d'un slot dans un template
class SlotDefinition {
  final String id;              // "temp_depart"
  final String label;           // "Température départ"
  final String? hint;           // "Sonde sur le départ du circuit"
  final SlotType type;          // analog, binary, multistate
  final double x;               // Position X en % (0.0 à 1.0)
  final double y;               // Position Y en % (0.0 à 1.0)
  final bool required;          // Slot obligatoire ?

  const SlotDefinition({...});
}

enum SlotType {
  analog,      // AI, AO, AV - affiche valeur numérique
  binary,      // BI, BO, BV - affiche état On/Off
  multistate,  // MSI, MSO, MSV - affiche état texte
  any,         // Tous types acceptés
}
```

### Vue synoptique utilisateur (stockée en BDD)

```dart
/// Vue synoptique créée par l'utilisateur (stockée dans Drift)
class SynopticView {
  final int id;
  final int connectionId;       // Lié à quel automate
  final String templateId;      // "circuit_regule"
  final String name;            // "Chauffage Nord"
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Association slot -> point (stockée dans Drift)
class SlotBinding {
  final int id;
  final int synopticViewId;
  final String slotId;          // "temp_depart"
  final String pointRef;        // "AI:12"
}
```

---

## Tables Drift (SQLite)

```dart
// lib/data/database/tables/synoptic_tables.dart

/// Vues synoptiques créées par l'utilisateur
class SynopticViews extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get connectionId => integer().references(Connections, #id)();
  TextColumn get templateId => text()();           // ID du template utilisé
  TextColumn get name => text()();                 // Nom donné par l'utilisateur
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Associations slot -> point BACnet
class SlotBindings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get synopticViewId => integer().references(SynopticViews, #id)();
  TextColumn get slotId => text()();               // ID du slot dans le template
  TextColumn get pointRef => text()();             // Référence du point "AI:12"

  @override
  List<Set<Column>>? get uniqueKeys => [{synopticViewId, slotId}];
}
```

---

## Templates à créer

### 1. Circuit régulé (`circuit_regule`)
Slots :
- `temp_depart` (analog) - Température départ
- `temp_retour` (analog) - Température retour
- `vanne` (analog) - Ouverture vanne 3 voies (%)
- `pompe` (binary) - État pompe
- `consigne` (analog, optionnel) - Consigne de température

### 2. CTA Simple (`cta_simple`)
Slots :
- `temp_soufflage` (analog) - Température soufflage
- `temp_reprise` (analog) - Température reprise
- `temp_exterieure` (analog, optionnel) - Température extérieure
- `ventilateur` (binary) - État ventilateur
- `batterie_chaud` (analog) - Vanne batterie chaude (%)
- `batterie_froid` (analog, optionnel) - Vanne batterie froide (%)
- `registre` (analog, optionnel) - Position registre (%)

### 3. Chaudière (`chaudiere`)
Slots :
- `temp_depart` (analog) - Température départ chaudière
- `temp_retour` (analog) - Température retour
- `bruleur` (binary) - État brûleur
- `pompe` (binary) - État pompe
- `consigne` (analog, optionnel) - Consigne
- `defaut` (binary, optionnel) - Défaut chaudière

### 4. Ballon ECS (`ballon_ecs`)
Slots :
- `temp_haut` (analog) - Température haut ballon
- `temp_bas` (analog) - Température bas ballon
- `pompe_bouclage` (binary) - Pompe de bouclage
- `vanne_charge` (analog) - Vanne de charge
- `consigne` (analog, optionnel) - Consigne ECS

### 5. PAC / Groupe froid (`pac`)
Slots :
- `temp_depart` (analog)
- `temp_retour` (analog)
- `compresseur` (binary)
- `pompe` (binary)
- `defaut` (binary, optionnel)

---

## Structure des fichiers

```
lib/
├── domain/
│   └── models/
│       └── synoptic.dart           # Modèles SynopticTemplate, SlotDefinition, etc.
│
├── data/
│   ├── database/
│   │   └── tables/
│   │       └── synoptic_tables.dart  # Tables Drift
│   └── repositories/
│       └── synoptic_repository.dart  # CRUD des vues
│
├── application/
│   └── providers/
│       └── synoptic_provider.dart    # Providers Riverpod
│
└── presentation/
    └── screens/
        └── synoptics/
            ├── synoptics_list_screen.dart    # Liste des vues créées
            ├── synoptic_view_screen.dart     # Affichage d'une vue (temps réel)
            ├── synoptic_edit_screen.dart     # Édition/création d'une vue
            └── widgets/
                ├── template_picker.dart       # Sélection du template
                ├── slot_binding_tile.dart     # Association slot -> point
                └── synoptic_renderer.dart     # Rendu SVG + valeurs

assets/
└── synoptics/
    ├── circuit_regule.svg
    ├── cta_simple.svg
    ├── chaudiere.svg
    ├── ballon_ecs.svg
    └── pac.svg
```

---

## Écrans à développer

### 1. Liste des synoptiques (`synoptics_list_screen.dart`)
- Liste des vues créées pour l'automate connecté
- Bouton "+" pour créer une nouvelle vue
- Tap pour afficher, long press pour éditer/supprimer

### 2. Création/Édition (`synoptic_edit_screen.dart`)
- Étape 1 : Choisir un template (grille avec aperçu)
- Étape 2 : Nommer la vue
- Étape 3 : Associer les points aux slots
  - Liste des slots avec leur type attendu
  - Tap sur un slot → sélection du point (liste filtrée par type)
  - Aperçu du point sélectionné (nom, valeur actuelle)

### 3. Affichage temps réel (`synoptic_view_screen.dart`)
- Image SVG en fond
- Badges avec valeurs positionnés sur les slots
- Rafraîchissement automatique des valeurs
- Tap sur un badge → navigation vers le détail du point

---

## Widget de rendu

```dart
class SynopticRenderer extends ConsumerWidget {
  final SynopticView view;
  final SynopticTemplate template;
  final Map<String, BacnetObject> boundPoints;  // slotId -> point avec valeur

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Image SVG de fond
            SvgPicture.asset(
              template.svgAsset,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              fit: BoxFit.contain,
            ),

            // Badges des valeurs
            for (final slot in template.slots)
              if (boundPoints.containsKey(slot.id))
                Positioned(
                  left: slot.x * constraints.maxWidth,
                  top: slot.y * constraints.maxHeight,
                  child: ValueBadge(
                    point: boundPoints[slot.id]!,
                    label: slot.label,
                  ),
                ),
          ],
        );
      },
    );
  }
}
```

---

## Étapes d'implémentation

### Phase 1 : Infrastructure
1. [ ] Créer les modèles (`synoptic.dart`)
2. [ ] Créer les tables Drift
3. [ ] Régénérer la base de données
4. [ ] Créer le repository

### Phase 2 : Templates
5. [ ] Créer/trouver les images SVG des templates
6. [ ] Définir les templates avec leurs slots (positions à ajuster)
7. [ ] Créer le provider des templates

### Phase 3 : Écrans
8. [ ] Écran liste des synoptiques
9. [ ] Écran création (sélection template + association slots)
10. [ ] Écran affichage temps réel

### Phase 4 : Intégration
11. [ ] Ajouter le menu "Synoptiques" sur l'écran d'accueil
12. [ ] Ajouter la route dans le router
13. [ ] Tests et ajustements

---

## Notes

- Les SVG doivent être simples et lisibles sur mobile
- Prévoir un mode paysage pour meilleure lisibilité
- Les positions des slots devront être ajustées visuellement
- Possibilité future : permettre à l'utilisateur d'importer ses propres SVG
