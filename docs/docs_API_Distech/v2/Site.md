# API V2 — Site

Chemins relatifs à `https://<hôte>/api/rest/v2` sauf mention contraire. Auth : Basic. Voir [INDEX](../INDEX.md).

## Site Element Examples › Buildings › Building Example › Building - Dashboard

#### Create Buildings - Building-Dashboard
`POST /services/site/buildings/Building/dashboards/Building_Summary`

Corps :
```json
{
  "key": "Building_Summary",
  "display": "Default"
}
```

#### List Buildings - Building-Dashboard
`GET /services/site/buildings/Building/dashboards`

#### Delete Buildings - Building-Dashboard
`DELETE /services/site/buildings/Building/dashboards/Building_Summary`

## Site Element Examples › Buildings › Building Example › Building - Equipment › Equipment - Dashboard

#### Create Buildings/Equipment/Dashboard - WaterMeter
`POST /services/site/buildings/Building/equipment/WaterMeter/dashboards/WaterMeter`

Corps :
```json
{
  "key": "WaterMeter",
  "subtype": "Meter",
  "serves": "Building",
  "description": "Building_Energy_Meters",
  "type": "Meter:Building_Meter:Building_Water_Meter",
  "order": 7
}
```

#### List Buildings/Equipment/Dashboard - WaterMeter
`GET /services/site/buildings/Building/equipment/WaterMeter/dashboards`

#### Delete Buildings/Equipment/Dashboard - WaterMeter
`DELETE /services/site/buildings/Building/equipment/WaterMeter/dashboards/WaterMeter`

## Site Element Examples › Buildings › Building Example › Building - Equipment › Equipment - Device Link

#### Create Buildings/Equipment/Devices - 1200
`POST /services/site/buildings/Building/equipment/WaterMeter/devices/1200`

Corps :
```json
{
  "path": "/services/bacnet/remote/devices/1200"
}
```

#### List Buildings/Equipment/Devices - 1200
`GET /services/site/buildings/Building/equipment/WaterMeter/devices/1200`

#### Delete Buildings/Equipment/Devices - 1200
`DELETE /services/site/buildings/Building/equipment/WaterMeter/devices/1200`

## Site Element Examples › Buildings › Building Example › Building - Equipment › Equipment - Point Link

#### Create Buildings/Equipment/Points - Gal
`POST /services/site/buildings/Building/equipment/WaterMeter/points/Gal`

Corps :
```json
{
  "reference": "/services/bacnet/remote/devices/1200/objects/analog-values/2",
  "instance-number": 2,
  "object-identifier": {
    "$value": "analog-value 2",
    "object-instance": 2,
    "object-type": "analog-value"
  },
  "local-name": "Gal"
}
```

#### List Buildings/Equipment/Points - Gal
`GET /services/site/buildings/Building/equipment/WaterMeter/points`

#### Delete Buildings/Equipment/Points - Gal
`DELETE /services/site/buildings/Building/equipment/WaterMeter/points/Gal`

## Site Element Examples › Buildings › Building Example › Building - Equipment

#### Create Buildings/Equipment - WaterMeter
`POST /services/site/buildings/Building/equipment/WaterMeter`

Corps :
```json
{
  "key": "WaterMeter",
  "subtype": "Meter",
  "serves": "Building",
  "description": "Building_Energy_Meters",
  "type": "Meter:Building_Meter:Building_Water_Meter",
  "order": 7
}
```

#### List Buildings/Equipment - WaterMeter
`GET /services/site/buildings/Building/equipment/WaterMeter`

#### Delete Buildings/Equipment - WaterMeter
`DELETE /services/site/buildings/Building/equipment/WaterMeter`

## Site Element Examples › Buildings › Building Example

#### Create Buildings - Building
`POST /services/site/buildings/Building`

Corps :
```json
{
  "key": "building",
  "use-type": "Office",
  "area": 4000,
  "address": "Parkland County, AB",
  "underground-floors": 0,
  "equipment": {},
  "description": "Building",
  "dashboards": {},
  "floor-display-method": "US/Canada",
  "above-ground-floors": 0,
  "year-built": 2023
}
```

#### List Buildings - Building
`GET /services/site/buildings/Building`

#### Delete Buildings - Building
`DELETE /services/site/buildings/Building`

## Site Element Examples › Buildings

#### Buildings
`GET /services/site/buildings`

## Site Element Examples › Floors › Floor Example › Floor - Dashboard

#### Create Floors - 1st-Dashboard
`POST /services/site/buildings/Building/floors/1st/dashboards/First_Floor`

Corps :
```json
{
  "key": "First_Floor",
  "display": "Default"
}
```

#### List Floors - 1st-Dashboard
`GET /services/site/buildings/Building/floors/1st/dashboards`

#### Delete Floors - 1st-Dashboard
`DELETE /services/site/buildings/Building/floors/1st/dashboards/First_Floor`

## Site Element Examples › Floors › Floor Example › Floor - Equipment › Equipment - Dashboard

#### Create Floors/Equipment/Dashboard - AHU-1
`POST /services/site/buildings/Building/floors/1st/equipment/AHU-1/dashboards/VAV_AHU_G36`

Corps :
```json
{
  "key": "VAV_AHU_G36",
  "display": "Default"
}
```

#### List Floors/Equipment/Dashboard - AHU-1
`GET /services/site/buildings/Building/floors/1st/equipment/AHU-1/dashboards`

#### Delete Floors/Equipment/Dashboard - AHU-1
`DELETE /services/site/buildings/Building/floors/1st/equipment/AHU-1/dashboards/VAV_AHU_G36`

## Site Element Examples › Floors › Floor Example › Floor - Equipment › Equipment - Device Link

#### Create Floors/Equipment/Devices - 1000
`POST /services/site/buildings/Building/floors/1st/equipment/AHU-1/devices/1000`

Corps :
```json
{
  "path": "/services/bacnet/remote/devices/1000"
}
```

#### List Floors/Equipment/Devices - 1000
`GET /services/site/buildings/Building/floors/1st/equipment/AHU-1/devices/1000`

#### Delete Floors/Equipment/Devices - 1000
`DELETE /services/site/buildings/Building/floors/1st/equipment/AHU-1/devices/1000`

## Site Element Examples › Floors › Floor Example › Floor - Equipment › Equipment - Point Link

#### Create Floors/Equipment/Points - MaxDischAirTempSP
`POST /services/site/buildings/Building/floors/1st/equipment/AHU-1/points/MaxDischAirTempSP`

Corps :
```json
{
  "reference": "/services/bacnet/remote/devices/1000/objects/analog-values/251",
  "instance-number": 251,
  "object-identifier": {
    "$value": "analog-value 2",
    "object-instance": 2,
    "object-type": "analog-value"
  },
  "local-name": "Gal"
}
```

#### List Floors/Equipment/Points - MaxDischAirTempSP
`GET /services/site/buildings/Building/floors/1st/equipment/AHU-1/points/MaxDischAirTempSP`

#### Delete Floors/Equipment/Points - MaxDischAirTempSP
`DELETE /services/site/buildings/Building/floors/1st/equipment/AHU-1/points/MaxDischAirTempSP`

## Site Element Examples › Floors › Floor Example › Floor - Equipment

#### Create Floors/Equipment - AHU-1
`POST /services/site/buildings/Building/floors/1st/equipment/AHU-1`

Corps :
```json
{
  "subtype": "VAV AHU",
  "serves": "Multi",
  "description": "G36 AHU",
  "type": "HVAC_Equipment:Air_Handling_Unit",
  "order": 0
}
```

#### List Floors/Equipment - AHU-1
`GET /services/site/buildings/Building/floors/1st/equipment/AHU-1`

#### Delete Floors/Equipment - AHU-1
`DELETE /services/site/buildings/Building/floors/1st/equipment/AHU-1`

## Site Element Examples › Floors › Floor Example

#### Create Floors - 1st
`POST /services/site/buildings/Building/floors/1st`

Corps :
```json
{
  "area": 1000,
  "level-number": 0,
  "description": "First Floor",
  "dashboards": {
    "Second_Floor": {
      "key": "First_Floor",
      "display": "Default"
    }
  }
}
```

#### List Floors - 1st
`GET /services/site/buildings/Building/floors/1st`

#### Delete Floors - 1st
`DELETE /services/site/buildings/Building/floors/1st`

## Site Element Examples › Spaces › Space Example › Space - Dashboard

#### Create Spaces - Room-101-Dashboard
`POST /services/site/buildings/Building/floors/1st/spaces/Room-101/dashboards/Room`

Corps :
```json
{
  "key": "First_Floor",
  "display": "Default"
}
```

#### List Spaces - Room-101-Dashboard
`GET /services/site/buildings/Building/floors/1st/spaces/Room-101/dashboards/Room`

#### Delete Spaces - Room-101-Dashboard
`DELETE /services/site/buildings/Building/floors/1st/spaces/Room-101/dashboards/Room`

## Site Element Examples › Spaces › Space Example › Space - Equipment › Equipment - Dashboard

#### Create Spaces/Equipment/Dashboard - VAV_G36
`POST /services/site/buildings/Building/floors/1st/spaces/Room-101/equipment/VAV/dashboards/VAV_G36`

Corps :
```json
{
  "key": "VAV_AHU_G36",
  "display": "Default"
}
```

#### List Spaces/Equipment/Dashboard - VAV_G36
`GET /services/site/buildings/Building/floors/1st/spaces/Room-101/equipment/VAV/dashboards/VAV_G36`

#### Delete Spaces/Equipment/Dashboard - VAV_G36
`DELETE /services/site/buildings/Building/floors/1st/spaces/Room-101/equipment/VAV/dashboards/VAV_G36`

## Site Element Examples › Spaces › Space Example › Space - Equipment › Equipment - Device Link

#### Create Spaces/Equipment/Devices - 1001
`POST /services/site/buildings/Building/floors/1st/spaces/Room-101/equipment/VAV/devices/1001`

Corps :
```json
{
  "path": "/services/bacnet/remote/devices/1001"
}
```

#### List Spaces/Equipment/Devices - 1001
`GET /services/site/buildings/Building/floors/1st/spaces/Room-101/equipment/VAV/devices/1001`

#### DeleteSpaces/Equipment/Devices - 1001
`DELETE /services/site/buildings/Building/floors/1st/spaces/Room-101/equipment/VAV/devices/1001`

## Site Element Examples › Spaces › Space Example › Space - Equipment › Equipment - Point Link

#### Create Spaces/Equipment/Points - MaxDischAirTempSP
`POST /services/site/buildings/Building/floors/1st/spaces/Room-101/equipment/VAV/points/MaxDischAirTempSP`

Corps :
```json
{
  "reference": "/services/bacnet/remote/devices/1000/objects/analog-values/251",
  "instance-number": 251,
  "object-identifier": {
    "$value": "analog-value 2",
    "object-instance": 2,
    "object-type": "analog-value"
  },
  "local-name": "Gal"
}
```

#### List Spaces/Equipment/Points - MaxDischAirTempSP
`GET /services/site/buildings/Building/floors/1st/spaces/Room-101/equipment/VAV/points/MaxDischAirTempSP`

#### Delete Spaces/Equipment/Points - MaxDischAirTempSP
`DELETE /services/site/buildings/Building/floors/1st/spaces/Room-101/equipment/VAV/points/MaxDischAirTempSP`

## Site Element Examples › Spaces › Space Example › Space - Equipment

#### Create Spaces/Equipment - VAV
`POST /services/site/buildings/Building/floors/1st/spaces/Room-101/equipment/VAV`

Corps :
```json
{
  "subtype": "VAV AHU",
  "serves": "Multi",
  "description": "G36 AHU",
  "type": "HVAC_Equipment:Air_Handling_Unit",
  "order": 0
}
```

#### List Spaces/Equipment - VAV
`GET /services/site/buildings/Building/floors/1st/spaces/Room-101/equipment/VAV`

#### Delete Space/Equipment - VAV
`DELETE /services/site/buildings/Building/floors/1st/spaces/Room-101/equipment/VAV`

## Site Element Examples › Spaces › Space Example

#### Create Spaces - Room-101
`POST /services/site/buildings/Building/floors/1st/spaces/Room-101`

Corps :
```json
{
  "area": 1000,
  "level-number": 0,
  "description": "First Floor",
  "dashboards": {
    "Second_Floor": {
      "key": "First_Floor",
      "display": "Default"
    }
  }
}
```

#### List Spaces - Room-101
`GET /services/site/buildings/Building/floors/1st/spaces/Room-101`

#### Delete Spaces - Room-101
`DELETE /services/site/buildings/Building/floors/1st/spaces/Room-101`

## Site

#### List Site
`GET /services/site`

#### Create Site
`POST /services/site/buildings`

Corps :
```json
{
  "address": null,
  "buildings": {
    "Multizone Office Simple Air": {
      "key": "Multizone Office Simple Air",
      "use-type": "Office",
      "area": 17896,
      "address": null,
      "underground-floors": 0,
      "equipment": {
        "Weather Station": {
          "key": "Weather Station",
          "devices": {
            "Local": "…"
          },
          "subtype": null,
          "serves": null,
          "description": null,
          "type": null,
          "dashboards": {
            "Weather Data": "…"
          },
          "points": {
            "Black Body Sky Temperature": "…",
            "Wind Direction": "…",
            "Solar Declination Angle": "…",
            "Day with units of Seconds": "…",
            "Global Horizontal Solar Irradiation": "…",
            "Outside Air Wetbulb": "…",
            "Solar Hour Angle": "…",
            "Opaque Sky Cover": "…",
            "Horizontal Infrared Irradiation": "…",
            "Solar Zenith Angle": "…",
            "Outside Air Relative Humidity": "…",
            "Solar Altitude Angle": "…",
            "…": "11 autres clés (Solar Time, Longitude, Atmospheric Pressure, Direct Normal Radiation, Latitude…)"
          },
          "order": 0
        }
      },
      "description": "Floor of an Office in Chicago",
      "dashboards": {
        "Building_Summary": {
          "key": "Building_Summary",
          "display": "Normal"
        }
      },
      "floor-display-method": "US/Canada",
      "above-ground-floors": 0,
      "floors": {
        "Mechanical Floor": {
          "key": "Mechanical Floor",
          "area": null,
          "level-number": 0,
          "schedules": {},
          "spaces": {},
          "equipment": {
            "Chiller": "…",
            "Heat Pump": "…",
            "AHU": "…"
          },
          "description": null,
          "dashboards": {},
          "order": 2
        },
        "First Floor": {
          "key": "First Floor",
          "area": null,
          "level-number": 0,
          "schedules": {},
          "spaces": {},
          "equipment": {
            "West VAV": "…",
            "Corridor VAV": "…",
            "East VAV": "…",
            "North VAV": "…",
            "South VAV": "…"
          },
          "description": null,
          "dashboards": {
            "First Floor": "…"
          },
          "order": 1
        }
      },
      "include-rooftop": false,
      "…": "3 autres clés (schedules, year-built, order…)"
    }
  },
  "schedules": {},
  "name": "BOP Test Framework",
  "equipment": {},
  "description": "Building Optimization Testing Framework",
  "type": "Site",
  "dashboards": {}
}
```

#### Create Site Distech_Controls
`POST /services/site/buildings/Distech_Controls`

Corps :
```json
{
  "use-type": "Office"
}
```

## Equipment

#### List Equipment
`GET /services/site/equipment`

#### Create Equipment
`POST /services/site/equipment/test2`

Corps :
```json
{
  "key": "test2",
  "devices": {},
  "subtype": "",
  "serves": "test-room",
  "description": "test2",
  "type": null,
  "dashboards": {},
  "points": {},
  "order": null
}
```

#### Create Equipment - qsys
`POST /services/site/equipment/qsys`

Corps :
```json
{
  "key": "qsys",
  "devices": {},
  "subtype": "",
  "serves": "qsys-integration",
  "description": "qsys-server",
  "type": null,
  "dashboards": {},
  "points": {},
  "order": null
}
```

#### Delete Equipment
`DELETE /services/site/equipment/test2`
