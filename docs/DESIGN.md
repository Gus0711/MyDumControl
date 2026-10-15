# Design system — MyGlobalDC

Interface de supervision GTB : sobre, dense mais aérée, lisible en clair comme en sombre.
Palette tirée du logo : bleu ciel / orange sur bleu nuit.

## Principes

1. **Jamais de couleur codée en dur pour un texte ou un fond.** Pas de `Colors.grey.shadeXXX`,
   `Colors.red.shade100`, ni de test `isDark ? … : …` : utiliser les jetons `context.dc`.
2. **Un état = un ton.** Succès (vert), avertissement (ambre), danger/alarme (rouge),
   forçage/dérogation (orange de marque, icône main `Icons.back_hand_rounded`), info/accent (bleu),
   neutre (gris bleuté). Chaque ton fournit `fg` (texte/icône), `bg` (fond doux), `border`.
3. **Les valeurs techniques en chasse fixe** (JetBrains Mono) : adresses IP, ports, instances,
   identifiants d'objets, horodatages, valeurs de points.
4. **Hiérarchie par la typographie et l'espace**, pas par la couleur : titres Inter 600,
   textes secondaires `dc.textSecondary`, métadonnées `dc.textMuted`.
5. **Grand écran** : contenu centré et limité (`DcContent`, 1240 px), grilles responsives.
6. Barre d'application bleu nuit identique dans les deux thèmes (`GradientAppBar`), avec
   le filet de marque bleu → orange.

## Jetons (`lib/core/theme/dc_tokens.dart`, accès `context.dc`)

| Jeton | Usage |
|---|---|
| `canvas` | fond d'écran (scaffold) |
| `surface` | cartes, panneaux |
| `surfaceRaised` | dialogues, menus |
| `surfaceSunken` | champs, puits (listes imbriquées dans une carte) |
| `border` / `borderStrong` | bordures normales / au survol, contours de boutons |
| `textPrimary` / `textSecondary` / `textMuted` | texte principal / secondaire / métadonnées |
| `accent`, `accentTone` | couleur d'action (bleu), ton info |
| `success`, `warning`, `danger`, `neutral`, `overrideTone`, `violet` | tons d'état (`DcTone`) |
| `toneOf(color)` | ton dérivé d'une couleur libre (couleur de dossier, type de point) |
| `cardShadow`, `raisedShadow` | ombres |

`DcRadius` (sm 6, md 10, lg 14, xl 20) et `DcSpace` (4/8/12/16/24/32, `contentMaxWidth`).
Typographie : `context.text.*` (Inter) ; `AppTextStyles.monospacedValue`, `AppTextStyles.overline`.

## Composants (`lib/presentation/widgets/ui/ui.dart`)

- `DcCard` — carte surface + bordure, survol et clic, liseré coloré optionnel (`accentColor`).
- `DcIconBox` — carré arrondi coloré contenant une icône (tête de carte / de ligne).
- `DcTag` — pastille compacte (modèle, version, état). `mono:` pour les valeurs techniques.
- `DcStatusDot` — point d'état avec halo.
- `DcBanner` — encadré info / avertissement / erreur (remplace les `Container` colorés).
- `DcSectionHeader` — sur-titre de section en capitales, compteur, action.
- `DcKpi` — indicateur chiffré cliquable.
- `DcInfoRow` — ligne « libellé : valeur » des fiches.
- `DcEmptyState` (+ `.error`) — état vide / erreur pleine page avec actions.
- `DcLoading` — chargement centré avec message.
- `DcContent` — centre et limite la largeur du contenu.
- `dcMenuItem(...)` — élément de menu contextuel (icône + libellé, rouge si `danger`).
- `dcSnackBar(...)`, `context.showSuccess/showError/showWarning/showInfo` — messages éphémères.

Points BACnet (`lib/presentation/widgets/point_widgets.dart`) :
`PointTypeBadge` (AI/BO/MSV…), `PointValueChip` (valeur colorée selon l'état),
`PointStatusTags` (alarme, forçage Pn, OOS), `pointValueText(point)`.
`BacnetTypeUtils.typeTone(context, type)` et `valueTone(context, point)` donnent les tons.

## Boutons

- Action principale : `FilledButton` (ou `FilledButton.icon`).
- Action secondaire : `OutlinedButton`. Action discrète / dialogue : `TextButton`.
- Action destructive : `FilledButton` avec `backgroundColor: dc.danger.fg` dans les dialogues de
  confirmation, `dcMenuItem(..., danger: true)` dans les menus.
- Dans les dialogues : l'action principale à droite.

## Icônes

Variantes `_rounded` / `_outlined` de Material Icons. Correspondances fixes :
favoris `star_rounded`, points `format_list_bulleted_rounded`, tableaux de bord `insights_rounded`,
horaires `calendar_month_rounded`, alarmes `notifications_active_rounded`,
forçages `back_hand_rounded`, synoptique `schema_rounded`, infos `info_outline_rounded`,
connexion API `memory_rounded`, BACnet `lan_outlined`.
