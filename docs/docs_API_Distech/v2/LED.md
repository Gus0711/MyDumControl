# API V2 — LED

Chemins relatifs à `https://<hôte>/api/rest/v2` sauf mention contraire. Auth : Basic. Voir [INDEX](../INDEX.md).

## LED

#### LED
`GET /services/led`

#### Scenes
`GET /services/led/scenes`

#### Active Scene
`GET /services/led/active-scene`

#### Brightness
`GET /services/led/brightness`

#### Brightness
`POST /services/led/brightness`

Corps :
```json
{
  "value": 7
}
```
