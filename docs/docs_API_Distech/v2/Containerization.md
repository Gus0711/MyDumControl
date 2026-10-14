# API V2 — Containerization

Chemins relatifs à `https://<hôte>/api/rest/v2` sauf mention contraire. Auth : Basic. Voir [INDEX](../INDEX.md).

## Containers › NodeRED

#### Create - NodeRED
`POST /services/containerization/containers/create-container`

Corps :
```json
{
  "name": "nodered",
  "options": {
    "Image": "nodered/node-red:latest",
    "ExposedPorts": {
      "1880/tcp": {},
      "1883/tcp": {}
    },
    "Env": [
      "NODE_TLS_REJECT_UNAUTHORIZED=0",
      "TZ=America/New_York",
      "NODE_OPTIONS=--max_old_space_size=64"
    ],
    "HostConfig": {
      "CpusetCpus": "0",
      "PortBindings": {
        "1880/tcp": [
          {
            "HostPort": "50080"
          }
        ]
      },
      "RestartPolicy": {
        "Name": "unless-stopped",
        "MaximumRetryCount": 0
      },
      "Mounts": [
        {
          "Target": "/data",
          "Source": "node-red",
          "Type": "volume",
          "ReadOnly": false,
          "Consistency": "default"
        }
      ]
    }
  }
}
```

#### Start - NodeRED
`POST /services/containerization/containers/start`

Corps :
```json
{
  "container-name": "nodered"
}
```

#### Stop - NodeRED
`POST /services/containerization/containers/stop`

Corps :
```json
{
  "container-name": "nodered"
}
```

#### Delete - NodeRED
`DELETE /services/containerization/containers/nodered`

## Containers › Atrius Edge Connector (AEC)

#### Create - AEC
`POST /services/containerization/containers/create-container`

Corps :
```json
{
  "name": "atrius-connector",
  "options": {
    "Image": "atriussmartsystems/edgybasharm64:latest",
    "Env": [
      "TRACE=true",
      "INTERVAL=0",
      "TREND_MAX_PULL=1",
      "… 9 autres éléments"
    ],
    "RestartPolicy": {
      "Name": "unless-stopped",
      "MaximumRetryCount": 0
    }
  }
}
```

#### Start - AEC
`POST /services/containerization/containers/start`

Corps :
```json
{
  "container-name": "atrius-connector"
}
```

#### Stop - AEC
`POST /services/containerization/containers/stop`

Corps :
```json
{
  "container-name": "atrius-connector"
}
```

#### Delete - AEC
`DELETE /services/containerization/containers/atrius-connector`

## Containers › RPORT

#### Create RPORT
`POST /services/containerization/containers/create-container`

Corps :
```json
{
  "name": "rport-client",
  "options": {
    "Image": "containers.dc8292.link/library/rport-arm64:latest",
    "Env": [
      "RPORT_AUTH=container-test1:86mkzsz0kgijNcK",
      "RPORT_SERVER=rport.test.com:80",
      "RPORT_NAME=system1-test1",
      "… 1 autres éléments"
    ],
    "HostConfig": {
      "CpusetCpus": "0",
      "RestartPolicy": {
        "Name": "unless-stopped",
        "MaximumRetryCount": 0
      },
      "Mounts": [
        {
          "Target": "/rport/app",
          "Source": "rport-client",
          "Type": "volume",
          "ReadOnly": false,
          "Consistency": "default"
        }
      ]
    }
  }
}
```

#### Create RPORT-CR
`POST https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/containerization/containers/create-container`, `Host: {{cloudrelayHostname}}`

Corps :
```json
{
  "name": "rport-client",
  "options": {
    "Image": "containers.dc8292.link/library/rport-arm64:latest",
    "Env": [
      "RPORT_AUTH=container-test1:86mkzsz0kgijNcK",
      "RPORT_SERVER=rport.test.com:80",
      "RPORT_NAME=system1-test1",
      "… 1 autres éléments"
    ],
    "HostConfig": {
      "CpusetCpus": "0",
      "RestartPolicy": {
        "Name": "unless-stopped",
        "MaximumRetryCount": 0
      },
      "Mounts": [
        {
          "Target": "/rport/app",
          "Source": "rport-client",
          "Type": "volume",
          "ReadOnly": false,
          "Consistency": "default"
        }
      ]
    }
  }
}
```

#### Create RPORT-CR Copy
`POST https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/containerization/containers/create-container`, `Host: {{cloudrelayHostname}}`

Corps :
```json
{
  "name": "rport-client",
  "options": {
    "Image": "containers.dc8292.link/library/rport-arm64:latest",
    "Env": [
      "RPORT_AUTH=container-test1:86mkzsz0kgijNcK",
      "RPORT_SERVER=rport.test.com:80",
      "RPORT_NAME=system1-test1",
      "… 1 autres éléments"
    ],
    "HostConfig": {
      "CpusetCpus": "0",
      "RestartPolicy": {
        "Name": "unless-stopped",
        "MaximumRetryCount": 0
      },
      "Mounts": [
        {
          "Target": "/rport/app",
          "Source": "rport-client",
          "Type": "volume",
          "ReadOnly": false,
          "Consistency": "default"
        }
      ]
    }
  }
}
```

#### Start RPORT
`POST /services/containerization/containers/start`

Corps :
```json
{
  "container-name": "rport-client"
}
```

#### Start RPORT-CR
`POST https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/containerization/containers/start`, `Host: {{cloudrelayHostname}}`

Corps :
```json
{
  "container-name": "rport-client"
}
```

#### Stop RPORT
`POST /services/containerization/containers/stop`

Corps :
```json
{
  "container-name": "rport-client"
}
```

#### Stop RPORT-CR
`POST https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/containerization/containers/stop`, `Host: {{cloudrelayHostname}}`

Corps :
```json
{
  "container-name": "rport-client"
}
```

#### Delete RPORT
`DELETE /services/containerization/containers/rport-client`

#### Delete RPORT-CR
`DELETE https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/containerization/containers/rport-client`, `Host: {{cloudrelayHostname}}`

## Containers › File Browser

#### Create - FileBrowser
`POST /services/containerization/containers/create-container`

Corps :
```json
{
  "name": "filebrowser",
  "options": {
    "Image": "filebrowser/filebrowser:latest",
    "HostConfig": {
      "PortBindings": {
        "80/tcp": [
          {
            "HostPort": "50088"
          }
        ]
      },
      "Mounts": [
        {
          "Target": "/srv",
          "Source": "zuulConfig",
          "Type": "volume",
          "ReadOnly": false,
          "Consistency": "default"
        }
      ]
    }
  }
}
```

#### Start - FileBrowser
`POST /services/containerization/containers/start`

Corps :
```json
{
  "container-name": "filebrowser"
}
```

#### Stop - FileBrowser
`POST /services/containerization/containers/stop`

Corps :
```json
{
  "container-name": "filebrowser"
}
```

#### Delete - FileBrowser
`DELETE /services/containerization/containers/filebrowser`

## Containers › BOPTest (AMD64 Only)

#### Create - BOP Server
`POST /services/containerization/containers/create-container`

Corps :
```json
{
  "name": "bop_multizone_simple_office_air",
  "options": {
    "Image": "fisha462/bop_custom:latest",
    "HostConfig": {
      "PortBindings": {
        "5000/tcp": [
          {
            "HostPort": "50080"
          }
        ]
      },
      "RestartPolicy": {
        "Name": "unless-stopped",
        "MaximumRetryCount": 0
      }
    },
    "NetworkingConfig": {
      "EndpointsConfig": {
        "boptest-net": {}
      }
    }
  }
}
```

#### Create - BOP Broker
`POST /services/containerization/containers/create-container`

Corps :
```json
{
  "name": "bop_broker",
  "options": {
    "Image": "fisha462/bop_broker:latest",
    "ExposedPorts": {
      "443/tcp": {}
    },
    "Env": [
      "BOP_SERVER_IP=bop_multizone_simple_office_air",
      "BOP_SERVER_PORT=5000",
      "ECY2_IP=10.168.15.24",
      "… 5 autres éléments"
    ],
    "HostConfig": {
      "PortBindings": {
        "443/tcp": [
          {
            "HostPort": "50081"
          }
        ]
      },
      "RestartPolicy": {
        "Name": "unless-stopped",
        "MaximumRetryCount": 0
      }
    },
    "NetworkingConfig": {
      "EndpointsConfig": {
        "boptest-net": {}
      }
    }
  }
}
```

#### Start - BOP Server
`POST /services/containerization/containers/start`

Corps :
```json
{
  "container-name": "bop_multizone_simple_office_air"
}
```

#### Start - BOP Broker
`POST /services/containerization/containers/start`

Corps :
```json
{
  "container-name": "bop_broker"
}
```

#### Stop - BOPServer
`POST /services/containerization/containers/stop`

Corps :
```json
{
  "container-name": "bop_multizone_simple_office_air"
}
```

#### Stop - BOP Broker
`POST /services/containerization/containers/stop`

Corps :
```json
{
  "container-name": "bop_broker"
}
```

#### Delete - BOP Server
`DELETE /services/containerization/containers/bop_multizone_simple_office_air`

#### Delete - BOP Broker
`DELETE /services/containerization/containers/bop_broker`

## Containers › Netdata

#### Create - Netdata
`POST /services/containerization/containers/create-container`

Corps :
```json
{
  "name": "netdata",
  "options": {
    "Image": "netdata/netdata:latest",
    "HostConfig": {
      "RestartPolicy": {
        "Name": "unless-stopped",
        "MaximumRetryCount": 0
      },
      "LogConfig": {
        "Type": "none",
        "Config": {}
      },
      "PortBindings": {
        "19999/tcp": [
          {
            "HostPort": "50099"
          }
        ]
      },
      "Mounts": [
        {
          "Target": "/etc/netdata",
          "Source": "netdataConfig",
          "Type": "volume",
          "ReadOnly": false,
          "Consistency": "default"
        },
        {
          "Target": "/var/lib/netdata",
          "Source": "netdatalib",
          "Type": "volume",
          "ReadOnly": false,
          "Consistency": "default"
        },
        {
          "Target": "/var/cache/netdata",
          "Source": "netdatacache",
          "Type": "volume",
          "ReadOnly": false,
          "Consistency": "default"
        }
      ]
    }
  }
}
```

#### Start - Netdata
`POST /services/containerization/containers/start`

Corps :
```json
{
  "container-name": "netdata"
}
```

#### Stop - Netdata
`POST /services/containerization/containers/stop`

Corps :
```json
{
  "container-name": "netdata"
}
```

#### Delete - Netdata
`DELETE /services/containerization/containers/netdata`

## Containers › Cloudflare

#### Create - Cloudflare
`POST /services/containerization/containers/create-container`

Corps :
```json
{
  "name": "cloudflare",
  "options": {
    "Image": "cloudflare/cloudflared:latest",
    "Cmd": [
      "tunnel",
      "--no-autoupdate",
      "run",
      "… 2 autres éléments"
    ],
    "HostConfig": {
      "RestartPolicy": {
        "Name": "unless-stopped",
        "MaximumRetryCount": 0
      }
    }
  }
}
```

#### Start - Cloudflare
`POST /services/containerization/containers/start`

Corps :
```json
{
  "container-name": "cloudflare"
}
```

#### Stop - Cloudflare
`POST /services/containerization/containers/stop`

Corps :
```json
{
  "container-name": "cloudflare"
}
```

#### Delete - Cloudflare
`DELETE /services/containerization/containers/cloudflare`

## Containers › NGINX Proxy Manager

#### Create - NXPM
`POST /services/containerization/containers/create-container`

Corps :
```json
{
  "name": "nxpm",
  "options": {
    "Image": "jc21/nginx-proxy-manager:latest",
    "HostConfig": {
      "RestartPolicy": {
        "Name": "unless-stopped",
        "MaximumRetryCount": 0
      },
      "PortBindings": {
        "81/tcp": [
          {
            "HostPort": "50081"
          }
        ],
        "443/tcp": [
          {
            "HostPort": "50243"
          }
        ],
        "80/tcp": [
          {
            "HostPort": "50280"
          }
        ]
      },
      "Mounts": [
        {
          "Target": "/app/config",
          "Source": "nxpm-config",
          "Type": "volume",
          "ReadOnly": false,
          "Consistency": "default"
        },
        {
          "Target": "/data",
          "Source": "nxpm-data",
          "Type": "volume",
          "ReadOnly": false,
          "Consistency": "default"
        },
        {
          "Target": "/etc/letsencrypt",
          "Source": "nxpm-certs",
          "Type": "volume",
          "ReadOnly": false,
          "Consistency": "default"
        }
      ]
    }
  }
}
```

#### Create - NXPM  (Streams3)
`POST /services/containerization/containers/create-container`

Corps :
```json
{
  "name": "nxpm",
  "options": {
    "Image": "jc21/nginx-proxy-manager:latest",
    "ExposedPorts": {
      "50300/tcp": {},
      "50301/tcp": {},
      "50302/tcp": {}
    },
    "HostConfig": {
      "RestartPolicy": {
        "Name": "unless-stopped",
        "MaximumRetryCount": 0
      },
      "PortBindings": {
        "81/tcp": [
          {
            "HostPort": "50081"
          }
        ],
        "443/tcp": [
          {
            "HostPort": "50243"
          }
        ],
        "80/tcp": [
          {
            "HostPort": "50280"
          }
        ],
        "50300/tcp": [
          {
            "HostPort": "50300"
          }
        ],
        "50301/tcp": [
          {
            "HostPort": "50301"
          }
        ],
        "50302/tcp": [
          {
            "HostPort": "50302"
          }
        ]
      },
      "Mounts": [
        {
          "Target": "/app/config",
          "Source": "nxpm-config",
          "Type": "volume",
          "ReadOnly": false,
          "Consistency": "default"
        },
        {
          "Target": "/data",
          "Source": "nxpm-data",
          "Type": "volume",
          "ReadOnly": false,
          "Consistency": "default"
        },
        {
          "Target": "/etc/letsencrypt",
          "Source": "nxpm-certs",
          "Type": "volume",
          "ReadOnly": false,
          "Consistency": "default"
        }
      ]
    }
  }
}
```

#### Start - NXPM
`POST /services/containerization/containers/start`

Corps :
```json
{
  "container-name": "nxpm"
}
```

#### Stop - NXPM
`POST /services/containerization/containers/stop`

Corps :
```json
{
  "container-name": "nxpm"
}
```

#### Delete - NXPM
`DELETE /services/containerization/containers/nxpm`

## Containers › TwinGate

#### Create TwinGate-CR
`POST https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/containerization/containers/create-container`, `Host: {{cloudrelayHostname}}`

Corps :
```json
{
  "name": "twingate-client",
  "options": {
    "Image": "twingate/connector:latest",
    "Env": [
      "TWINGATE_NETWORK=dchosting",
      "TWINGATE_ACCESS_TOKEN={{vault:json-web-token}}",
      "TWINGATE_REFRESH_TOKEN=kJ5x9U5xvmvMErVUJXthfE6ACoO9E9lKqeBA2iRuwPayWZDDGcKFvRv-C4EHVLyBe7WiLUChVYR7pnEalauGx_Sdp9Yt1U_",
      "… 3 autres éléments"
    ],
    "HostConfig": {
      "CpusetCpus": "0",
      "RestartPolicy": {
        "Name": "unless-stopped",
        "MaximumRetryCount": 0
      }
    }
  }
}
```

#### Start TwinGate-CR
`POST https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/containerization/containers/start`, `Host: {{cloudrelayHostname}}`

Corps :
```json
{
  "container-name": "twingate-client"
}
```

#### Stop TwinGate-CR
`POST https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/containerization/containers/stop`, `Host: {{cloudrelayHostname}}`

Corps :
```json
{
  "container-name": "twingate-client"
}
```

#### Delete TwinGate-CR
`DELETE https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/containerization/containers/twingate-client`, `Host: {{cloudrelayHostname}}`

## Containers › ECY Hub

#### Create - ECY Hub
`POST /services/containerization/containers/create-container`

Corps :
```json
{
  "name": "ecy_hub",
  "options": {
    "Image": "containers.dc8292.link/ecy-hub/ecy-hub-arm64:latest",
    "HostConfig": {
      "PortBindings": {
        "5000/tcp": [
          {
            "HostPort": "50098"
          }
        ]
      }
    }
  }
}
```

#### Start - ECY Hub
`POST /services/containerization/containers/start`

Corps :
```json
{
  "container-name": "ecy_hub"
}
```

#### Stop - ECY Hub
`POST /services/containerization/containers/stop`

Corps :
```json
{
  "container-name": "ecy_hub"
}
```

#### Delete - ECY Hub
`DELETE /services/containerization/containers/ecy_hub`

## Containers › Newt

#### Create Newt-CR
`POST https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/containerization/containers/create-container`, `Host: {{cloudrelayHostname}}`

Corps :
```json
{
  "name": "p2-3asy-link",
  "options": {
    "Image": "fosrl/newt",
    "Env": [
      "PANGOLIN_ENDPOINT=https://pangolin.p2.3asy.link",
      "NEWT_ID=lhhr93vivasyovq",
      "NEWT_SECRET=c3opmm19yr21ig83oovh13i38aermivrk71a648wt8q6b9f6"
    ],
    "HostConfig": {
      "CpusetCpus": "0",
      "RestartPolicy": {
        "Name": "unless-stopped",
        "MaximumRetryCount": 0
      }
    }
  }
}
```

#### Start Newt-CR
`POST https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/containerization/containers/start`, `Host: {{cloudrelayHostname}}`

Corps :
```json
{
  "container-name": "p2-3asy-link"
}
```

#### Stop Newt-CR
`POST https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/containerization/containers/stop`, `Host: {{cloudrelayHostname}}`

Corps :
```json
{
  "container-name": "p2-3asy-link"
}
```

#### Delete Newt-CR
`DELETE https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/containerization/containers/p2-3asy-link`, `Host: {{cloudrelayHostname}}`

## Containers

#### List Containers
`GET /services/containerization/containers`

#### List Containers-CR
`GET https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/containerization/containers`, `Host: {{cloudrelayHostname}}`

## Images › File Browser

#### List Images - Filebrowser
`GET /services/containerization/images/filebrowser%2Ffilebrowser%3Alatest`

#### Del Images - Filebrowser
`DELETE /services/containerization/images/filebrowser%2Ffilebrowser%3Alatest`

## Images

#### List Images
`GET /services/containerization/images`

#### List Images-CR
`GET https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/containerization/images`, `Host: {{cloudrelayHostname}}`

#### Pull Image - Netdata
`POST /services/containerization/images/pull-image`

Corps :
```json
{
  "image": "netdata/netdata"
}
```

#### Pull Image RPORT
`POST /services/containerization/images/pull-image`

Corps :
```json
{
  "image": "containers.dc8292.link/library/rport-arm64:latest"
}
```

#### Pull Image RPORT-CR
`POST https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/containerization/images/pull-image`, `Host: {{cloudrelayHostname}}`

Corps :
```json
{
  "image": "containers.dc8292.link/library/rport-arm64:latest"
}
```

#### Pull Image Newt-CR
`POST https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/containerization/images/pull-image`, `Host: {{cloudrelayHostname}}`

Corps :
```json
{
  "image": "fosrl/newt:latest"
}
```

#### Pull Image TwinGate-CR
`POST https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/containerization/images/pull-image`, `Host: {{cloudrelayHostname}}`

Corps :
```json
{
  "image": "twingate/connector:latest"
}
```

#### Pull Image - Netdata-CR
`POST https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/containerization/images/pull-image`, `Host: {{cloudrelayHostname}}`

Corps :
```json
{
  "image": "netdata/netdata"
}
```

#### Pull Image - NodeRED
`POST /services/containerization/images/pull-image`

Corps :
```json
{
  "image": "nodered/node-red"
}
```

#### Pull Image - AEC
`POST /services/containerization/images/pull-image`

Corps :
```json
{
  "image": "atriussmartsystems/edgybasharm64:latest"
}
```

#### Pull Image - Cloudflare
`POST /services/containerization/images/pull-image`

Corps :
```json
{
  "image": "cloudflare/cloudflared"
}
```

#### Pull Image - ECY Hub
`POST /services/containerization/images/pull-image`

Corps :
```json
{
  "image": "containers.dc8292.link/ecy-hub/ecy-hub-arm64:latest"
}
```

## Registries

#### List Registries
`GET /services/containerization/registries`

#### List Registries-CR
`GET https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/containerization/registries`, `Host: {{cloudrelayHostname}}`

#### Add Registry
`POST /services/containerization/registries/dc-registry3.8292-tunnel.link`

Corps :
```json
{
  "key": "dc-registry3.8292-tunnel.link",
  "username": "dc-test",
  "password": "<masqué>"
}
```

#### Add Registry Copy
`POST /services/containerization/registries/test1`

Corps :
```json
{
  "key": "10.110.210.131:5000",
  "username": "distech",
  "password": "<masqué>"
}
```

#### Add Registry-CR
`POST https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/containerization/registries/containers.dc8292.link`, `Host: {{cloudrelayHostname}}`

Corps :
```json
{
  "key": "containers.dc8292.link",
  "username": "dc-readonly",
  "password": "<masqué>"
}
```

#### Read Registry
`GET /services/containerization/registries/dc-registry3.8292-tunnel.link`

#### Read Registries-CR
`GET https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/containerization/registries/containers.dc8292.link`, `Host: {{cloudrelayHostname}}`

## Volumes

#### List Volumes
`GET /services/containerization/volumes`

#### Delete Volume - netdata
`DELETE /services/containerization/volumes/netdatacache`

## Networks

#### List Networks
`GET /services/containerization/networks/`

#### Create Network
`POST /services/containerization/networks/boptest-net`

Corps :
```json
{
  "key": "boptest-net",
  "driver": "bridge",
  "scope": "local",
  "containers": {
    "923b7c0b5ff2f6d02e3160f78370b2c06ef7f5fcdad38b8e444eff43720227e1": {
      "key": "923b7c0b5ff2f6d02e3160f78370b2c06ef7f5fcdad38b8e444eff43720227e1",
      "mac-address": "02:42:ac:1e:01:02",
      "ipv4-address": "172.30.1.2/24",
      "ipv6-address": ""
    },
    "1c8a156759333a17b15bdc1aaf4555f70b1d1ed4fccb5a09288298117ff2da93": {
      "key": "1c8a156759333a17b15bdc1aaf4555f70b1d1ed4fccb5a09288298117ff2da93",
      "mac-address": "02:42:ac:1e:01:03",
      "ipv4-address": "172.30.1.3/24",
      "ipv6-address": ""
    }
  },
  "ip-configurations": [
    {
      "subnet": "172.30.1.0/24",
      "gateway": "172.30.1.1"
    }
  ]
}
```

#### Delete Network
`DELETE /services/containerization/networks/boptest-net`

## Containerization

#### Containerization
`GET /services/containerization`
