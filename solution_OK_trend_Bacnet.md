# Solution TrendLog BACnet - Pagination bySequenceNumber

## Probleme initial

La lecture des TrendLogs via BACnet/IP natif ne fonctionnait pas au-dela de ~130 records (48h de donnees).

**Symptomes:**
- Les 24 dernieres heures s'affichaient correctement
- Les periodes 7j, 30j, "Tout" ne retournaient que ~48h de donnees
- La pagination s'arretait apres 2 iterations (2 x 65 records)

**Cause identifiee:**
L'ancienne implementation utilisait `ReadRange byTime` avec un count negatif. Le probleme etait l'ambiguite sur l'ordre des records retournes et le calcul du timestamp de reference pour la pagination.

## Solution implementee

### Approche: ReadRange bySequenceNumber

Selon le standard BACnet, `bySequenceNumber` est la methode recommandee pour la pagination fiable des TrendLogs:
> "If a subscriber needs to fetch all of the new records, it should use the 'By Sequence Number' form of the ReadRange service request."

### Avantages de bySequenceNumber

1. **Numeros de sequence uniques et incrementaux** - Pas d'ambiguite
2. **firstSequenceNumber dans la reponse** - Indique exactement ou on en est
3. **Detection des records manques** - Possible via les gaps de sequence
4. **Pas de probleme de timestamps en double**

## Implementation

### 1. Lecture de totalRecordCount

Ajout de la propriete `totalRecordCount` (ID 145) a la liste des proprietes lues pour un TrendLog:

```dart
// bacnet_service.dart - getTrendLogProperties()
final propertyIds = [
  BacnetPropertyId.objectName,
  BacnetPropertyId.description,
  BacnetPropertyId.logDeviceObjectProperty,
  BacnetPropertyId.logInterval,
  BacnetPropertyId.bufferSize,
  BacnetPropertyId.recordCount,
  BacnetPropertyId.totalRecordCount, // Pour pagination bySequenceNumber
  BacnetPropertyId.enable,
];
```

### 2. Modele BacnetTrendLog

Ajout du champ `totalRecordCount`:

```dart
class BacnetTrendLog {
  // ...
  final int? totalRecordCount; // Numero de sequence du dernier record
  // ...
}
```

### 3. Methode readTrendLogBuffer

Logique de pagination:

```dart
Future<List<TrendLogRecordData>> readTrendLogBuffer({
  required String host,
  required int port,
  required int trendLogInstance,
  int? maxRecords,
  int? totalRecordCount, // Optionnel, lu automatiquement si pas fourni
}) async {
  // 1. Obtenir totalRecordCount (= seqNum du dernier record)
  int? lastSeqNum = totalRecordCount;
  if (lastSeqNum == null) {
    // Lecture via ReadProperty si pas fourni
    final trcResponse = await readProperty(..., propertyId: BacnetPropertyId.totalRecordCount);
    lastSeqNum = trcResponse.value as int;
  }

  // 2. Pagination avec bySequenceNumber
  int referenceSeqNum = lastSeqNum;

  while (allRecords.length < recordsToRead && referenceSeqNum > 0) {
    final response = await readRange(
      rangeType: ReadRangeType.bySequenceNumber,
      referenceIndex: referenceSeqNum,
      count: -65, // Negatif = lire vers le passe
    );

    final result = response.value as ReadRangeResult;
    allRecords.insertAll(0, result.records); // Maintenir l'ordre chronologique

    // Prochain point de depart = juste avant le premier record recu
    if (result.firstSequenceNumber != null) {
      referenceSeqNum = result.firstSequenceNumber! - 1;
    } else {
      referenceSeqNum -= result.records.length;
    }
  }

  return allRecords;
}
```

## Fichiers modifies

- `lib/data/services/bacnet_service.dart`
  - Ajout `totalRecordCount` aux proprietes lues (ligne ~925)
  - Ajout champ `totalRecordCount` dans `BacnetTrendLog` (ligne ~1246)
  - Reecriture complete de `readTrendLogBuffer()` (ligne ~1114)

## Constantes BACnet

| Element | Valeur |
|---------|--------|
| TrendLog object type | 20 |
| log-buffer property | 131 |
| record-count property | 141 |
| total-record-count property | 145 |
| ReadRange service choice | 26 |
| bySequenceNumber context tag | 6 |
| Limite Distech par requete | 65 records |

## Comportement attendu

Avec la nouvelle implementation:

| Periode | Records attendus | Iterations |
|---------|-----------------|------------|
| 24h | ~96 | 2 |
| 7j | ~672 | 11 |
| 30j | ~2880 | 45 |
| Tout | Variable | Variable |

## Logs de debug

En cas de probleme, les logs suivants sont disponibles:

```
readTrendLogBuffer: starting for TrendLog X on host:port
readTrendLogBuffer: totalRecordCount=XXXX
readTrendLogBuffer: using bySequenceNumber, starting from seqNum=XXXX
readTrendLogBuffer: iteration N, referenceSeqNum=XXX, requesting -65
readTrendLogBuffer: received 65 records, firstSeqNum=XXX
readTrendLogBuffer: completed with XXX total records over N iterations
```

## References

- [BACnet Stack ReadRange Implementation](https://github.com/stargieg/bacnet-stack/blob/master/src/readrange.c)
- [BACnet TrendLog Tutorial (David Fisher)](https://polarsoft.com/bex/papers/Trend%20Log.pdf)
- [BACnet Standard Addendum 135-2001b](https://bacnet.org/wp-content/uploads/sites/4/2022/08/Add-2004-135b.pdf)

---

**Date de resolution:** 08/12/2025
**Status:** FONCTIONNE
