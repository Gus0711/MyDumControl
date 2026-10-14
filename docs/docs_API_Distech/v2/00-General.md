# API V2 — Général

Chemins relatifs à `https://<hôte>/api/rest/v2` sauf mention contraire. Auth : Basic. Voir [INDEX](../INDEX.md). Authentification, version, requêtes groupées (batch) et exemples de `$select` / filtres.

## Authentication

#### Token
`POST https://<hôte>/auth/local/token`

#### OAuth (InDev)
`POST https://<hôte>/auth/oauth2/register`

Corps :
```json
{
  "token_endpoint_auth_signing_alg": "RS256",
  "post_logout_redirect_uris": [
    "https://ECLYPSE-A001B6-test/logout"
  ],
  "grant_types": [
    "authorization_code"
  ],
  "redirect_uris": [
    "https://ECLYPSE-A001B6-test/auth/oidc/callback"
  ],
  "client_name": "ECYAPEX-D76F6FFC-9611-533F-8BF4-249372C3564H",
  "token_endpoint_auth_method": "client_secret_basic",
  "response_types": [
    "code"
  ]
}
```

## Batch Examples

#### List Objects
`POST /batch`

Corps :
```json
{
  "requests": [
    {
      "id": "1",
      "url": "/api/rest/v2/services/bacnet/local/objects?$select=analog-values($select=*($select=object-name,present-value))"
    },
    {
      "id": "2",
      "method": "GET",
      "url": "/api/rest/v2/services/bacnet/local/objects/analog-values/1/object-name"
    },
    {
      "id": "3",
      "url": "/api/rest/v2/services/bacnet/local/objects/analog-values/3/present-value"
    },
    "… 1 autres éléments"
  ]
}
```

#### ECY Hub Call
`POST /batch`

This is the filtered batch call used to gather the data from a ECY2 device in the ECY Hub backend. It contains multiple examples of using layered filters. The ECY Hub only cares about specific data so its not necessary to include all of the data from each endpoint.

Corps :
```json
{
  "requests": [
    {
      "id": "Local BACNet Data",
      "url": "/api/rest/v2/services/bacnet/local/objects/devices?$select=*…(291 caractères)"
    },
    {
      "id": "Local GFX Network Values",
      "method": "GET",
      "url": "/api/rest/v2/services/gfx/configuration?$select=network*"
    },
    {
      "id": "Remote BACnet Data",
      "url": "/api/rest/v2/services/bacnet/remote/devices?$select=*($selec…(250 caractères)"
    },
    "… 11 autres éléments"
  ]
}
```

#### Misc Example1
`POST /batch`

Corps :
```json
{
  "requests": [
    {
      "id": "1",
      "url": "/api/rest/v2/services/bacnet/local/objects?$select=analog-values($select=*($select=object-name,present-value))"
    },
    {
      "id": "2",
      "method": "GET",
      "url": "/api/rest/v2/services/bacnet/remote/devices/45071/objects?$select=*($select=*($select=name,default-value,present-value,policy-name,status($select=$value)))"
    },
    {
      "id": "3",
      "url": "/api/rest/v2/services/platform"
    },
    "… 1 autres éléments"
  ]
}
```

## Query Parameters

#### BACnet AVs
`GET /services/bacnet/local/objects?$select=analog-values($select=*($select=object-name,present-value))`

#### BACnet AV-BV
`GET /services/bacnet/local/objects?$select=analog-values($select=*($select=object-name,present-value))&$select=binary-values($select=*($select=object-name,present-value))`

#### BACnet BVs
`GET /services/bacnet/local/objects?$select=binary-values($select=*($select=object-name,present-value))`

#### BACnet Objects
`GET /services/bacnet/local/objects?$select=*($select=*($select=object-name,present-value))`

#### BACnet Remote Objects Example1
`GET /services/bacnet/remote/devices/101/objects?$select=*($select=*($select=name,default-value,present-value,policy-name,status($select=$value)))`

#### BACnet Remote Objects Example2
`GET /services/bacnet/remote/devices?$select=45071($select=objects($select=analog-inputs($select=*($select=present-value))))`

#### BACnet Remote Objects Example3
`GET /services/bacnet/remote/devices?$select=45071($select=objects($select=analog-inputs($select=*($select=present-value))))&$select=45064($select=objects($select=analog-inputs($select=*($select=present-value))))`

#### BACnet Remote Objects Example4
`GET /services/bacnet/remote/devices?$select=45071($select=objects($select=analog-values($select=*($select=present-value))))&$select=45064($select=objects($select=analog-values($select=*($select=present-value))))`

#### Site Values
`GET /services/site?$select=buildings($select=*($select=floors($select=*($select=equipment($select=*($select=points($select=*($select=key,present-value,units))))))))`

#### Packages
`GET /services/packages?$select=*($select=*($select=display-name,status))`

#### Containers
`GET /services/containerization/containers?$select=*($select=state)`

## Filters

#### BACnet AVs
`GET /services/bacnet/local/objects?$select=analog-values($select=*($select=object-name,present-value))`

#### BACnet AV-BV-MSV
`GET /services/bacnet/local/objects?$select=analog-values($select=*($select=object-name,present-value))&$select=binary-values($select=*($select=object-name,present-value))&$select=multi-state-values($select=*($select=object-name,present-value))`

#### BACnet Remote AV-BV-MSV
`GET /services/bacnet/remote/devices/300072?$select=objects($select=analog-values($select=*($select=object-name,present-value))&$select=objects($select=binary-values($select=*($select=object-name,present-value))&$select=objects($select=multi-state-values($select=*($select=object-name,present-value))&=`

#### BACnet BVs
`GET /services/bacnet/local/objects?$select=binary-values($select=*($select=object-name,present-value))`

#### BACnet Objects
`GET /services/bacnet/local/objects?$select=*($select=*($select=object-name,present-value))`

#### BACnet Objects Remote Persisted
`GET /services/bacnet/remote/devices/300072?$select=objects($select=*($select=*($select=present-value,persisted)))`

#### BACnet Objects Remote Persisted (Preferred)
`GET /services/bacnet/remote/devices/300072?$select=objects($select=analog-values($select=*($select=present-value,persisted)))&$select=objects($select=binary-values($select=*($select=present-value,persisted)))&$select=objects($select=multi-state-values($select=*($select=present-value,persisted)))`

#### BACnet Remote Objects Example1
`GET /services/bacnet/remote/devices/222002/objects?$select=*($select=*($select=name,default-value,present-value,policy-name,status($select=$value)))`

#### BACnet Remote Objects Example2
`GET /services/bacnet/remote/devices?$select=222002($select=objects($select=analog-inputs($select=*($select=present-value))))`

#### BACnet Remote Objects Example3
`GET /services/bacnet/remote/devices?$select=22202($select=objects($select=analog-inputs($select=*($select=present-value))))&$select=45064($select=objects($select=analog-inputs($select=*($select=present-value))))`

#### BACnet Remote Objects Example4
`GET /services/bacnet/remote/devices?$select=45071($select=objects($select=analog-values($select=*($select=present-value))))&$select=45064($select=objects($select=analog-values($select=*($select=present-value))))`

#### Site Values
`GET /services/site?$select=buildings($select=*($select=floors($select=*($select=equipment($select=*($select=points($select=*($select=key,present-value,units))))))))`

#### Packages
`GET /services/packages?$select=*($select=*($select=display-name,status))`

#### Containers
`GET /services/containerization/containers?$select=*($select=state)`

## Général

#### API Version
`GET https://<hôte>/api/rest`

#### Services-CR
`GET https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services`, `Host: {{cloudrelayHostname}}`

#### Services
`GET /services`

#### Filter-Call-Example
`GET /services/bacnet/remote/devices?$*select=($select=object-name,object-identifier,connection-status,objects($select=binary-values($select=($select=present-value,status($select=$value))),binary-inputs($select=($select=present-value,status($select=$value))),binary-outputs($select=($select=present-value,status($select=$value))),analog-inputs($select=($select=present-value,status($select=$value))),analog-outputs($select=($select=present-value,status($select=$value))),analog-values($select=($select=present-value,status($select=$value))),multi-state-values($select=($select=state-text,present-value,status($select=$value))),multi-state-inputs($select=*($select=state-text,present-value,status($select=$value)))))`

En-têtes : `Cache-Control: no-cache`, `Postman-Token: <calculated when request is sent>`, `Host: <calculated when request is sent>`, `User-Agent: PostmanRuntime/7.39.1`, `Accept-Encoding: gzip, deflate, br`, `Connection: keep-alive`
