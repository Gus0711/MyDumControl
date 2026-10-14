# API V2 — Packages

Chemins relatifs à `https://<hôte>/api/rest/v2` sauf mention contraire. Auth : Basic. Voir [INDEX](../INDEX.md).

## Download

#### Download Package Zip
`POST /services/packages/download`

Corps :
```json
{
  "url": "https://portal.lxr-hosting.link/s/AGRQRJ9GDFn2x4R/download/ecy10_bundle.zip",
  "sync": false
}
```

#### Download Package dcar
`POST /services/packages/download`

Corps :
```json
{
  "url": "https://portal.dc8292.link/s/yCwWqHJeQpq2B9K/download/eclypse-bacnet-2.5.2+master.24325.1.dcar",
  "sync": false
}
```

#### Download Package dcar failed
`POST /services/packages/download`

Corps :
```json
{
  "url": "https://portal.dc8292.link/s/yCwWqHJeQp3332B9K/download/eclypse-bacnet-2.5.2+master.24325.2.dcar",
  "sync": false
}
```

#### Download Package dcar-CR
`POST https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/packages/download`, `Host: {{cloudrelayHostname}}`

Corps :
```json
{
  "url": "https://nx1.8292.io/public.php/dav/files/C6tMewX3ztpWsmq",
  "sync": false
}
```

## Packages

#### List Packages-CR
`GET https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/packages`, `Host: {{cloudrelayHostname}}`

#### List Packages-CR (Filtered)
`GET https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/packages?$select=*($select=*($select=display-name,status))`, `Host: {{cloudrelayHostname}}`

#### List Packages
`GET /services/packages`

#### List Packages (Filtered)
`GET /services/packages?$select=*($select=*($select=display-name,status))`

#### Upload Package
`POST /services/packages/store`

#### Upload Package-CR
`POST https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/packages/store`, `Host: {{cloudrelayHostname}}`

#### Commit-Install
`POST /services/packages/commit`

Corps :
```json
{
  "operations": [
    {
      "type": "Install",
      "item": "com.distech.dcaf.mqtt-2.0.0+22326.1"
    }
  ]
}
```

#### Commit-Install-CR
`POST https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/packages/commit`, `Host: {{cloudrelayHostname}}`

Corps :
```json
{
  "operations": [
    {
      "type": "Install",
      "item": "com.distech.dcaf.remotetunneling-2.8.4+25197.3"
    }
  ]
}
```

#### Validate - Uninstall-CR
`POST https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/packages/validate`, `Host: {{cloudrelayHostname}}`

Corps :
```json
{
  "operations": [
    {
      "type": "Uninstall",
      "item": "com.distech.dcaf.atrius-2.8.4+25198.1"
    }
  ]
}
```

#### Commit-Uninstall - CR
`POST https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Cache-Control: no-cache`, `Postman-Token: <calculated when request is sent>`, `Content-Length: <calculated when request is sent>`, `Host: <calculated when request is sent>`, `User-Agent: PostmanRuntime/7.39.1`, `Accept-Encoding: gzip, deflate, br`, `Connection: keep-alive`, `Remote-Query: {{basePath}}/services/packages/commit`

Corps :
```json
{
  "operations": [
    {
      "type": "Uninstall",
      "item": "com.distech.dcaf.atrius-2.8.4+25198.1"
    },
    {
      "type": "Clean",
      "item": "com.distech.dcaf.atrius-2.8.4+25198.1"
    }
  ]
}
```

#### Commit-Uninstall2 - CR
`POST https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Cache-Control: no-cache`, `Postman-Token: <calculated when request is sent>`, `Content-Length: <calculated when request is sent>`, `Host: <calculated when request is sent>`, `User-Agent: PostmanRuntime/7.39.1`, `Accept-Encoding: gzip, deflate, br`, `Connection: keep-alive`, `Remote-Query: {{basePath}}/services/packages/commit`

Corps :
```json
{
  "operations": [
    {
      "type": "Uninstall",
      "item": "com.distech.dcaf.remotetunneling-2.8.4+25197.3"
    },
    {
      "type": "Clean",
      "item": "com.distech.dcaf.remotetunneling-2.8.4+25197.3"
    }
  ]
}
```

#### Commit - Install All
`POST /services/packages/commit`

Corps :
```json
{
  "operations": [
    {
      "type": "Install",
      "item": "*"
    }
  ]
}
```

#### Commit - Uninstall
`POST /services/packages/commit`

Corps :
```json
{
  "operations": [
    {
      "type": "Uninstall",
      "item": "com.distech.dcaf.mqtt-2.0.0+22326.1"
    }
  ]
}
```

#### Commit - Cancel/Remove
`POST /services/packages/commit`

Corps :
```json
{
  "operations": [
    {
      "type": "Remove",
      "item": "com.distech.dcaf.mqtt-2.0.0+22326.1"
    }
  ]
}
```

#### Commit - Cancel/Remove All
`POST /services/packages/commit`

Corps :
```json
{
  "operations": [
    {
      "type": "Remove",
      "item": "*"
    }
  ]
}
```
