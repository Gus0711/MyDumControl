# API V2 — Weather

Chemins relatifs à `https://<hôte>/api/rest/v2` sauf mention contraire. Auth : Basic. Voir [INDEX](../INDEX.md).

## Locations

#### List Locations
`GET /services/weather/locations`

#### Add Location
`POST /services/weather/locations/55953`

Corps :
```json
{
  "provider": "accuweather",
  "key": "55953"
}
```

#### Delete Location
`DELETE /services/weather/locations/55953`

## Weather

#### List Weather
`GET /services/weather`
