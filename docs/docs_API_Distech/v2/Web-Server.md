# API V2 — Web Server

Chemins relatifs à `https://<hôte>/api/rest/v2` sauf mention contraire. Auth : Basic. Voir [INDEX](../INDEX.md).

## Proxies

#### Proxies
`GET /services/web-server/proxies`

#### Proxy-Netdata
`POST /services/web-server/proxies/netdata`

Corps :
```json
{
  "path": "/netdata",
  "proxy-url": "http://127.0.0.1:50099"
}
```

#### Proxy-Netdata Copy
`POST /services/web-server/proxies/netdata2`

Corps :
```json
{
  "path": "/netdata2",
  "proxy-url": "http://10.110.210.5:50099"
}
```

#### Proxy-NodeRed
`POST /services/web-server/proxies/nodered`

Corps :
```json
{
  "path": "/nodered",
  "proxy-url": "http://127.0.0.1:50081"
}
```

#### Proxy-NXPM-VAV71
`POST /services/web-server/proxies/vav71`

Corps :
```json
{
  "path": "/vav71",
  "proxy-url": "http://127.0.0.1:50300"
}
```

#### Proxy-NXPM-router
`POST /services/web-server/proxies/router`

Corps :
```json
{
  "path": "/router",
  "proxy-url": "http://127.0.0.1:50301"
}
```

#### Proxy-ECNet
`POST /services/web-server/proxies/ecnet`

Corps :
```json
{
  "path": "/ecnet",
  "proxy-url": "http://127.0.0.1:50180"
}
```

#### Proxy-Netdata
`DELETE /services/web-server/proxies/netdata`

#### Proxy-NodeRed
`DELETE /services/web-server/proxies/netdata`

#### Proxy-NXPM-VAV71
`DELETE /services/web-server/proxies/vav71`

#### Proxy-NXPM-router
`DELETE /services/web-server/proxies/router`

#### Proxy-ECNet
`DELETE /services/web-server/proxies/ecnet`

## HTTPS › mTLS

#### Mutual TLS
`GET /services/web-server/https/client-authentication-enabled`

#### Set Mutual TLS
`POST /services/web-server/https/client-authentication-enabled`

Corps :
```json
{
  "$value": false
}
```

## HTTPS

#### https
`GET /services/web-server/https`

#### https
`POST /services/web-server/https`

Corps :
```json
{
  "certificate": "ECLYPSE-A00499"
}
```

## Web Server

#### Web Server
`GET /services/web-server`
