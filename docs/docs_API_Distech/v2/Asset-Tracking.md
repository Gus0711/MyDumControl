# API V2 — Asset-Tracking

Chemins relatifs à `https://<hôte>/api/rest/v2` sauf mention contraire. Auth : Basic. Voir [INDEX](../INDEX.md).

## Adapter

#### mg-pan-id
`POST /services/asset-tracking/adapter/mg-pan-id-command`

#### necyd-pan-id
`POST /services/asset-tracking/adapter/necyd-pan-id-command`

Corps :
```json
{
  "panId": 17185
}
```

## Edgar

#### locate-neighbors
`POST /services/asset-tracking/edgars/locate-neighbors`

Corps :
```json
{
  "edgar-id": 126,
  "egw-locat-count": 10
}
```

#### beaconing
`POST /services/asset-tracking/edgars/beaconing`

#### advertising
`POST /services/asset-tracking/edgars/advertising`

Corps :
```json
{
  "enable": false
}
```

#### BLE-filtering
`POST /services/asset-tracking/edgars/ble-filtering`

Corps :
```json
{
  "filtering": 0
}
```

#### Start-Firmware-Upgrade
`POST /services/asset-tracking/edgars/ble-filtering`

Corps :
```json
{
  "filtering": 0
}
```

#### edgars
`GET /services/asset-tracking/edgars`
