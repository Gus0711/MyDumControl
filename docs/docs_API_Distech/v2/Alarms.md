# API V2 — Alarms

Chemins relatifs à `https://<hôte>/api/rest/v2` sauf mention contraire. Auth : Basic. Voir [INDEX](../INDEX.md).

## Classes

#### Classes
`GET /services/alarms/classes`

#### Class
`POST /services/alarms/classes/class`

#### Add Recipient to Class
`POST /services/alarms/classes/bacnet Critical/recipients/mqtt-recipients`

## Recipients

#### Recipients
`GET /services/alarms/recipients`

#### MQTT Recipient
`POST /services/alarms/recipients/mqtt-recipient`

Corps :
```json
{
  "type": "MQTT",
  "connection": "HomeAssistant",
  "topic": "alarms/apex",
  "qos": 0,
  "parameters": {
    "days-of-week": [
      "Monday",
      "Tuesday",
      "Wednesday",
      "… 2 autres éléments"
    ],
    "time-range": {
      "start-time": "07:30:00",
      "end-time": "18:45:00"
    },
    "ack": {
      "enabled": true,
      "message": "Ack Time: {ackTime.formatTime()}\nAck User: {ackUser}\n Message: {message}\n Timestamp: {timestamp.formatTime()}\n Alarm Class: {alarmClass}"
    },
    "fault": {
      "enabled": true
    },
    "normal": {
      "enabled": true
    },
    "offnormal": {
      "enabled": true
    }
  }
}
```

#### Email Recipient
`POST /services/alarms/recipients/email-recipient`

Corps :
```json
{
  "key": "email-recipient",
  "addresses-to": [],
  "body-format": "TextPlain",
  "subject": "[{toState}, {ackState}] {message}",
  "addresses-cc": [],
  "from": {
    "address": null,
    "name": ""
  },
  "type": "Email",
  "addresses-bcc": [],
  "parameters": {
    "offnormal": {
      "message": "Message: {message}\nTimestamp: {timestamp.formatTime()}\nAlarm…(205 caractères)",
      "enabled": true
    },
    "time-range": {
      "start-time": "00:00:00",
      "end-time": "00:00:00"
    },
    "normal": {
      "message": "Message: {message}\nTimestamp: {timestamp.formatTime()}\nAlarm…(205 caractères)",
      "enabled": false
    },
    "ack": {
      "message": "Ack Time: {ackTime.formatTime()}\nAck User: {ackUser}\nMessage…(258 caractères)",
      "enabled": false
    },
    "fault": {
      "message": "Message: {message}\nTimestamp: {timestamp.formatTime()}\nAlarm…(205 caractères)",
      "enabled": true
    },
    "days-of-week": [
      "Sunday",
      "Monday",
      "Tuesday",
      "… 4 autres éléments"
    ]
  },
  "account": "Email Server"
}
```

#### IOT Recipient
`POST /services/alarms/recipients/iot-recipient`

Corps :
```json
{
  "type": "IotHub",
  "iot-connection": "Atrius Facilities",
  "initiator": "IOT Alarm",
  "qos": 0,
  "parameters": {
    "days-of-week": [
      "Monday",
      "Tuesday",
      "Wednesday",
      "… 2 autres éléments"
    ],
    "time-range": {
      "start-time": "07:30:00",
      "end-time": "18:45:00"
    },
    "ack": {
      "enabled": true,
      "message": "Ack Time: {ackTime.formatTime()}\nAck User: {ackUser}\n Message: {message}\n Timestamp: {timestamp.formatTime()}\n Alarm Class: {alarmClass}"
    },
    "fault": {
      "enabled": true
    },
    "normal": {
      "enabled": true
    },
    "offnormal": {
      "enabled": true
    }
  }
}
```

#### IOT Recipient
`DELETE /services/alarms/recipients/iot-recipient`

#### MQTT Recipient
`DELETE /services/alarms/recipients/mqtt-recipient`

#### Email Recipient
`DELETE /services/alarms/recipients/email-recipient`

## Alarms

#### Alarms
`GET /services/alarms`

#### Alarm-Table
`POST /services/alarms/get-alarm-table`
