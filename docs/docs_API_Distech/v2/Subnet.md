# API V2 — Subnet

Chemins relatifs à `https://<hôte>/api/rest/v2` sauf mention contraire. Auth : Basic. Voir [INDEX](../INDEX.md).

## Devices › Smartvue

#### List Smartvue
`GET /services/subnet/devices/smartvue`

## Devices › light-sunblind › Modules

#### List Modules
`GET /services/subnet/devices/light-sunblind/modules`

#### List Module 1 Inputs
`GET /services/subnet/devices/light-sunblind/modules/1/inputs`

#### List Module 1 control-gears
`GET /services/subnet/devices/light-sunblind/modules/1/control-gears`

#### List Module 1 outputs
`GET /services/subnet/devices/light-sunblind/modules/1/output`

## Devices › light-sunblind

#### List Light-Sunblind
`GET /services/subnet/devices/light-sunblind`

#### Discover Modules
`POST /services/subnet/devices/light-sunblind/discover`

Corps :
```json
{
  "module": "ECx module address",
  "discover-type": ""
}
```

## Subnet

#### Subnet
`GET /services/subnet`

#### Devices
`GET /services/subnet/devices`
