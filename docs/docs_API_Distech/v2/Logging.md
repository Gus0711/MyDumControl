# API V2 — Logging

Chemins relatifs à `https://<hôte>/api/rest/v2` sauf mention contraire. Auth : Basic. Voir [INDEX](../INDEX.md).

## Logging

#### Logging
`GET /services/logging`

#### List Logs
`GET /services/logging/logs`

#### List Logs-CR
`GET https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/logging/logs`, `Host: {{cloudrelayHostname}}`

#### Logs - specific
`GET /services/logging/store/eclypse_2025-08-09_071550.log`

#### Logs - karaf
`GET /services/logging/store/karaf.log`

#### Logs - Karaf-CR
`GET https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/logging/store/karaf.log`, `Host: {{cloudrelayHostname}}`

#### Logs - karaf (time)
`GET /services/logging/store/karaf.log?v=1677861701930`

#### Logs - OS
`GET /services/logging/store/os.log`
