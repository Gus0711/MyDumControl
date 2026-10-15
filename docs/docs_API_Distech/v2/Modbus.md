# API V2 — Modbus

Chemins relatifs à `https://<hôte>/api/rest/v2` sauf mention contraire. Auth : Basic. Voir [INDEX](../INDEX.md).

## Client › Networks

#### List Networks
`GET /services/modbus/networks`

#### Read Network - RS485
`GET /services/modbus/networks/Modbus RS-485 Network 1`

#### Create Network - RS485
`POST /services/modbus/networks/Modbus RS-485 Network 1`

Corps :
```json
{
  "key": "Modbus RS-485 Network 1",
  "stop-bits": 1,
  "port": "COM1",
  "parity": "None",
  "data-bits": 8,
  "description": "",
  "state": "Disable",
  "enabled": true,
  "speed": 38400
}
```

#### Delete Network - RS485
`DELETE /services/modbus/networks/Modbus RS-485 Network 1`

## Client › Device - IP › Points

#### List Points
`GET /services/modbus/devices/ecbos51/points`

#### Read Point - testNum1
`GET /services/modbus/devices/ecbos51/points/testNum1`

#### Create Points
`POST /services/modbus/devices/ecbos51/points`

Corps :
```json
{
  "testBool1": {
    "key": "testBool1",
    "default-value": false,
    "address": "1",
    "register-type": "Coils",
    "desired-value": false,
    "data-type": "Bit",
    "units": "NoUnits",
    "out-of-service": false,
    "present-value": true,
    "priority-array": [
      null,
      null,
      null,
      "… 13 autres éléments"
    ],
    "polling-interval": 10,
    "last-error-code": 0,
    "…": "6 autres clés (address-type, access-type, modbus-status, data-units, polling-timeout…)"
  },
  "testBool2": {
    "key": "testBool2",
    "default-value": false,
    "address": "2",
    "register-type": "Coils",
    "desired-value": false,
    "data-type": "Bit",
    "units": "NoUnits",
    "out-of-service": false,
    "present-value": true,
    "priority-array": [
      null,
      null,
      null,
      "… 13 autres éléments"
    ],
    "polling-interval": 10,
    "last-error-code": 0,
    "…": "6 autres clés (address-type, access-type, modbus-status, data-units, polling-timeout…)"
  },
  "testNum2": {
    "key": "testNum2",
    "register-type": "HoldingRegister",
    "value-scale": 1.0,
    "units": "NoUnits",
    "polling-interval": 10,
    "last-error-code": 0,
    "modbus-status": "Ok",
    "data-units": "NoUnits",
    "polling-timeout": 1,
    "default-value": 0,
    "address": "40002",
    "desired-value": 0,
    "…": "8 autres clés (data-type, out-of-service, priority-array, present-value, address-type…)"
  },
  "testNum1": {
    "key": "testNum1",
    "register-type": "HoldingRegister",
    "value-scale": 1.0,
    "units": "NoUnits",
    "polling-interval": 10,
    "last-error-code": 0,
    "modbus-status": "Ok",
    "data-units": "NoUnits",
    "polling-timeout": 1,
    "default-value": 0,
    "address": "40001",
    "desired-value": 0,
    "…": "8 autres clés (data-type, out-of-service, priority-array, present-value, address-type…)"
  }
}
```

#### Create Point - Numeric
`POST /services/modbus/devices/ecbos51/points/testNum3`

Corps :
```json
{
  "key": "testNum3",
  "register-type": "HoldingRegister",
  "value-scale": 1.0,
  "units": "NoUnits",
  "polling-interval": 10,
  "data-units": "NoUnits",
  "polling-timeout": 1,
  "default-value": 0,
  "address": "40003",
  "desired-value": 0,
  "data-type": "Uint16",
  "out-of-service": false,
  "…": "3 autres clés (address-type, access-type, value-offset…)"
}
```

## Client › Device - IP

#### Create Device - IP
`POST /services/modbus/devices/Modbus Device 2`

Corps :
```json
{
  "key": "Modbus Device 2",
  "address": {
    "port": 502,
    "ip": "192.168.45.99",
    "type": "TcpIp",
    "modbus-address": 2
  },
  "max-read-coils": 2000,
  "description": "",
  "encoding": {
    "int64-byte-ordering": {
      "byte-swap": false,
      "word-swap": false,
      "double-word-swap": false
    },
    "double-byte-ordering": {
      "byte-swap": false,
      "word-swap": false,
      "double-word-swap": false
    },
    "int16-byte-ordering": {
      "byte-swap": false
    },
    "int32-byte-ordering": {
      "byte-swap": false,
      "word-swap": false
    },
    "float-byte-ordering": {
      "byte-swap": false,
      "word-swap": false
    }
  },
  "heartbeat-point": "",
  "points": {},
  "request-throttle": 0.0,
  "max-write-coils": 1968,
  "supports-write-multiple-coils": true,
  "supports-write-multiple-registers": true,
  "max-read-registers": 125,
  "…": "2 autres clés (max-write-registers, polling-timeout…)"
}
```

#### Read Device - IP
`GET /services/modbus/devices/ecbos51`

#### Delete Device - IP
`DELETE /services/modbus/devices/ecbos51`

## Client › Device - RS485

#### Create Device - RS485
`POST /services/modbus/devices/Modbus Device 1`

Corps :
```json
{
  "key": "Modbus Device 1",
  "address": {
    "type": "Rs485",
    "modbus-address": 1,
    "network": "Modbus RS-485 Network 1"
  },
  "max-read-coils": 2000,
  "description": "",
  "encoding": {
    "int64-byte-ordering": {
      "byte-swap": false,
      "word-swap": false,
      "double-word-swap": false
    },
    "double-byte-ordering": {
      "byte-swap": false,
      "word-swap": false,
      "double-word-swap": false
    },
    "int16-byte-ordering": {
      "byte-swap": false
    },
    "int32-byte-ordering": {
      "byte-swap": false,
      "word-swap": false
    },
    "float-byte-ordering": {
      "byte-swap": false,
      "word-swap": false
    }
  },
  "heartbeat-point": "",
  "points": {},
  "request-throttle": 0.0,
  "max-write-coils": 1968,
  "supports-write-multiple-coils": true,
  "supports-write-multiple-registers": true,
  "max-read-registers": 125,
  "…": "2 autres clés (max-write-registers, polling-timeout…)"
}
```

#### Read Device - RS485
`GET /services/modbus/devices/Modbus Device 1`

#### Delete Device - RS485
`DELETE /services/modbus/devices/Modbus Device 1`

## Server › Points

#### List - Points
`GET /services/modbus/server/points`

#### List - Points Specific
`GET /services/modbus/server/points/ASHP%20B-01%20Return%20Temp`

#### Map - Point
`POST /services/add`

Corps :
```json
{
  "address": 40003,
  "data-type": "Float",
  "key": "ASHP B-01 Supply Temp",
  "register-type": "HoldingRegister",
  "source": "/services/bacnet/local/objects/analog-inputs/103",
  "units": "DegreesCelsius"
}
```

#### Map - Point Copy
`POST /services/add/ASHP%20B-01%20Supply%20Temp?item=ASHP B-01 Supply Temp&path=/services/modbus/server/points`

Corps :
```json
{
  "ASHP B-01 Supply Temp": {
    "address": 40003,
    "data-type": "Float",
    "key": "ASHP B-01 Supply Temp",
    "register-type": "HoldingRegister",
    "source": "/services/bacnet/local/objects/analog-inputs/103",
    "units": "DegreesCelsius"
  }
}
```

#### Map - Point Copy 2
`POST /services/modbus/server/points`

Corps :
```json
{
  "address": 40003,
  "data-type": "Float",
  "key": "ASHP B-01 Supply Temp",
  "register-type": "HoldingRegister",
  "source": "/services/bacnet/local/objects/analog-inputs/103",
  "units": "DegreesCelsius"
}
```

#### Map - Point Copy 3
`POST /services/modbus/server/points/ASHP%20B-01%20Supply%20Temp`

Corps :
```json
{
  "address": 40003,
  "data-type": "Float",
  "key": "ASHP B-01 Supply Temp",
  "register-type": "HoldingRegister",
  "source": "/services/bacnet/local/objects/analog-inputs/103",
  "units": "DegreesCelsius"
}
```

#### Map - Point Copy 4
`DELETE /services/modbus/server/points/ASHP%20B-01%20Supply%20Temp`

## Server

#### List - Server
`GET /services/modbus/server`

#### Server - TcpIp
`POST /services/modbus/server`

Corps :
```json
{
  "address": {
    "port": 502,
    "type": "TcpIp"
  },
  "update-interval": 5000,
  "encoding": {
    "int64-byte-ordering": {
      "byte-swap": false,
      "word-swap": false,
      "double-word-swap": false
    },
    "double-byte-ordering": {
      "byte-swap": false,
      "word-swap": false,
      "double-word-swap": false
    },
    "int16-byte-ordering": {
      "byte-swap": false
    },
    "int32-byte-ordering": {
      "byte-swap": false,
      "word-swap": false
    },
    "float-byte-ordering": {
      "byte-swap": false,
      "word-swap": false
    }
  },
  "enabled": true
}
```

#### Server - RS485 OnBoard
`POST /services/modbus/server`

Corps :
```json
{
  "address": {
    "stop-bits": 1,
    "port": "COM1",
    "parity": "None",
    "data-bits": 8,
    "type": "Rs485",
    "speed": 38400,
    "modbus-address": 1
  },
  "update-interval": 5000,
  "encoding": {
    "int64-byte-ordering": {
      "byte-swap": false,
      "word-swap": false,
      "double-word-swap": false
    },
    "double-byte-ordering": {
      "byte-swap": false,
      "word-swap": false,
      "double-word-swap": false
    },
    "int16-byte-ordering": {
      "byte-swap": false
    },
    "int32-byte-ordering": {
      "byte-swap": false,
      "word-swap": false
    },
    "float-byte-ordering": {
      "byte-swap": false,
      "word-swap": false
    }
  },
  "enabled": true
}
```

#### Server - Module Port1
`POST /services/modbus/server`

Corps :
```json
{
  "address": {
    "stop-bits": 1,
    "port": "COM2",
    "parity": "None",
    "data-bits": 8,
    "type": "Rs485",
    "speed": 38400,
    "modbus-address": 1
  },
  "update-interval": 5000,
  "encoding": {
    "int64-byte-ordering": {
      "byte-swap": false,
      "word-swap": false,
      "double-word-swap": false
    },
    "double-byte-ordering": {
      "byte-swap": false,
      "word-swap": false,
      "double-word-swap": false
    },
    "int16-byte-ordering": {
      "byte-swap": false
    },
    "int32-byte-ordering": {
      "byte-swap": false,
      "word-swap": false
    },
    "float-byte-ordering": {
      "byte-swap": false,
      "word-swap": false
    }
  },
  "enabled": true
}
```

#### Server - Module Port2
`POST /services/modbus/server`

Corps :
```json
{
  "address": {
    "stop-bits": 1,
    "port": "COM3",
    "parity": "None",
    "data-bits": 8,
    "type": "Rs485",
    "speed": 38400,
    "modbus-address": 1
  },
  "update-interval": 5000,
  "encoding": {
    "int64-byte-ordering": {
      "byte-swap": false,
      "word-swap": false,
      "double-word-swap": false
    },
    "double-byte-ordering": {
      "byte-swap": false,
      "word-swap": false,
      "double-word-swap": false
    },
    "int16-byte-ordering": {
      "byte-swap": false
    },
    "int32-byte-ordering": {
      "byte-swap": false,
      "word-swap": false
    },
    "float-byte-ordering": {
      "byte-swap": false,
      "word-swap": false
    }
  },
  "enabled": true
}
```

## Modbus

#### Modbus
`GET /services/modbus`

#### List Devices
`GET /services/modbus/devices`
