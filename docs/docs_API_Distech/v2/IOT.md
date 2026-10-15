# API V2 — IOT

Chemins relatifs à `https://<hôte>/api/rest/v2` sauf mention contraire. Auth : Basic. Voir [INDEX](../INDEX.md).

## IOT

#### List IOT-CR
`GET https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/iot`, `Host: {{cloudrelayHostname}}`

#### List IOT
`GET /services/iot`

#### Connections
`GET /services/iot/connections`

#### Create Connection
`POST /services/iot/connections/AZ-IOT-DCTS`

Corps :
```json
{
  "key": "AZ-IOT-DCTS",
  "heartbeat-interval": 120,
  "provider": "azure",
  "secret": "<masqué>",
  "enabled": true
}
```

#### Create Connection-CR
`POST https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/iot/connections/iot`, `Host: {{cloudrelayHostname}}`

Corps :
```json
{
  "key": "iot",
  "heartbeat-interval": 120,
  "provider": "azure",
  "secret": "<masqué>",
  "enabled": true
}
```

#### Create Connection2-CR
`POST https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/iot/connections/iot`, `Host: {{cloudrelayHostname}}`

Corps :
```json
{
  "key": "iot",
  "heartbeat-interval": 120,
  "provider": "azure",
  "secret": "<masqué>",
  "enabled": true
}
```

#### Modify Connection
`POST /services/iot/connections/AZ-IOT-DCTS`

Corps :
```json
{
  "heartbeat-enabled": true,
  "heartbeat-interval": 240
}
```

#### Delete Connection-CR
`DELETE https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/iot/connections/iot`, `Host: {{cloudrelayHostname}}`

#### Delete Connection
`DELETE /services/iot/connections/AZ-IOT-DCTS`
