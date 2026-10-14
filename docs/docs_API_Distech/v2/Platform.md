# API V2 — Platform

Chemins relatifs à `https://<hôte>/api/rest/v2` sauf mention contraire. Auth : Basic. Voir [INDEX](../INDEX.md).

## Network › Interfaces › Primary

#### List Primary
`GET /services/platform/network/interfaces/primary`

#### Set Primary - ipv4-static
`POST /services/platform/network/interfaces/primary`

Corps :
```json
{
  "ipv4": {
    "ip-address": "10.110.210.62",
    "system": {
      "routes": []
    },
    "dns-primary": "10.110.210.1",
    "manual": {
      "routes": []
    },
    "dhcp-enabled": false,
    "dns-secondary": "",
    "enabled": true,
    "gateway": "10.110.210.1",
    "subnet-prefix-length": 24
  },
  "ipv6": {
    "system": {
      "routes": [],
      "gateways": [],
      "dns": [],
      "ip-addresses": []
    },
    "addressing-method": "Automatic",
    "manual": {
      "routes": [],
      "gateways": [],
      "dns": [],
      "ip-addresses": []
    },
    "enabled": false
  },
  "enabled": true
}
```

#### Set Primary - ipv4-dhcp
`POST /services/platform/network/interfaces/primary`

Corps :
```json
{
  "ipv4": {
    "dhcp-enabled": true,
    "enabled": true
  },
  "ipv6": {
    "system": {
      "routes": [],
      "gateways": [],
      "dns": [],
      "ip-addresses": []
    },
    "addressing-method": "Automatic",
    "manual": {
      "routes": [],
      "gateways": [],
      "dns": [],
      "ip-addresses": []
    },
    "enabled": false
  },
  "enabled": true
}
```

## Network › Interfaces › Secondary

#### List Secondary
`GET /services/platform/network/interfaces/secondary`

#### Set Secondary - ipv4-static
`POST /services/platform/network/interfaces/secondary`

Corps :
```json
{
  "ipv4": {
    "ip-address": "192.168.100.2",
    "system": {
      "routes": []
    },
    "dns-primary": null,
    "manual": {
      "routes": []
    },
    "dhcp-enabled": false,
    "dns-secondary": null,
    "enabled": true,
    "gateway": null,
    "subnet-prefix-length": 24
  },
  "ipv6": {
    "system": {
      "routes": [],
      "gateways": [],
      "dns": [],
      "ip-addresses": []
    },
    "addressing-method": "Automatic",
    "manual": {
      "routes": [],
      "gateways": [],
      "dns": [],
      "ip-addresses": []
    },
    "enabled": false
  },
  "enabled": true
}
```

#### Set Secondary - ipv4-dhcp
`POST /services/platform/network/interfaces/secondary`

Corps :
```json
{
  "ipv4": {
    "dhcp-enabled": true,
    "enabled": true
  },
  "ipv6": {
    "system": {
      "routes": [],
      "gateways": [],
      "dns": [],
      "ip-addresses": []
    },
    "addressing-method": "Automatic",
    "manual": {
      "routes": [],
      "gateways": [],
      "dns": [],
      "ip-addresses": []
    },
    "enabled": false
  },
  "enabled": true
}
```

## Network › Interfaces › Wireless

#### List Wireless
`GET /services/platform/network/interfaces/wireless`

#### List Wireless Copy
`GET /services/platform/network/interfaces/wireless/scan`

#### Create Hotspot
`POST /services/platform/network/interfaces/wireless`

Corps :
```json
{
  "key": "wireless",
  "standard": "N",
  "mac-address": null,
  "channel": "6",
  "ssid": "r200-jax-apex61",
  "enabled": true,
  "mode": "Hotspot",
  "password": "<masqué>",
  "encryption": "Wpa2",
  "ipv4": {
    "ip-address": "192.168.0.1",
    "range-start": "192.168.0.100",
    "range-end": "192.168.0.199",
    "enabled": true,
    "subnet-prefix-length": 24
  },
  "ssid-hidden": false,
  "share-network-connection-from": "disabled"
}
```

#### Create Hotspot (shared)
`POST /services/platform/network/interfaces/wireless`

Corps :
```json
{
  "key": "wireless",
  "standard": "N",
  "mac-address": null,
  "channel": "6",
  "ssid": "r200-jax-apex61",
  "enabled": true,
  "mode": "Hotspot",
  "password": "<masqué>",
  "encryption": "Wpa2",
  "ipv4": {
    "ip-address": "192.168.0.1",
    "range-start": "192.168.0.100",
    "range-end": "192.168.0.199",
    "enabled": true,
    "subnet-prefix-length": 24
  },
  "ssid-hidden": false,
  "share-network-connection-from": "bridge"
}
```

#### Create Access Point
`POST /services/platform/network/interfaces/wireless`

Corps :
```json
{
  "key": "wireless",
  "mode": "AccessPoint",
  "standard": "N",
  "password": "<masqué>",
  "encryption": "Wpa2",
  "ssid-hidden": false,
  "channel": "6",
  "ssid": "r200-jax-apex61",
  "enabled": true
}
```

#### Create Client (Static)
`POST /services/platform/network/interfaces/wireless`

Corps :
```json
{
  "key": "wireless",
  "mode": "Client",
  "password": "<masqué>",
  "ipv4": {
    "ip-address": "192.168.5.5",
    "dns-primary": "192.168.5.1",
    "dhcp-enabled": false,
    "dns-secondary": "",
    "enabled": true,
    "gateway": "192.168.5.1",
    "subnet-prefix-length": 24
  },
  "encryption": "Wpa2",
  "ssid-hidden": false,
  "ssid": "r200-jax-apex61",
  "enabled": true
}
```

#### Disable Wireless
`POST /services/platform/network/interfaces/wireless`

Corps :
```json
{
  "enabled": false
}
```

#### Enable Wireless
`POST /services/platform/network/interfaces/wireless`

Corps :
```json
{
  "enabled": true
}
```

## Network › Interfaces › Bridge

#### List Bridge
`GET /services/platform/network/interfaces/bridge`

#### Set Bridge - ipv4-static
`POST /services/platform/network/interfaces/bridge`

Corps :
```json
{
  "ipv4": {
    "ip-address": "10.110.210.66",
    "system": {
      "routes": []
    },
    "dns-primary": "10.110.210.1",
    "manual": {
      "routes": []
    },
    "dhcp-enabled": false,
    "dns-secondary": "",
    "enabled": true,
    "gateway": "10.110.210.1",
    "subnet-prefix-length": 24
  },
  "ipv6": {
    "system": {
      "routes": [],
      "gateways": [],
      "dns": [],
      "ip-addresses": []
    },
    "addressing-method": "Automatic",
    "manual": {
      "routes": [],
      "gateways": [],
      "dns": [],
      "ip-addresses": []
    },
    "enabled": false
  },
  "enabled": true
}
```

## Network › Interfaces

#### List Interfaces
`GET /services/platform/network/interfaces`

## Network

#### List Network
`GET /services/platform/network`

#### List Network-Hostname
`GET /services/platform/network/hostname`

#### Set Network-Hostname
`POST /services/platform/network/hostname`

Corps :
```json
{
  "$value": "r200-jax-apex61"
}
```

#### Connected-to-Internet
`GET /services/platform/network/connected-to-internet`

## Time

#### List Platform Time
`GET /services/platform/time`

#### List Platform Time (DateTime)
`GET /services/platform/time/date-time`

## Platform

#### List Platform
`GET /services/platform`

#### List Host-ID
`GET /services/platform/host-id`

#### Reboot Controller-CR
`POST https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/platform/reboot`, `Host: {{cloudrelayHostname}}`

#### Reboot Controller
`POST /services/platform/reboot`
