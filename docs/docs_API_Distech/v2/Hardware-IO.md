# API V2 — Hardware-IO

Chemins relatifs à `https://<hôte>/api/rest/v2` sauf mention contraire. Auth : Basic. Voir [INDEX](../INDEX.md).

## Module1 › Outputs

#### List Outputs
`GET /services/hardware-io/modules/1/outputs`

#### Output-1 Read
`GET /services/hardware-io/modules/1/outputs/1`

## Module1 › Inputs › Input 1

#### Input-1 Read
`GET /services/hardware-io/modules/1/inputs/1`

#### Input-1 Write
`POST /services/hardware-io/modules/1/inputs/1`

Corps :
```json
{
  "key": "1",
  "signal-type": "Resistance",
  "signal-high-limit": 0.0,
  "default-value": 0,
  "thermistor-type": "",
  "signal-interpretation": "Disconnected",
  "offset": 1.0,
  "module": "1",
  "description": "test input",
  "signal-low-limit": 0.0,
  "units": "NoUnits",
  "out-of-service": false,
  "…": "8 autres clés (present-value, signal-offset, lookup-table, reliability-state, name…)"
}
```

#### Input 1 Write Options
`POST /services/hardware-io/modules/1/inputs/1/options`

Corps :
```json
{
  "reverse-action": true,
  "smooth-curve": false,
  "use-override": false,
  "check-signal-fault": false,
  "use-filter": true,
  "check-out-of-range": false
}
```

## Module1 › Inputs

#### List Inputs
`GET /services/hardware-io/modules/1/inputs`

## Module1

#### List Module
`GET /services/hardware-io/modules/1`

## Hardware-IO

#### List Hardware
`GET /services/hardware-io`

#### Add Module
`POST /services/hardware-io/modules`

Corps :
```json
{
  "configured": true,
  "version": "unknown",
  "configured-module-type-id": "30016cffff03010a",
  "name": "IO Module 2"
}
```

#### Module-2
`POST /services/hardware-io/modules/2`
