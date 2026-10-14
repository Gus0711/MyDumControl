# API Distech ECLYPSE — index

Référence compacte générée depuis les collections Postman officielles (`API-V2.postman_collection.json`, `API-V1.postman_collection.json`) par `postman_to_md.py`. Ne pas modifier les fichiers `v1/` et `v2/` à la main : relancer `python3 postman_to_md.py`.

## Conventions

- **URL de base V2** : `https://<hôte>/api/rest/v2` (variable Postman `{{BasePath}}`). Les chemins des fichiers `v2/` sont relatifs à cette base.
- **URL de base V1** : `https://<hôte>/api/rest/v1` (legacy, contrôleurs anciens).
- **Version de l'API** : `GET https://<hôte>/api/rest`.
- **Authentification** : HTTP Basic (identifiants du contrôleur) sur toutes les requêtes. Jeton possible via `POST https://<hôte>/auth/local/token` (voir [v2/00-General.md](v2/00-General.md)).
- **Lecture** : `GET` ; **écriture** : `POST` avec un corps JSON partiel (seuls les champs envoyés sont modifiés) ; `PUT` pour créer/remplacer ; `DELETE` pour supprimer.
- **Les nombres dans les chemins sont des exemples** (ex. `devices/210066/objects/binary-values/11` = device BACnet 210066, instance 11). Les noms d'objets BACnet sont en kebab-case : `analog-values`, `binary-inputs`, `multi-state-values`…
- **Sélection de champs (`$select`)**, imbricable : `GET /services/bacnet/local/objects?$select=analog-values($select=*($select=object-name,present-value))`. `*` = tous les éléments d'une collection. Plusieurs `$select` se combinent avec `&`. Exemples complets dans [v2/00-General.md](v2/00-General.md).
- **Exemples de corps** : les longues chaînes et listes sont tronquées (`…(N caractères)`, `… N autres éléments`).

## API V2 (590 requêtes)

| Domaine | Fichier | Requêtes | Sous-parties |
|---|---|---|---|
| Général (auth, version, batch, $select, filtres) | [v2/00-General.md](v2/00-General.md) | 34 | Authentication, Batch Examples, Query Parameters, Filters |
| Alarms | [v2/Alarms.md](v2/Alarms.md) | 12 | Classes, Recipients |
| Asset-Tracking | [v2/Asset-Tracking.md](v2/Asset-Tracking.md) | 8 | Adapter, Edgar |
| Atrius-Facilities | [v2/Atrius-Facilities.md](v2/Atrius-Facilities.md) | 1 |  |
| BACnet | [v2/BACnet.md](v2/BACnet.md) | 93 | Remote, Local, Communication |
| Backup | [v2/Backup.md](v2/Backup.md) | 6 | Backups, External Backups, Excludes |
| Certificates | [v2/Certificates.md](v2/Certificates.md) | 5 | User Trusted, User Keychain, User Revoked |
| Containerization | [v2/Containerization.md](v2/Containerization.md) | 83 | Containers, Images, Registries, Volumes, Networks |
| Control Variables | [v2/Control-Variables.md](v2/Control-Variables.md) | 5 | Variables |
| Designer | [v2/Designer.md](v2/Designer.md) | 3 |  |
| Display | [v2/Display.md](v2/Display.md) | 1 |  |
| Email | [v2/Email.md](v2/Email.md) | 3 |  |
| Events | [v2/Events.md](v2/Events.md) | 49 | Recipients, Tasks, Bindings |
| Extensions | [v2/Extensions.md](v2/Extensions.md) | 1 |  |
| GFX | [v2/GFX.md](v2/GFX.md) | 18 | Programs, Configuration, Runtime |
| Hardware-IO | [v2/Hardware-IO.md](v2/Hardware-IO.md) | 10 | Module1 |
| History | [v2/History.md](v2/History.md) | 6 |  |
| IOT | [v2/IOT.md](v2/IOT.md) | 9 |  |
| Jobs | [v2/Jobs.md](v2/Jobs.md) | 8 |  |
| LED | [v2/LED.md](v2/LED.md) | 5 | Scenes |
| Licenses | [v2/Licenses.md](v2/Licenses.md) | 1 |  |
| Logging | [v2/Logging.md](v2/Logging.md) | 8 |  |
| Machine-Learning | [v2/Machine-Learning.md](v2/Machine-Learning.md) | 12 | Thermal Sensor |
| Modbus | [v2/Modbus.md](v2/Modbus.md) | 28 | Client, Server |
| Monitoring | [v2/Monitoring.md](v2/Monitoring.md) | 1 |  |
| MQTT | [v2/MQTT.md](v2/MQTT.md) | 9 | Connections |
| M-Bus | [v2/M-Bus.md](v2/M-Bus.md) | 1 |  |
| OpenADR | [v2/OpenADR.md](v2/OpenADR.md) | 1 |  |
| Packages | [v2/Packages.md](v2/Packages.md) | 19 | Download |
| Platform | [v2/Platform.md](v2/Platform.md) | 27 | Network, Debug, Miscellaneous, Monitoring, Security, Name, Time |
| Protector | [v2/Protector.md](v2/Protector.md) | 1 |  |
| Remote Tunneling | [v2/Remote-Tunneling.md](v2/Remote-Tunneling.md) | 1 |  |
| Schedules | [v2/Schedules.md](v2/Schedules.md) | 8 | Schedule 1 |
| Security (Users) | [v2/Security-Users.md](v2/Security-Users.md) | 20 | Users, Authorization, Authentication, Policies |
| Site | [v2/Site.md](v2/Site.md) | 62 | Site Element Examples, Site, Equipment |
| Subnet | [v2/Subnet.md](v2/Subnet.md) | 9 | Devices |
| UDMI | [v2/UDMI.md](v2/UDMI.md) | 1 |  |
| Weather | [v2/Weather.md](v2/Weather.md) | 4 | Locations, Providers |
| Web Server | [v2/Web-Server.md](v2/Web-Server.md) | 17 | Proxies, HTTPS |

## API V1 (54 requêtes)

| Domaine | Fichier | Requêtes | Sous-parties |
|---|---|---|---|
| Protocols | [v1/Protocols.md](v1/Protocols.md) | 54 | BACnet |
