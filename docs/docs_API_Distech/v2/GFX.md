# API V2 — GFX

Chemins relatifs à `https://<hôte>/api/rest/v2` sauf mention contraire. Auth : Basic. Voir [INDEX](../INDEX.md).

## Programs

#### Download Binary Program-1
`POST /services/gfx/programs/1/download-binary`

#### Reset Persist Program-1
`POST /services/gfx/programs/1/reset-persistent-data`

#### Restart Program-1
`POST /services/gfx/programs/1/start`

#### Pause Program-1
`POST /services/gfx/programs/1/start`

#### Start Program-1
`POST /services/gfx/programs/1/start`

#### Run Program-1
`POST /services/gfx/programs/1/run`

#### Stop Program-1
`POST /services/gfx/programs/1/stop`

#### List Program-1
`GET /services/gfx/programs/1`

#### List Program
`GET /services/gfx/programs`

## Configuration

#### Add-Update-Network-Value
`POST /services/gfx/configuration/add-update-network-value`

Request to add or modify the paramters of a network value.

Corps :
```json
{
  "number": 1,
  "device-instance": 15002,
  "object-instance": 1,
  "configuration": {
    "local-desc": "test"
  }
}
```

#### List Configuration
`GET /services/gfx/configuration`

#### New Configuration
`POST /services/gfx/configuration/write`

Corps :
```json
{
  "key": "schedule-1",
  "path": "/services/bacnet/local/objects/schedules/1",
  "references": [
    {
      "url": "/services/bacnet/local/objects/schedules/1",
      "body": {}
    },
    {
      "url": "/services/gfx/runtime/objects/schedules/0",
      "body": {
        "path": "/services/bacnet/local/objects/schedules/1"
      }
    }
  ]
}
```

#### Configuration
`DELETE /services/gfx/configuration/schedule-1`

#### Overrides
`POST /services/gfx/configuration/get-overrides`

#### Clear Values
`POST /services/gfx/programs/clear-values`

## Runtime

#### List Runtime
`GET /services/gfx/runtime`

#### List Trends
`GET /services/gfx/runtime/objects/trend-logs`

## GFX

#### GFX
`GET /services/gfx`
