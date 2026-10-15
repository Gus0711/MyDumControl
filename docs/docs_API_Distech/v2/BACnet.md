# API V2 — BACnet

Chemins relatifs à `https://<hôte>/api/rest/v2` sauf mention contraire. Auth : Basic. Voir [INDEX](../INDEX.md).

## Remote › Devices › AnalogValue

#### List {objects-av}
`GET /services/bacnet/remote/devices/210064/objects/analog-values`

#### Create {object-av}
`POST /services/bacnet/remote/devices/210064/objects/add`

Corps :
```json
{
  "object-type": "AnalogValue",
  "instance-number": 1500,
  "name": "apiAVTest2"
}
```

#### Persist {object-av}
`POST /services/bacnet/remote/devices/210064/objects/analog-values/3`

Corps :
```json
{
  "policy": "lxr2_policy_poll",
  "managed-properties": {
    "36": {},
    "81": {
      "sync-on-present-value-change": true
    },
    "85": {
      "operation": "ReadWrite"
    },
    "87": {
      "sync-on-present-value-change": true
    },
    "103": {},
    "104": {
      "sync-on-present-value-change": true
    },
    "111": {},
    "117": {
      "sync-on-present-value-change": true
    }
  }
}
```

#### List {object-av}
`GET /services/bacnet/remote/devices/210064/objects/analog-values/23`

#### List {object-av-presentValue}
`GET /services/bacnet/remote/devices/210064/objects/analog-values/2/present-value`

#### Write {object-av-presentValue} (Alternative)
`POST /services/bacnet/remote/devices/210066/objects/analog-values/23/present-value`

Corps :
```json
{
  "$value": 2.0
}
```

#### Write {object-av-presentValue} (Preferred)
`POST /services/bacnet/remote/devices/210064/objects/analog-values/2/set-value`

Corps :
```json
{
  "value": 5.0
}
```

#### Write {object-av-priority} (Preferred)
`POST /services/bacnet/remote/devices/210066/objects/analog-values/23/set-value-at`

Corps :
```json
{
  "value": 6.0,
  "priority": 10
}
```

#### Auto {object-av} (Preferred)
`POST /services/bacnet/remote/devices/210066/objects/analog-values/23/auto`

Corps :
```json
{}
```

#### E-Auto {object-av} (Preferred)
`POST /services/bacnet/remote/devices/210066/objects/analog-values/23/emergency-auto`

Corps :
```json
{}
```

#### Override {object-av} (Preferred)
`POST /services/bacnet/remote/devices/210066/objects/analog-values/23/override`

Corps :
```json
{
  "value": 8.0
}
```

#### E-Override {object-av} (Preferred)
`POST /services/bacnet/remote/devices/210066/objects/analog-values/23/emergency-override`

Corps :
```json
{
  "value": 8.0
}
```

#### Delete {object-av}
`DELETE /services/bacnet/remote/devices/47071/objects/analog-values/100`

## Remote › Devices › BinaryValue

#### List {objects-bv}
`GET /services/bacnet/remote/devices/210064/objects/binary-values`

#### Create {object-bv}
`POST /services/bacnet/remote/devices/45071/objects/add`

Corps :
```json
{
  "object-type": "BinaryValue",
  "instance-number": 100,
  "name": "apiBVTest2"
}
```

#### Persist {object-bv}
`POST /services/bacnet/remote/devices/210064/objects/binary-values/3`

Corps :
```json
{
  "policy": "lxr2_policy_poll",
  "managed-properties": {
    "4": {},
    "36": {},
    "46": {},
    "81": {
      "sync-on-present-value-change": true
    },
    "85": {
      "operation": "ReadWrite"
    },
    "87": {
      "sync-on-present-value-change": true
    },
    "103": {},
    "104": {
      "sync-on-present-value-change": true
    },
    "111": {}
  }
}
```

#### Remove {object-bv}
`DELETE /services/bacnet/remote/devices/210064/objects/binary-values/3`

#### List {object-bv}
`GET /services/bacnet/remote/devices/210064/objects/binary-values/3`

#### List {object-bv-presentValue}
`GET /services/bacnet/remote/devices/210066/objects/binary-values/11/present-value`

#### Write {object-bv-priority} (Preferred)
`POST /services/bacnet/remote/devices/210066/objects/binary-values/11/set-value-at`

Corps :
```json
{
  "value": "null",
  "priority": 10
}
```

#### Write {object-bv-presentValue} (Preferred)
`POST /services/bacnet/remote/devices/210066/objects/binary-values/11/set-value`

Corps :
```json
{
  "value": "active"
}
```

#### Auto {object-bv} (Preferred)
`POST /services/bacnet/remote/devices/210066/objects/binary-values/11/auto`

Corps :
```json
{}
```

#### E-Auto {object-bv} (Preferred)
`POST /services/bacnet/remote/devices/210066/objects/binary-values/11/emergency-auto`

Corps :
```json
{}
```

#### Override {object-bv} (Preferred)
`POST /services/bacnet/remote/devices/210066/objects/binary-values/11/override`

Corps :
```json
{
  "value": "Inactive"
}
```

#### E-Override {object-bv} (Preferred)
`POST /services/bacnet/remote/devices/210066/objects/binary-values/11/emergency-override`

Corps :
```json
{
  "value": "Inactive"
}
```

## Remote › Devices › MultiStateValue

#### List {objects-msv}
`GET /services/bacnet/remote/devices/47071/objects/multi-state-values`

#### Create {object-msv}
`POST /services/bacnet/remote/devices/47071/objects/add`

Corps :
```json
{
  "object-type": "MultiStateValue",
  "instance-number": 1,
  "name": "apiMSVTest3"
}
```

#### List {object-msv}
`GET /services/bacnet/remote/devices/47071/objects/multi-state-values/1`

#### List {object-msv-presentValue}
`GET /services/bacnet/remote/devices/47071/objects/multi-state-values/1/present-value`

#### Write {object-msv-presentValue}
`POST /services/bacnet/remote/devices/47071/objects/multi-state-values/1`

Corps :
```json
{
  "present-value": 1
}
```

#### Write {object-msv-override}
`POST /services/bacnet/remote/devices/47071/objects/multi-state-values/1/override`

Corps :
```json
{
  "value": 2
}
```

#### Delete {object-msv}
`DELETE /services/bacnet/remote/devices/47071/objects/multi-state-values/100`

## Remote › Devices › BinaryOutput

#### List {objects-bo}
`GET /services/bacnet/remote/devices/210066/objects/binary-outputs`

#### List {object-bo}
`GET /services/bacnet/remote/devices/210066/objects/binary-outputs/110`

#### List {object-bo-presentValue}
`GET /services/bacnet/remote/devices/210066/objects/binary-outputs/110/present-value`

#### Write {object-bo-priority} (Preferred)
`POST /services/bacnet/remote/devices/210066/objects/binary-outputs/110/set-value-at`

Corps :
```json
{
  "value": "inactive",
  "priority": 10
}
```

#### Write {object-bo-presentValue} (Preferred)
`POST /services/bacnet/remote/devices/210066/objects/binary-outputs/110/set-value`

Corps :
```json
{
  "$value": "inactive"
}
```

#### Override {object-bo} (Preferred)
`POST /services/bacnet/remote/devices/210066/objects/binary-outputs/110/override`

Corps :
```json
{
  "value": "Active"
}
```

#### Auto {object-bo} (Preferred)
`POST /services/bacnet/remote/devices/210066/objects/binary-outputs/110/auto`

Corps :
```json
{}
```

## Remote › Devices

#### List Devices
`GET /services/bacnet/remote/devices`

#### List {deviceID}
`GET /services/bacnet/remote/devices/210066`

#### List {deviceID} Objects
`GET /services/bacnet/remote/devices/210066/objects`

#### List {deviceID} Discover Objects
`POST /services/bacnet/remote/devices/210066/discover-objects`

#### Create Device
`POST /services/bacnet/remote/devices/1`

Corps :
```json
{
  "local-name": "Device Name 1",
  "description": "myDescription",
  "address": {
    "network-number": 1,
    "port": 47808,
    "ip": "192.168.1.150",
    "type": "Ip"
  }
}
```

#### Delete {deviceID}
`DELETE /services/bacnet/remote/devices/45051`

## Remote › Policies

#### List Policies
`GET /services/bacnet/remote/policies`

#### List {policyKey}
`GET /services/bacnet/remote/policies/default`

## Remote

#### Remote
`GET /services/bacnet/remote/devices`

#### Discover
`POST /services/bacnet/remote/discover-devices`

Corps :
```json
{
  "low-limit": null,
  "high-limit": null,
  "network-addresses": null,
  "timeout": null,
  "clear-transients": true
}
```

## Local › AnalogValue

#### List {objects-av}
`GET /services/bacnet/local/objects/analog-values`

#### Create {object-av}
`POST /services/bacnet/local/objects/add`

Corps :
```json
{
  "object-type": "AnalogValue",
  "instance-number": 10002,
  "name": "apiAVTest2"
}
```

#### List {av}
`GET /services/bacnet/local/objects/analog-values/99`

#### List {av-presentValue}
`GET /services/bacnet/local/objects/analog-values/99/present-value`

#### Write {av-presentValue}
`POST /services/bacnet/local/objects/analog-values/99`

Corps :
```json
{
  "present-value": 3.0
}
```

#### Write Priority {av-priority10}
`POST /services/bacnet/local/objects/analog-values/99/set-value-at`

Corps :
```json
{
  "value": 176.0,
  "priority": 10
}
```

#### Write Priority {clear av-priority10}
`POST /services/bacnet/local/objects/analog-values/99/set-value-at`

Corps :
```json
{
  "value": null,
  "priority": 10
}
```

#### Delete {av}
`DELETE /services/bacnet/local/objects/analog-values/10002`

## Local › BinaryValue

#### List {bv}
`GET /services/bacnet/local/objects/binary-values`

#### Create {bv}
`POST /services/bacnet/local/objects/add`

Corps :
```json
{
  "object-type": "BinaryValue",
  "instance-number": 10002,
  "name": "apiBVTest2"
}
```

#### List {bv}
`GET /services/bacnet/local/objects/binary-values/99`

#### List {bv-presentValue}
`GET /services/bacnet/local/objects/binary-values/99/present-value`

#### Write {bv-presentValue}
`POST /services/bacnet/local/objects/binary-values/99`

Corps :
```json
{
  "present-value": false
}
```

#### Write Priority {bv-priority-10}
`POST /services/bacnet/local/objects/binary-values/99/set-value-at`

Corps :
```json
{
  "value": "active",
  "priority": 10
}
```

#### Write Priority {clear bv-priority-10}
`POST /services/bacnet/local/objects/binary-values/99/set-value-at`

Corps :
```json
{
  "value": null,
  "priority": 10
}
```

#### Delete {bv}
`DELETE /services/bacnet/local/objects/binary-values/99`

## Local › MultiStateValue

#### List {msv}
`GET /services/bacnet/local/objects/multi-state-values`

#### Create {msv}
`POST /services/bacnet/local/objects/add`

Corps :
```json
{
  "object-type": "MultiStateValue",
  "instance-number": 10002,
  "name": "apiMSVTest2"
}
```

#### List {msv}
`GET /services/bacnet/local/objects/multi-state-values/99`

#### List {msv-presentValue}
`GET /services/bacnet/local/objects/multi-state-values/99/present-value`

#### Write {msv-presentValue}
`POST /services/bacnet/local/objects/multi-state-values/99/set-value-at`

Corps :
```json
{
  "present-value": 1.1
}
```

#### Write Priority {msv-priority-10}
`POST /services/bacnet/local/objects/multi-state-values/99/set-value-at`

Corps :
```json
{
  "value": 2,
  "priority": 10
}
```

#### Write Priority {clear msv-priority-10}
`POST /services/bacnet/local/objects/multi-state-values/99/set-value-at`

Corps :
```json
{
  "value": 2,
  "priority": 10
}
```

#### Delete {msv}
`DELETE /services/bacnet/local/objects/multi-state-values/99`

## Local › Loops

#### List Loops
`GET /services/bacnet/local/objects/loops`

## Local › Schedules

#### List {schedules}
`GET /services/bacnet/local/objects/schedules`

#### Add Schedule
`POST /services/bacnet/local/objects/add`

Corps :
```json
{
  "object-type": "Schedule",
  "instance-number": 10002,
  "name": "apiAVTest2"
}
```

## Local

#### List {objects}
`GET /services/bacnet/local/objects`

#### List {objects}-CR
`GET https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/bacnet/local/objects`, `Host: {{cloudrelayHostname}}`

#### List
`GET /services/bacnet/local`

#### List Copy
`GET /services/bacnet/local`

En-têtes : `Cache-Control: no-cache`, `Postman-Token: <calculated when request is sent>`, `Host: <calculated when request is sent>`, `User-Agent: PostmanRuntime/7.39.1`, `Accept-Encoding: gzip, deflate, br`, `Connection: keep-alive`

#### Local Device ID
`GET /services/bacnet/local/instance-id`

#### Local Set Device ID
`POST /services/bacnet/local/set-device-instance`

Corps :
```json
{
  "value": 300001
}
```

#### Create {objects-multiple}
`POST /batch`

Corps :
```json
{
  "requests": [
    {
      "id": "1",
      "method": "POST",
      "url": "/api/rest/v2/services/bacnet/local/objects/add",
      "body": {
        "object-type": "AnalogValue",
        "instance-number": 10010,
        "name": "apiAVTest10"
      }
    },
    {
      "id": "2",
      "method": "POST",
      "url": "/api/rest/v2/services/bacnet/local/objects/add",
      "body": {
        "object-type": "BinaryValue",
        "instance-number": 10010,
        "name": "apiBVTest10"
      }
    },
    {
      "id": "3",
      "method": "POST",
      "url": "/api/rest/v2/services/bacnet/local/objects/add",
      "body": {
        "object-type": "MultiStateValue",
        "instance-number": 10010,
        "name": "apiMSVTest10"
      }
    }
  ]
}
```

#### Delete {objects-multiple}
`POST /batch`

Corps :
```json
{
  "requests": [
    {
      "id": "1",
      "method": "DELETE",
      "url": "/api/rest/v2/services/bacnet/local/objects/analog-values/10010"
    },
    {
      "id": "2",
      "method": "DELETE",
      "url": "/api/rest/v2/services/bacnet/local/objects/binary-values/10010"
    },
    {
      "id": "3",
      "method": "DELETE",
      "url": "/api/rest/v2/services/bacnet/local/objects/multi-state-values/10010"
    }
  ]
}
```

#### Read Property Mulitple - CR
`POST https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/bacnet/local/objects/read-property-multiple`, `Host: {{cloudrelayHostname}}`

Corps :
```json
{
  "encode": "text",
  "property-references": [
    {
      "type": "analogValue",
      "instance": 1,
      "property": "presentValue"
    },
    {
      "type": "analogValue",
      "instance": 2,
      "property": "presentValue"
    }
  ]
}
```

#### Read Property Multiple
`POST /services/bacnet/local/objects/read-property-multiple`

Corps :
```json
{
  "encode": "text",
  "property-references": [
    {
      "type": "analogValue",
      "instance": 1,
      "property": "presentValue"
    },
    {
      "type": "analogValue",
      "instance": 4,
      "property": "presentValue"
    }
  ]
}
```

#### Write Property Multiple
`POST /services/bacnet/local/objects/write-property-multiple`

Corps :
```json
{
  "encode": "text",
  "property-references": [
    {
      "type": "analogValue",
      "instance": 1,
      "property": "presentValue",
      "value": "65.0"
    },
    {
      "type": "analogValue",
      "instance": 4,
      "property": "presentValue",
      "value": "70.0"
    }
  ]
}
```

## Communication › Network › Ports › SecureConnect

#### Write Network (SC-Cert)
`POST /services/bacnet/communication/network/ports/secure-connect`

Corps :
```json
{
  "certificate": "lxr-demo1-apex61",
  "description": "",
  "enabled": true,
  "network-number": 110
}
```

#### Create Network (SC)
`POST /services/bacnet/communication/network/add-sc-network-port`

Corps :
```json
{
  "accept-enabled": false,
  "failover-uri": "",
  "hub-connector-enabled": true,
  "hub-function-enabled": false,
  "initiate-enabled": false,
  "network-number": 110,
  "primary-uri": "wss://192.168.1.2/api/bacnet/sc/hub"
}
```

#### List Network (SC)
`GET /services/bacnet/communication/network/ports/secure-connect`

## Communication › Network › Ports

#### List Network (Ports)
`GET /services/bacnet/communication/network/ports`

## Communication › Network

#### List Networks
`GET /services/bacnet/communication/network`

## BACnet

#### BACnet
`GET /services/bacnet`
