# API V2 — MQTT

Chemins relatifs à `https://<hôte>/api/rest/v2` sauf mention contraire. Auth : Basic. Voir [INDEX](../INDEX.md).

## Connections › Brokers › Publications

#### List Publications
`GET /services/mqtt/connections/secy1/publications`

#### Create Publications
`POST /services/mqtt/connections/secy1/publications`

Corps :
```json
{
  "Analog Value 3": {
    "key": "Analog Value 3",
    "qos": 0,
    "format-template": "",
    "topic": "bacnet/Analog_Value_3",
    "source": "/services/bacnet/local/objects/analog-values/3"
  },
  "Analog Value 4": {
    "key": "Analog Value 4",
    "qos": 0,
    "format-template": "",
    "topic": "bacnet/Analog_Value_4",
    "source": "/services/bacnet/local/objects/analog-values/4"
  },
  "Analog Value 5": {
    "key": "Analog Value 5",
    "qos": 0,
    "format-template": "",
    "topic": "bacnet/Analog_Value_5",
    "source": "/services/bacnet/local/objects/analog-values/5"
  },
  "Analog Value 6": {
    "key": "Analog Value 6",
    "qos": 0,
    "format-template": "",
    "topic": "bacnet/Analog_Value_6",
    "source": "/services/bacnet/local/objects/analog-values/6"
  },
  "Analog Value 1": {
    "key": "Analog Value 1",
    "qos": 0,
    "format-template": "",
    "topic": "bacnet/Analog_Value_1",
    "source": "/services/bacnet/local/objects/analog-values/1"
  },
  "Analog Value 2": {
    "key": "Analog Value 2",
    "qos": 0,
    "format-template": "",
    "topic": "bacnet/Analog_Value_2",
    "source": "/services/bacnet/local/objects/analog-values/2"
  },
  "Analog Value 10": {
    "key": "Analog Value 10",
    "qos": 0,
    "format-template": "",
    "topic": "bacnet/Analog_Value_10",
    "source": "/services/bacnet/local/objects/analog-values/10"
  },
  "Analog Value 7": {
    "key": "Analog Value 7",
    "qos": 0,
    "format-template": "",
    "topic": "bacnet/Analog_Value_7",
    "source": "/services/bacnet/local/objects/analog-values/7"
  },
  "Analog Value 8": {
    "key": "Analog Value 8",
    "qos": 0,
    "format-template": "",
    "topic": "bacnet/Analog_Value_8",
    "source": "/services/bacnet/local/objects/analog-values/8"
  },
  "Analog Value 9": {
    "key": "Analog Value 9",
    "qos": 0,
    "format-template": "",
    "topic": "bacnet/Analog_Value_9",
    "source": "/services/bacnet/local/objects/analog-values/9"
  }
}
```

#### Delete Publications
`DELETE /services/mqtt/connections/secy1/publications/Analog%20Value%203`

## Connections › Brokers

#### Broker
`GET /services/mqtt/connections/lxr-rs52-emqx2`

#### Create Broker-TCP
`POST /services/mqtt/connections/secy1`

Corps :
```json
{
  "key": "secy1",
  "broker-port": 1883,
  "max-inflight": 10,
  "lwt": {
    "retained": false,
    "qos": 0,
    "topic": "",
    "message": "",
    "enabled": false
  },
  "keep-alive-interval": 60,
  "clean-session": true,
  "enabled": true,
  "timeout": 30,
  "protocol": "Tcp",
  "root-topic": "secy1",
  "client-id": "r200-secy1",
  "broker-address": "127.0.0.1",
  "…": "1 autres clés (authentication…)"
}
```

#### Create Broker-WSS
`POST /services/mqtt/connections/lxr-rs52-emqx2`

Corps :
```json
{
  "key": "lxr-rs52-emqx2",
  "broker-port": 443,
  "max-inflight": 10,
  "lwt": {
    "retained": false,
    "qos": 0,
    "topic": "",
    "message": "",
    "enabled": false
  },
  "keep-alive-interval": 60,
  "clean-session": true,
  "enabled": true,
  "timeout": 30,
  "protocol": "Wss",
  "root-topic": "/lxr/secy045",
  "client-id": "lxr-jax-secy045",
  "broker-address": "mqtt.lhosting.link",
  "…": "1 autres clés (authentication…)"
}
```

#### Delete Broker
`DELETE /services/mqtt/connections/secy1`

## Connections

#### List Connections
`GET /services/mqtt/connections`

## MQTT

#### MQTT
`GET /services/mqtt`
