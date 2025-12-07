# Notes TrendLog BACnet - Session du 07/12/2025

## Contexte
Implementation de la lecture des TrendLogs via BACnet/IP natif (sans passer par l'API REST).

## Ce qui fonctionne

1. **Decouverte des TrendLogs** : Les objets TrendLog (type 20) sont correctement decouverts lors du scan BACnet.

2. **Mapping TrendLog -> Point** : Via la propriete `log-device-object-property` (property ID 132), on determine quel point est associe a chaque TrendLog.

3. **Lecture des valeurs recentes** : En utilisant ReadRange avec `byTime` et un count negatif, on lit les donnees depuis maintenant vers le passe. Les 24 dernieres heures s'affichent correctement.

4. **Decodage des valeurs** : Le decodage des `logDatum` (CHOICE avec context tags) fonctionne :
   - Context tag [2] = real-value (IEEE 754 float)
   - Context tag [1] = boolean
   - Context tag [4] = unsigned
   - etc.

## Ce qui NE fonctionne PAS

### Pagination au-dela de 65 records

**Symptome** : Quand on demande 7j, 30j ou "Tout", on n'obtient que ~48h de donnees (environ 130 records pour 2 jours a 15min d'intervalle).

**Observations** :
- Le controleur Distech retourne maximum **65 records par requete ReadRange**
- Le controleur retourne `moreItems=false` meme quand il y a plus de donnees
- Meme en ignorant `moreItems` et en paginant par timestamp, la pagination semble s'arreter trop tot

**Logs observes** :
```
readTrendLogBuffer: iteration 1, received 65 records
readTrendLogBuffer: iteration 2, received 65 records
readTrendLogBuffer: completed with 130 total records
```

On devrait avoir ~16 iterations pour 7 jours (7*24*4 = 672 records / 65 = ~10 iterations), mais ca s'arrete apres 2.

### Hypotheses a explorer

1. **Probleme de timestamp reference** : Peut-etre que le calcul du nouveau `referenceTime` pour la prochaine iteration n'est pas correct. On prend le timestamp du record le plus ancien et on soustrait 1ms, mais peut-etre que le controleur interprete ca differemment.

2. **Format de date BACnet** : Verifier si le format de date/heure envoye dans la requete ReadRange est correct. Le BACnet utilise un format specifique pour les dates.

3. **Limite du buffer** : Le TrendLog a peut-etre une limite de `record-count` ou `buffer-size` qui limite les donnees disponibles. Verifier la propriete `record-count` du TrendLog.

4. **Erreur silencieuse** : Peut-etre qu'apres la 2eme iteration, le controleur retourne une erreur qu'on ne detecte pas correctement.

## Fichiers cles

- `lib/data/services/bacnet_service.dart` : Methode `readTrendLogBuffer()` (ligne ~1108)
- `lib/data/services/bacnet/bacnet_decoder.dart` : Decodage ReadRange et LogRecord
- `lib/data/services/bacnet/bacnet_encoder.dart` : Encodage requete ReadRange avec byTime
- `lib/application/providers/trend_log_provider.dart` : Gestion des periodes et cache

## Constantes importantes

- **Limite par requete** : 65 records (limite firmware Distech)
- **Intervalle TrendLog typique** : 15 minutes
- **Records par jour** : ~96 (24h * 4)
- **Records par semaine** : ~672
- **Records par mois** : ~2880

## Structure ReadRange byTime

La requete utilise :
- `referenceTime` : DateTime de reference
- `count` : Negatif pour lire vers le passe

```dart
final requestCount = -remaining.clamp(1, chunkSize); // ex: -65
```

Le controleur devrait retourner les `|count|` records avant `referenceTime`.

## Prochaines etapes suggerees

1. Ajouter des logs detailles pour voir exactement ce que retourne le controleur a chaque iteration (timestamps min/max des records)

2. Verifier si le probleme vient de l'encodage de la date dans la requete ReadRange

3. Essayer avec `bySequenceNumber` au lieu de `byTime` si les sequence numbers sont disponibles dans la reponse

4. Consulter la doc BACnet sur ReadRange pour verifier le comportement attendu avec count negatif

## Notes techniques BACnet

- ReadRange service choice = 26
- TrendLog object type = 20
- log-buffer property = 131
- log-device-object-property = 132
- record-count property = 141

Le ReadRange byTime avec count negatif devrait fonctionner comme :
> "Donne-moi les 65 records juste avant cette date/heure"
