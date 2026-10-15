# API V2 — Control Variables

Chemins relatifs à `https://<hôte>/api/rest/v2` sauf mention contraire. Auth : Basic. Voir [INDEX](../INDEX.md).

## Variables › Numeric

#### Read Numeric
`GET /services/control/variables/numeric`

#### Create Numeric
`POST /services/control/variables/numeric/MyTest`

Corps :
```json
{
  "key": "MyTest",
  "description": "",
  "units": "NoUnits",
  "persist": false,
  "type": "Numeric",
  "present-value": 0.0
}
```

#### Read Numeric - MyTest
`GET /services/control/variables/numeric/MyTest`

#### Delete Numeric - MyTest
`DELETE /services/control/variables/numeric/MyTest`

## Variables

#### List Variables
`GET /services/control/variables`
