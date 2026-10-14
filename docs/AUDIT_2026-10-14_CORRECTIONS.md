# Corrections de l'audit — bilan (nuit du 14 au 15/10/2026)

Branche `fix/audit-2026-10`, créée depuis `main` après `211ac66` et non pushée : 48 commits hors merges, 116 fichiers modifiés.
Constats d'origine : [AUDIT_2026-10-14.md](AUDIT_2026-10-14.md) (synthèse) et [AUDIT_2026-10-14_details.md](AUDIT_2026-10-14_details.md) (détail).

## État final vérifié

| Vérification | Avant | Après |
|---|---|---|
| `flutter analyze` | 92 issues (warnings inclus) | **1 info** (`discover_bacnet_screen.dart:468`, `value` déprécié, laissé volontairement) |
| `flutter test` | 1 smoke test, en échec | **155 tests verts** |
| `flutter build linux` / `web` | OK | OK |
| Lancement Linux | OK | OK |

**Rien n'a été testé sur un vrai automate.** Voir la check-list en fin de document.

## Déroulé

1. **Phase 1** : 7 agents en parallèle, un par groupe de fichiers, chacun dans son worktree : BACnet, API, données, providers cœur, providers fonctionnels, UI cœur, UI fonctionnelle.
2. **Phase 2** : corrections transversales.
   - **Sécurité :** TOFU TLS, client API factorisé, erreurs d'auth.
   - **Branchements reportés :** courbes, plannings, réglages.
3. **Phase 3** : l10n (environ 470 chaînes extraites, FR et EN), déduplication des helpers, logger global, nettoyage de l'analyse.
4. **Revue indépendante anti-régressions**, puis **phase 4** : correction des 7 régressions qu'elle a trouvées.

## Principales corrections

### Sécurité
- **TOFU TLS** :
  - l'empreinte SHA-256 est enregistrée à la première connexion, puis vérifiée ;
  - si elle change, la connexion est refusée avec un message clair et un bouton « Faire confiance au nouveau certificat » ;
  - même logique dans la WebView Envysion ;
  - l'empreinte est réinitialisée quand l'hôte, le port ou le schéma changent, et elle est incluse dans l'export/import.
- **Envysion** : les identifiants ne sont envoyés qu'à l'hôte de l'automate, sans persistance permanente.
- **HTTP** : avertissement non bloquant indiquant que le mot de passe circule en clair.

### Driver BACnet
- Écriture du present-value dans le bon type de données : Enumerated pour les binaires, Real pour les analogiques, Unsigned pour les multi-états.
- `init()` ne bloque plus. Segmentation gérée : réassemblage avec SegmentACK, et repli sur l'object-list lue élément par élément.
- I-Am reçus via BBMD (Forwarded-NPDU), découvertes successives, broadcast multi-interfaces sous Linux.
- Drapeaux ReadRange, décodage UTF-8 et UCS-2, corrélation des réponses par invokeId et adresse source, retry, limite de concurrence.
- RPM groupé (25 objets par requête). Repli ReadProperty seulement sur rejet du device, plus sur un simple timeout.
- Plannings : le type de valeur d'origine est conservé à l'écriture.

### API REST Distech
- Exceptions typées et détection des 401/403. Une erreur d'auth ne coupe la connexion que si elle empêche de lire les points.
- Planning hebdomadaire illisible : affichage en lecture seule et édition bloquée, au lieu d'un planning vide qu'on pouvait réécrire sur l'automate.
- `forceInput` atomique en V1, avec compensation qui respecte l'état précédent.
- Chemins de repli et noms de types corrigés.
- **Perf :**
  - requêtes indépendantes en parallèle (`Future.wait`) ;
  - cache des propriétés statiques et `$select` en V2 ;
  - trend-logs dédupliqués ;
  - buffers non ré-encodés et parsés dans `compute()`.

### État, races et fuites
- Jeton de connexion pour que les réponses d'un ancien automate soient ignorées. `connect()` attend bien ses appels (`await`).
- `refresh()` fonctionne en BACnet natif.
- Plus de réécriture complète du cache à chaque tick. Les `forceRefresh` lancés pendant un chargement ne sont plus perdus.
- `autoDispose` avec keep-alive limité. Timers des synoptiques arrêtés. Les providers ne `watch` plus que les champs utiles.
- Les échecs d'écriture BACnet sont remontés (out-of-service, libération d'urgence sur les 16 priorités).

### Données
- Cache des points rafraîchi et purgé à chaque chargement.
- Suppression d'une connexion en cascade, dans une transaction.
- Cache invalidé quand la connexion change.
- **Import JSON, qui était cassé** : chaque connexion reçoit sa propre clé de mot de passe et un badge « mot de passe à ressaisir ».
- Schéma v13 : 4 index ajoutés, migration testée.

### UI
- Graphes : downsampling (environ 1 500 points affichés), données mémoïsées, zoom pinch corrigé, reconfiguration du multi-courbes prise en compte.
- Plus de boucle de rechargement sur le dashboard, plus de skeleton infini, gardes `mounted`, `_isWriting` remis à faux en cas d'erreur.
- Corrections N+1 sur les favoris : un seul stream partagé et des lookups en mémoire.
- Réglages branchés : décimales, °C/°F (affichage seul), 12/24 h, port BACnet, intervalle de rafraîchissement, timeout de connexion.

## Non fait (volontairement)

- **Découpage des gros fichiers** (`api_service.dart`, `bacnet_service.dart`, écrans de plus de 1 000 lignes) et **déduplication profonde V1/V2 et graphes** : trop risqué sans tests sur automate réel. À faire maintenant qu'il existe 155 tests.
- **Montée des dépendances majeures** (Riverpod 3, go_router, fl_chart…) : changements cassants, à faire dans une branche dédiée.
- **Devices BACnet derrière un routeur** (DNET/DADR) : il faudrait faire évoluer le modèle de connexion.
- **Options iOS de `flutter_secure_storage`** : risque de rendre illisibles les secrets déjà stockés.
- **`build_runner`** complet : il ne termine pas (plus de 10 min). Le projet n'a aucune annotation `@riverpod`, donc `riverpod_generator` peut être retiré. Seul Drift est régénéré, avec `--build-filter="lib/data/database/app_database.g.dart"`.

## Check-list de tests sur automate réel

**Connexion / sécurité**
- [ ] Première connexion HTTPS : l'empreinte est enregistrée. Une connexion existante continue de marcher.
- [ ] Certificat régénéré sur l'automate : message, bouton « faire confiance », reconnexion.
- [ ] Mauvais mot de passe : « Identifiants invalides ».
- [ ] Compte à droits limités (401/403 sur l'heure ou les infos device) : la connexion reste active avec un simple avertissement.
- [ ] Import d'une sauvegarde : mots de passe à ressaisir, puis distincts par connexion.

**API Distech**
- [ ] Lecture et écriture de points, forçage d'une entrée, y compris une entrée déjà forcée, et libération.
- [ ] Planning : ouverture, édition, sauvegarde. Un planning dont le weekly-schedule renvoie 403/404 s'affiche en lecture seule.
- [ ] Super-favoris : rafraîchissement, et changement de mot de passe d'une connexion.
- [ ] Trend logs : 24 h, 7 jours, « Tout ». Multi-courbes : changement de période, Rafraîchir. Dashboard.

**BACnet natif**
- [ ] Écriture d'un BV/BO (`active`/`inactive`), d'un AV et d'un MSV.
- [ ] Découverte sous Linux avec une interface choisie, via un BBMD, puis deuxième scan.
- [ ] Device avec un gros object-list (segmentation).
- [ ] Historiques sur 7 et 30 jours (pagination ReadRange).
- [ ] Planning BACnet unsigned/real/multistate : sauvegarde puis relecture (type et secondes conservés).
- [ ] Device éteint : échec en 10 s environ.

**Affichage**
- [ ] Décimales, °F, horloge 12 h, interface en anglais.
