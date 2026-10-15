# API V2 — Events

Chemins relatifs à `https://<hôte>/api/rest/v2` sauf mention contraire. Auth : Basic. Voir [INDEX](../INDEX.md).

## Recipients

#### Recipients
`GET /services/events/recipients`

#### Recipients batch-test
`GET /services/events/recipients/batch-test`

#### Recipients Create iot-hub
`POST /services/events/recipients/iot-hub`

Corps :
```json
{
  "type": "IotHub",
  "iot-connection": "Main",
  "initiator": "test2"
}
```

#### Recipients Create iotHub
`POST /services/events/recipients/iotHub`

Corps :
```json
{
  "type": "IotHub",
  "iot-connection": "DCTS",
  "initiator": "dcts-test1"
}
```

#### Recipients Create batch-test
`POST /services/events/recipients/batch-test`

Corps :
```json
{
  "type": "IotHub",
  "iot-connection": "DCTS",
  "initiator": "batchTest"
}
```

#### Recipients Create Email
`POST /services/events/recipients/email`

Corps :
```json
{
  "addresses-to": [],
  "body-format": "TextPlain",
  "subject": "",
  "addresses-cc": [],
  "from": {
    "address": null,
    "name": ""
  },
  "type": "Email",
  "addresses-bcc": [],
  "account": ""
}
```

#### Recipients Create lxr-smtp
`POST /services/events/recipients/lxr-smtp`

Corps :
```json
{
  "type": "Email",
  "account": "dc-test",
  "addresses-to": [
    {
      "address": "lxr200@mail.com",
      "name": "Robert Lastinger"
    }
  ],
  "body-format": "TextPlain",
  "subject": "logs",
  "addresses-cc": [],
  "from": {
    "address": "distech-test@distech-lxr.link",
    "name": "dc-test"
  },
  "addresses-bcc": []
}
```

#### Recipients Create lxr-smtp example2
`POST /services/events/recipients/chiller1-alarm-status`

Corps :
```json
{
  "type": "Email",
  "account": "DC-Test2",
  "addresses-to": [
    {
      "address": "robert@email.com",
      "name": "Robert Lastinger"
    }
  ],
  "body-format": "TextPlain",
  "subject": "Chiller 1 Alarm Status",
  "addresses-cc": [],
  "from": {
    "address": "dc-test@bsystems",
    "name": "secy045"
  },
  "addresses-bcc": []
}
```

#### Recipients Create MQTT
`POST /services/events/recipients/mqtt`

Corps :
```json
{
  "type": "MQTT",
  "connection": "HomeAssistant",
  "topic": "rm/ir-frame"
}
```

#### Recipients Create lxr-mqtt
`POST /services/events/recipients/lxr-mqtt`

Corps :
```json
{
  "type": "MQTT",
  "connection": "lxr-wsl1-emqx01",
  "topic": "lxr/event1"
}
```

#### Recipients Create emqx01-ws1
`POST /services/events/recipients/lxr-wsl1-emqx01`

Corps :
```json
{
  "type": "MQTT",
  "connection": "lxr-wsl1-emqx01",
  "topic": "event1"
}
```

#### Recipients iot-hub
`DELETE /services/events/recipients/iot-hub`

#### Recipients iotHub
`DELETE /services/events/recipients/iotHub`

#### Recipients batch-test
`DELETE /services/events/recipients/batch-test`

#### Recipients MQTT
`DELETE /services/events/recipients/mqtt`

#### Recipients lxr-mqtt
`DELETE /services/events/recipients/lxr-mqtt`

#### Recipients lxr
`DELETE /services/events/recipients/lxr`

#### Recipients lxr-smtp
`DELETE /services/events/recipients/lxr-smtp`

#### Recipients Email
`DELETE /services/events/recipients/email`

## Tasks

#### Sched Tasks
`GET /services/events/tasks`

#### Sched Tasks - IR-Image
`GET /services/events/tasks/IR-Image`

#### Sched Tasks - MyTask
`GET /services/events/tasks/MyTask`

#### Sched Tasks - ts-test-event
`GET /services/events/tasks/ts-test-event`

#### Sched Tasks - batchTest
`GET /services/events/tasks/batchTest`

#### Sched Tasks - IR-Image
`POST /services/events/tasks/IR-Image`

Corps :
```json
{
  "enabled": true,
  "action": {
    "type": "Rest",
    "method": "POST",
    "url": "/api/rest/v2/services/machine-learning/thermal-sensor/save-irframe",
    "body": "{\"IR-FRAME\": 0}"
  },
  "triggers": {
    "trigger-1": {
      "type": "OnChange",
      "path": "/services/bacnet/local/objects/analog-values/6"
    }
  },
  "recipients": {
    "mqtt": {}
  }
}
```

#### Sched Tasks - MyTask
`POST /services/events/tasks/MyTask`

Corps :
```json
{
  "enabled": true,
  "action": {
    "type": "Rest",
    "method": "GET",
    "url": "/api/rest/v2/services/bacnet/local/objects/analog-values/1",
    "body": "{\"present-value\": 0}"
  },
  "triggers": {
    "trigger-1": {
      "type": "OnChange",
      "path": "/services/bacnet/local/objects/analog-values/1"
    },
    "trigger-2": {
      "type": "Interval",
      "cron-expression": "*/10 * * * * ?"
    }
  },
  "recipients": {
    "iot-hub": {}
  }
}
```

#### Sched Tasks - RPM
`POST /services/events/tasks/rpm`

Corps :
```json
{
  "enabled": true,
  "action": {
    "type": "Rest",
    "method": "POST",
    "url": "/api/rest/v2/services/bacnet/local/objects/read-property-multiple",
    "body": "{\r\n  \"encode\": \"text\",\r\n  \"property-references\": [\r\n    {\r\n …(259 caractères)"
  },
  "triggers": {
    "trigger-1": {
      "type": "OnChange",
      "path": "/services/bacnet/local/objects/analog-values/1"
    },
    "trigger-2": {
      "type": "Interval",
      "cron-expression": "*/45 * * * * ?"
    }
  },
  "recipients": {
    "lxr-smtp": {}
  }
}
```

#### Sched Tasks - ts-test-event
`POST /services/events/tasks/ts-test-event`

Corps :
```json
{
  "enabled": true,
  "action": {
    "type": "Rest",
    "method": "GET",
    "url": "/api/rest/v2/services/bacnet/local/objects/analog-values/1",
    "body": "{\"present-value\": 0}"
  },
  "triggers": {
    "trigger-1": {
      "type": "OnChange",
      "path": "/services/bacnet/local/objects/analog-values/1"
    },
    "trigger-2": {
      "type": "Interval",
      "cron-expression": "*/10 * * * * ?"
    }
  },
  "recipients": {
    "ts-test": {}
  }
}
```

#### Sched Tasks - batchTest
`POST /services/events/tasks/batchTask`

Corps :
```json
{
  "enabled": true,
  "action": {
    "type": "Rest",
    "method": "POST",
    "url": "/api/rest/v2/batch",
    "body": "{\r\n    \"requests\":[\r\n        {\r\n            \"id\": \"1\",\r\n    …(700 caractères)"
  },
  "triggers": {
    "trigger-1": {
      "type": "Interval",
      "cron-expression": "30 * * * * * ?"
    }
  },
  "recipients": {
    "batch-test": {}
  }
}
```

#### Sched Tasks - batchTest2
`POST /services/events/tasks/batchTask`

Corps :
```json
{
  "enabled": true,
  "action": {
    "type": "Rest",
    "method": "POST",
    "url": "/api/rest/v2/batch",
    "body": {
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
  },
  "triggers": {
    "trigger-1": {
      "type": "Interval",
      "cron-expression": "*/30 * * * * ?"
    }
  },
  "recipients": {
    "batch-test": {}
  }
}
```

#### Sched Tasks - MQTTTask
`POST /services/events/tasks/MQTTTask`

Corps :
```json
{
  "enabled": true,
  "action": {
    "type": "Rest",
    "method": "GET",
    "url": "/api/rest/v2/services/bacnet/local/objects/analog-values/1",
    "body": "{\"present-value\": 0}"
  },
  "triggers": {
    "trigger-1": {
      "type": "OnChange",
      "min-time": 10.0,
      "path": "/services/bacnet/local/objects/analog-values/1"
    },
    "trigger-2": {
      "type": "Interval",
      "cron-expression": "*/45 * * * * ?"
    }
  },
  "recipients": {
    "lxr-mqtt": {}
  }
}
```

#### Sched Tasks - emqx01-ws1
`POST /services/events/tasks/emqx01-ws1`

Corps :
```json
{
  "enabled": true,
  "action": {
    "type": "Rest",
    "method": "GET",
    "url": "/api/rest/v2/services/bacnet/local/objects/analog-values/1"
  },
  "triggers": {
    "trigger-1": {
      "type": "OnChange",
      "min-time": 10.0,
      "path": "/services/bacnet/local/objects/analog-values/1"
    },
    "trigger-2": {
      "type": "Interval",
      "cron-expression": "*/45 * * * * ?"
    }
  },
  "recipients": {
    "lxr-wsl1-emqx01": {}
  }
}
```

#### Sched Tasks - emqx01-ws1 v2
`POST /services/events/tasks/emqx01-ws1`

Corps :
```json
{
  "enabled": true,
  "action": {
    "type": "Rest",
    "method": "GET",
    "url": "/api/rest/v2/services/bacnet/remote/devices/222002?$select=objects($select=*($select=*($select=present-value,persisted)))"
  },
  "triggers": {
    "trigger-1": {
      "type": "Interval",
      "cron-expression": "*/45 * * * * ?"
    }
  },
  "recipients": {
    "lxr-wsl1-emqx01": {}
  }
}
```

#### Sched Tasks - lxr-event2
`POST /services/events/tasks/lxr-event2`

Corps :
```json
{
  "enabled": true,
  "action": {
    "type": "Rest",
    "method": "GET",
    "url": "/api/rest/v2/services/bacnet/local/objects?$select=analog-values($select=*($select=object-name,present-value))&$select=binary-values($select=*($select=object-name,present-value))"
  },
  "triggers": {
    "trigger-1": {
      "type": "Interval",
      "cron-expression": "*/45 * * * * ?"
    }
  },
  "recipients": {
    "lxr": {}
  }
}
```

#### Sched Tasks - Packages
`POST /services/events/tasks/packages`

Corps :
```json
{
  "enabled": true,
  "action": {
    "type": "Rest",
    "method": "POST",
    "url": "/api/rest/v2/services/packages/download",
    "body": "{\r\n    \"url\": \"https://portal.dc8292.link/s/yCwWqHJeQpq2B9K/download/eclypse-bacnet-2.5.2+master.24325.1.dcar\",\r\n    \"sync\": false\r\n}"
  },
  "triggers": {
    "trigger-1": {
      "type": "Interval",
      "cron-expression": "*/45 * * * * ?"
    }
  },
  "recipients": {
    "DCTS": {}
  }
}
```

#### Sched Tasks - SMTPTask
`POST /services/events/tasks/SMTPTask`

Corps :
```json
{
  "enabled": true,
  "action": {
    "type": "Rest",
    "method": "GET",
    "url": "/api/rest/v2/services/logging/logs"
  },
  "triggers": {
    "trigger-1": {
      "type": "Interval",
      "cron-expression": "*/30 * * * * ?"
    }
  },
  "recipients": {
    "lxr-smtp": {}
  }
}
```

#### Sched Tasks - MyTask
`DELETE /services/events/tasks/MyTask`

#### Sched Tasks - RPM
`DELETE /services/events/tasks/rpm`

#### Sched Tasks - IR-Image
`DELETE /services/events/tasks/IR-Image`

#### Sched Tasks - ts-test-event
`DELETE /services/events/tasks/ts-test-event`

#### Sched Tasks - batchTest
`DELETE /services/events/tasks/batchTask`

#### Sched Tasks - MQTTTask
`DELETE /services/events/tasks/MQTTTask`

#### Sched Tasks - emqx01-ws1
`DELETE /services/events/tasks/emqx01-ws1`

#### Sched Tasks - lxr-event2
`DELETE /services/events/tasks/lxr-event2`

#### Sched Tasks - packages
`DELETE /services/events/tasks/packages`

#### Sched Tasks - SMTPTask
`DELETE /services/events/tasks/SMTPTask`

## Bindings

#### Bindings
`GET /services/events/bindings`

#### New Binding
`POST /services/events/bindings/test`

Corps :
```json
{
  "key": "test",
  "sync-a-to-b": {
    "options": {
      "priorities": true,
      "write-priority": 14,
      "value": false,
      "out-of-service": true
    },
    "triggers": {
      "1": {
        "key": "1",
        "min-sync-time": 0.0,
        "type": "OnChange"
      }
    }
  },
  "element-b": "/services/bacnet/remote/devices/15024/objects/analog-values/53",
  "element-a": "/services/bacnet/local/objects/analog-values/1020",
  "initialize": "b-to-a",
  "type": "ControlElement",
  "sync-b-to-a": {
    "options": {
      "priorities": true,
      "write-priority": 14,
      "value": false,
      "out-of-service": true
    },
    "triggers": {
      "1": {
        "key": "1",
        "min-sync-time": 0.0,
        "type": "OnChange"
      }
    }
  }
}
```

#### Remove Binding
`DELETE /services/events/bindings/test`
