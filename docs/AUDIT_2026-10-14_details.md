# Audit MyDumControl — détail des constats (2026-10-14)
Généré par 8 agents de revue (lecture seule). Confiance : high / medium / low. Les numéros de ligne correspondent au commit `7a6a133`.

## API REST Distech (21 constats)

api_service.dart (3757 lignes) utilise un Dio par ConnectedApiClient et des acces groupes (RPM V1, batch V2) pour les points, ce qui est correct. Faiblesses : TLS non verifie sans epinglage ; aucune gestion du 401, aucun retry, aucune erreur typee (validateStatus < 500, donc tout echec devient [], null ou false) ; chemins de repli invalides ; lectures sequentielles ou redondantes ; duplication V1/V2 massive ; code mort. docs/api-integration.md est obsolete. Les constats sur les noms de types V1 viennent du code seul, l'API reelle n'a pas ete testee.

### [critique] TLS non verifie sur toutes les requetes, empreinte jamais epinglee
`lib/data/services/api_service.dart:223` · securite · confiance high

ConnectedApiClient fait badCertificateCallback => true. Le fingerprint calcule dans ApiService (l.43-54) n'est jamais persiste ni compare : updateCertificateFingerprint n'est appele nulle part dans lib/. Un faux certificat sur le reseau permet d'intercepter le header Authorization Basic (envoye a chaque requete) puis de forcer des points ou ecrire des schedules. useHttps=false envoie le Basic en clair sans avertissement.

**Correction :** Stocker le fingerprint a la premiere connexion (TOFU) et le comparer dans badCertificateCallback de ConnectedApiClient ; refuser s'il differe. Avertir en HTTP.

### [majeur] Replis getAllObjects/getObjectsByType avec un mauvais chemin
`lib/data/services/api_service.dart:918` · bug · confiance high

getObjectsByType appelle /objects/${type.apiName} (kebab singulier, ex. analog-input). V1 attend camelCase (analogInput) et V2 le pluriel (analog-inputs), comme le font _objectTypeToCamelCase et _objectTypeToKebabCasePlural. Quand RPM (l.1085) ou batch (l.1140) echoue et que le repli getAllObjects() s'execute, les GET renvoient 404 (<500, donc pas d'exception) et le catch les avale : liste vide sans erreur.

**Correction :** Utiliser les helpers de conversion par version dans getObjectsByType, ou supprimer le repli ; propager l'erreur.

### [majeur] Aucune gestion du 401/403 : tout echec d'auth devient une liste vide ou false
`lib/data/services/api_service.dart:211` · bug · confiance medium

validateStatus accepte tout < 500. Si le mot de passe change ou si le compte est refuse, getSchedules (l.2896), getPointsOptimized (l.1080), getDeviceInfo, etc. renvoient [] ou des defauts et les ecritures renvoient false. L'UI affiche 'aucun schedule' ou 'echec' sans indiquer des identifiants invalides. Les methodes n'ont pas de convention commune : certaines rethrow (getObjectsSummary l.690, setControllerTime), d'autres retournent []/null/false.

**Correction :** Ajouter un interceptor Dio qui leve une ApiAuthException sur 401/403 et une exception typee sur les autres statuts, et uniformiser (throw dans la couche service, catch dans les providers).

### [majeur] Planning hebdo vide affiche comme reel si la lecture echoue, puis ecrasable
`lib/data/services/api_service.dart:3128` · bug · confiance medium

Dans _getScheduleDetailV1/V2, si le GET weekly-schedule renvoie un statut non 200 (ex. 404/401/403, pas d'exception), weeklySchedule reste WeeklySchedule.empty() et le Schedule est renvoye comme valide. Si l'utilisateur edite et sauvegarde, writeWeeklySchedule remplace le planning reel de l'automate par un planning quasi vide.

**Correction :** Retourner null / lever une exception quand le weekly-schedule n'est pas lu en 200, ne jamais substituer un planning vide.

### [majeur] forceInput en 2 appels sans rollback (out-of-service reste a true)
`lib/data/services/api_service.dart:1874` · bug · confiance medium

_forceInputV1 (l.1874-1940) et _forceInputV2 (l.2105-2150) posent out-of-service=true puis ecrivent present-value dans une 2e requete. Si la 2e echoue (timeout, 4xx), l'entree reste out-of-service a une valeur obsolete et la fonction renvoie false : un capteur reste gele sans que l'utilisateur le sache. De plus en V1 write-property-multiple accepte plusieurs propertyReferences, donc un seul appel atomique est possible.

**Correction :** En V1, envoyer les deux references dans un seul write-property-multiple. En cas d'echec de l'etape 2, tenter un releaseInput de compensation.

### [majeur] Super-favoris : relecture des proprietes statiques a chaque rafraichissement
`lib/data/services/api_service.dart:3483` · performance · confiance high

_readMultiplePointsV1 demande a chaque appel objectName, units, description, activeText, inactiveText, stateText (5 a 8 refs par point) alors que seuls presentValue/outOfService changent. En V2 (l.3499-3530) un GET /objects/{type}/{id} par point renvoie l'objet complet (priority-array, alarmes) alors que les docs Postman V2 documentent $select (488 occurrences). Avec N favoris sur M connexions et un rafraichissement periodique, la charge est multipliee par 3 a 5 inutilement.

**Correction :** Lire les proprietes statiques une fois (cache par pointRef) puis ne rafraichir que presentValue/outOfService (V1) ou ajouter ?$select=present-value,out-of-service dans l'URL batch (V2).

### [majeur] Mapping trend-logs : requetes redondantes ou sequentielles
`lib/data/services/api_service.dart:2384` · performance · confiance high

_getTrendLogMappingV1 appelle d'abord _getTrendLogsV1 (GET liste) puis un RPM, soit 2 requetes sequentielles ; _getTrendLogMappingV2 refait un GET /trend-logs que _getTrendLogsV2 (l.2342) fait deja. trend_log_provider (l.108 et 125) rappelle getTrendLogMapping une 2e fois en rafraichissement de fond apres la lecture du cache. Les deux sont sans deduplication : un meme GET /trend-logs peut partir deux fois.

**Correction :** Mutualiser la liste des trend-logs (cache memoire court dans le client) et dedupliquer les rafraichissements en vol.

### [majeur] Detail de schedule : requetes sequentielles qui pourraient etre paralleles
`lib/data/services/api_service.dart:3055` · performance · confiance high

_getScheduleDetailV1 enchaine RPM, GET weekly-schedule, GET schedule-state-text (l.3072, 3121, 3158), trois allers-retours independants. En V2 (l.3251 et 3301), details puis weekly-schedule, egalement independants. Sur un lien VPN a 200 ms de latence, l'ouverture d'un schedule prend 3 RTT au lieu de 1.

**Correction :** Lancer les requetes avec Future.wait. En V2, utiliser le endpoint batch pour combiner les deux GET.

### [majeur] Trend V1 : re-serialisation JSON inutile de jusqu'a 50 000 enregistrements
`lib/data/services/api_service.dart:2625` · performance · confiance medium

_getTrendLogBufferV1 recoit response.data deja decode par Dio, puis fait jsonEncode(response.data) (l.2660) pour renvoyer une String, que l'appelant doit rejsonDecode. Idem V2 (l.2790). Le tout tourne sur l'isolate UI. Le limit=50000 fixe tronque aussi silencieusement les historiques longs en mode 'allData'. Le receiveTimeout de 5 minutes n'existe qu'en V1 : la requete V2 get-table avec limit 0 sur 10 ans herite du timeout de 60 s.

**Correction :** Retourner directement les structures decodees (List/Map), ou demander ResponseType.plain et parser une fois dans compute(). Ajouter un receiveTimeout long pour V2 get-table et paginer.

### [majeur] Incoherence du nom de type multi-etats en V1 (multiState vs multistate)
`lib/data/services/api_service.dart:751` · bug · confiance medium

_importantTypes (l.750) et _readMultiplePointsV1 (l.3445, via type.name) utilisent 'multiStateInput', alors que _getAllPointsV1Optimized (l.960) et _objectTypeToCamelCase (l.2182) utilisent 'multistateInput'. Le premier choix est donc suppose faux : si l'automate repond 'multistateInput', _parseObjectsSummaryFromRpm (filtre exact _importantTypes.contains, l.773) compte 0 multi-etats et _parseMultiplePointsFromRpm ne retrouve pas la cle refMapping (type.name:instance), donc le super-favori multi-etats est renvoye sous une cle brute que l'UI ne retrouve pas.

**Correction :** Centraliser le mapping type <-> nom API V1 (un seul helper, comparaison insensible a la casse) et l'utiliser partout.

### [majeur] Course : reponses de fond d'une ancienne connexion ecrasent l'etat de la nouvelle
`lib/application/providers/active_connection_provider.dart:375` · bug · confiance medium

_loadDataInBackground lance getDeviceInfo/getObjectsSummary/getControllerTime/getNetworkInfo en then() et ne verifie que 'mounted', pas que state.client est encore le client concerne. Si l'utilisateur se deconnecte (client.dispose) puis se connecte a un autre automate pendant que ces requetes sont en vol, les reponses de A ecrasent deviceInfo/summary/time de B dans l'etat actif. Aussi apiVersion par defaut 'V2' ici (l.316) mais 'V1' dans super_favorites_provider (l.590) pour la meme connexion.

**Correction :** Comparer state.client == client avant chaque state=. Unifier le defaut de apiVersion (lever une erreur si null).

### [mineur] Logs debug avec interpolation de grosses reponses evaluee meme en release
`lib/data/services/api_service.dart:657` · performance · confiance high

17 appels _logger.d('...${response.data}') (l.251, 299, 329, 404, 545, 579, 657, 733, 1764, 2786, 3022, 3160, 3483, 3537, ...) construisent la String de la reponse entiere (Map profonde de tous les schedules ou points) avant que le Logger ne filtre le niveau. Le cout est paye sur le thread UI, y compris en release ou rien n'est affiche. getObjectsSummary V2 (l.657) et batch favoris (l.3537) concernent de gros payloads.

**Correction :** Supprimer ces logs ou les proteger par if (kDebugMode), ou logger seulement statusCode et la taille.

### [mineur] Resume V1 : reponse RPM non-200 retourne un ObjectsSummary vide sans repli
`lib/data/services/api_service.dart:721` · bug · confiance medium

Dans _getObjectsSummaryV1, le repli _getObjectsSummaryV1Fallback n'est appele que sur exception. Un 401/403/404 (validateStatus <500) tombe sur 'return ObjectsSummary()' (l.746) : zero partout, cache ecrase par active_connection_provider (l.413) avec ces zeros.

**Correction :** Lever une exception ou appeler le repli si statusCode != 200, et ne pas ecraser le cache avec un resume vide.

### [mineur] Boilerplate HTTP copie-colle : 37 blocs Options(headers: Authorization+Content-Type)
`lib/data/services/api_service.dart:1640` · duplication · confiance high

Chaque methode V1/V2 reecrit le try/post/Options/statusCode==200||204/catch->false (_writePropertyV1/V2, _writeValueV1/V2, _releaseOverrideV1/V2, _emergencyReleaseV1/V2, _forceInputV1/V2, _releaseInputV1/V2, writeWeeklySchedule V1/V2...). _authOptions existe deja (l.235) mais n'est pas utilise pour les POST. Le parsing du wrapper RPM 'List ou Map.propertyReferences' est repete au moins 8 fois (l.730, 772, 1376, 2444, 2979, 3095, 3445, 3623). Les mappings de types sont dupliques : _mapTypeName, _mapTypeNameV2, _typeToV2Name, _objectTypeToCamelCase, _objectTypeToKebabCasePlural. getControllerTime/getNetworkInfo/getDeviceInfo ont aussi des paires V1/V2 copiees.

**Correction :** Mettre Authorization/Content-Type dans BaseOptions.headers, ajouter _postOk(url, body) et _extractRpmRefs(data), et un seul tableau de correspondance de types.

### [mineur] Fichier monolithique de 3757 lignes et ApiConstants ignore
`lib/data/services/api_service.dart:1` · architecture · confiance high

ApiService, ConnectedApiClient (acces, parsing RPM/batch, schedules, trend-logs, ecritures) tiennent dans un fichier. ApiConstants (v1Objects, v2Batch, v2Alarms, timeouts...) n'est importe que pour les ports : api_service.dart reecrit les chemins ('/api/rest/v2/batch', '/api/rest/v1/info/device'...) et les timeouts (10s/30s/60s) en dur. ApiConstants.connectTimeout (30 s) et ApiService.testConnection (10 s) divergent.

**Correction :** Decouper en client Dio + repositories (points, schedules, trend, systeme) avec une interface commune V1/V2 (strategie) et utiliser ApiConstants.

### [mineur] Methodes sans appelant
`lib/data/services/api_service.dart:2804` · code-mort · confiance high

getTrendLogHistoryV2 (l.2804) et getPointTrendV1 (l.2853) n'ont aucun appelant dans lib/. objectsByTypeProvider et allObjectsProvider (active_connection_provider l.530-544) ne sont references nulle part, donc getObjectsByType, getObjectDetails et getAllObjects ne servent que de repli (casse, voir plus haut). _getAllPointsV2Optimized n'est utilise qu'en interne. De plus getTrendLogHistoryV2 utilise 'trend-log-$instance' comme nom d'historique alors que _getTrendLogBufferV2 le lit dans le champ 'history' du trend-log : incoherent.

**Correction :** Supprimer ces methodes et providers inutilises.

### [mineur] Empreinte de certificat obsolete reutilisee entre tests de connexion
`lib/data/services/api_service.dart:45` · bug · confiance medium

_lastCertificateFingerprint n'est jamais remis a null dans testConnection ; l'empreinte renvoyee peut venir d'un test precedent sur un autre hote (certificat valide : callback non appele, donc empreinte de l'hote precedent). Le nom de _calculateFingerprint dit SHA256 mais le code utilise cert.sha1. De plus testConnection essaie V2 puis V1 sequentiellement (2 x 10 s de timeout sur hote injoignable) et avale l'erreur V2 sans la journaliser.

**Correction :** Remettre l'empreinte a null au debut, utiliser un vrai SHA-256 (package crypto), et abandonner V1 si V2 a echoue en connectionError.

### [mineur] _parseValue convertit toute chaine numerique, branches mortes
`lib/data/services/api_service.dart:1311` · bug · confiance low

_parseValue teste num.tryParse avant '1'/'0' : les cas value == '1' / '0' vers bool (l.1393-1394) sont inatteignables, et une valeur textuelle numerique d'un MSV ou d'un nom est convertie en nombre. Un binaire V1 renvoye '1' devient donc 1 (num) et non true, selon le type attendu par l'UI.

**Correction :** Parser selon le type d'objet (binaire vs analogique) plutot que par heuristique sur la chaine.

### [mineur] priorityArrayRaw stocke le toString() de chaque priority-array
`lib/data/services/api_service.dart:1211` · performance · confiance low

_parsePointsFromBatchV2 et _parsePointsFromRpm construisent priorityArray?.toString() (16 entrees) pour chaque point alors que isOverridden/overridePriority/overrideValue sont deja extraits. Sur plusieurs milliers de points c'est une allocation inutile sur le thread UI, et tout le parsing de la liste complete se fait sur l'isolate UI.

**Correction :** Ne conserver priorityArrayRaw qu'a la demande (detail du point) et deplacer le parsing de gros payloads dans compute().

### [mineur] Reponses batch V2 : statut par sous-requete ignore
`lib/data/services/api_service.dart:1140` · conformite-bacnet · confiance low

_parsePointsFromBatchV2 (l.1172-1182) ne lit pas batchResponse['status'] (contrairement a _parseMultiplePointsFromBatchV2 qui teste 200). Un type dont la sous-requete renvoie 4xx/5xx est silencieusement omis : la liste de points est incomplete sans signal (par ex. 'multi-state-values' absent). Aucune pagination n'est geree (aucune trace de limit/offset dans le client, alors que get-table V2 accepte limit).

**Correction :** Verifier status par sous-reponse, journaliser/remonter les types en echec et proposer un rafraichissement partiel.

### [mineur] Documentation d'integration obsolete et trompeuse
`lib/docs/api-integration.md:30` · securite · confiance low

La doc decrit ApiService(host, port, username, password) avec _dio.options.headers['Authorization'] et des chemins /api/rest/v1/protocol/bacnet/... alors que le code reel utilise /protocols/bacnet/local, ApiService() sans parametres et ConnectedApiClient. Elle ne mentionne ni batch V2, ni RPM V1, ni la desactivation de la verification TLS. L'auth Bearer/token V2 (present dans la collection Postman) n'est pas utilisee : Basic envoye a chaque requete.

**Correction :** Mettre a jour la doc (classes, chemins, flux de connexion, risques TLS) et evaluer le token V2 pour eviter d'exposer les identifiants a chaque appel.

## Driver BACnet (26 constats)

Le driver BACnet maison est fonctionnel pour le cas nominal (unicast ReadProperty/RPM/WriteProperty, ReadRange bySequenceNumber, encodage des tags et constantes globalement corrects), mais il présente plusieurs défauts de conformité ASHRAE 135 et de robustesse. Les plus graves : init() qui peut bloquer indéfiniment après un échec de bind, ecriture des points binaires en BACnet natif envoyée sous forme de CharacterString, absence totale de segmentation (lecture de l'object-list impossible sur gros devices), I-Am issus de BBMD (Forwarded-NPDU) avalés à cause d'un mauvais offset, et dédoublonnage `_seenDevices` qui rend whoIs/scan/connect muets après une première découverte. Les flags ReadRange more-items sont mal décodés (toujours faux) et la pagination trend s'arrête dès qu'un lot est plus court que demandé. Côté architecture : corrélation des réponses par invokeId seul (sans adresse source), aucun retry, pas de contrôle de concurrence, N+1 requêtes pour découverte/refresh, calcul de broadcast /24 en dur (dupliqué), code mort (scanIpRange, encodeWeeklySchedule…), et plusieurs duplications de formatage multistate/binaire. Aucun problème de secrets/TLS dans ce périmètre (UDP BACnet non authentifié par nature).

### [critique] init() : _isInitializing jamais remis à false si le bind échoue -> boucle d'attente infinie
`lib/data/services/bacnet_service.dart:91` · bug · confiance high

_isInitializing = true (l.91) puis RawDatagramSocket.bind(bindAddress, 0) (l.112) peut lever (interface disparue, permission, adresse invalide). Aucune try/finally ne remet _isInitializing à false. Tout appel ultérieur à init() (appelé par whoIs, readProperty, etc.) entre dans `while (_isInitializing && !_isInitialized)` (l.86) et boucle indéfiniment toutes les 50 ms : l'UI reste bloquée sur 'Connexion...' jusqu'au redémarrage de l'app. Même risque si deux appels concurrents attendent un init qui échoue.

**Correction :** Entourer l'init d'un try/finally qui remet _isInitializing=false, et partager un Future<void> _initFuture unique (les appels concurrents l'attendent et reçoivent la même exception) au lieu d'un polling.

### [critique] Ecriture BACnet native des points binaires envoyée en CharacterString (type applicatif non adapté à la propriété)
`lib/data/services/bacnet/bacnet_encoder.dart:427` · bug · confiance high

_encodeApplicationValue choisit le tag d'après le type Dart : String->CharacterString, int->Unsigned, double->Real. point_detail_screen.dart:522 met _editValue = 'active'/'inactive' pour les points binaires et points_provider._writeValueBacnet/_writeOverrideBacnet/_forceInputBacnet le passent tel quel à writePointValue : le device reçoit une CharacterString pour un present-value de BI/BO/BV (qui est ENUMERATED) -> Error invalid-data-type. De même un int écrit sur un AV/AO part en Unsigned au lieu de Real, et un bool sur un BV part en Boolean au lieu d'Enumerated. Seuls double (analogique) et int (multistate) fonctionnent.

**Correction :** Fournir un type cible à l'encodeur (selon objectType/propriété : analogique->Real, binaire->Enumerated 0/1, multistate->Unsigned, outOfService->Boolean) et convertir 'active'/'inactive'/bool/int avant l'encodage. Lever une exception sur type non supporté plutôt que `value as int` (l.445).

### [critique] Aucune segmentation : lecture de l'object-list entière impossible sur un device avec beaucoup d'objets
`lib/data/services/bacnet_service.dart:889` · conformite-bacnet · confiance high

Les requêtes annoncent max-segments=0 / APDU 1476 (octet 0x05, bit segmented-response-accepted absent) et discoverObjects/discoverTrendLogs/discoverSchedules/_findStateTextsFromMultistateByName font un seul ReadProperty(object-list) sans arrayIndex. Au-delà d'environ 290 objets (5 octets/objet) le device doit répondre Abort (segmentation-not-supported / buffer-overflow) ou une Error ; le code log l'échec et retourne une liste vide (l.897 'Failed to read object-list'). Aucun traitement des PDU segmentés (flag SEG/MOR, SegmentACK) dans le décodeur non plus.

**Correction :** Lire object-list par index : ReadProperty arrayIndex=0 (longueur) puis arrayIndex=1..N (ou RPM par paquets), et/ou activer segmented-response-accepted + gérer SegmentACK. Détecter Abort 1/4 et basculer automatiquement sur la lecture indexée.

### [majeur] Forwarded-NPDU (BBMD) : octet de contrôle NPDU lu au mauvais offset, I-Am avalés
`lib/data/services/bacnet_service.dart:226` · bug · confiance high

Le test Network Layer Message lit datagram.data[5] comme NPDU control. Pour un BVLC Forwarded-NPDU (0x04), les octets 4-9 sont l'adresse B/IP d'origine, le NPDU commence à 10 : data[5] est le 2e octet de l'IP source (ex. 168 pour 192.168.x.x). 168 & 0x80 != 0 -> le paquet est traité comme message de couche réseau et abandonné par _handleNetworkLayerMessage (data[6] = octet d'IP). Tous les I-Am relayés par un BBMD dont le 2e octet IP >= 128 sont perdus. De plus, pour ces paquets l'adresse source utilisée (datagram.address) est celle du BBMD et non celle du device (adresse d'origine dans le BVLC ignorée).

**Correction :** Calculer le début du NPDU selon la fonction BVLC (4 ou 10), lire le control à cet offset, et pour 0x04 utiliser l'adresse/port contenus dans l'en-tête Forwarded comme source.

### [majeur] Dédoublonnage _seenDevices : whoIs, scanIpRange et la connexion BACnet ne trouvent plus rien après une première découverte
`lib/data/services/bacnet_service.dart:308` · bug · confiance high

_handleIAm ignore silencieusement tout I-Am d'un deviceId déjà vu avec la même IP (l.337 'return') et n'émet rien sur iAmStream. Seul discoverLocalDevices appelle clearSeenDevices(). whoIs() (utilisé par active_connection_provider._connectBacnet l.166 et testConnection sans deviceId) et scanIpRange() s'abonnent à iAmStream : si le device a déjà été vu (ex. découverte broadcast puis connexion, ou 2e scan), la liste revient vide -> 'Aucun device BACnet n'a répondu' alors que le device répond. whoIs n'est de plus pas filtré par host : devices.first peut être un autre device répondant en broadcast pendant la fenêtre.

**Correction :** Séparer le cache de conflits du flux d'événements : émettre chaque I-Am (avec flag 'nouveau'), ou appeler clearSeenDevices() au début de whoIs/scanIpRange ; dans whoIs unicast filtrer sur l'adresse cible. Pour un deviceId connu, lire device,4194303 (wildcard) au lieu de Who-Is.

### [majeur] ReadRange : drapeaux de résultat (first-item/last-item/more-items) mal décodés, moreItems toujours faux
`lib/data/services/bacnet/bacnet_decoder.dart:536` · conformite-bacnet · confiance high

BACnetResultFlags est un BIT STRING MSB-first : first-item=0x80, last-item=0x40, more-items=0x20. Le décodeur prend data[offset+1] et teste (resultFlags & 0x01), bit de bourrage toujours à 0 -> moreItems est constamment false. Conséquence dans readTrendLogBuffer (bacnet_service.dart:1875) : la fin du buffer est déduite de `records.length < requestCount`, alors qu'un device peut renvoyer moins de 65 records parce que l'APDU est plein (c'est précisément le symptôme décrit dans solution_OK_trend_Bacnet.md) : la pagination s'arrête prématurément et l'historique est silencieusement tronqué.

**Correction :** Utiliser (flags & 0x20) pour more-items et (flags & 0x40) pour last-item ; dans readTrendLogBuffer continuer tant que firstSequenceNumber>1 et qu'on n'a pas atteint maxRecords, en s'arrêtant sur firstItem/records vides plutôt que sur le nombre de records.

### [majeur] WriteProperty weekly-schedule avec arrayIndex : élément de tableau sans enveloppe [0]
`lib/data/services/bacnet/bacnet_encoder.dart:796` · conformite-bacnet · confiance medium

BACnetDailySchedule ::= SEQUENCE { day-schedule [0] SEQUENCE OF BACnetTimeValue }. Pour l'écriture des 7 jours le code entoure bien chaque jour de 0x0E/0x0F, mais pour l'écriture d'un seul jour (dayIndex 1..7, utilisé par writeDailySchedule) il émet les TimeValue 'à nu' entre 3E/3F sans l'enveloppe [0] : le device doit rejeter (invalid-data-type / parameter out of range) ou mal l'interpréter. Le commentaire du code dit explicitement 'pas d'encapsulation supplémentaire', ce qui contredit le décodeur (_decodeWeeklyScheduleValue) qui attend bien [0] par jour.

**Correction :** Toujours encadrer le DailySchedule par 0x0E ... 0x0F, y compris quand arrayIndex est spécifié ; ajouter un test d'aller-retour encode/decode.

### [majeur] CharacterString : UTF-8 décodé comme Latin-1, autres encodages ignorés
`lib/data/services/bacnet/bacnet_decoder.dart:918` · bug · confiance high

Les deux branches (encoding==0 et else) font String.fromCharCodes(octets) : un nom UTF-8 'Température'/'Chaudière'/'°C' donne 'TempÃ©rature'. Les encodages 4 (UCS-2/UTF-16BE), 5 (ISO 8859-1), 3 (UCS-4) renvoyés par certains contrôleurs sont aussi mal lus. L'encodeur, lui, écrit en UTF-8 : asymétrique, donc writeDescription corrompt/relit mal les accents.

**Correction :** encoding 0 -> utf8.decode(bytes, allowMalformed:true) ; 4 -> décodage UTF-16BE ; 5 -> latin1.decode ; 3 -> UCS-4.

### [majeur] Résultat de writeProperty ignoré : succès affiché alors que le device a refusé
`lib/application/providers/points_provider.dart:860` · bug · confiance high

BacnetService.writeProperty ne lève jamais d'exception sur Error/Reject/Abort/timeout, il retourne un BacnetResponse. _forceInputBacnet (l.860, out-of-service), _releaseInputBacnet (l.939) et _writeDescriptionBacnet (l.1006) n'examinent pas isSuccess : ils mettent l'état local à jour et retournent true. Pire pour _forceInputBacnet : si out-of-service=true réussit puis l'écriture de present-value échoue, l'entrée reste hors service sans rollback ni erreur. (writePointValue, lui, vérifie bien.)

**Correction :** Vérifier response.isSuccess et lever/retourner false avec le message d'erreur ; dans forceInput, remettre out-of-service=false si la 2e écriture échoue.

### [majeur] Corrélation des réponses par invokeId seul, sans adresse source, sans retry ni limite de concurrence
`lib/data/services/bacnet_service.dart:355` · bug · confiance medium

_pendingRequests est indexé par invokeId uniquement et _handleResponse ne compare jamais datagram.address à l'hôte interrogé. Plusieurs devices interrogés en parallèle (super_favorites, trend, points) peuvent se voler leurs réponses si les invokeId coïncident (compteur partagé 1..255 sans test d'occupation : un wrap écrase silencieusement un completer en attente, l.361). Un hôte du LAN peut aussi forger un SimpleAck/ComplexAck à invokeId prévisible (séquentiel). L'onTimeout (l.371) supprime l'entrée par id, ce qui peut supprimer la requête plus récente ayant réutilisé l'id. Aucun retry sur timeout/Abort/device-busy (APDU_Timeout/retries de la spec : 3 essais), un paquet UDP perdu = échec dur après 5 s ; aucune limite de requêtes simultanées par device alors que refresh, trend et schedule partagent le même socket.

**Correction :** Clé = (host,port,invokeId) ; allouer un invokeId libre (sauter ceux en cours) ; retry 2-3 fois avec même invokeId sur timeout et sur Error/Abort 'busy' ; sémaphore par device (ex. 4 requêtes max).

### [majeur] refreshMultiplePointValues : une requête RPM par point (N requêtes) alors que RPM accepte plusieurs objets
`lib/data/services/bacnet_service.dart:1351` · performance · confiance high

Chaque point déclenche son propre readPropertyMultiple avec un seul ReadPropertyMultipleItem (batchSize=10 requêtes en parallèle). Pour 300 points = 300 aller-retours par cycle de rafraîchissement, alors que l'encodeur supporte une liste d'items et qu'un APDU de 1476 octets contient ~20-30 objets. Les units (statiques) sont relues à chaque cycle. Même N+1 dans discoverObjects (l.922 : boucle séquentielle d'un RPM par objet, sans progression) et _findStateTextsFromMultistateByName (un readProperty séquentiel par objet).

**Correction :** Regrouper 15-25 objets par RPM (en respectant la taille d'APDU et en retraitant les objets partiels), ne relire units/stateText qu'à la découverte, paralléliser la découverte par lots.

### [majeur] Fallback ReadProperty en cascade déclenché aussi par un simple timeout
`lib/data/services/bacnet_service.dart:1044` · performance · confiance medium

Quand le RPM échoue (rpmResult.isSuccess faux, y compris timeout : _sendAndWait retourne BacnetResponse.error -> parseError), _readObjectProperties (l.1044), _readTrendLogProperties (l.1599) lancent 6 à 9 readProperty séquentiels, chacun avec timeout de 5 s. Si le réseau coupe en cours de découverte, on attend jusqu'à ~45 s par objet, sur des centaines d'objets. Rien ne distingue timeout, Reject(unrecognized-service) et Error de propriété.

**Correction :** Ne basculer sur le fallback que pour Reject/Abort/Error indiquant que RPM n'est pas supporté ; sur timeout, abandonner (ou 1 retry) ; mémoriser par device 'RPM non supporté'. Ajouter un type BacnetResponseType.timeout.

### [majeur] Interface sélectionnée : bind sur l'IP unicast, les I-Am envoyés en broadcast ne sont pas reçus sous Linux
`lib/data/services/bacnet_service.dart:112` · bug · confiance medium

Avec une interface choisie, le socket est lié à l'adresse de l'interface (InternetAddress(bindInterface.address)). Sous Linux un socket lié à une IP unicast ne reçoit pas les datagrammes destinés à l'adresse de broadcast : les I-Am (souvent émis en broadcast local en réponse au Who-Is) sont perdus, la découverte semble vide. Le bloc 'Essayer de joindre l'adresse broadcast' (l.121-128) ne fait en réalité que logger l'adresse locale et n'a aucun effet. (La machine cible est Ubuntu.)

**Correction :** Lier sur anyIPv4 et choisir l'interface d'envoi autrement, ou ouvrir un second socket lié à l'adresse de broadcast du sous-réseau ; supprimer le bloc mort.

### [mineur] Conflit Device ID : adresse en double et alertes répétées à chaque I-Am
`lib/data/services/bacnet_service.dart:315` · bug · confiance high

Pour un deviceId déjà vu à l'adresse A, chaque nouvel I-Am venant de B (3 Who-Is envoyés par discoverLocalDevices, plus retours) appelle withConflict(B) sans vérifier que B est déjà dans conflictingAddresses : la liste devient [B,B,B], allAddresses contient des doublons, conflictStream émet 3 DeviceIdConflict et l'écran empile 3 snackbars/entrées dans _conflicts. Un device multi-homé ou relayé par BBMD (voir Forwarded) est aussi faussement signalé en conflit.

**Correction :** Ignorer l'événement si address est déjà connue (premier ou conflictingAddresses) ; dédupliquer allAddresses ; ne signaler qu'une fois par deviceId.

### [mineur] _parseStateText supprime les libellés vides -> décalage des index multistate
`lib/data/services/bacnet_service.dart:1293` · bug · confiance high

state-text est un tableau indexé par la valeur (1-based). Le filtre `.where((s) => s.isNotEmpty)` supprime les entrées vides au milieu du tableau : si l'état 2 n'a pas de texte, l'état 3 est affiché avec le libellé de l'état 4, etc. (stateText[value-1] est utilisé partout, ex. bacnet_type_utils.dart:156).

**Correction :** Conserver les positions (remplacer null/vide par une chaîne vide ou null) et n'ignorer que les chaînes vides en fin de liste.

### [mineur] Adresse de broadcast calculée en /24 en dur (dupliquée) et Who-Is vers loopback/docker
`lib/data/services/bacnet_service.dart:785` · conformite-bacnet · confiance high

_getLocalBroadcastAddresses (l.800) et NetworkInterfaceChoice.listAvailable (network_interface_choice.dart, 'simplification /24', subnetMask jamais renseigné) fabriquent a.b.c.255 quel que soit le masque : réseau /16, /23 ou /25 -> broadcast incorrect, device jamais trouvé. En mode 'toutes interfaces' NetworkInterface.list inclut aussi loopback et ponts docker/VM (172.17.0.255…). whoIs() considère aussi tout hôte finissant par '.255' comme broadcast (l.508) : un device unicast en x.x.1.255 reçoit un BVLC 'Original-Broadcast'. Aucun Who-Is en Distribute-Broadcast-To-Network/BBMD (Foreign Device) pour les sous-réseaux distants.

**Correction :** Calculer le broadcast avec le préfixe réel (lire le masque via ip/ifconfig ou saisie utilisateur), mutualiser le calcul dans NetworkInterfaceChoice, exclure loopback et interfaces virtuelles, déduire broadcast depuis un paramètre explicite plutôt que '.255'.

### [mineur] Devices routés injoignables : SNET ignoré, port source des I-Am perdu
`lib/data/services/bacnet_service.dart:253` · conformite-bacnet · confiance medium

Le décodeur saute le SNET/SADR du NPDU sans l'exposer, et IAmInfo.networkNumber n'est jamais renseigné : tous les devices derrière un routeur apparaissent avec l'IP du routeur et aucune requête (encodeur : NPDU sans DNET) ne peut les adresser. IAmInfo ne stocke pas non plus datagram.port, alors que discover_bacnet_screen.dart code '47808' en dur (l.138, 263 _selectDevice) : un device sur un autre port UDP est enregistré avec le mauvais port. Les phases 1 et 3 de discoverLocalDevices (Who-Is-Router, Who-Is vers DNET) découvrent donc des réseaux dont les devices ne sont pas exploitables.

**Correction :** Extraire SNET/SADR dans la réponse, stocker port et network/MAC dans IAmInfo/Connection, et encoder DNET/DADR dans les requêtes confirmées vers un device routé.

### [mineur] Exceptions de décodage avalées : la requête attend le timeout au lieu d'échouer immédiatement
`lib/data/services/bacnet_service.dart:261` · bug · confiance medium

Le catch vide de _handleResponse (l.261-264) ignore toute erreur de décodage (RangeError sur paquet tronqué par exemple). Si la réponse est celle d'une requête en attente, son invokeId n'est jamais résolu : l'appelant attend 5 s puis reçoit 'Timeout waiting for response' qui masque la vraie cause (réponse malformée). Idem les accès data[offset+1..2] sans contrôle de taille dans _decodeComplexAck/_decodeError/_decodeReject/_decodeAbort. Par ailleurs un seul receive() est lu par événement 'read' (l.204) : sous rafale d'I-Am, des datagrammes peuvent n'être traités qu'au prochain événement.

**Correction :** Extraire l'invokeId en premier et, en cas d'exception, compléter le completer avec une erreur de parsing ; boucler `while ((d = socket.receive()) != null)` ; logger au niveau debug.

### [mineur] priority-array : priorité 16 jamais considérée comme forçage et valeurs null rejetées
`lib/data/services/bacnet_service.dart:1207` · bug · confiance medium

_parsePriorityArray ne parcourt que les 15 premiers index (i<15) ; une commande à la priorité 16 (celle utilisée par défaut par un WriteProperty sans priorité, cf. _writeValueBacnet) n'est jamais détectée. Le décodeur RPM supprime en outre toute propriété dont la valeur est un unique Null (bacnet_decoder.dart ~l.263 `finalValue != null || hasStructuredValue`) et les erreurs de propriété ([5] error) sont ignorées sans trace (PropertyResult.error jamais renseigné), ce qui rend impossible de distinguer 'propriété inexistante' de 'valeur null'.

**Correction :** Parcourir 16 entrées en documentant le choix ; renseigner PropertyResult.error avec class/code décodés depuis l'opening tag [5].

### [mineur] ReadProperty ACK : valeurs construites non décodées (contrairement au RPM) et saut de closing tag par balayage d'octets
`lib/data/services/bacnet/bacnet_decoder.dart:186` · bug · confiance medium

_decodeReadPropertyAck boucle sur _decodeApplicationValue qui retourne null pour tout tag contextuel/opening (ex. log-device-object-property, list-of-object-property-references, date-time) : la valeur est null sans le fallback _decodeConstructedValue utilisé par RPM. Les helpers de lecture de log record, weekly-schedule et RPM sautent aussi jusqu'au prochain octet 0x0F/0x1F/0x3F en balayant les données brutes, ce qui peut s'arrêter sur un octet de donnée (ex. un REAL 0x3F800000 = 1.0f contient 0x3F). Les tags de numéro >=15 (extended tag number) et les longueurs étendues d'unsigned contextuels (len==5) ne sont pas gérés.

**Correction :** Écrire un lecteur de tags unique (tag number étendu, longueur étendue, opening/closing avec profondeur) et l'utiliser partout ; appliquer le décodage construit aussi à ReadProperty.

### [mineur] Log record : timestamp inventé (now) si illisible, status flags bruts
`lib/data/services/bacnet/bacnet_decoder.dart:619` · bug · confiance medium

_decodeLogRecord retourne un enregistrement avec `timestamp ?? DateTime.now()` (via TrendLogRecordData) quand seul logValue est décodé : une valeur de trend est alors affichée à l'heure courante au lieu d'être rejetée. La date utilise DateTime(year,month,day…) avec month/day wildcard 255 (non validés) qui débordent silencieusement. Le statusFlags est exposé comme l'octet brut data[offset+1] (MSB-first, in-alarm=0x80) sans documentation, et les logDatum 'failure' [8] (opening tag 0x8E) sont mal lus comme un tag de longueur 6.

**Correction :** Rejeter les records sans timestamp valide, valider les champs de date, décoder les statusFlags en bits nommés et gérer le choix failure [8] et any-value [10].

### [mineur] Formatage binaire/multistate dupliqué à 5 endroits
`lib/presentation/shared/utils/bacnet_type_utils.dart:156` · duplication · confiance high

La conversion 'valeur multistate -> libellé (valeur)' existe dans BacnetTypeUtils.formatMultiStateValue (l.145-168) et formatMultiStateValueFromRaw (l.205-222), ainsi que dans BacnetObject.formattedMultiStateValue (bacnet_object.dart:236-262) et currentStateLabel (l.264-283). 'valeur binaire active ?' est dupliquée à l'identique : BacnetTypeUtils.isBinaryActive (l.80) et BacnetObject._isBinaryValueActive (bacnet_object.dart:285). formatValue et formatOverrideValue partagent aussi tout leur corps (branches binaire/num/units). Ces copies divergent déjà sur le format (avec ou sans '(valeur)').

**Correction :** Garder une seule implémentation (méthodes sur BacnetObject ou BacnetTypeUtils) et faire appeler les autres ; formatValue(point, rawValue) paramétré.

### [mineur] Constructions de BacnetObject/TrendLog dupliquées (RPM vs ReadProperty) et ids de propriété lus en 4 variantes
`lib/data/services/bacnet_service.dart:1581` · duplication · confiance high

_createBacnetObjectFromProperties/…FromPropertiesMap et _createTrendLogFromProperties/…FromPropertiesMap ne diffèrent que par la conversion List<PropertyResult> -> Map ; les blocs 'RPM puis fallback boucle readProperty' sont recopiés dans _readObjectProperties, _readTrendLogProperties (et partiellement readScheduleBasicInfo). discoverObjects, discoverTrendLogs et discoverSchedules relisent chacun l'object-list entière (3+ lectures par session, plus celle de _findStateTextsFromMultistateByName) sans cache par device. Les 3 écritures de weekly-schedule (writeWeeklySchedule, writeDailySchedule + encodeWriteDailyScheduleRequest qui reconstruit un planning vide) répètent aussi le même flux.

**Correction :** Extraire un helper readPropertiesWithFallback(objectType, instance, propertyIds) -> Map<int,dynamic> et un cache object-list par (host,deviceId) invalidé à la reconnexion.

### [mineur] Code mort dans le périmètre BACnet
`lib/data/services/bacnet_service.dart:697` · code-mort · confiance high

scanIpRange() n'a aucun appelant dans lib/ (l'UI correspondante a disparu, seules les chaînes l10n subsistent) ; BacnetEncoder.encodeWeeklySchedule et encodeDailySchedule (bacnet_encoder.dart ~l.700-730) ne sont appelées nulle part ; BacnetUnits/constantes bacnetDefaultTimeout et bacnetDefaultPort, BacnetTypeUtils.isPointType ne sont pas référencées ; le bloc 'joindre l'adresse broadcast' d'init() (l.121-128) ne fait que logger ; ReadRangeType.byPosition/byTime et Who-Is avec lowLimit seul (encodage invalide : la spec exige low ET high ensemble) ne sont pas utilisés. scanIpRange parse aussi avec int.parse non protégé (FormatException) et attend 500 ms par lot de 10 IP (13 s pour un /24) alors qu'il suffirait d'envoyer puis d'attendre une fois.

**Correction :** Supprimer ou réactiver scanIpRange (avec correction du dédoublonnage), retirer les helpers d'encodage et constantes inutilisés.

### [mineur] Une requête de détails par événement I-Am, sans limite, et rebuild complet à chaque événement
`lib/presentation/screens/connections/discover_bacnet_screen.dart:140` · performance · confiance medium

Chaque émission de iAmStream (nouveau device ET chaque mise à jour de conflit) déclenche _fetchDeviceDetails -> testConnection (un RPM par device, sans file ni plafond). Sur un réseau de 200 contrôleurs, 200 requêtes partent en rafale juste après les Who-Is, avec risque de collisions d'invokeId (compteur modulo 256) et de pertes UDP ; en cas de conflits répétés la même requête est renvoyée. Chaque événement fait aussi un setState complet avec indexWhere O(n). _onInterfaceChanged utilise ref.read après un await sans test mounted (l.85-91), et _startBroadcastDiscovery appelé depuis le refresh pendant une découverte précédente peut créer deux abonnements au flux (le premier `subscription` n'est annulé que dans le finally de son propre appel).

**Correction :** File d'attente avec concurrence 4-5 et ne récupérer les détails qu'une fois par (deviceId,adresse) ; tester mounted avant ref.read ; désactiver tout nouveau lancement tant qu'une découverte est en cours.

### [mineur] Cycle de vie du service : controllers fermés définitivement par dispose, requêtes en attente non résolues
`lib/data/services/bacnet_service.dart:156` · architecture · confiance medium

dispose() ferme _iAmController/_routerController/_conflictController (final, non recréables) : après dispose() tout réemploi du même BacnetService (listen sur flux fermé) ne reçoit plus aucun événement, sans erreur. rebindToInterface() et dispose() vident _pendingRequests sans compléter les completers : les appelants attendent leur timeout de 5 s ; le provider (keepAlive) rend le cas rare mais rebindToInterface est appelé depuis l'UI pendant que des refresh/lectures de trend peuvent être en vol. Le service mélange transport UDP, encodage de flux, découverte, parsing de modèles (status-flags, priority-array en Map/String/int) et modèles de domaine (BacnetTrendLog, BacnetScheduleInfo, IAmInfo dans le même fichier de 2500 lignes).

**Correction :** Compléter les requêtes en attente avec une erreur lors de rebind/dispose ; scinder en BacnetTransport (socket + corrélation), BacnetDiscovery, BacnetPointsClient, BacnetSchedulesClient et déplacer les modèles dans domain/models ; supprimer les formats d'entrée spéculatifs (String/int/Map) de _parseStatusFlags que le décodeur ne produit jamais.

## Données (Drift, cache) (21 constats)

Le périmètre (Drift + cache + mDNS) est globalement lisible et les mots de passe sont bien dans flutter_secure_storage (la DB ne contient que passwordKey). Les vrais problèmes : le cache des points n'est jamais rafraîchi à cause de cachedAt (upsert sans mise à jour du timestamp), le cache n'est jamais invalidé après modification ou suppression d'une connexion, la suppression de connexion laisse des lignes orphelines (aucun PRAGMA foreign_keys, aucune cascade), et l'import JSON crée des connexions avec passwordKey '' partagé. Beaucoup de code mort dans app_database.dart (nombreuses méthodes jamais appelées, CacheService.clearExpiredCache jamais déclenché). Pas d'index ni de transactions sur plusieurs écritures liées (favoris, dashboards, dossiers).

### [majeur] Cache des points jamais rafraîchi : cachedAt non mis à jour par l'upsert
`lib/data/database/app_database.dart:513` · bug · confiance medium

cachePoints() fait insertAllOnConflictUpdate avec des CachedPointsCompanion.insert(...) sans cachedAt (cache_service.dart:43-53). Drift n'inclut dans le DO UPDATE que les colonnes présentes ; cachedAt (default SQL currentDateAndTime) garde donc la valeur de la première insertion. isPointsCacheValid() (l.495-505) lit une ligne arbitraire (limit 1) et compare son cachedAt à 24h. Scénario : 1re connexion jour J, cache valide 24h ; à J+1 le cache est déclaré invalide à chaque fois, même s'il vient d'être réécrit, donc l'affichage instantané depuis le cache (points_provider.dart:261) est perdu définitivement. Inversement, si la ligne lue est récente et d'autres anciennes, la validité est aléatoire. clearExpiredCache n'étant jamais appelée, rien ne remet le cache à neuf.

**Correction :** Passer cachedAt: Value(DateTime.now()) dans cacheStaticPoints, et valider via MIN/MAX(cachedAt) ou supprimer puis réinsérer dans une transaction.

### [majeur] Cache des points : les points supprimés sur l'automate ne sont jamais retirés
`lib/data/services/cache_service.dart:41` · bug · confiance high

cacheStaticPoints n'écrit que des upserts, sans purge préalable des lignes de la connexion. Scénario : un point AV:12 est supprimé de l'automate ; tant que le cache est 'valide', createFromCache() (l.85-101) le réaffiche (points_provider.dart:262-264) comme point fantôme, et il reste en base indéfiniment car les lignes absentes de la nouvelle liste ne sont jamais effacées. Le mapping/le tri utilisent aussi ces fantômes.

**Correction :** Dans une transaction : delete(cachedPoints) where connectionId puis batch insert (ou DELETE des pointRef absents).

### [majeur] Suppression d'une connexion : données liées orphelines, pas de transaction, FK non appliquées
`lib/application/providers/connection_providers.dart:116` · bug · confiance high

deleteConnection supprime le secret puis appelle deleteConnectionById (app_database.dart:128) qui ne supprime que la ligne connections. Aucun PRAGMA foreign_keys=ON / beforeOpen n'existe (grep) et aucune cascade n'est déclarée dans les tables : favorites, favorite_folders, favorite_folder_assignments, cached_* , dashboards et dashboard_widgets de cette connexion restent en base. Scénario : suppression d'une connexion puis nouvelle connexion : SQLite réutilise l'id max+1 (AUTOINCREMENT, donc pas de réutilisation ici), mais les favoris/dashboards fantômes restent à vie (dashboards.connectionId fantôme invisible mais jamais purgé) ; l'export/import ou un futur activage des FK ferait échouer le delete. De plus le secret est supprimé avant la ligne DB : si le delete DB échoue, la connexion existe sans mot de passe.

**Correction :** Dans AppDatabase, créer deleteConnectionCascade(id) en transaction (assignments, favorites, favorite_folders, caches, widgets, dashboards, connection) ; activer PRAGMA foreign_keys=ON dans beforeOpen et ajouter onDelete: KeyAction.cascade ; supprimer le secret après la réussite du delete DB.

### [majeur] Import JSON : passwordKey vide partagé entre toutes les connexions importées
`lib/application/providers/settings_provider.dart:315` · bug · confiance high

importConnectionsFromJson insère passwordKey: '' pour chaque connexion (l.315). Dans updateConnection (connection_providers.dart:93-96), 'secureStorage.write(key: existing.passwordKey, ...)' écrit alors sous la clé '' ; toutes les connexions importées partagent ce même slot. Scénario : on importe A et B, on saisit le mot de passe de A en édition, puis celui de B : B écrase le secret de A, les deux se connectent avec le mot de passe de B. Avant saisie, _connectDistechApi lit la clé '' (active_connection_provider.dart:299) et renvoie 'Mot de passe introuvable'. De plus le champ withLength(min:1) de la table n'est pas respecté par '' (non validé par SQLite, mais contrat violé).

**Correction :** Générer une clé unique à l'import (conn_pwd_<uuid>) comme createConnection, ou passer par ConnectionRepository.createConnection avec password vide.

### [majeur] Modification d'une connexion (host/port/type) sans invalidation du cache
`lib/application/providers/connection_providers.dart:71` · bug · confiance medium

Le cache (cached_points, device_info, trend mapping, summary) est indexé uniquement par connectionId. updateConnection change host/port/connectionType/bacnetDeviceId sans appeler clearAllCache. Scénario : l'utilisateur réutilise une entrée en changeant l'IP pour pointer un autre automate ; pendant 24h (points) / 1h les points, modèle et compteurs de l'ancien automate sont affichés (points_provider.dart:261, active_connection_provider.dart:334) puis mélangés avec les valeurs live du nouveau (mergeWithCache).

**Correction :** Appeler CacheService.clearAllCache(id) dans updateConnection lorsque host, port, connectionType ou bacnetDeviceId changent.

### [mineur] Import : connectionType par défaut 'api' invalide, bacnetDeviceId et designerUrl perdus
`lib/application/providers/settings_provider.dart:316` · bug · confiance high

Valeur par défaut 'api' alors que le schéma/les connexions utilisent 'distech_api' (connection_providers.dart:47). L'export écrit bacnetDeviceId (l.~214) mais l'import ne le relit pas, et designerUrl n'est ni exporté ni importé. Scénario : sauvegarde puis restauration d'une connexion BACnet avec Device ID 1234 : le device ID est perdu ; une connexion ancienne sans champ reçoit 'api', valeur absente de tous les switch connectionType == 'bacnet'/'distech_api'. L'unicité host:port ignore aussi le type (deux connexions BACnet/API sur même host:port => la 2e est ignorée).

**Correction :** Défaut 'distech_api', lire bacnetDeviceId et designerUrl, exporter designerUrl, inclure connectionType dans la clé de dédoublonnage.

### [mineur] clearAllCacheGlobal oublie cached_trend_log_mapping ; stats chargent toutes les lignes
`lib/application/providers/settings_provider.dart:378` · bug · confiance high

Le bouton 'vider le cache' (settings_screen.dart:459) supprime points, device info, summary mais pas cachedTrendLogMapping (commentaire l.382 erroné). Le mapping périmé reste utilisé jusqu'à 1h. getGlobalCacheStats (l.386-389) fait select(...).get() de toutes les lignes pour ne prendre que .length (plusieurs milliers de lignes cached_points matérialisées sur le thread UI) au lieu d'un COUNT.

**Correction :** Ajouter delete(cachedTrendLogMapping).go() (ou utiliser AppDatabase.clearAllCache par connexion) et utiliser selectOnly + count().

### [mineur] Suppression d'un favori laisse des assignations de dossier orphelines
`lib/data/database/app_database.dart:297` · bug · confiance medium

deleteFavoriteById (l.297) et deleteFavorite (l.302) ne suppriment pas les lignes de favorite_folder_assignments. Scénario : un favori assigné au dossier F est retiré ; l'assignation reste, donc countFavoritesInFolder (l.915, compte sur assignments seuls) et tout affichage basé sur la table d'assignation surcomptent. Aucune transaction non plus pour deleteFavoriteFolder (l.769) : si la seconde suppression échoue, le dossier reste vide d'assignations.

**Correction :** Supprimer les assignations dans la même transaction, ou déclarer onDelete cascade et activer foreign_keys.

### [mineur] Courses read-then-write sans transaction (favoris, dashboards, synoptiques)
`lib/data/database/app_database.dart:310` · bug · confiance medium

toggleFavorite (l.310-335), addFavorite (l.288, MAX(sort_order)+1 puis insert), createDashboard (l.1180, utilise existing.length comme sortOrder), createSynoptic (l.984), upsertBinding (l.1065) enchaînent lecture et écriture hors transaction. Scénario : double tap rapide sur l'étoile : deux toggleFavorite lisent 'absent' puis insèrent ; le second viole l'uniqueKey (connectionId, pointRef) et lève une exception non gérée dans toggleFavorite (le try/catch n'existe que dans addFavorite côté provider). createDashboard avec length comme ordre produit des doublons de sortOrder après suppression d'un dashboard au milieu.

**Correction :** Envelopper dans transaction() et utiliser insertOnConflictUpdate/MAX(sortOrder)+1 ; pour les bindings, insertOnConflictUpdate sur l'unique (synopticId, svgElementId).

### [mineur] deleteFolderById, deleteDashboard, deleteFavoriteFolder : écritures multiples hors transaction
`lib/data/database/app_database.dart:226` · bug · confiance high

deleteFolderById (l.226-234), deleteDashboard (l.1218-1223) et deleteFavoriteFolder (l.769-776) font deux requêtes dépendantes sans transaction (contrairement à deleteSynoptic l.1019 qui en utilise une). Une erreur ou l'arrêt de l'app entre les deux laisse un état incohérent (connexions pointant vers un dossier supprimé, widgets orphelins).

**Correction :** Utiliser transaction(() async {...}) comme deleteSynoptic.

### [mineur] Import JSON : requêtes allFolders/allConnections répétées dans les boucles (N+1)
`lib/application/providers/settings_provider.dart:265` · performance · confiance high

Pour chaque dossier (l.265) et chaque connexion (l.293) importés, toute la table est relue en entier puis filtrée en Dart. Un import de 200 connexions = 200 SELECT complets. Pas de transaction : un échec au milieu laisse un import partiel.

**Correction :** Charger une fois les listes avant les boucles (et maintenir un Set host:port), et envelopper l'import dans db.transaction.

### [mineur] getFolderFavoriteCounts en N+1 (et jamais utilisée)
`lib/data/database/app_database.dart:925` · performance · confiance medium

Une requête COUNT par dossier de favoris (l.926-930). Aucun appelant dans lib/ (grep) : code mort qui serait un N+1 s'il était branché.

**Correction :** Supprimer, ou remplacer par un seul GROUP BY folder_id.

### [mineur] Validation du cache = requêtes redondantes ; réécriture complète du cache à chaque chargement
`lib/data/services/cache_service.dart:21` · performance · confiance medium

getStaticPointsCache fait isPointsCacheValid (SELECT limit 1) puis getAllCachedPoints ; getCachedDeviceInfo fait isDeviceInfoCacheValid (qui rappelle getCachedDeviceInfo) puis getCachedDeviceInfo : 2 SELECT identiques. getCacheStats (l.255-267) relit device info, trend et summary en entier juste pour un booléen. À chaque loadPoints (points_provider.dart:302) tous les points (milliers possibles) sont ré-upsertés, non attendus, sans diff, en doublon avec la lecture déjà faite.

**Correction :** Lire une seule fois puis tester cachedAt ; ne réécrire que si le contenu a changé ou si le cache est expiré.

### [mineur] Accès DB placé en extension dans un provider, au lieu de AppDatabase/CacheService
`lib/application/providers/settings_provider.dart:376` · architecture · confiance high

AppDatabaseCacheExtension (clearAllCacheGlobal, getGlobalCacheStats, allFolders, allConnections) vit dans settings_provider.dart alors que AppDatabase.getAllConnections() (l.~104) et getAllFolders() (l.~207) existent déjà : doublons (allConnections vs getAllConnections, allFolders vs getAllFolders). La logique de cache est répartie sur 3 endroits : AppDatabase, CacheService (qui n'est qu'un passe-plat try/catch) et cette extension.

**Correction :** Déplacer ces méthodes dans AppDatabase/CacheService et supprimer les doublons.

### [mineur] God class AppDatabase (1320 lignes) avec logique de présentation et de cache
`lib/data/database/app_database.dart:1` · architecture · confiance high

Une seule classe porte CRUD de 13 tables, politique d'expiration (constantes de durée), sérialisation JSON du trend mapping (l.579-622) et jointures. Tests et lecture difficiles. Drift permet des DAOs (@DriftAccessor) par domaine (connexions, favoris, cache, synoptiques, dashboards).

**Correction :** Découper en DAOs par domaine.

### [mineur] Migrations : aucun beforeOpen (foreign_keys), aucun index, pas de test de migration
`lib/data/database/app_database.dart:43` · architecture · confiance high

onUpgrade enchaîne createTable/addColumn corrects (v1 à v12), mais il n'y a pas de beforeOpen pour activer PRAGMA foreign_keys, pas de transaction explicite ni de vérification (validateDatabaseSchema), et aucun index secondaire : dashboards.connection_id, synoptics.connection_id, favorite_folder_assignments.folder_id (la contrainte unique est sur (favoriteId, folderId), donc les recherches par folderId seule ne l'utilisent pas), cached_* hors PK. Négligeable sur de petits volumes, mais getFavoritesInFolder/countFavoritesInFolder scannent la table. Synoptics.connectionId (synoptics_table.dart) n'a pas de references() contrairement aux autres tables.

**Correction :** Ajouter @TableIndex sur les colonnes de jointure, beforeOpen avec foreign_keys=ON, et utiliser les schema tests de drift_dev.

### [mineur] Exceptions de décodage avalées sans log ; cache trend mapping cast fragile
`lib/data/database/app_database.dart:592` · bug · confiance medium

getCachedTrendLogMapping attrape toute erreur de jsonDecode/cast (value as int) avec catch(_) et renvoie null sans log, et ne supprime pas la ligne corrompue : elle est relue (et échoue) à chaque ouverture jusqu'à expiration. Par ailleurs CacheService.getStaticPointsCache avale toutes les erreurs DB (cache_service.dart:34-37), masquant un échec de migration en simple 'cache vide'.

**Correction :** Logger l'erreur et supprimer la ligne corrompue.

### [mineur] Secure storage : options par plateforme minimales, nom d'utilisateur en clair en DB
`lib/application/providers/connection_providers.dart:8` · securite · confiance low

FlutterSecureStorage est configuré avec encryptedSharedPreferences seulement (Android) ; pas d'options iOS/macOS (accessibility) ni Linux/Windows. Le mot de passe n'est pas en DB (OK, seule la clé passwordKey l'est), mais username, host et certificateFingerprint sont en clair dans mydumcontrol.db, et la DB n'est pas chiffrée. L'export JSON (settings_provider.dart:201-217) écrit username et hôtes en clair dans un fichier temporaire partagé via Share, sans mot de passe (correct). Risque limité aux métadonnées.

**Correction :** Si la sensibilité l'exige, chiffrer la DB (sqlcipher) ; sinon documenter. Définir IOSOptions(accessibility: first_unlock_this_device).

### [mineur] Nombreuses méthodes AppDatabase jamais appelées
`lib/data/database/app_database.dart:480` · code-mort · confiance high

Aucune référence en dehors de app_database.dart (grep lib/) pour : getCachedPoint (l.480), cachePoint (l.508), clearExpiredCache (l.692) et CacheService.clearExpiredCache (cache_service.dart:249, jamais déclenché : aucune maintenance du cache n'est exécutée), getFolderFavoriteCounts (l.925), countFavoritesInFolder (l.915), getPointRefsForSynoptic (l.1140), deleteAllBindingsForSynoptic (l.1125), createBinding (l.1090), updateBinding (l.1095), getBindingById (l.1053), getAllSynoptics/watchAllSynoptics (l.939/944), updateSynoptic (l.997), countDashboardWidgets (l.1312), getAllSuperFavoritesGrouped/getSuperFavoritesByConnection/countSuperFavorites. Ajoute aussi la pagination de surface de test inutile.

**Correction :** Supprimer les méthodes non utilisées ; brancher clearExpiredCache au démarrage si l'on veut un vrai nettoyage.

### [mineur] Logique de validité/expiration du cache copiée 4 fois
`lib/data/database/app_database.dart:638` · duplication · confiance high

Les quatre caches (points l.494, device info l.551, trend mapping l.579-609, summary l.639-663) répliquent 'select where connectionId, getSingleOrNull, DateTime.now().difference(cachedAt) < maxAge' ; getCachedX et isXValid dupliquent la même requête. Même pattern dupliqué pour les 4 clear*Cache (l.520/565/625/671) et clearExpiredCache (l.692). Les paires watch/get (watchSynopticsForConnection/getSynopticsForConnection, watchDashboardsForConnection/getDashboardsForConnection, watchAllSuperFavoritesGrouped/getAllSuperFavoritesGrouped, watchUnassignedFavorites/getUnassignedFavorites) dupliquent aussi leurs requêtes.

**Correction :** Extraire un helper générique isFresh(DateTime cachedAt, Duration maxAge) et construire les SimpleSelectStatement une fois (ex. _synopticsQuery(connectionId)) puis .get()/.watch().

### [mineur] Parseur mDNS : seuls les enregistrements 'answers' sont lus, pas additional ; stop() ne coupe pas l'attente
`lib/data/services/mdns_discovery_service.dart:176` · bug · confiance low

answerCount (l.157) ignore les sections authority/additional ; dans une réponse mDNS standard SRV/A sont souvent en additional, donc port reste 443 par défaut et l'IP est celle de la source. stop() (l.285) ferme le socket mais discoverEclypseDevices attend encore Future.delayed(timeout) (l.96) sans pouvoir être annulé, et _socket/_subscription sont des champs d'instance écrasés si discoverEclypseDevices est appelé deux fois en parallèle (fuite du premier socket jusqu'au finally). Le commentaire 'QU bit set (0x8001)' (l.142) ne correspond pas au code (0x0001). catch (e) vide à l.79.

**Correction :** Parser ancount+nscount+arcount, utiliser un Completer pour l'attente annulable, rendre les sockets locaux à l'appel.

## Providers A (connexion, points, courbes) (25 constats)

Périmètre providers audité en lecture seule. Les problèmes principaux sont des races entre connexions (réponses d'un ancien automate écrites dans l'état du nouveau), un `return` sans `await` dans `connect()` qui contourne le try/catch, et un rafraîchissement API qui recharge et réécrit tout le cache à chaque tick. Les providers de trend log ne sont pas autoDispose. `trendLogMappingProvider` watch tout l'état de connexion, donc il relance des requêtes réseau à chaque changement de champ. Il y a aussi du code mort (`_loadFromBacnet`/`_loadFromApi`, `_cachedBuffer`, réglages jamais consommés) et des exceptions avalées sur les écritures API. Aucun Timer ni StreamSubscription n'est détenu par ces providers : les Timers d'auto-refresh sont dans l'UI et annulés au dispose. Aucun secret en clair dans le périmètre (le mot de passe va dans secure storage, l'export JSON l'omet).

### [majeur] connect() : `return _connectX()` sans await, le try/catch ne protège rien
`lib/application/providers/active_connection_provider.dart:136` · bug · confiance high

Aux lignes 136 et 142, `return _connectBacnet(connection)` et `return _connectDistechApi(connection)` renvoient le Future sans `await` dans un bloc try. Toute exception levée ensuite (Who-Is qui jette, secureStorage.read, database.updateLastConnectedAt, cache) échappe au catch de la ligne 143. `isConnecting` reste alors à true indéfiniment et l'exception remonte non gérée à l'appelant (écran de connexion bloqué sur le spinner).

**Correction :** Utiliser `return await _connectBacnet(connection);` et `return await _connectDistechApi(connection);`.

### [majeur] Chargements en arrière-plan non liés à la connexion courante : un ancien automate écrase le nouveau
`lib/application/providers/active_connection_provider.dart:371` · bug · confiance high

`_loadDataInBackground` (API) et `_loadBacnetDataInBackground` ne vérifient que `mounted`, jamais que `state.connection?.id` est encore celui de la connexion lancée. Scénario : connexion à A, puis connexion rapide à B (l'ancien client est `dispose()` ligne 107). Les `then` de A qui arrivent après écrivent `deviceInfo`, `objectsSummary` et `controllerTime` de A dans l'état de B. Pire, le `catchError` de A (client disposé, donc erreur quasi certaine) met `deviceInfo = DeviceInfo(fallbackName de A)` et `isLoadingDeviceInfo=false` sur l'état de B. L'UI affiche alors le nom de l'automate A pendant que B est connecté. Même risque en BACnet (lignes 216-291).

**Correction :** Capturer `connection.id` (ou le `client`) au lancement et faire `if (!mounted || state.connection?.id != connectionId) return;` avant chaque écriture d'état. Idem pour `cacheService.cacheDeviceInfo`.

### [majeur] refresh() : `state.client!` crashe en connexion BACnet native
`lib/application/providers/active_connection_provider.dart:513` · bug · confiance high

`refresh()` ne teste que `state.isConnected`, qui est vrai en BACnet avec `client == null`. La ligne 513 fait `_loadDataInBackground(state.client!, ...)`, donc `Null check operator used on a null value` dès qu'on rafraîchit (pull-to-refresh sur l'écran d'accueil) avec une connexion BACnet. Les flags `isLoadingDeviceInfo`/`isLoadingSummary` mis à true ligne 506 restent alors bloqués.

**Correction :** Si `state.isBacnetConnection`, appeler `_loadBacnetDataInBackground(state.connection!, state.bacnetDeviceId!)` ; sinon la branche API.

### [majeur] Auto-refresh API : rechargement complet et réécriture du cache à chaque tick
`lib/application/providers/points_provider.dart:302` · performance · confiance high

Pour une connexion API, `refresh()` (ligne 409) et `refreshPointValue()` (ligne 487, appelée pour un seul point) appellent `loadPoints()`. Celui-ci fait `getAllPointsOptimized()` (tous les points) puis `cacheService.cacheStaticPoints(connectionId, points)` (ligne 302, non attendu) à chaque appel. Avec l'auto-refresh à 5 s (points_screen.dart:125-134), on refait un fetch complet de l'automate ECLYPSE (faible CPU) et on réécrit tout le cache SQLite toutes les 5 s, alors que les propriétés statiques ne changent pas. `isLoading=true` à chaque cycle fait aussi clignoter le spinner. Rafraîchir un seul point recharge aussi tout.

**Correction :** Séparer 'chargement initial (statique + cache)' et 'refresh valeurs'. Ne réécrire le cache que sur le premier chargement ou forceRefresh. Ne pas mettre `isLoading` pendant un refresh silencieux. Utiliser un endpoint de valeurs seules, ou au minimum ne pas recharger tout pour un point.

### [majeur] Race : réponse d'un ancien automate écrite dans l'état après changement de connexion
`lib/application/providers/points_provider.dart:290` · bug · confiance medium

`loadPoints` capture `connectionState.client` et `connectionId` avant les `await`, mais n'en revérifie aucun avant `state = state.copyWith(points: points)` (ligne 304) ni dans le catch. `connect()` appelle `reset()` (via `_clearDataProviders`) puis le nouveau chargement. Si le `getAllPointsOptimized()` de l'automate A se termine après le reset, il réinjecte les points de A dans `pointsProvider` alors que B est actif. Il écrit aussi le cache : `cacheStaticPoints(connectionId=A)` est correct, mais l'UI de B affiche les points de A et les écritures iraient vers A. Même problème pour `_loadPointsBacnet` (361-380) et `_refreshAllValuesBacnet` (438-464). Aucun garde de concurrence non plus : deux `loadPoints` simultanés (auto-refresh + pull-to-refresh) se chevauchent.

**Correction :** Après chaque await, comparer `_ref.read(activeConnectionProvider).connection?.id` à l'id capturé, ou utiliser un compteur de génération incrémenté dans `reset()` ; ignorer le résultat si différent. Ajouter un flag `_inFlight`.

### [majeur] emergencyRelease BACnet : 15 écritures séquentielles, échecs ignorés, retourne toujours true
`lib/application/providers/points_provider.dart:776` · bug · confiance medium

Dans la branche BACnet, la boucle `for priority 1..15` appelle `_releaseOverrideBacnet` qui capture ses erreurs et renvoie false. Le résultat est ignoré, puis `_updatePointLocally(isOverridden:false)` et `return true`. Si certaines priorités échouent (timeout, device occupé), l'UI affiche le point comme libéré alors qu'il reste forcé. Le fonctionnement séquentiel (15 aller-retours UDP, avec timeouts) est lent. Pas de priorité 16 (relinquish default n'est pas une priorité écrivable, donc correct), mais le commentaire ligne 774-775 est confus.

**Correction :** Agréger les résultats (`results.every`), ne mettre à jour localement que si tout réussit (ou refaire lire le priority-array), et paralléliser par petits lots ou lire d'abord le priority-array pour ne libérer que les priorités occupées.

### [majeur] trendLogMappingProvider watch tout activeConnectionProvider : relance des requêtes réseau à chaque champ qui change
`lib/application/providers/trend_log_provider.dart:20` · performance · confiance high

Ligne 20 : `ref.watch(activeConnectionProvider)` sur l'état complet. Chaque `copyWith` (deviceInfo chargé, objectsSummary, controllerTime, networkInfo, `refresh()` qui bascule les flags isLoading...) ré-évalue le provider. À chaque ré-évaluation avec cache non vide, `_refreshMappingInBackground` / `_refreshBacnetMappingInBackground` (lignes 39-55) relancent une découverte complète des trend logs (en BACnet : discoverTrendLogs, très coûteux en UDP). À la connexion cela fait au moins 4-5 relances successives. En plus, le résultat du refresh en arrière-plan n'est écrit que dans le cache : le provider retourne `cachedMapping` (ligne 57), donc l'UI ne voit jamais la mise à jour avant la prochaine ré-évaluation.

**Correction :** Utiliser `ref.watch(activeConnectionProvider.select((s) => (s.connection?.id, s.isBacnetConnection)))` plus `ref.read` pour le client. Déclencher le refresh d'arrière-plan une seule fois et invalider/mettre à jour le provider à la fin.

### [majeur] trendLogViewerProvider et multiCurveViewerProvider sans autoDispose : buffers conservés pour toute la session
`lib/application/providers/trend_log_provider.dart:543` · performance · confiance medium

Les deux `StateNotifierProvider.family` (trend_log_provider.dart:543, multi_curve_provider.dart:456) ne sont pas `autoDispose`. Chaque trend log ouvert garde jusqu'à 10 000 enregistrements (`_cachedFullData`, `_cachedBuffer` chaîne brute du JSON/texte API, qui peut peser plusieurs Mo) et son état tant que l'app vit, sans jamais être libéré. Avec le multi-courbes (8 instances x buffers + copie dans `_cachedTrendLogData`), la mémoire grossit. La clé de famille est l'instance seule (sans connectionId) : l'instance 300454 de deux automates partage donc le même notifier. Il n'est invalidé que si `loadData` est rappelé.

**Correction :** Passer en `StateNotifierProvider.autoDispose.family` avec clé `(connectionId, instance)` ; ne pas garder `_cachedBuffer`.

### [majeur] Multi-courbes : période ignorée par le cache du viewer, données non filtrées pour les instances déjà chargées, échecs silencieux
`lib/application/providers/multi_curve_provider.dart:277` · bug · confiance medium

`_loadSingleCurveData` appelle `notifier.loadData(period: state.selectedPeriod, forceRefresh: false)` sur le notifier partagé `trendLogViewerProvider(instance)`. Si ce viewer a déjà `_cachedFullData` (la vue simple a été ouverte avant), il ne refait aucun fetch : `setPeriod(...)` du multi-courbes (qui force `forceRefresh: true` ligne 205) ne propage donc pas le forçage au viewer ; seul le filtre est ré-appliqué sur un cache pouvant être trop court (voir le constat BACnet). De plus, le multi-courbes lit `viewerState.data` qui est déjà filtré/mis à jour par la vue simple, et partage ainsi l'état avec l'écran de détail ouvert en parallèle. Si une courbe échoue (`viewerState.error`), seul un warning est loggé : `loadData` ne positionne jamais `error`, l'utilisateur voit un graphique sans cette courbe sans explication. Le chargement est aussi séquentiel (ligne 243), N téléchargements en série pouvant durer des minutes en API.

**Correction :** Passer `forceRefresh` au viewer, remonter les erreurs par courbe dans l'état, et charger en parallèle (`Future.wait`) avec limite de concurrence.

### [mineur] Écritures API : exceptions avalées sans log, l'utilisateur ne sait pas pourquoi
`lib/application/providers/points_provider.dart:585` · bug · confiance high

Les blocs `catch (e) { return false; }` de writeValue (585), writeOverride (658), releaseOverride (730), emergencyRelease (802), forceInput (845) et releaseInput (924) ne loguent rien et ne conservent pas l'erreur, contrairement aux variantes BACnet qui font `_logger.e`. Un 401/403/timeout est indiscernable d'un refus logique de l'automate ; impossible à diagnostiquer sur le terrain.

**Correction :** Ajouter `_logger.e(...)` et exposer le message d'erreur (état ou exception typée).

### [mineur] Pattern API/BACnet dupliqué sur 8 opérations d'écriture
`lib/application/providers/points_provider.dart:551` · duplication · confiance high

writeValue, writeOverride, releaseOverride, emergencyRelease, forceInput, releaseInput, writeDescription (lignes 552-995) répètent le même squelette : lire activeConnectionProvider, tester isConnected, brancher BACnet/API, tester client==null, try/catch, `_updatePointLocally`. De même, `_bacnetObjectTypeToCode` (1025-1056) est une conversion enum -> code qui pourrait être une propriété de l'enum, et le tri 'type puis nom' est copié aux lignes 267, 293 et 369. Le notifier est un fichier de 1100 lignes qui mélange état de liste et accès service.

**Correction :** Extraire une abstraction 'PointTransport' (API/BACnet) avec une implémentation par type de connexion, et une méthode `_run(op)` commune ; déplacer le code de type dans l'enum ; factoriser le comparateur de tri.

### [mineur] ref.watch après un await dans un FutureProvider
`lib/application/providers/trend_log_provider.dart:41` · bug · confiance medium

`ref.watch(activeBacnetConnectionProvider)` est appelé aux lignes 41 et 64 après `await cacheService.getCachedTrendLogMapping(...)` (ligne 34). Riverpod déconseille ce schéma : après un trou asynchrone, l'abonnement n'est pas garanti de la même façon (les dépendances ajoutées tard peuvent être ignorées ou provoquer des rebuilds en cours de calcul). Le commentaire ligne 63 compte pourtant dessus pour réagir au changement de connexion BACnet.

**Correction :** Faire tous les `ref.watch` en tête de fonction avant le premier await.

### [mineur] _cachedBuffer jamais lu
`lib/application/providers/trend_log_provider.dart:238` · code-mort · confiance high

`_cachedBuffer` est assigné (lignes 415, 500, 518) mais jamais lu : il retient inutilement la chaîne brute entière en mémoire.

**Correction :** Supprimer le champ.

### [mineur] BACnet : maxRecords dépend de la période initiale, le cache est ensuite réutilisé pour des périodes plus longues
`lib/application/providers/trend_log_provider.dart:324` · bug · confiance medium

`_loadDataFromBacnet` lit `maxRecords` selon la période demandée (hour=10, day=150, ...). Le résultat est stocké dans `_cachedFullData`, puis `setPeriod` (lignes 506-508) réutilise ce cache en prétendant avoir 30 jours ('on a déjà 30 jours de données'). Scénario : ouverture avec TrendPeriod.hour (10 enregistrements), puis choix de 7j : le filtre s'applique à 10 points, et si au moins un est numérique, le graphique 7j n'en montre que 2h30. Le commentaire est faux pour BACnet.

**Correction :** Toujours charger le maximum de la période la plus large (ex. 3500) en BACnet, ou invalider `_cachedFullData` quand la nouvelle période dépasse la couverture chargée.

### [mineur] refresh() perd le mode 'Tout l'historique'
`lib/application/providers/trend_log_provider.dart:519` · bug · confiance high

`loadData` écrase `_loadAllData = allData` (ligne 255). `refresh()` appelle `loadData(forceRefresh: true)` avec `allData` à false, alors que la période sélectionnée est toujours `all`. Le rafraîchissement ne retélécharge que 30 jours tandis que l'UI affiche 'Tout'.

**Correction :** Dans refresh, passer `allData: state.selectedPeriod == TrendPeriod.all`.

### [mineur] Tri complet de l'historique uniquement pour des logs de debug
`lib/application/providers/trend_log_provider.dart:459` · performance · confiance high

À chaque changement de période, `_applyPeriodFilter` fait `List.from(records)..sort(...)` sur jusqu'à 10 000 records, sur le thread UI, uniquement pour logger la plage de dates en niveau debug. Le travail est fait même en release (le logger évalue les arguments). Idem le `where(...).length` ligne 379 (BACnet) et les 5 premiers records loggés.

**Correction :** Supprimer ou conditionner par `kDebugMode`, et utiliser min/max en un passage au lieu d'un tri.

### [mineur] loadData sans garde de concurrence ni de dispose/connexion
`lib/application/providers/trend_log_provider.dart:253` · bug · confiance medium

Pas de verrou ni de génération : deux `loadData` concurrents (setPeriod(all) lance `loadData` sans await, ligne 502, puis un refresh) écrasent leurs états de façon indéterminée. Si le provider est libéré ou la connexion change pendant `getTrendLogBuffer` (qui peut prendre 'plusieurs minutes' selon le message), les `state =` suivants s'exécutent après dispose (StateNotifier.mounted non testé) et lèvent une assertion, ou injectent des données du mauvais automate. Le `_cachedFullData` est alors rempli avec les données de l'ancienne connexion mais marqué avec le `_lastConnectionId` du nouveau.

**Correction :** Vérifier `mounted` et un id de requête après chaque await ; mémoriser l'id de connexion capturé au début.

### [mineur] _loadFromBacnet, _loadFromApi, _filterByPeriod et _getMaxRecordsForPeriod jamais appelés
`lib/application/providers/multi_curve_provider.dart:302` · code-mort · confiance high

`_loadSingleCurveData` délègue à `trendLogViewerProvider`. Les méthodes privées `_loadFromBacnet` (302), `_loadFromApi` (335), `_filterByPeriod` (360) et `_getMaxRecordsForPeriod` (423) ne sont référencées nulle part, soit environ 140 lignes mortes qui dupliquent la logique de trend_log_provider.dart (conversion records BACnet, choix allData). Les imports `bacnet_provider.dart` et `BacnetObject`/`bacnet_object` ne servent plus qu'à elles ou à availableTrendLogsProvider.

**Correction :** Supprimer ces méthodes et les imports devenus inutiles.

### [mineur] initialize() mute la map passée en paramètre
`lib/application/providers/multi_curve_provider.dart:96` · bug · confiance medium

`final curveNames = names ?? {}` puis `curveNames.putIfAbsent(...)` modifie la map de l'appelant (qui peut être const/immuable : `UnsupportedError`). De plus, `initialize` ne remet pas `_cachedTrendLogData` à zéro ni `data` : réutiliser le même chartId avec d'autres instances affiche d'anciennes courbes en cache (`loadData` sans forceRefresh prend le chemin cache ligne 229).

**Correction :** Copier la map (`Map.of(names ?? {})`) et vider `_cachedTrendLogData` dans initialize.

### [mineur] alarmsProvider recalcule et notifie à chaque rafraîchissement de points
`lib/application/providers/alarms_provider.dart:19` · performance · confiance medium

`ref.watch(pointsProvider)` sur tout l'état : chaque changement (recherche, tri, catégorie, valeur) reconstruit la liste filtrée, une nouvelle liste est produite et, comme les listes ne sont pas égales par valeur, tous les watchers (`alarmsCountProvider`, `hasAlarmsProvider`, `filteredAlarmsProvider`, home_screen.dart:285) sont notifiés même si les alarmes n'ont pas changé. `filteredAlarmsProvider` retrie à chaque tick de refresh. `hasAlarmsProvider` n'est utilisé nulle part (code mort).

**Correction :** `ref.watch(pointsProvider.select((s) => s.points))` et comparer le contenu ; n'exposer que l'int pour `alarmsCountProvider`. Supprimer hasAlarmsProvider.

### [mineur] pointDetailProvider reconstruit à chaque modification de l'état des points
`lib/application/providers/points_provider.dart:1104` · performance · confiance medium

`ref.watch(pointsProvider)` (état complet) puis `firstWhere` linéaire avec exception comme flux de contrôle (try/catch). L'écran de détail (point_detail_screen.dart:72) se reconstruit à chaque tick d'auto-refresh, saisie dans la recherche ou changement de tri, même quand le point n'a pas changé. Chaque `_updatePointLocally` reconstruit aussi la liste entière (O(n) copyWith pour un seul point).

**Correction :** `ref.watch(pointsProvider.select((s) => s.points.where(...).firstOrNull))` (BacnetObject avec égalité de valeur) ; remplacer le try/catch par `firstWhereOrNull`.

### [mineur] activeBacnetConnectionProvider jamais réinitialisé ; double source de vérité BACnet
`lib/application/providers/active_connection_provider.dart:189` · architecture · confiance medium

L'état BACnet est stocké à la fois dans `ActiveConnectionState` (isBacnetConnection, bacnetDeviceId) et dans `activeBacnetConnectionProvider` (StateProvider). Il n'est mis à jour qu'en ligne 189 : `disconnect()` et `_connectDistechApi` ne le remettent pas à null. Après connexion BACnet puis déconnexion/connexion API, `activeBacnetConnectionProvider` garde host/port de l'ancien automate (consommé par `trendLogMappingProvider` via watch, ligne 41/64). `ActiveConnectionNotifier` dépend aussi directement de `pointsProvider` et `scheduleEditProvider` (couplage circulaire contourné par `reset()`), et `connect()` ne remet pas la connexion en cours de côté si un `connect()` précédent est encore en vol (pas de verrou : deux appels rapides font deux clients).

**Correction :** Dériver la connexion BACnet de `ActiveConnectionState` ou la réinitialiser dans `disconnect()` et `_connectDistechApi` ; ajouter un jeton de connexion pour ignorer les `connect()` obsolètes.

### [mineur] SettingsNotifier : init asynchrone sans garde, setters perdus avant la fin du chargement
`lib/application/providers/settings_provider.dart:88` · bug · confiance high

`_init()` (lignes 88-91) est lancé dans le constructeur sans await ; `_prefs` est nul tant que `getInstance()` n'a pas répondu. Un setter appelé avant (`setThemeMode...`) fait `state = ...` mais `_prefs?.setInt` est un no-op : la valeur n'est jamais persistée, puis `_loadSettings` écrase l'état avec les anciennes valeurs. Avec `dispose` pendant l'init, `state = AppSettings(...)` après dispose lève une assertion. Les `await _prefs?.set...` ignorent aussi le booléen de retour (échec d'écriture silencieux). `sharedPreferencesProvider` (ligne 71) est dupliqué et jamais utilisé.

**Correction :** Précharger SharedPreferences dans `main()` et l'injecter par override, ou attendre `_init` dans les setters ; supprimer `sharedPreferencesProvider`.

### [mineur] Réglages connectionTimeout et refreshInterval non consommés (et doublon avec autoRefreshIntervalProvider)
`lib/application/providers/settings_provider.dart:29` · code-mort · confiance high

`connectionTimeoutSeconds` et `refreshIntervalSeconds` sont sauvegardés et affichés dans settings_screen.dart (198, 232, 265) mais aucun client réseau ni timer ne les lit (recherche sur tout lib/ : seuls settings_provider et settings_screen y font référence). Le rafraîchissement réel utilise `autoRefreshIntervalProvider` (points_provider.dart:1092, StateProvider volatile non persisté). L'utilisateur règle donc un timeout et un intervalle qui n'ont aucun effet, et deux réglages se contredisent. `temperatureUnit`, `use24HourFormat`, `decimalPlaces` et `defaultBacnetPort` ne sont référencés que par app.dart/settings_screen, à vérifier.

**Correction :** Brancher ces réglages sur ConnectedApiClient/BacnetService et sur le timer de points (en remplaçant autoRefreshIntervalProvider), ou les retirer de l'UI.

### [mineur] Import JSON : connexions créées avec passwordKey vide, inutilisables ; N requêtes ; clear cache incomplet
`lib/application/providers/settings_provider.dart:315` · bug · confiance high

Les connexions importées reçoivent `passwordKey: ''` (ligne 315). `_connectDistechApi` fait `secureStorage.read(key: '')` qui renvoie null, d'où l'erreur 'Mot de passe introuvable' sans moyen de saisie évident, et `connectionType` par défaut `'api'` (ligne 316) alors que le reste du code crée `'distech_api'` (connection_providers.dart:47). La valeur `apiVersion` et `designerUrl` ne sont ni exportés ni importés. Par ailleurs `await db.allFolders` et `await db.allConnections` sont relus à chaque itération des boucles (265, 293) : N+1 requêtes SQL. `clearAllCacheGlobal` (378) ne vide pas la table du mapping des trend logs alors que `clearAllCache(connectionId)` le fait, le commentaire ligne 382 l'ignore, et les providers déjà en mémoire ne sont pas invalidés.

**Correction :** Lire folders/connections une seule fois avant les boucles, utiliser les mêmes valeurs de connectionType que le reste, forcer la saisie du mot de passe à l'ouverture, et inclure `cachedTrendLogMappings` dans clearAllCacheGlobal.

## Providers B (plannings, dashboards, favoris, modèles) (22 constats)

Le périmètre providers (schedule, dashboard, favorites, super_favorites, synoptics, dossiers) et models (schedule, favorite, trend_log, multi_curve_chart, network_interface_choice) est lisible et globalement cohérent, mais il présente plusieurs vrais défauts. Les plus sérieux : (1) la réécriture BACnet d'un planning force le tag boolean/enumerated et peut corrompre des plannings unsigned/real/signed ; (2) SynopticLiveNotifier est un provider non autoDispose dont le Timer tourne indéfiniment, et il ne lit aucune donnée réseau (il dépend de pointsProvider) ; (3) les providers de listes (schedulesListProvider, scheduleDetailProvider, favoris, dashboards…) font ref.watch de tout activeConnectionProvider, ce qui relance des requêtes BACnet lourdes à chaque mise à jour d'état en arrière-plan ; (4) le chargement d'un planning est fait deux fois (scheduleDetailProvider + loadSchedule). On note aussi une dette de duplication (chargement BACnet/API, construction du client API, mapping type->code BACnet, conversions de tags), du code mort notable (modèle domain/Favorite, BacnetScheduleConverter/ScheduleBacnetExtension, plusieurs providers favoris/dashboards), et des conversions fragiles (copyWith qui ne peut pas remettre null, index state-text incohérents, broadcast /24 codé en dur). Aucun secret loggé dans ce périmètre ; le TLS désactivé (badCertificateCallback => true dans ConnectedApiClient) est hors périmètre mais impacte les clients créés par super_favorites_provider.

### [majeur] Écriture BACnet : tag de valeur forcé en boolean/enumerated, corrompt les plannings unsigned/real/signed
`lib/application/providers/schedule_provider.dart:815` · bug · confiance high

_convertToBacnetWeeklySchedule choisit le tag uniquement via schedule.valueType (boolean sinon enumerated). Or _detectValueTypeFromWeeklySchedule (l.76-117) classe en boolean un planning unsigned dont les valeurs sont toutes 0/1, et en enumerated tout le reste (real tag 4, signed tag 3, unsigned >1). Scénario : un Schedule BACnet de type unsigned/real lu puis sauvegardé (même après un simple copier/coller de jour) est réécrit avec des tags enumerated/boolean : le type de données ne correspond plus au Schedule (rejet par le device ou changement silencieux de type). Le champ ScheduleTransition.type (rempli à la lecture, l.239) est ignoré à l'écriture. Les transitions null (retour au défaut) passent aussi par le même chemin.

**Correction :** Utiliser transition.type / le tag d'origine (conserver valueTag dans ScheduleTransition) pour choisir ScheduleValueTag, et n'appliquer boolean/enumerated que pour les nouvelles transitions sans type ; gérer explicitement null -> tag null.

### [majeur] schedulesListProvider / scheduleDetailProvider relancés à chaque changement de l'état de connexion
`lib/application/providers/schedule_provider.dart:13` · performance · confiance high

ref.watch(activeConnectionProvider) sans select (l.13 et l.122). ActiveConnectionState est reconstruit plusieurs fois juste après la connexion (deviceInfo, objectsSummary, controllerTime, networkInfo : active_connection_provider.dart l.389-456, plus refresh()). Chaque emission invalide le FutureProvider : discoverSchedules (lecture de tous les schedules en BACnet) ou getSchedules / getScheduleDetail sont relancés 3-5 fois si l'écran Plannings est ouvert pendant le chargement de fond. Même défaut dans favoritesProvider (favorites_provider.dart l.20), isFavoriteProvider, favoriteStateProvider, favoritesCountProvider, favoriteFoldersProvider/unassignedFavoritesProvider (favorite_folders_provider.dart l.12,24), dashboardsProvider (dashboard_provider.dart l.18), synopticsProvider (synoptics_provider.dart l.48) : les streams drift sont recréés pour rien.

**Correction :** Surveiller seulement ce qui compte : ref.watch(activeConnectionProvider.select((s) => (s.connection?.id, s.isConnected, s.isBacnetConnection, s.client))) ou des providers dérivés (activeConnectionIdProvider).

### [majeur] Double (voire triple) chargement du planning à l'ouverture de l'écran de détail
`lib/application/providers/schedule_provider.dart:349` · performance · confiance high

schedule_detail_screen.dart l.32 appelle ScheduleEditNotifier.loadSchedule() et l.45 fait watch(scheduleDetailProvider(instance)) : les deux exécutent la même lecture (readScheduleFull BACnet ou getScheduleDetail API, code dupliqué l.121-179 vs l.349-398). Après save(), l.779 invalide scheduleDetailProvider, ce qui refait une lecture complète alors que editedSchedule est déjà l'état écrit. Le bouton refresh (l.179-180 de l'écran) enchaîne aussi invalidate + loadSchedule.

**Correction :** Une seule source : faire lire loadSchedule depuis ref.read(scheduleDetailProvider(instance).future) (ou l'inverse) et factoriser le fetch BACnet/API dans une fonction privée unique.

### [majeur] SynopticLiveNotifier jamais disposé : Timer périodique éternel + timer créé après dispose
`lib/application/providers/synoptics_provider.dart:316` · bug · confiance high

synopticLiveProvider est un StateNotifierProvider.family sans autoDispose (aucun autoDispose dans application/). Une fois le synoptique ouvert, le Timer.periodic de 5 s (l.248) tourne tant que l'app vit, et chaque tick fait state=copyWith(isLoading:true) puis false (2 rebuilds/5 s). Dans _init (l.240-244), si le notifier est disposé pendant les await de loadBindings/refreshValues, _startAutoRefresh() est quand même appelé après dispose : le Timer n'est alors plus jamais annulé et modifie un state disposé (assert en debug).

**Correction :** Utiliser StateNotifierProvider.autoDispose.family, tester mounted après chaque await dans _init/loadBindings/refreshValues, et ne démarrer le timer que si mounted.

### [majeur] refreshValues ne lit rien sur le réseau et échoue entièrement si un seul point manque
`lib/application/providers/synoptics_provider.dart:271` · bug · confiance high

Malgré le commentaire 'depuis l'API', refreshValues ne fait que relire pointsProvider (l.281) : si l'écran Points n'a pas chargé la liste, ou si le type n'est pas chargé, le firstWhere lance Exception('Point not found') (l.290) et tout l'état passe en erreur, sans aucune valeur. Les valeurs ne sont jamais plus fraîches que le dernier chargement des points, malgré le polling 5 s. Le fallback fuzzy (l.289) compare startsWith(prefix) et endsWith(':instance'), ce qui peut associer un autre type (ex. préfixe 'A' vs 'AV'/'AI'). Les liaisons modifiées dans l'éditeur ne sont pas rechargées non plus (loadBindings n'est appelé que dans _init).

**Correction :** Lire les valeurs via le client actif (readMultiplePoints API / refreshMultiplePointValues BACnet comme dans super_favorites), ignorer les points introuvables au lieu de lever, supprimer le fallback fuzzy, et écouter watchBindingsForSynoptic.

### [majeur] Le refresh écrase les modifications DB survenues pendant l'await (super favori retiré réapparaît)
`lib/application/providers/super_favorites_provider.dart:317` · bug · confiance medium

refreshConnection capture superFavs avant les await réseau (readMultiplePoints, Future.wait, updateModelName). Au retour, updatedList est construit depuis cette liste périmée puis écrit dans state.byConnection (l.327-342 et l.476-482). Si l'utilisateur rétrograde/supprime un super favori (ou en ajoute un) pendant le refresh (jusqu'à 30-60 s de timeout), _updateFromDb avait mis à jour state, mais le résultat écrasé fait réapparaître l'ancien super favori (ou perd le nouveau) jusqu'à la prochaine émission DB.

**Correction :** Au retour, fusionner : repartir de state.forConnection(connectionId) courant et n'appliquer liveData/lastRefreshed que pour les pointRef encore présents.

### [majeur] Cache _apiClients jamais invalidé : identifiants/hôte modifiés ignorés, clients en doublon
`lib/application/providers/super_favorites_provider.dart:554` · bug · confiance medium

_getApiClientForConnection renvoie le client en cache en premier (l.554) avant de regarder la connexion active. Si l'utilisateur édite le mot de passe, l'hôte ou apiVersion d'une connexion, le client mis en cache garde l'ancien baseUrl/basicAuth : le refresh échoue en 401 jusqu'au redémarrage. Aucun code hors du notifier n'invalide ce cache. Un client est aussi créé pour la connexion active alors qu'elle en a déjà un. La version d'API par défaut diverge : 'V1' ici (l.591) contre 'V2' dans active_connection_provider.dart (_connectDistechApi, ~l.272) pour une même connexion sans apiVersion.

**Correction :** Clé de cache = (id, host, port, username, passwordKey, useHttps, apiVersion), ou invalider via un listener sur la table connections ; unifier le défaut d'apiVersion dans une factory commune.

### [mineur] Construction du client API (baseUrl + Basic auth) dupliquée
`lib/application/providers/super_favorites_provider.dart:581` · duplication · confiance high

Les lignes 573-594 (lecture mot de passe, scheme/baseUrl, base64 Basic, new ConnectedApiClient) reproduisent presque à l'identique active_connection_provider.dart (_connectDistechApi, l.255-285). Idem _bacnetTypeToObjectTypeCode (l.486-517) dupliqué dans points_provider.dart (~l.1028), et le parsing 'shortName:instance' fait deux fois dans _refreshBacnetConnection (l.359 et l.419).

**Correction :** Extraire une factory ConnectedApiClient.fromConnection(connection, password) et une extension BacnetObjectType.toTypeCode ; parser une seule fois les pointRefs (liste de records réutilisée pour les résultats).

### [mineur] save() : les modifications faites pendant l'écriture sont marquées comme sauvegardées
`lib/application/providers/schedule_provider.dart:769` · bug · confiance medium

Après l'await d'écriture (l.752/763), le code fait originalSchedule: state.editedSchedule et hasChanges:false (l.770-775). Si l'utilisateur modifie un jour pendant l'envoi, la version modifiée devient 'originale' sans avoir été envoyée, et hasChanges repasse à false : le bouton Sauvegarder disparaît et ces changements sont perdus à la prochaine sortie. Même problème de portée : l'écriture BACnet (l.752) n'envoie pas deviceId alors que readScheduleFull le fait (l.147).

**Correction :** Capturer toWrite = state.editedSchedule au début, et après succès: originalSchedule = toWrite, hasChanges = !identical(state.editedSchedule, toWrite). Bloquer aussi les éditions pendant isSaving.

### [mineur] Exceptions BACnet avalées : liste vide / null au lieu d'une erreur affichable, et chargement API sans try/catch
`lib/application/providers/schedule_provider.dart:52` · bug · confiance medium

schedulesListProvider (l.52-55) et scheduleDetailProvider (l.162-165) retournent [] / null sur toute exception BACnet : un timeout UDP s'affiche comme 'aucun planning' sans possibilité de retry, alors que la branche API (l.61, l.171) propage l'erreur en AsyncError (comportement incohérent). loadSchedule (l.349-398) n'a aucun try/catch côté API (l.387) : un échec réseau lève dans un Future non attendu (unawaited dans l'écran, l.32) et reste silencieux/non géré ; sur BACnet il retourne sans mettre d'erreur dans le state. Pas de garde de concurrence : deux loadSchedule rapides (changement d'instance) peuvent écrire dans le désordre.

**Correction :** Laisser remonter l'exception (rethrow) pour avoir AsyncError, ou la stocker dans ScheduleEditState.error ; ignorer les réponses obsolètes (token d'instance).

### [mineur] toV1Json : type déduit de la valeur Dart, ignore ScheduleTransition.type (boolean planifié en 'enumerated')
`lib/domain/models/schedule.dart:101` · bug · confiance medium

toV1Json calcule le type uniquement par le runtime type (bool -> 'boolean', int -> 'enumerated'). Or l'éditeur propose pour un schedule booléen des valeurs int 1/0 (Schedule.possibleValues l.640-647). Un créneau ajouté sur un schedule booléen est donc envoyé en V1 avec type 'enumerated' alors que les transitions existantes lues en V1 sont des bool ('boolean') : planning à types mélangés, et valeurs unsigned/real existantes réécrites en 'enumerated'. Le champ type lu en fromV1 est perdu.

**Correction :** Passer valueType du Schedule à toV1Json et utiliser type existant (this.type) en priorité ; normaliser 1/0 en bool pour valueType boolean.

### [mineur] copyWith impossible pour remettre une valeur à null (ScheduleTransition, TimeSlot, Schedule)
`lib/domain/models/schedule.dart:139` · bug · confiance medium

ScheduleTransition.copyWith (l.139 'value ?? this.value'), TimeSlot.copyWith (l.261) et Schedule.copyWith (description, presentValue, scheduleDefault l.690-699) ne peuvent pas affecter null. Or null est une valeur métier ('Auto' / retour au défaut, voir possibleValues l.645 et toTransitions l.228). Un copyWith(value: null) pour passer un créneau en Auto garde l'ancienne valeur sans erreur. Aucun appel actuel ne le fait (grep) mais le piège est présent pour toute évolution de l'éditeur.

**Correction :** Utiliser un sentinel (Object? value = _unset) ou des paramètres clearValue, comme déjà fait pour ScheduleEditState.

### [mineur] Précision horaire : secondes/centièmes perdus et 23:59 interprété comme fin de journée
`lib/domain/models/schedule.dart:67` · bug · confiance medium

timeInMinutes ignore secondes et centièmes ; _convertDecodedWeeklySchedule (schedule_provider.dart l.234) tronque l'heure BACnet en 'HH:mm'. Une transition à 08:00:30 est réécrite à 08:00:00 à la sauvegarde. Dans transitionsToSlots, toute transition à >= 23:59 (l.304) devient 24:00, et timeStringToMinutes (l.247) fait de même : une vraie transition de début à 23:59 ou 23:59:30 est confondue avec le marqueur de fin '23:59:59.99'. toTransitions écrit en plus systématiquement un null à 23:59:59.99 pour tout créneau finissant à minuit (retour au défaut 10 ms avant minuit, et ajout d'une transition inutile par jour).

**Correction :** Représenter l'heure en secondes (ou TimeOfDay + centièmes), conserver la chaîne d'origine et ne tronquer que l'affichage ; ne pas émettre de null final si le dernier créneau va jusqu'à minuit.

### [mineur] Index des state-texts incohérent : base 1 dans l'extension, base 0 dans le provider
`lib/domain/models/schedule.dart:873` · bug · confiance medium

ScheduleBacnetExtension.fromBacnetInfo (l.873) numérote les stateTexts à partir de 1 (i+1, convention multistate BACnet), alors que _convertBacnetScheduleInfoToSchedule (schedule_provider.dart l.206-207) les numérote à partir de 0 avec le commentaire 'index 0 = premier état'. possibleValues/getStateText (l.621-632) cherchent par index : sur un schedule multistate (valeurs 1..N) le libellé affiché est décalé d'un cran (valeur 1 affichée avec le texte de l'état 2) si la convention du provider (utilisée en réalité) est fausse ; pour un booléen (0/1) elle est correcte. Les deux conversions ne peuvent pas être justes en même temps.

**Correction :** Décider la convention par valueType (enum -> index = i+1, boolean -> i) dans une seule fonction partagée, et supprimer l'autre.

### [mineur] Section 'BACnet Schedule Converters' entièrement inutilisée et dupliquant le provider
`lib/domain/models/schedule.dart:748` · code-mort · confiance high

BacnetScheduleConverter, _WeeklyScheduleData/_DailyScheduleData/_TimeValueData et ScheduleBacnetExtension.fromBacnetInfo (l.748-894) ne sont référencés nulle part (grep sur lib/). Ils dupliquent _convertDecodedWeeklySchedule, _valueTagToTypeString (identique, schedule_provider.dart l.255 vs schedule.dart l.794) et _detectValueType (provider l.67 vs l.889), avec des types dynamic non vérifiés et la divergence d'index state-text ci-dessus. Aussi dupliqué : ScheduleValueType.fromValue (l.33).

**Correction :** Supprimer la section et garder une seule implémentation, idéalement dans le modèle ou un mapper dédié, avec des types BacnetScheduleInfo explicites.

### [mineur] Modèle domain Favorite inutilisé et en collision de nom avec la classe drift Favorite
`lib/domain/models/favorite.dart:4` · code-mort · confiance high

domain/models/favorite.dart n'est importé nulle part ; fromBacnetObject, copyWithLiveData, copyWithSortOrder, copyWithSuperFavorite sont du code mort. La classe homonyme Favorite générée par drift (app_database.dart) est utilisée partout (favorites_provider, super_favorites_provider), ce qui risque des imports ambigus. Son == ne compare que connectionId+pointRef. Providers/notifiers aussi sans appelant : isFavoriteProvider, favoritesCountProvider, FavoritesNotifier.toggleFavorite/addFavorite/removeFavorite/clearAllFavorites (favorites_provider.dart), dashboardByIdProvider, DashboardNotifier.deleteWidgetByPosition, cacheStatsProvider.

**Correction :** Supprimer le modèle et les providers inutilisés, ou les brancher réellement (liaison avec liveData) ; sinon renommer pour éviter la collision.

### [mineur] favoriteStateProvider : un stream drift complet par ligne (N watchers x O(N))
`lib/application/providers/favorites_provider.dart:43` · performance · confiance medium

favoriteStateProvider.family est un StreamProvider qui ouvre pour chaque pointRef un watchFavoritesByConnection (liste complète) puis un firstWhere avec try/catch. FavoriteButton (favorite_button.dart l.20) l'utilise par tile : pour N points visibles, chaque écriture favoris relance N requêtes et N filtres O(N), alors que points_screen.dart l.194-208 maintient déjà un Set d'IDs via favoritesProvider. cycleFavoriteState (l.134) recharge aussi toute la liste pour retrouver un seul favori et fait un read-modify-write non atomique (un double tap lève la contrainte unique, attrapée et renvoyée comme FavoriteState.none, donc état affiché faux).

**Correction :** Dériver un Map<pointRef, FavoriteState> d'un seul favoritesProvider (Provider.family avec select) et ajouter une requête DB ciblée getFavoriteByPointRef ; exécuter le cycle dans une transaction drift.

### [mineur] toggleSuperFavoriteProvider avale l'erreur et renvoie false (indiscernable de 'désactivé')
`lib/application/providers/super_favorites_provider.dart:626` · bug · confiance medium

En cas d'exception drift le callback retourne false (l.629-630), identique au résultat 'n'est plus super favori' : l'UI ne peut pas distinguer échec et succès. Le provider est de plus un Provider<Future Function> qui watch databaseProvider (pas de notifier). Même motif de swallow dans DashboardNotifier.reorderDashboards (dashboard_provider.dart l.182) et FavoritesNotifier.* qui renvoient false sans propager l'erreur.

**Correction :** Retourner bool? (null = erreur) ou laisser l'exception remonter ; exposer l'erreur dans un AsyncValue.

### [mineur] État partagé isLoading/successMessage du DashboardNotifier et conversions de config fragiles
`lib/application/providers/dashboard_provider.dart:87` · bug · confiance medium

Toutes les opérations (create/update/delete/widget) partagent un seul isLoading ; deux opérations concurrentes se remettent mutuellement à false. copyWith (l.61-71) remet error et successMessage à null à chaque appel (impossible de conserver un message). MultiCurveWidgetConfig.curveNamesAsInt/curveUnitsAsInt (l.407-413) font int.parse sans protection : une clé corrompue en configJson lève FormatException lors du build du widget (fromJsonString ne protège que le décodage). fromJson fait aussi (json['trendLogInstance'] as int) et (e as int) : une instance stockée en double (300454.0) fait retourner null silencieusement et le widget disparaît. DashboardDatabase.deleteDashboard (app_database.dart l.1218-1223) supprime widgets puis dashboard hors transaction.

**Correction :** Utiliser int.tryParse avec filtre, parser via (num).toInt(), et envelopper deleteDashboard dans transaction().

### [mineur] Adresse de broadcast codée en /24 pour le Who-Is / discovery BACnet/IP
`lib/domain/models/network_interface_choice.dart:422` · conformite-bacnet · confiance medium

broadcastAddress = a.b.c.255 quelle que soit la vraie netmask (subnetMask est déclaré mais jamais rempli). Cette valeur est utilisée par bacnet_service.dart l.785-786 lorsqu'une interface est sélectionnée. Sur un réseau /23, /16 ou /25 (fréquent en GTB), le directed broadcast est faux : les Who-Is ne parviennent pas aux automates hors du /24 ou tombent sur une adresse hôte (BVLL Original-Broadcast-NPDU, ASHRAE 135 Annex J). L'exception de listAvailable est de plus avalée sans log (l.441-444). bacnetPortInfoProvider (bacnet_provider.dart l.398-405) est un Provider calculé une seule fois : actualPort/isUsingStandardPort sont lus avant l'init asynchrone du socket (service.dart l.107-115) et l'avertissement 'port non standard' ne se met jamais à jour.

**Correction :** Récupérer la netmask (dart:io ne la fournit pas : plugin natif ou network_info_plus) et calculer addr | ~mask, avec repli sur 255.255.255.255 ; rendre bacnetPortInfoProvider réactif (StateProvider/notifier rafraîchi après init).

### [mineur] Parsing trend-log fragile : casts directs et valeurs NaN
`lib/domain/models/trend_log.dart:82` · bug · confiance low

TrendLog.fromJson fait enabled: json['enable'] ?? json['enabled'] affecté à bool? (l.82) : un backend renvoyant 'true' ou 1 lève TypeError qui fait échouer toute la liste. parseV2 fait sample['type'] as int? (l.366) : un type texte fait échouer tout le log. _parseInt ignore les double (300454.0). Dans le buffer V1, _parseValue accepte 'NaN'/'Infinity' via double.tryParse (l.419) : un NaN poisonne min/max/avg dans TrendLogData.fromRecords (l.192-194, comparaisons a<b fausses) et CurveData.fromTrendLogData (l.216-218), et une courbe fl_chart avec un spot NaN peut lever à l'affichage.

**Correction :** Parser défensivement (is bool / == 'true'), tryParse sur type, num.toInt() dans _parseInt, et filtrer !isFinite dans numericValue.

### [mineur] Statistiques et filtre valueRecords recalculés à 3 endroits ; configs de graphiques dupliquées
`lib/domain/models/multi_curve_chart.dart:198` · duplication · confiance medium

Le filtre records.where(isValueRecord && numericValue != null), le tri par timestamp et le calcul min/max/avg sont refaits dans TrendLogData.fromRecords (trend_log.dart l.185-201, avec un tri O(n log n) juste pour start/end), CurveData.fromTrendLogData (l.198-218) et MultiCurveData.fromTrendLogDataList (l.279-294, 2e balayage complet), puis filterByTimeRange recalcule tout via fromRecords. Pour de gros logs (milliers de points x plusieurs courbes) c'est du travail redondant sur le thread UI à chaque changement de période. En parallèle, dashboard_provider.dart définit SingleChartWidgetConfig/MultiCurveWidgetConfig/StatsWidgetConfig, qui recoupent CurveConfig/MultiCurveChartConfig (3 formats JSON pour la même notion, mêmes fromJsonString copiés trois fois).

**Correction :** Calculer une fois (min/max/sum/start/end en un seul passage sans tri) et exposer valueRecords en lazy final ; factoriser fromJsonString avec un helper générique ; unifier CurveConfig et les configs de widgets.

## UI A (connexions, points, accueil, réglages, core) (22 constats)

Le périmètre (écrans connections/points/home/device_info/settings/splash/alarms/overrides + lib/core) est globalement propre côté dispose (controllers, timers et AnimationController libérés correctement dans la plupart des cas) et côté `mounted` après await. Les vrais problèmes sont : (1) des réglages utilisateur entièrement morts (6 sur 8 de SettingsScreen ne sont lus nulle part), (2) un N+1 de streams Drift par tuile de point (FavoriteButton), (3) un overlay de chargement Home qui peut rester bloqué à vie sur un automate à 0 point, (4) des setState sur dialogue fermé dans la sync d'heure, (5) beaucoup de code mort dans lib/core (errors, platform, constants) et de duplication (2 boutons refresh, 2 dialogues dossier, 2 boutons Appliquer, 2 handlers discover). Dette d'architecture : écrans géants (point_detail 1414 l., connections_list 1266 l., home 1215 l.) mêlant logique d'écriture BACnet, dialogues CRUD et accès repository directs dans l'UI, ainsi qu'un grand nombre de chaînes françaises en dur malgré l10n.

### [majeur] 6 réglages sur 8 sont stockés mais jamais utilisés par l'app
`lib/presentation/screens/settings/settings_screen.dart:210` · code-mort · confiance high

Seuls themeMode et locale sont consommés (lib/app.dart:16). connectionTimeoutSeconds, refreshIntervalSeconds, defaultBacnetPort, temperatureUnit, use24HourFormat et decimalPlaces ne sont lus par aucun autre fichier (grep settingsProvider/AppSettings hors settings_screen et settings_provider : seul app.dart). Scénario : l'utilisateur règle le timeout à 60 s ou les décimales à 3, rien ne change ; add_connection_screen.dart:97 code '47808' en dur au lieu de defaultBacnetPort ; l'auto-refresh de points_screen utilise un autre provider (autoRefreshIntervalProvider, non persisté, défaut 0) et ignore refreshIntervalSeconds.

**Correction :** Soit brancher ces réglages (Dio timeout, défaut du port BACnet, formatage valeurs, intervalle d'auto-refresh initial), soit retirer les sélecteurs inopérants de l'écran.

### [majeur] N+1 : un StreamProvider Drift par tuile de point (utilisé dans points_screen)
`lib/presentation/widgets/favorite_button.dart:20` · performance · confiance high

_PointTile (points_screen.dart:~575) affiche un FavoriteButton qui fait ref.watch(favoriteStateProvider(point.objectId)). Ce StreamProvider.family (favorites_provider.dart:43) ouvre pour chaque point visible un watchFavoritesByConnection(connectionId) complet puis un firstWhere linéaire. Avec 500 points scrollés, 500 requêtes/streams Drift ; chaque ajout/retrait de favori réémet N fois ; et comme le provider fait ref.watch(activeConnectionProvider) en entier, TOUT changement d'état de connexion (refresh, heure automate) invalide et recrée tous ces streams.

**Correction :** Fournir un seul provider Set<String> de pointRef (favoritesProvider déjà existant, avec select sur activeConnection.connection?.id) et lire l'état par lookup O(1) dans la tuile.

### [majeur] Skeleton de chargement infini si l'automate connecté a 0 point (ou chargement en échec)
`lib/presentation/screens/home/home_screen.dart:221` · bug · confiance high

isLoadingPoints = ptsState.isLoading || (ptsState.points.isEmpty && state.isConnected). _initialLoadComplete (l.88-96) n'est mis à true que si pointsState.points.isNotEmpty. Scénario : automate vide, ou loadPoints() échoue avec points vides : isLoadingPoints reste true, showLoadingOverlay reste true, HomeScreen affiche indéfiniment DashboardSkeletonGrid 'Chargement des points...' sans menu ni erreur (le bloc d'erreur l.246 n'est atteint que si !isConnected).

**Correction :** Distinguer 'jamais chargé' de 'chargé vide' (flag hasLoaded/error dans PointsState) et marquer _initialLoadComplete dès que isLoading passe à false, même avec 0 point ou erreur.

### [majeur] setDialogState appelé après fermeture du dialogue (sync heure automate)
`lib/presentation/screens/home/home_screen.dart:1128` · bug · confiance high

Dans _showTimeDialog, le bouton Synchroniser fait setDialogState(isSyncing=true) puis await widget.onSyncTime (réseau + refresh), puis setDialogState (l.1135 et l.1150) sans vérifier dialogContext.mounted. Scénario : l'utilisateur tape 'Fermer' (ou retour système) pendant la sync : le StatefulBuilder est démonté, le setState suivant lève 'setState() called after dispose()'. Le bouton Fermer n'est pas désactivé pendant isSyncing. De plus _ControllerTimeDisplay lui-même peut être démonté car refresh() le reconstruit.

**Correction :** Tester dialogContext.mounted avant chaque setDialogState après un await, et/ou désactiver Fermer/barrierDismissible pendant isSyncing.

### [majeur] _isWriting jamais remis à false si une écriture lève une exception
`lib/presentation/screens/points/point_detail_screen.dart:797` · bug · confiance medium

_writeValue, _releaseInput, _releaseOverride et _emergencyRelease font setState(_isWriting=true) puis await ref.read(pointsProvider.notifier).xxx() sans try/catch/finally. Les méthodes du notifier retournent bool et catchent côté API Distech, mais les chemins BACnet (_writeValueBacnet, _releaseOverrideBacnet appelés en boucle dans emergencyRelease) ne sont pas garantis de ne pas lever. Si une exception remonte (timeout socket UDP), _isWriting reste true : boutons désactivés à vie, spinner infini, aucune SnackBar. Par ailleurs en BACnet emergencyRelease (points_provider.dart:776-780) ignore les résultats de _releaseOverrideBacnet et retourne toujours true : l'UI affiche 'toutes priorités libérées' même si l'écriture a échoué.

**Correction :** Encadrer chaque action par try { ... } catch { success=false } finally { if (mounted) setState(_isWriting=false) } et agréger les résultats dans emergencyRelease BACnet.

### [mineur] Effets de bord dans build() : postFrameCallback enregistré à chaque rebuild + ref.watch(pointsProvider) complet
`lib/presentation/screens/home/home_screen.dart:98` · performance · confiance medium

build() enregistre à chaque appel un addPostFrameCallback qui relit les providers (l.103-111) et un second quand la condition de fin est vraie (l.90-96). HomeScreen et _buildMenuGrid (l.273) watchent tout pointsProvider, donc chaque tick d'auto-refresh/refresh de points reconstruit l'écran, recalcule overriddenPoints (liste filtrée, points_provider.dart:195) deux fois (overriddenCount + hasOverrides) et la grille de tuiles animées.

**Correction :** Déplacer le chargement initial dans initState/ref.listen (déjà présent l.68), utiliser ref.watch(pointsProvider.select(...)) pour overriddenCount/isLoading, et mémoïser le comptage dans le provider.

### [mineur] connect() lancé seulement dans initState, pas de didUpdateWidget
`lib/presentation/screens/home/home_screen.dart:53` · bug · confiance medium

initState appelle activeConnectionProvider.notifier.connect(widget.connectionId!) une fois. Si GoRouter réutilise l'état de HomeScreen pour /home?connectionId=B après A (même route, query param différent, widget reconstruit mais State conservé), la connexion B n'est jamais lancée et _pointsLoadTriggered/_initialLoadComplete restent périmés. Par ailleurs disconnect() (l.185) n'est pas attendu avant context.go.

**Correction :** Implémenter didUpdateWidget(oldWidget) pour relancer connect quand connectionId change, ou donner une ValueKey(connectionId) à la page dans le router.

### [mineur] TextEditingController disposé juste après fermeture du dialogue (animation de sortie encore active) + setState sans mounted
`lib/presentation/screens/connections/connections_list_screen.dart:386` · bug · confiance medium

Dans _showAddFolderDialog (l.294-386) et _showEditFolderDialog (l.390-474), nameController.dispose() est appelé dès que showDialog retourne, alors que le TextField est encore dans l'arbre pendant l'animation de fermeture : source connue de 'A TextEditingController was used after being disposed'. Dans _showAddFolderDialog, après await repository.createFolder (l.376) le setState(l.381) n'est pas protégé par if (mounted) (le mounted précédent date d'avant l'await), et text.isNotEmpty accepte un nom d'espaces seuls ('   ' crée un dossier au nom vide après trim).

**Correction :** Extraire le dialogue dans un StatefulWidget qui possède et dispose son controller ; tester mounted après l'await ; valider trim().isNotEmpty.

### [mineur] Dialogues 'Nouveau dossier' et 'Modifier dossier' quasi identiques
`lib/presentation/screens/connections/connections_list_screen.dart:293` · duplication · confiance high

_showAddFolderDialog (l.293-387) et _showEditFolderDialog (l.389-475) dupliquent le sélecteur de couleurs (liste de 8 hex copiée l.296-305 et l.392-395), le StatefulBuilder, la grille de pastilles avec ombre/coche, et la logique controller/dispose. Seuls titre, valeur initiale et appel repository diffèrent.

**Correction :** Créer un widget FolderDialog(initialName, initialColor) + constante kFolderColors partagée (retourne (name,color)).

### [mineur] _FolderRefreshButton et _RefreshButton : même widget copié (~130 lignes)
`lib/presentation/screens/connections/connections_list_screen.dart:1025` · duplication · confiance high

Les deux classes (l.1025-1157 et l.1161-1265) dupliquent timer 1 Hz, spinner 40x40, chrono 'Ns', IconButton refresh et postFrameCallback de démarrage ; seul l'agrégat (max des cooldowns d'une liste d'ids vs un id) et la méthode appelée (refreshFolder vs refreshConnection) changent. Chaque instance déclenche en plus un setState/s tant que le cooldown court, et chaque _ConnectionCard (l.675) watch tout superFavoritesProvider, donc toute la liste se reconstruit à chaque changement de n'importe quelle connexion.

**Correction :** Un seul _RefreshButton(connectionIds, onRefresh, iconSize) ; utiliser ref.watch(superFavoritesProvider.select(...)) par carte.

### [mineur] _buildApplyButton et _buildApplyButtonWithValidation dupliqués ; 3 handlers de release copiés
`lib/presentation/screens/points/point_detail_screen.dart:463` · duplication · confiance high

Les deux méthodes (l.463-515 et l.739-795) contiennent le même switch WriteMode -> (texte, couleur, icône) et le même bouton avec spinner ; seule la validation du Form diffère. _releaseInput/_releaseOverride/_emergencyRelease (l.1044-1151) répètent le schéma setState(_isWriting) / await / mounted / SnackBar vert|rouge ; _writeValue (l.797) idem. Les bannières orange/violette de _buildEditWidget (l.292-345) sont aussi deux Container quasi identiques.

**Correction :** Extraire _applyStyle(point, l10n) -> record, un helper _runWrite(Future<bool>, okMsg, errMsg) avec try/finally, et un widget ModeBadge(color, icon, text).

### [mineur] Tri/filtrage complets des points dans build, par onglet, à chaque changement d'état
`lib/presentation/screens/points/points_screen.dart:431` · performance · confiance medium

_PointsCategoryTab.build fait ref.watch(pointsProvider) (état entier) puis getFilteredAndSortedPoints(category) (points_provider.dart:76), getAvailableSubTypes et getSubTypeCountsForCategory à chaque build ; TabBarView garde jusqu'à 2-3 onglets vivants, et le screen parent calcule en plus pointCountByCategory (l.~213). Avec l'auto-refresh BACnet (Timer.periodic), chaque tick entraîne N tris + parcours pour chaque onglet monté, sur le thread UI. Les tuiles (_PointTile) n'ont pas de key.

**Correction :** Mémoïser la liste filtrée dans le provider (Provider.family<PointCategory> avec select) et ajouter key: ValueKey(point.objectId).

### [mineur] Auto-refresh : timer actif quand l'écran est masqué, et non relancé si la connexion change
`lib/presentation/screens/points/points_screen.dart:125` · bug · confiance medium

_setupAutoRefresh démarre un Timer.periodic qui appelle refresh() même quand PointsScreen est recouvert par PointDetailScreen (l'état de la route reste monté) : requêtes réseau en parallèle de l'écran de détail/édition, pouvant écraser la valeur éditée. Si la connexion est coupée (disconnect) la page reste montée tant qu'elle n'est pas dépilée, et le timer continue de tirer sur une connexion fermée ; la valeur autoRefreshIntervalProvider (StateProvider global non persisté) n'est pas réinitialisée à la déconnexion.

**Correction :** Mettre en pause le timer via RouteAware / isCurrent, vérifier activeConnection.isConnected dans _doAutoRefresh, et reset de l'intervalle à la déconnexion.

### [mineur] En édition, 'Tester' envoie un mot de passe vide
`lib/presentation/screens/connections/add_connection_screen.dart:637` · bug · confiance medium

_loadConnection (l.70-92) ne recharge pas le mot de passe (stocké via passwordKey), et le validateur l.340 l'accepte vide en édition. _testDistechConnection envoie password: _passwordController.text (vide) : sur un équipement existant, tester sans retaper le mot de passe échoue en 401 alors que la connexion enregistrée est valide ; l'utilisateur croit son automate injoignable. Le champ bacnetDeviceId n'a pas de validateur (int.parse l.675/722 lève FormatException, rattrapée seulement par le catch générique), et l'hôte est validé avant trim() (l.245 vs .trim() à l'usage).

**Correction :** En édition, relire le secret depuis le repository si le champ est vide pour le test, ajouter un validator int au device id et valider value.trim().

### [mineur] _openDiscoverEclypse / _openDiscoverBacnet quasi identiques
`lib/presentation/screens/connections/add_connection_screen.dart:120` · duplication · confiance high

Les deux méthodes (l.120-145 et l.148-172) font le même context.push, le même remplissage name/host/port et le même SnackBar 'selectionne' ; seul deviceId/useHttps diffère. Le schéma de construction d'URL '$protocol://host:port' est aussi recopié dans home_screen.dart:36, connections_list_screen.dart:677, envysion_viewer_screen.dart:77, active_connection_provider.dart:311, super_favorites_provider.dart:582 et api_service.dart:82.

**Correction :** Factoriser _applyDiscoveryResult(Map) et ajouter Connection.baseUrl (extension) utilisé partout.

### [mineur] _errorMessage inatteignable : le service avale toutes les erreurs
`lib/presentation/screens/connections/discover_eclypse_screen.dart:47` · bug · confiance high

MdnsDiscoveryService.discoverEclypseDevices (data/services/mdns_discovery_service.dart, bloc try/catch/finally) attrape toute exception (bind refusé, réseau absent), la logge et retourne une liste vide. Le catch de l'écran (l.51-57) ne s'exécute donc jamais : en cas d'échec réel du socket l'utilisateur voit 'aucun appareil trouvé' sans cause. De plus l'écran n'a pas de dispose() : quitter pendant les 5 s de découverte laisse le socket UDP/abonnement actifs jusqu'au timeout.

**Correction :** Relancer l'exception (ou retourner un résultat avec erreur) dans le service, et ajouter une méthode cancel() appelée depuis dispose().

### [mineur] lib/core/errors, platform_info, UiConstants, AppConstants : code mort
`lib/core/errors/exceptions.dart:1` · code-mort · confiance high

Aucun import de core/errors/exceptions.dart, core/errors/failures.dart, core/platform/platform_info.dart, core/constants/ui_constants.dart ni app_constants.dart dans lib/ ni test/ (grep). ~20 classes Exception/Failure jamais levées/utilisées (le projet utilise Exception/String d'erreur à la place), PlatformInfo (supportsSelfSignedCertificates, requiresProxy…) jamais appelée, constantes UI jamais appliquées. Routes.pointDetail, scheduleDetail, synopticView, synopticEdit, dashboardView, editConnection, synopticCreate sont aussi inutilisées.

**Correction :** Supprimer ces fichiers/constantes, ou les adopter réellement (la hiérarchie Failure pour typer les erreurs au lieu de e.toString() affiché dans les SnackBars).

### [mineur] Route /synoptics/create dupliquée et inutile, debugLogDiagnostics toujours actif, ids invalides => 0
`lib/core/router/app_router.dart:194` · architecture · confiance high

La sous-route 'create' (l.194-201) rend simplement SynopticsListScreen en fadeTransition (aucun appelant, Routes.synopticCreate jamais utilisé) : cela crée une 2e instance de l'écran liste. debugLogDiagnostics: true (l.36) est inconditionnel et loggue chaque navigation, y compris en release (URLs avec connectionId). int.tryParse(...) ?? 0 (l.130, 202, 246, 263…) ouvre silencieusement l'id 0 au lieu d'une page d'erreur. Aucun redirect/guard : /points, /alarms… sont accessibles sans connexion active (deep link web).

**Correction :** Supprimer la route create, debugLogDiagnostics: kDebugMode, retourner une page d'erreur sur id invalide, ajouter un redirect si activeConnection non connectée.

### [mineur] Logger au niveau debug en production
`lib/core/utils/logger.dart:19` · securite · confiance medium

AppLogger est construit avec level: Level.debug sans condition de build : en release, tous les logs d'URL, hôtes, noms d'utilisateurs et réponses d'API passent par PrettyPrinter (couleurs ANSI/emoji) vers la sortie standard/logcat. Aucun log de mot de passe direct n'a été trouvé dans le périmètre (le seul log lié, super_favorites_provider.dart:577, cite la clé et non la valeur), mais la surface est large. De plus mdns_discovery_service.dart et d'autres créent leur propre Logger() au lieu du wrapper global.

**Correction :** level: kReleaseMode ? Level.warning : Level.debug, et réutiliser le logger global partout.

### [mineur] Écrans géants mélangeant logique métier et UI ; chaînes françaises en dur
`lib/presentation/screens/points/point_detail_screen.dart:1` · architecture · confiance high

point_detail_screen.dart (1414 l.), connections_list_screen.dart (1266 l.), home_screen.dart (1215 l.), points_screen.dart (822 l.), add_connection_screen.dart (785 l.). Logique métier dans l'UI : orchestration releaseOverride puis emergencyRelease pour le mode Auto (point_detail:826-836), choix de priorité 1 / 8 en dur, appels directs aux repositories (connections_list:376, 507, 604), pickFiles + lecture de fichier (settings:524-539), calcul d'URL Envysion et launchUrl (home:32-51). Beaucoup de textes non localisés malgré l10n : 'Favoris', 'Dashboard', 'Synoptique', 'Connexion en cours...', 'Nouveau dossier', 'Sans dossier', 'Déplacer', 'Heure de l\'automate', 'Erreur: $e', etc. (home_screen, connections_list_screen, add_connection_screen, device_info_screen) ; device_info_screen utilise dynamic pour device/connection/summary (l.65, 119, 365, 473).

**Correction :** Déplacer les use-cases d'écriture dans PointsNotifier (writeWithMode) et des controllers pour dossiers/export ; découper en widgets de fichiers dédiés ; migrer les chaînes vers l10n ; typer les paramètres.

### [mineur] Import/export de connexions cassés sur Web et export incomplet
`lib/presentation/screens/settings/settings_screen.dart:1` · bug · confiance medium

Le fichier importe dart:io et utilise File(result.files.single.path!) (l.536) : sur Flutter Web (cible déclarée dans CLAUDE.md) path est null (rien ne se passe, aucun message) et dart:io empêche même la compilation web. L'import conditionnel 'if (dart.library.html)' sur file_picker pointe vers le même fichier, donc inutile. L'export (settings_provider.dart:222-228) omet designerUrl alors que l'import ne le rétablit pas non plus ; l'import fait db.allFolders/allConnections à chaque itération de boucle (N+1, l.~279 et ~300). _resetSettings (l.~594) n'a pas de try/catch ni setState de chargement. Le TextEditingController de _showBacnetPortDialog (l.290) n'est jamais disposé.

**Correction :** Utiliser result.files.single.bytes (withData: true) au lieu de File, charger allFolders/allConnections une fois avant les boucles, inclure designerUrl, disposer le controller via un StatefulWidget de dialogue.

### [mineur] Splash : délai artificiel de 2 s sans initialisation réelle
`lib/presentation/screens/splash/splash_screen.dart:52` · performance · confiance low

_initializeAndNavigate fait seulement await Future.delayed(2s) puis context.go(connections) : aucune initialisation (DB, settings) n'y est faite, ajoutant 2 s fixes à chaque démarrage. Le spinner reste visible même si le lancement est prêt. Les cercles décoratifs utilisent withOpacity (déprécié, 4 occurrences ici, aussi dans add_connection_screen et overrides_screen).

**Correction :** Attendre les vrais providers d'init (database, settings) avec un délai minimal court, remplacer withOpacity par withValues(alpha:).

## UI B (plannings, dashboards, synoptiques, graphes) (28 constats)

Périmètre lu et vérifié : écrans schedules, dashboard, favorites, synoptics et widgets de graphes. Le point le plus fragile est la chaîne graphes/dashboard. Il n'y a aucun downsampling, `_ChartData.fromRecords` est recalculé à chaque build, la boucle de rechargement des dashboards est sans garde, la reconfiguration d'un multi-courbes n'est jamais prise en compte et le zoom du multi-courbes est exponentiel. Côté sécurité, la WebView Envysion accepte tous les certificats et renvoie les identifiants à n'importe quel hôte. Côté synoptics, le notifier live tourne indéfiniment, ne relit jamais les bindings et ne rafraîchit pas réellement les valeurs. Les controllers et AnimationController sont globalement bien disposés. Seuls deux TextEditingController du dashboard fuient, et les BuildContext après await sont plutôt bien protégés par `mounted`. Il reste de la duplication importante entre trend_log_viewer et multi_curve_chart (calcul des spots, sélecteurs, états, formatage) et du code mort dans multi_curve_provider.

### [majeur] Aucun downsampling : jusqu'à 10 000 points passés à fl_chart, filtrés à chaque frame de zoom
`lib/presentation/widgets/trend_log_viewer.dart:1572` · performance · confiance high

Les records (maxRecords jusqu'à 10 000 en 'all', 3 000-3 500 en 'month') deviennent autant de FlSpot sans décimation (grep downsampl/decimat : aucun résultat dans lib/). Dans _TrendChart._buildChart, `widget.chartData.spots.where(...).toList()` (l.1572) est exécuté en O(n) à chaque setState du geste de pinch/pan (_onScaleUpdate). La courbe est `isCurved: true` avec `Shadow` (blurRadius 6) et `belowBarData` en dégradé (l.1731+). `LineChart(duration: 150ms)` interpole en plus les listes de spots entre deux frames. En plein écran avec 'Tout', le zoom/pan saccade sur le thread UI. Dans multi_curve_chart.dart, `_MultiCurveLineChart` passe `curve.spots` complets à chaque courbe (jusqu'à 8 × N points), sans fenêtrage.

**Correction :** Décimer avant d'afficher (min/max par bucket ou LTTB, cible ~2× la largeur en pixels), sur la fenêtre visible uniquement. Mettre le résultat en cache tant que (zoom, pan, données) ne changent pas. Désactiver `isCurved`, `shadow` et `duration` quand n > ~500.

### [majeur] _ChartData.fromRecords recalculé (filter + sort + 3 passes) à chaque build, jamais mémoïsé
`lib/presentation/widgets/trend_log_viewer.dart:1051` · performance · confiance high

_ChartData.fromRecords (l.340) fait where().toList(), sort(), map(values) puis reduce ×3 et une boucle min/max. Il est appelé dans _buildChart (l.1051) du viewer, dans _buildFullscreenChart (l.1297) et dans EmbeddedTrendChart.build (l.2144). Chaque setState (changement de couleur, toggle tableau/graphe) ou tout rebuild du provider (le dashboard watch trendLogViewerProvider) refait le tri complet sur le thread UI. Sur un dashboard avec plusieurs EmbeddedTrendChart, chaque rebuild de grille multiplie ce coût.

**Correction :** Calculer _ChartData une seule fois par TrendLogData, par exemple dans le notifier ou via un Provider.family dérivé du state, ou en cache dans l'State avec invalidation sur identité de `data`. Le tri peut se faire à l'ingestion.

### [majeur] Zoom pinch exponentiel : details.scale (cumulatif) multiplié à _zoomLevel à chaque update
`lib/presentation/widgets/multi_curve_chart.dart:423` · bug · confiance high

onScaleUpdate fait `_zoomLevel = (_zoomLevel * details.scale).clamp(1,10)`. Or `details.scale` est le facteur cumulé depuis le début du geste (pas un delta). Avec un pinch de 1.0 à 1.5, la mise à jour successive donne 1.0×1.1, puis ×1.2, ×1.3... et le zoom explose en quelques frames jusqu'à 10×. Il n'y a ni onScaleStart pour mémoriser le zoom de base, contrairement à _TrendChartState qui utilise _lastScale. De plus un doigt seul (scale=1) déclenche un pan à 0.5 min/pixel quel que soit le range affiché, et fl_chart (lineTouchData enabled) rivalise avec ce GestureDetector.

**Correction :** Mémoriser `_baseZoom = _zoomLevel` dans onScaleStart et appliquer `_zoomLevel = (_baseZoom * details.scale).clamp(...)`. Rendre la sensibilité du pan proportionnelle à (visibleRange / largeur px). Mieux : factoriser avec la logique de _TrendChartState.

### [majeur] Reconfiguration d'un multi-courbes du dashboard jamais prise en compte
`lib/presentation/widgets/multi_curve_chart.dart:57` · bug · confiance high

_MultiCurveChartState n'initialise qu'une fois (_initialized + initState, aucun didUpdateWidget). Le provider est indexé par chartId='dashboard_widget_<id>' (dashboard_widget_card.dart l.~140). Après _configureMultiCurve (dashboard_screen.dart l.~297) qui modifie la config en base, la carte est reconstruite avec la même ValueKey(id) donc le même State. Même après recréation, _initializeChart (l.67-72) voit selectedTrendLogInstances non vide et sort sans appeler initialize(). Le graphique garde donc les anciennes courbes, noms et unités jusqu'au redémarrage de l'app. Même problème si seuls les noms/unités changent.

**Correction :** Implémenter didUpdateWidget : si initialTrendLogInstances / curveNames / curveUnits changent, appeler un notifier.reconfigure(...) (reset du cache et du state). Ou inclure un hash de la config dans le chartId.

### [majeur] Boucle de rechargement réseau si le trend log est vide (postFrameCallback dans build, sans garde isLoading)
`lib/presentation/screens/dashboard/widgets/dashboard_widget_card.dart:116` · bug · confiance medium

Dans _buildSingleChart, si `state.data == null || state.data!.records.isEmpty`, le build planifie `loadData(period: day)` à chaque build. Quand le buffer est vide (provider trend_log_provider.dart l.~404 pour l'API, l.~335 pour BACnet), le notifier met `data: TrendLogData.fromRecords([])` + error, sans renseigner _cachedFullData. Donc : (1) la branche d'erreur `state.error != null && state.data == null` est ignorée car data est non-null ; (2) la branche vide relance loadData → nouvelle requête réseau → state change → rebuild → nouveau callback. Pendant le chargement (isLoading=true, data non-null), chaque rebuild planifie en plus un loadData concurrent, car loadData n'a pas de garde anti-réentrance. Résultat : requêtes en rafale tant que l'écran est ouvert (le buffer API peut prendre plusieurs minutes), et un seul trend vide suffit. Le même schéma existe en StatsCard (l.~160) mais avec la garde `!isLoading && error == null`.

**Correction :** Ne pas déclencher de chargement depuis build : le faire dans initState/ref.listen ou via un provider FutureProvider. Ajouter dans loadData une garde `if (state.isLoading) return` et ne relancer que si data == null et error == null. Traiter 'vide' comme un état final.

### [majeur] Rafraîchir / changer de période d'un multi-courbes ne recharge jamais les données
`lib/application/providers/multi_curve_provider.dart:260` · bug · confiance high

MultiCurveViewerNotifier.refresh() et setPeriod() appellent loadData(forceRefresh:true), mais _loadSingleCurveData (l.254-262) délègue à `notifier.loadData(period:..., forceRefresh:false)` du TrendLogViewerNotifier. Celui-ci, dès que _cachedFullData existe, ne fait qu'un _applyPeriodFilter sur le cache et ne retélécharge rien. Le bouton Rafraîchir du multi-courbes (multi_curve_chart.dart l.~180) est donc sans effet réseau. Par ailleurs, changer la période d'un multi-courbes modifie le selectedPeriod du provider single partagé par instance (effet de bord visible sur les autres écrans/dashboard qui affichent ce trend log). Le chargement des N courbes est de plus séquentiel (for + await, l.236-243), donc jusqu'à 8 téléchargements de buffer l'un après l'autre.

**Correction :** Passer forceRefresh à loadData du TrendLogViewerNotifier quand il est demandé. Charger les courbes en parallèle avec Future.wait. Séparer l'état période du multi-courbes de celui du viewer single, ou filtrer localement.

### [majeur] WebView Envysion : tous les certificats TLS acceptés sans vérification
`lib/presentation/screens/synoptics/envysion_viewer_screen.dart:314` · securite · confiance high

onReceivedServerTrustAuthRequest répond systématiquement ServerTrustAuthResponseAction.PROCEED (l.318) pour n'importe quel hôte, alors que le commentaire parle de TOFU (aucune empreinte n'est stockée ni comparée). Un attaquant sur le réseau local (typiquement des sites clients) peut faire du MITM sur la session Envysion/OIDC et capturer les identifiants Basic envoyés (voir le constat suivant).

**Correction :** Ne faire PROCEED que si le host == _connection.host et que l'empreinte du certificat correspond à celle mémorisée (TOFU réel, stockée avec la connexion). Sinon CANCEL ou demander confirmation à l'utilisateur.

### [majeur] Identifiants fournis à n'importe quel hôte qui émet un défi HTTP Auth, avec persistance permanente
`lib/presentation/screens/synoptics/envysion_viewer_screen.dart:322` · securite · confiance high

onReceivedHttpAuthRequest renvoie username/password de la connexion sans vérifier challenge.protectionSpace.host (l.322-331), avec `permanentPersistence: true`. Si la page Envysion redirige ou charge une ressource sur un autre hôte (OIDC, CDN, tiers) qui répond 401 Basic, le mot de passe de l'automate lui est envoyé et mémorisé durablement par la WebView. En plus, l'en-tête `Authorization: Basic ...` est posé sur la requête initiale (l.~238).

**Correction :** Vérifier `challenge.protectionSpace.host == _connection.host` (et le port) et sinon retourner CANCEL. Mettre `permanentPersistence: false`. Limiter shouldOverrideUrlLoading au même host et ouvrir le reste dans le navigateur externe.

### [majeur] synopticLiveProvider : Timer 5 s jamais arrêté, bindings jamais rechargés, refresh sans appel réseau
`lib/application/providers/synoptics_provider.dart:316` · bug · confiance high

Le provider est un StateNotifierProvider.family sans autoDispose : le Timer.periodic (l.241) tourne tant que l'app vit, même après avoir quitté le viewer et même pour un synoptique supprimé. Chaque tick fait copyWith(isLoading:true) puis un second état, donc 2 notifications toutes les 5 s. loadBindings() n'est appelé qu'une fois dans _init : après l'édition d'une liaison (upsertBinding/deleteBinding), aucun ref.invalidate(synopticLiveProvider) n'est fait (grep : aucune invalidation), donc une nouvelle liaison s'affiche '-' (pointValues sans sa clé) jusqu'au redémarrage de l'app. refreshValues() ne lit que pointsProvider (cache local) alors que le commentaire dit 'depuis l'API' : le bouton Rafraîchir du viewer ne retélécharge rien. Enfin un seul point introuvable lève Exception et abandonne toute la mise à jour des autres valeurs.

**Correction :** Utiliser StateNotifierProvider.autoDispose.family. Recharger les bindings sur invalidation ou watch du stream DB. Faire lire réellement les valeurs de ces points (read batch) au lieu du cache. Ignorer les points manquants au lieu de throw.

### [majeur] N+1 par tuile de favori : 2 requêtes DB et watch complet de pointsProvider par ligne
`lib/presentation/screens/favorites/favorites_screen.dart:799` · performance · confiance high

Chaque _FavoriteTileInFolder watch pointsProvider en entier (l.799), donc chaque mise à jour des points (polling) reconstruit toutes les tuiles. Il watch aussi folderIdsForFavoriteProvider(favorite.id) (StreamProvider = une requête watch par tuile) et foldersForFavoriteProvider(favorite.id) (une autre requête par tuile, l.802). Elle fait un firstWhere linéaire dans pointsState.points (_findLivePoint, l.~1007) par tuile, soit O(favoris × points). De plus ReorderableListView(children: [...]) est non paresseux : toutes les sections et tuiles sont construites d'un coup.

**Correction :** Charger en une seule requête la map favoriteId→folders (JOIN) dans un unique provider. Dériver une Map<objectId, BacnetObject> via `ref.watch(pointsProvider.select(...))` ou un provider.family par objectId, avec select pour limiter les rebuilds. Passer à ReorderableListView.builder.

### [majeur] Tags de dossiers des favoris périmés : FutureProvider jamais invalidé
`lib/application/providers/favorite_folders_provider.dart:47` · bug · confiance high

foldersForFavoriteProvider est un FutureProvider.family (une requête unique), alors que les mutations (assignToFolder l.164, setFavoriteFolders l.192, ainsi que l'assignation par lot de favorites_screen) n'invalident rien (grep : aucun invalidate dans ce fichier). L'écran affiche les pastilles de couleur à partir de ce provider (favorites_screen.dart l.~802, 826-845). Après avoir assigné un favori à un dossier, ou en avoir supprimé un, les pastilles restent fausses tant que le provider n'est pas détruit. Seul folderIdsForFavoriteProvider, lui, est un stream.

**Correction :** Convertir en StreamProvider (watchFoldersForFavorite) comme son jumeau, ou invalider les familles concernées après chaque mutation.

### [majeur] Le détail d'un planning est lu deux fois sur l'automate (scheduleDetailProvider + ScheduleEditNotifier.loadSchedule)
`lib/presentation/screens/schedules/schedule_detail_screen.dart:28` · performance · confiance high

À l'ouverture, initState planifie loadSchedule(widget.instance) (l.28-31, appel BACnet readScheduleFull ou API getScheduleDetail), alors que build watch aussi scheduleDetailProvider(instance), qui fait la même lecture. Le bouton Rafraîchir (l.~176) relance les deux, et save() réinvalide encore scheduleDetailProvider (schedule_provider.dart l.779) : en tout 2 à 3 lectures complètes du WeeklySchedule par ouverture/sauvegarde (sur BACnet/UDP avec ReadProperty fragmentés, c'est coûteux).

**Correction :** Un seul chargement : initialiser ScheduleEditState depuis le résultat de scheduleDetailProvider (ref.listen) plutôt que de relire, ou l'inverse, et ne pas invalider après save mais mettre à jour le cache avec l'édité.

### [majeur] ScheduleEditNotifier global non réinitialisé : un planning périmé ou mauvais peut être affiché/écrit si loadSchedule échoue
`lib/application/providers/schedule_provider.dart:349` · bug · confiance medium

scheduleEditProvider est un StateNotifierProvider global (ni family ni autoDispose, l.851) et dispose() de l'écran ne le reset pas (commentaire dans schedule_detail_screen.dart l.37-41). loadSchedule retourne silencieusement sans toucher l'état en cas d'erreur BACnet, de connexion absente, ou si le schedule est null (l.352-385). Scénario : ouvrir le planning A, puis le planning B dont la lecture BACnet échoue (timeout). En mode édition, `displaySchedule` utilise `editState.editedSchedule` (l.94) donc affiche le planning A sous le titre de B, et save() écrit editedSchedule.instance = A. Aucune erreur n'est remontée à l'utilisateur car loadSchedule ne renseigne pas `error`. De plus, deux loadSchedule rapides (A puis B) ne sont pas ordonnés : la réponse tardive de A écrase B.

**Correction :** Reset l'état au début de loadSchedule (ou autoDispose.family par instance), poser state.error en cas d'échec, vérifier `editedSchedule.instance == widget.instance` avant d'afficher/éditer, et ignorer les réponses obsolètes.

### [mineur] _panOffset non re-clampé quand on dézoome : graphe décalé à zoom 1x
`lib/presentation/widgets/multi_curve_chart.dart:429` · bug · confiance high

Le pan n'est clampé que `if (_zoomLevel > 1.0)` (l.428). Si l'utilisateur zoome, panne, puis pince pour revenir à 1.0 (le clamp ramène à 1.0), _panOffset garde sa valeur. actualMinX = minX + _panOffset et actualMaxX = actualMinX + totalRange (l.405-407) : le graphe affiche alors une fenêtre décalée, avec des données coupées et du vide à droite, sans indicateur de zoom (masqué si zoom == 1). Seul le double-tap remet à zéro. De plus, si visibleMinY == visibleMaxY (courbe constante), yPadding = 0 donc minY == maxY, ce qui est invalide pour fl_chart. _TrendChart protège ce cas via minX>=maxX / minY>=maxY, pas le multi-courbes.

**Correction :** Re-clamper _panOffset à chaque changement de zoom (comme _clampPanOffset du TrendChart). Appliquer un padding minimal (ex. 1.0) quand range == 0.

### [mineur] Tri complet de tous les records uniquement pour des logs de debug, à chaque changement de période
`lib/application/providers/trend_log_provider.dart:459` · performance · confiance high

Dans _applyPeriodFilter, `List.from(records)..sort(...)` (l.459) est exécuté inconditionnellement pour calculer dataStart/dataEnd, qui ne servent qu'à des _logger.d(...). Pour 10 000 records, c'est un tri O(n log n) sur le thread UI à chaque setPeriod, loadData sur cache ou dashboard. Même chose avec les boucles de logs debug de _loadDataFromBacnet. De plus `json.decode(bufferData)` et le parsing (l.424) du buffer V1/V2 (potentiellement plusieurs Mo) se font sur le thread UI.

**Correction :** Supprimer le bloc de debug ou le garder derrière `kDebugMode`. Déplacer le décodage JSON + parsing dans `compute()` / Isolate.run.

### [mineur] Réglages WebView trop permissifs : accès fichiers universel, contenu mixte, saveFormData
`lib/presentation/screens/synoptics/envysion_viewer_screen.dart:261` · securite · confiance medium

initialSettings active allowUniversalAccessFromFileURLs et allowFileAccessFromFileURLs (l.265-266), mixedContentMode MIXED_CONTENT_ALWAYS_ALLOW (l.261) et saveFormData, avec JS activé. Aucun contenu file:// n'est chargé ici, donc ces droits n'ont aucune utilité. Ils augmentent la surface d'attaque si la page distante est compromise ou si un redirect pointe vers un schéma inattendu.

**Correction :** Passer les deux allow...FileURLs à false, mixedContentMode à COMPATIBILITY_MODE ou NEVER_ALLOW, et saveFormData à false.

### [mineur] useShouldInterceptRequest actif uniquement pour un debugPrint
`lib/presentation/screens/synoptics/envysion_viewer_screen.dart:268` · performance · confiance medium

Avec useShouldInterceptRequest:true, chaque requête de sous-ressource de la page Envysion traverse le pont natif vers Dart. Le callback (l.289-296) se contente d'un debugPrint et de `return null`. Il utilise aussi `_connection!.host`. Le surcoût est inutile et ralentit le chargement d'un synoptique chargé en ressources. Le commentaire annonce une injection d'en-tête qui n'existe pas.

**Correction :** Supprimer useShouldInterceptRequest et le callback.

### [mineur] Un 404/401 sur une sous-ressource affiche l'overlay d'erreur plein écran
`lib/presentation/screens/synoptics/envysion_viewer_screen.dart:346` · bug · confiance medium

onReceivedHttpError (l.341-352) fait setState(_errorMessage) pour tout 401/404, y compris favicon.ico ou n'importe quelle ressource secondaire, contrairement à onReceivedError qui filtre sur l'URL principale. Un favicon 404 suffit donc à recouvrir la page chargée par la carte 'Erreur de chargement' (affichée dès `!_isLoading`). Les setState des callbacks onLoadStart/onLoadStop/onProgressChanged (l.~290-315) n'ont pas de garde `mounted`.

**Correction :** Filtrer comme dans onReceivedError (`request.isForMainFrame == true` ou URL == _buildFullUrl()) et ajouter `if (!mounted) return` dans les callbacks. Supprimer _initCookieManager qui n'a aucun effet (variable inutilisée).

### [mineur] Chemin SVG+overlays : positions codées en dur pour CR_V0.1, uniquement atteint pour les autres SVG
`lib/presentation/screens/synoptics/synoptic_viewer_screen.dart:595` · code-mort · confiance high

_buildSynopticWidget (l.149) route CR_V0.1 vers le widget natif, donc _SvgWithOverlays n'est utilisé que pour d'autres SVG. Pourtant _getOverlayPosition (l.595-612) ne connaît que des ids du SVG CR_V0.1 (offsets en pixels logiques 'approximatifs', ne suivant pas le BoxFit.contain ni le zoom du SvgPicture) et renvoie null pour le reste : ce chemin n'affiche donc aucune valeur. Il crée aussi un AnimationController qui tourne en boucle à l'infini (l.390-393) même sans binding d'animation, et re-parse BindingConfig.fromJson (jsonDecode) pour chaque binding à chaque rebuild/poll (l.430, 473, 518 et 180).

**Correction :** Soit supprimer le fallback, soit lire les positions depuis le SVG/une table par synoptique et mapper via la matrice de rendu. Ne démarrer le controller que si un binding animation est actif. Pré-parser BindingConfig une fois (cache par binding.id). Remplacer le test `contains('CR_V0.1')` par un champ 'renderer' en base.

### [mineur] Éditeur de synoptique inutilisable sur téléphone : panneau droit fixe 350 px dans un Row
`lib/presentation/screens/synoptics/synoptic_editor_screen.dart:59` · architecture · confiance medium

Le body est un Row avec panneau SVG Expanded(flex 2) et Container(width: 350) (l.~99). Sur un téléphone de ~360-400 dp (cible Android/iOS de l'app, la WebView n'y étant supportée que sur ces plateformes), l'aperçu SVG se réduit à quelques dizaines de pixels, voire déborde.

**Correction :** Utiliser LayoutBuilder : en dessous d'environ 700 dp, empiler (Column) ou passer par des onglets plutôt qu'un Row à largeur fixe.

### [mineur] TextEditingController jamais disposé (titre widget et nom du dashboard)
`lib/presentation/screens/dashboard/dashboard_screen.dart:385` · bug · confiance high

`final controller = TextEditingController(text: currentTitle)` (l.385) et `final nameController = TextEditingController(text: dashboard.name)` (l.471) sont créés dans des méthodes qui ouvrent un showDialog, sans jamais appeler dispose() (grep : aucun dispose dans le fichier). Chaque ouverture du dialogue fuit un controller et ses listeners. Autre point : _addWidget attend un `Future.delayed(100ms)` arbitraire (l.227) pour 'laisser le provider se mettre à jour' puis passe un DashboardWidget temporaire avec configJson null à _configureWidget.

**Correction :** Disposer les controllers après le `await showDialog` (try/finally) ou déplacer le contenu dans un StatefulWidget dédié. Remplacer le Future.delayed par l'attente de l'état du provider ou utiliser directement le widget retourné par addWidget.

### [mineur] Pull-to-refresh du dashboard sans effet sur les données, et chargements concurrents du même trend log
`lib/presentation/screens/dashboard/dashboard_screen.dart:105` · performance · confiance high

RefreshIndicator.onRefresh (l.106-108) ne fait qu'invalider dashboardWidgetsProvider (la liste des widgets en base, qui retourne immédiatement) et ne rafraîchit aucun trend log. Chaque DashboardWidgetCard déclenche indépendamment loadData pour le même trendLogInstance (carte single en période 'day', carte stats avec le défaut), sans déduplication de requêtes en vol dans TrendLogViewerNotifier.loadData : deux téléchargements concurrents du même buffer sont possibles. Tous les providers family de trend restent en mémoire (non autoDispose) avec leurs records complets.

**Correction :** Dans onRefresh, appeler refresh() sur les notifiers concernés et attendre leur fin. Mémoriser le Future en cours dans loadData (single-flight). Passer en autoDispose.family ou purger le cache à la sortie du dashboard.

### [mineur] Opérations de masse : N×M écritures séquentielles et itération sur un Set modifiable pendant des await
`lib/presentation/screens/favorites/favorites_screen.dart:210` · bug · confiance medium

_assignSelectedToFolders (l.210-214) et _deleteSelected (l.258-260) bouclent sur `_selectedFavoriteIds` en faisant un await par écriture DB (jusqu'à favoris × dossiers écritures, chacune réémettant les streams). Pendant ces await, l'UI reste interactive : toucher une case de sélection (_toggleFavoriteSelection) modifie le Set en cours d'itération et lève ConcurrentModificationError. Dans _deleteSelected, le message de confirmation utilise `_selectedFavoriteIds.length` après la boucle. Le Dismissible.onDismissed (l.994-1000) affiche un SnackBar via `context.mounted` après un await alors que la tuile a été retirée de l'arbre (le contexte est probablement déjà démonté, donc pas de confirmation).

**Correction :** Copier la sélection (`final ids = _selectedFavoriteIds.toList()`) avant la boucle et bloquer l'UI pendant l'opération. Ajouter dans la DB une méthode batch en transaction (assignFavoritesToFolders / deleteFavorites). Capturer le ScaffoldMessenger avant l'await.

### [mineur] _handleCloseEdit : setState et ref sans vérification mounted après await ; setEditing(false) appelé même si l'édition continue
`lib/presentation/screens/schedules/schedule_detail_screen.dart:268` · bug · confiance medium

Après `await showDialog`, _handleCloseEdit appelle setState (l.278, 281) et ref.read (l.283) sans `if (!mounted) return`. Si l'utilisateur quitte l'écran pendant le dialogue, setState après dispose lève une exception. Quand l'utilisateur répond 'Garder' (discard != true), le code exécute quand même `setEditing(false)` (l.283) : le flag isEditing du provider passe à false alors que l'écran reste en mode édition (_isEditing local à true). Après un save réussi, _handleSave ne rappelle pas non plus setEditing(false).

**Correction :** Ajouter `if (!mounted) return` après chaque await. N'appeler setEditing(false) que dans les branches où l'on quitte l'édition (ou supprimer le doublon d'état _isEditing / editState.isEditing).

### [mineur] shouldRepaint de _DayTimelinePainter incomplet
`lib/presentation/screens/schedules/widgets/weekly_schedule_view.dart:426` · bug · confiance medium

shouldRepaint ne compare que daySchedule et colorScheme. Les champs schedule (valueType, utilisé par ScheduleColors.getColorForValue), hourWidth, startHour et endHour peuvent changer sans repaint (par exemple le type de valeur détecté après chargement, ou une taille différente si hourWidth/range deviennent dynamiques). daySchedule est comparé par identité (pas d'operator ==), ce qui reste correct mais repeint à chaque rebuild avec une nouvelle instance. À contrario, le circuit_regule_painter compare bien ses champs.

**Correction :** Comparer aussi schedule.valueType, hourWidth, startHour, endHour. Idéalement donner des == aux modèles DaySchedule/Schedule.

### [mineur] Gros copier-coller entre trend_log_viewer.dart et multi_curve_chart.dart (+ domain/multi_curve_chart.dart)
`lib/presentation/widgets/trend_log_viewer.dart:338` · duplication · confiance high

Éléments dupliqués : (1) _ChartData.fromRecords (trend_log_viewer l.338-387) vs CurveData.fromTrendLogData (domain/models/multi_curve_chart.dart l.195-250) : même filtre/tri/spots/min/max/avg/minSpot/maxSpot ; (2) _PeriodSelector (trend_log_viewer l.582) vs _MultiCurvePeriodSelector (multi_curve_chart l.320), quasi identiques ; (3) _LoadingState/_ErrorState/_EmptyState (trend_log_viewer l.738/769/806 vs multi_curve_chart l.724/753/788) ; (4) _formatValue (trend_log_viewer l.~296 vs multi_curve_chart l.817), à l'identique ; (5) _StatisticsBar/_StatItem (l.621/685) vs _MultiCurveStatistics/_StatColumn (l.615/670) ; (6) la logique de zoom/pan/_buildDateLabel/intervalles, avec en prime une version correcte (_TrendChartState) et une buggée (_MultiCurveLineChartState). La duplication a déjà produit des divergences de comportement : zoom exponentiel et pan non clampé côté multi-courbes seulement.

**Correction :** Extraire un fichier `chart_common.dart` (états loading/erreur/vide, formatValue, PeriodSelector générique avec callback) et un ZoomPanController partagé. Réutiliser CurveData pour le single chart (liste à 1 courbe) et fusionner les deux LineChart dans un widget unique `TrendLineChart(curves: [...])`.

### [mineur] Code mort dans MultiCurveViewerNotifier : _loadFromBacnet, _loadFromApi, _filterByPeriod, _getMaxRecordsForPeriod
`lib/application/providers/multi_curve_provider.dart:302` · code-mort · confiance high

Ces quatre méthodes (l.302-366 et 423-440) ne sont appelées nulle part (grep : seules leurs définitions et les appels entre elles). Le chargement passe par trendLogViewerProvider (_loadSingleCurveData). Elles reproduisent par ailleurs la logique du TrendLogViewerNotifier (maxRecords par période, appel BACnet/API), source de divergence. Même constat pour `_cachedBuffer` de TrendLogViewerNotifier, écrit mais jamais relu pour parser.

**Correction :** Supprimer ces méthodes et le champ _cachedBuffer.

### [mineur] Zoom/pan de _TrendChart conservés quand les données changent ; showDots basé sur le total plutôt que le visible
`lib/presentation/widgets/trend_log_viewer.dart:1362` · bug · confiance low

_TrendChartState garde _zoomLevel/_panOffsetX/_panOffsetY à travers un changement de chartData (changement de période, refresh, autre trend log dans le même arbre) car il n'y a pas de didUpdateWidget qui les remet à zéro ; X/Y bornés par les nouvelles données peuvent alors afficher une fenêtre incohérente. showDots est décidé avec chartData.spots.length (l.1060/1312/2156) puis combiné à visibleSpots.length<50 : en plein écran avec 40 points visibles sur 5 000, les points sont masqués. La sensibilité de pan est calculée via `totalRangeX/300` pixels fixes (l.~1480), pas en fonction de la largeur réelle du widget.

**Correction :** Réinitialiser le zoom dans didUpdateWidget quand chartData change d'identité. Utiliser LayoutBuilder pour avoir la largeur réelle du chart pour le pan. Décider showDots seulement sur visibleSpots.

## Transversal (sécurité, duplication, deps, tests, l10n) (22 constats)

Audit transversal de lib/. Le point le plus grave est la sécurité TLS : toutes les connexions HTTPS acceptent n'importe quel certificat, et le TOFU annoncé dans CLAUDE.md n'existe pas. L'empreinte est calculée puis jamais stockée ni comparée. Le basicAuth est dupliqué dans deux providers avec une logique de connexion copiée-collée, et le cache de clients de super_favorites peut rester périmé. Les helpers de formatage sont dupliqués (_formatMinutes x3, _formatValue x3). Il y a beaucoup de chaînes françaises en dur dans presentation/ malgré les fichiers ARB. La couverture de tests est quasi nulle (un seul smoke test, aucun test sur l'encodeur/décodeur BACnet de plus de 2800 lignes). Les dépendances sont globalement en retard de plusieurs versions majeures et sqlite3_flutter_libs est EOL. flutter analyze remonte 92 issues, surtout des deprecations (withOpacity, Radio groupValue) et du code mort. Non vérifiés faute de temps : les races asynchrones fines et les fuites dans bacnet_service.

### [critique] TLS désactivé sans TOFU : tout certificat est accepté, y compris pour les requêtes authentifiées
`lib/data/services/api_service.dart:223` · securite · confiance high

ConnectedApiClient (l.223) fait client.badCertificateCallback = (cert, host, port) => true, et ApiService._configureForSelfSignedCerts (l.43-48) renvoie aussi true sans comparer l'empreinte. Ce client envoie l'en-tête Authorization: Basic (identifiants en base64) à chaque requête. Un attaquant en MITM sur le réseau (Wi-Fi de chantier) présente n'importe quel certificat et récupère login et mot de passe, puis peut écrire sur les automates. Le TOFU décrit dans CLAUDE.md n'est pas implémenté : certificateFingerprint est calculé (l.45, 100-122) et la colonne DB existe (connections_table.dart:40, app_database.dart:163 updateCertificateFingerprint), mais rg ne trouve aucun appelant. L'empreinte n'est donc jamais stockée ni vérifiée. Le commentaire l.46 'TOFU géré au niveau supérieur' est faux.

**Correction :** Stocker l'empreinte au premier test de connexion (updateCertificateFingerprint). Dans ConnectedApiClient, passer l'empreinte attendue et ne retourner true que si cert.sha256 correspond (utiliser SHA-256 et non SHA-1 comme _calculateFingerprint). Alerter l'utilisateur si l'empreinte change.

### [majeur] usesCleartextTraffic=true : HTTP en clair autorisé globalement avec Basic Auth
`android/app/src/main/AndroidManifest.xml:6` · securite · confiance high

Le trafic HTTP en clair est autorisé pour tout domaine. Une connexion avec useHttps=false envoie Authorization: Basic en clair sur le réseau. Le réglage useHttps est lisible dans active_connection_provider.dart:312 et rien n'avertit l'utilisateur.

**Correction :** Restreindre le cleartext via network_security_config aux IP privées si nécessaire, et afficher un avertissement quand useHttps=false.

### [majeur] Construction du client API (lecture du mot de passe, basicAuth, ConnectedApiClient) copiée dans deux providers
`lib/application/providers/super_favorites_provider.dart:575` · duplication · confiance high

Le bloc secureStorage.read(passwordKey) puis base64Encode('user:password') puis new ConnectedApiClient apparaît dans active_connection_provider.dart:299-323 et super_favorites_provider.dart:575-594. Les versions par défaut divergent : 'V2' à l.318 d'un côté, 'V1' à l.591 de l'autre, donc deux comportements différents pour une connexion dont apiVersion est null. De plus, ConnectedApiClient reçoit un String basicAuth précalculé et le répète dans des dizaines de blocs headers 'Authorization' dans api_service.dart (l.398, 492, 538... plus de 50 occurrences) au lieu d'utiliser un interceptor Dio ou _authOptions (l.235).

**Correction :** Extraire une factory unique (ex. connectionClientFactory(Connection)) avec une seule valeur par défaut d'apiVersion. Mettre l'en-tête Authorization dans BaseOptions.headers ou un interceptor, et supprimer les 50 répétitions.

### [majeur] Cache _apiClients jamais invalidé : identifiants périmés après changement de mot de passe ou d'hôte
`lib/application/providers/super_favorites_provider.dart:554` · bug · confiance medium

_getApiClientForConnection renvoie _apiClients[connectionId] (l.554-555) sans jamais le recréer. Le basicAuth est figé à la création. Si l'utilisateur modifie le mot de passe, l'hôte ou le port d'une connexion (connection_providers.dart:84-95 updateConnection), les super-favoris continuent avec les anciennes identifiants (401 répétés, ou compte verrouillé) jusqu'au redémarrage du provider. Aucun invalidate n'est lié à la mise à jour. Aucun lien non plus avec la suppression d'une connexion.

**Correction :** Invalider/fermer l'entrée de _apiClients lors de updateConnection/deleteConnection (ref.listen sur la connexion), ou ne pas mettre en cache le client.

### [majeur] Import : connexions créées avec passwordKey vide ; les chemins de connexion échouent sans guidage
`lib/application/providers/settings_provider.dart:315` · securite · confiance medium

Après import de sauvegarde, insertConnection met passwordKey: '' (l.315). Au connect, secureStorage.read(key: '') renvoie null et l'erreur 'Mot de passe introuvable' (active_connection_provider.dart:301-307) est affichée sans que l'utilisateur sache qu'il doit éditer la connexion. De plus la colonne exige withLength(min:1) (connections_table.dart:29) : l'insertion d'une chaîne vide peut violer la contrainte selon la couche de validation Drift. Les messages d'erreur sont aussi en français en dur.

**Correction :** Générer une clé passwordKey unique à l'import (comme connection_providers.dart:52) et marquer la connexion comme 'mot de passe à saisir' dans l'UI.

### [majeur] Couverture de tests quasi nulle : un seul smoke test
`test/widget_test.dart:1` · tests · confiance high

test/ contient uniquement widget_test.dart (21 lignes) qui pompe MyGlobalDCApp. Aucun test sur bacnet_encoder.dart (961 l.), bacnet_decoder.dart (1860 l.), bacnet_constants.dart, api_service.dart (3757 l.), schedule.dart (894 l.) ou bacnet_object.dart (1068 l.). mocktail est en dev_dependencies mais inutilisé.

**Correction :** Tests prioritaires : (1) round-trip encode/decode BACnet (tags, Real, Unsigned, ObjectIdentifier, APDU ReadProperty/ReadPropertyMultiple/WriteProperty) avec trames de référence ; (2) parsing de schedule.dart (weekly schedule, exceptions, conversion minutes/heures) ; (3) parsing V1/V2 des réponses API avec mocks Dio (mocktail) ; (4) conversions d'unités/valeurs de bacnet_object.dart ; (5) import/export de settings_provider ; (6) logique de cooldown de super_favorites.

### [majeur] _formatMinutes copié 3 fois à l'identique
`lib/presentation/screens/schedules/widgets/vertical_day_schedule_view.dart:522` · duplication · confiance high

Même corps (minutes >= 1440 donne '24:00', sinon HH:mm) dans vertical_day_schedule_view.dart:522 et :836 (deux classes de la même fichier) et schedule_dialogs.dart:51. Une correction de bug devrait être appliquée 3 fois.

**Correction :** Extraire une fonction top-level dans core/utils (ex. formatMinutesOfDay) ou une extension sur int.

### [majeur] Souscription du socket UDP non conservée ; rebind ferme le socket sans annuler le listener
`lib/data/services/bacnet_service.dart:130` · conformite-bacnet · confiance low

_socket!.listen(_handleResponse) (l.130) ne garde pas le StreamSubscription. rebindToInterface (l.139-153) et dispose (l.156) ferment le socket sans nettoyer les timers/Completers de _pendingRequests (qui est simplement .clear(), laissant les Future en attente jamais complétées). Un appel en cours lors d'un changement d'interface attend jusqu'à un éventuel timeout ou reste suspendu, selon son implémentation. Non vérifié plus loin dans bacnet_service.dart.

**Correction :** Conserver la subscription, l'annuler avant fermeture, et compléter les requêtes en attente avec une erreur dans rebind/dispose.

### [majeur] api_service.dart : fichier monolithique de 3757 lignes, V1/V2 mélangés, plus des widgets de 1000 à 2200 lignes
`lib/data/services/api_service.dart:1` · architecture · confiance high

api_service.dart regroupe test de connexion, client V1/V2, points, trends, schedules et alarmes, avec une branche apiVersion == 'V2' par méthode. Même constat pour trend_log_viewer.dart (2205 l.), bacnet_service.dart (2500 l.), bacnet_decoder.dart (1860 l.), home_screen.dart (1215 l.), connections_list_screen.dart (1266 l.). CLAUDE.md décrit une Clean Architecture 4 couches 'planned' mais domain/ ne contient que des modèles et l'UI appelle directement les services. Cela rend les tests difficiles (cf. constat tests).

**Correction :** Découper en interface ApiClient + ApiClientV1 / ApiClientV2 (strategy) et un repository par domaine (points, trends, schedules) ; scinder les grands écrans en widgets.

### [majeur] Fichiers l10n dupliqués : lib/l10n/*.dart et lib/l10n/generated/*.dart
`lib/l10n/app_localizations.dart:1` · architecture · confiance high

Les deux répertoires contiennent app_localizations.dart, _en.dart et _fr.dart identiques (par exemple password en l.39 dans les deux). Deux sources de vérité potentielles qui divergeront après un gen-l10n (l10n.yaml pointe vers l'un seulement).

**Correction :** Vérifier l10n.yaml (output-dir) et supprimer le répertoire obsolète, n'importer que l'autre.

### [majeur] Nombreuses chaînes françaises en dur, non traduites malgré l10n EN/FR
`lib/presentation/screens/synoptics/synoptic_editor_screen.dart:31` · architecture · confiance high

22 fichiers de presentation/ contiennent des Text('...') littéraux : 'Annuler', 'Enregistrer', 'Supprimer la liaison ?', 'Synoptique non trouvé', 'Erreur: $e' (synoptic_editor_screen.dart, synoptic_viewer_screen.dart:40-136), 'Assigner aux dossiers', 'Créer un dossier' (assign_folders_dialog.dart:71-193), 'Réessayer' (trend_log_viewer.dart:796, multi_curve_chart.dart:779, dashboard_widget_card.dart:112), 'Heure de l'automate' (home_screen.dart:998), colonnes 'Date/Heure|Valeur|Status' (trend_log_viewer.dart:861). Les messages d'erreur dans les providers sont aussi en dur ('Mot de passe introuvable', 'Erreur de connexion'). Une UI en anglais affichera du français.

**Correction :** Ajouter les clés dans app_fr.arb/app_en.arb (cancel, save, retry, error, ...) et remplacer les littéraux ; réutiliser les clés existantes quand elles existent. Remonter des codes d'erreur plutôt que des textes depuis les providers.

### [majeur] Dépendances en retard de plusieurs versions majeures, dont une EOL
`pubspec.yaml:20` · architecture · confiance high

flutter pub outdated : flutter_riverpod 2.6.1 vers 3.4.3, riverpod_annotation 2.6.1 vers 4.0.7, go_router 14.8.1 vers 18.1.0, file_picker 8.3.7 vers 13.1.0, flutter_secure_storage 9.2.4 vers 11.2.0, share_plus 10.1.4 vers 13.3.1, fl_chart 0.68.0 vers 1.2.0, connectivity_plus 6.1.5 vers 7.3.2, freezed 2.5.8 vers 4.0.2, drift 2.28 vers 2.35, drift_flutter 0.1.0 vers 0.3.1. sqlite3_flutter_libs est marqué '0.6.0+eol' (paquet abandonné, à migrer vers sqlite3 + hooks). Les mineures sans risque (dio 5.9 vers 5.11, flutter_svg, logger, uuid, path_provider, shared_preferences) peuvent être appliquées immédiatement. dartz est dans les deps mais probablement peu utilisé (non vérifié). flutter_inappwebview n'apparaît pas outdated.

**Correction :** flutter pub upgrade pour les mineures ; planifier la migration Riverpod 3 + go_router + flutter_secure_storage (stockage des mots de passe) ; vérifier l'usage réel de dartz, equatable, crypto via rg et retirer les inutilisés.

### [mineur] Log d'erreur avec le nom de clé de stockage sécurisé
`lib/application/providers/super_favorites_provider.dart:577` · securite · confiance high

_logger.e affiche passwordKey ('conn_pwd_<timestamp>'). Ce n'est pas le secret mais cela expose le nom de clé dans les logs. Aucun log de mot de passe ou de basicAuth n'a été trouvé (rg), c'est donc mineur. Notons qu'il n'y a pas de LogInterceptor Dio non plus.

**Correction :** Retirer la clé du message de log.

### [mineur] _formatValue dupliqué avec des précisions incohérentes
`lib/presentation/widgets/trend_log_viewer.dart:296` · duplication · confiance high

trend_log_viewer.dart:296 et multi_curve_chart.dart:817 sont identiques (2 décimales). dashboard_widget_card.dart:268 est la même fonction avec 1 décimale. Un même point peut donc s'afficher 12.34 dans la courbe et 12.3 sur le dashboard. Aussi _formatTimestamp/_formatAlarmTimestamp/_formatDateTime (alarms_screen.dart:381, point_detail_screen.dart:925, device_info_screen.dart:532) refont du formatage de date à la main alors que intl est une dépendance.

**Correction :** Centraliser dans core/utils/formatters.dart (formatNumber(value, decimals), formatDateTime via intl DateFormat avec locale).

### [mineur] Boilerplate de dialogs et de RadioListTile répété (AlertDialog dans 15 fichiers)
`lib/presentation/screens/settings/settings_screen.dart:132` · duplication · confiance medium

rg compte 9 AlertDialog dans settings_screen.dart, 8 dans schedule_dialogs.dart, 5 dans dashboard_screen.dart et 5 dans connections_list_screen.dart, souvent des confirmations Annuler/Confirmer identiques. settings_screen.dart répète 8 paires RadioListTile groupValue/onChanged (l.132, 167, 178, 216, 265, 347, 358, 406), toutes dépréciées (cf. analyze).

**Correction :** Créer un helper showConfirmDialog(context, title, content, destructive) et migrer les radios vers RadioGroup en une passe.

### [mineur] Code mort signalé par l'analyzer : _loadFromBacnet, _loadFromApi, _filterByPeriod
`lib/application/providers/multi_curve_provider.dart:302` · code-mort · confiance high

Trois méthodes privées jamais référencées (l.302, 335, 360), soit environ 80 lignes. Même chose pour _cachedBuffer (trend_log_provider.dart:238), _showUnsupportedPlatformDialog (envysion_viewer_screen.dart:120), la variable cookieManager inutilisée (envysion_viewer_screen.dart:46), canRefresh (connections_list_screen.dart:1209), colorScheme (vertical_day_schedule_view.dart:27), le paramètre startYAtZero (trend_log_viewer.dart:1355) et l'import inutile de ui_constants.dart:1.

**Correction :** Supprimer ces éléments (flutter analyze les liste tous).

### [mineur] return d'un Future sans await dans un try/catch : les exceptions ne sont pas capturées
`lib/application/providers/active_connection_provider.dart:136` · bug · confiance medium

return _connectBacnet(connection) (l.136) et return _connectDistechApi(connection) (l.142) sont dans un try { } catch. Sans await, une exception asynchrone levée par ces méthodes (par exemple l'échec du secureStorage.read l.299) échappe au catch, donc isConnecting reste true et l'UI reste en 'connexion en cours' indéfiniment.

**Correction :** Utiliser return await _connectDistechApi(connection); (idem _connectBacnet).

### [mineur] Timer.periodic 1 s avec setState sur tout le widget
`lib/presentation/screens/connections/connections_list_screen.dart:1053` · performance · confiance low

Deux Timer.periodic d'une seconde (l.1053 et 1190) appellent setState(() {}) pour un compte à rebours et relisent superFavoritesProvider à chaque tick. Le widget entier se reconstruit chaque seconde tant qu'un cooldown est actif. Les timers semblent annulés (garde mounted présente) mais je n'ai pas vérifié le dispose.

**Correction :** Isoler le compte à rebours dans un petit widget (ValueListenable/StreamBuilder) pour ne reconstruire que le texte.

### [mineur] use_build_context_synchronously : context utilisé après await derrière un mounted non pertinent
`lib/presentation/screens/settings/settings_screen.dart:461` · bug · confiance medium

analyze signale ce schéma dans settings_screen.dart (461, 467, 500, 542, 549, 631), dashboard_screen.dart (240, 276, 324, 578), favorites_screen.dart (218, 263, 424), dashboard_list_screen.dart:188. Le garde mounted porte sur un autre objet : si l'écran est fermé pendant un await (export de fichier, dialog), Navigator/ScaffoldMessenger.of(context) lève une exception sur un contexte démonté.

**Correction :** Capturer ScaffoldMessenger/Navigator avant l'await ou tester context.mounted sur le bon contexte.

### [mineur] Un client Dio par ConnectedApiClient sans partage de connexions
`lib/data/services/api_service.dart:198` · performance · confiance low

Chaque ConnectedApiClient crée son Dio et son HttpClient (l.213-225). Super-favoris et connexion active peuvent ouvrir deux clients vers la même IP au lieu d'un, doublant les handshakes TLS (pas de keep-alive partagé). _apiClients est dédupliqué par id, mais le client actif de active_connection_provider n'est réutilisé que s'il est connecté (super_favorites_provider.dart:553).

**Correction :** Fournir le client via un registre unique par connectionId (voir le constat sur la factory).

### [mineur] WebView avec cookies tiers activés et session OIDC persistante
`lib/presentation/screens/synoptics/envysion_viewer_screen.dart:269` · architecture · confiance medium

thirdPartyCookiesEnabled: true et persistance des cookies (l.40-48, 269-273) pour garder la session OIDC du designer Envysion. Acceptable pour ce besoin, mais la session reste persistée sans bouton de déconnexion. Pas de validation TLS spécifique ici (non vérifiée).

**Correction :** Ajouter une purge des cookies à la suppression de la connexion, et limiter l'URL à l'hôte de l'automate.

### [mineur] Repo racine encombré d'artefacts (logs, PDF, binaires) et lints bruyants
`lib/domain/models/schedule.dart:1` · code-mort · confiance medium

À la racine : logs_boot.txt, renduA.pdf, rendu_mydumcontrol.pdf, images_model/, solution_OK_trend_Bacnet.md, build/ ; ils devraient être en .gitignore ou dans docs/. flutter analyze compte 92 issues dont ~80 infos : withOpacity déprécié (splash_screen.dart:89-208, home_screen.dart:485, discover_bacnet_screen.dart:239...), unnecessary_underscores (6 occurrences), Form 'value' dépréciée (discover_bacnet_screen.dart:425), onReorder déprécié (favorites_screen.dart:311). Aucun warning bloquant hormis le code mort ci-dessus.

**Correction :** Remplacer withOpacity par withValues(alpha:), nettoyer la racine et lancer dart fix --apply pour les lints automatiques.
