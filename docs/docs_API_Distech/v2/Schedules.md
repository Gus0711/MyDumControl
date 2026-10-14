# API V2 — Schedules

Chemins relatifs à `https://<hôte>/api/rest/v2` sauf mention contraire. Auth : Basic. Voir [INDEX](../INDEX.md).

## Schedule 1

#### List Schedule 1
`GET /services/bacnet/local/objects/schedules/1`

#### Write Schedule 1 Name
`POST /services/bacnet/local/objects/schedules/1/object-name`

Corps :
```json
{
  "$value": "schedule 1 test"
}
```

#### Read Weekly
`GET /services/bacnet/local/objects/schedules/1/weekly-schedule`

#### Write Weekly
`POST /services/bacnet/local/objects/schedules/1/weekly-schedule`

Corps :
```json
{
  "sunday": {
    "transitions": {}
  },
  "saturday": {
    "transitions": {}
  },
  "tuesday": {
    "transitions": {
      "1": {
        "time": "05:00:00.00",
        "value": true,
        "key": "1"
      },
      "2": {
        "time": "06:30:00.00",
        "value": null,
        "key": "2"
      }
    }
  },
  "wednesday": {
    "transitions": {
      "1": {
        "time": "10:30:00.00",
        "value": true,
        "key": "1"
      },
      "2": {
        "time": "12:30:00.00",
        "value": null,
        "key": "2"
      }
    }
  },
  "thursday": {
    "transitions": {
      "1": {
        "time": "06:30:00.00",
        "value": true,
        "key": "1"
      },
      "2": {
        "time": "08:30:00.00",
        "value": null,
        "key": "2"
      }
    }
  },
  "friday": {
    "transitions": {}
  },
  "monday": {
    "transitions": {}
  }
}
```

#### Read Special-Events
`GET /services/bacnet/local/objects/schedules/1/special-events`

#### Write Special-Events
`POST /services/bacnet/local/objects/schedules/1/special-events`

Corps :
```json
{
  "1": {
    "event-priority": 16,
    "period": {
      "date": {
        "$value": "****-12-25-***",
        "day-of-week": null,
        "month": 12,
        "year": null,
        "day-of-month": 25
      },
      "type": "Date"
    },
    "name": "Christmas",
    "transitions": {
      "1": {
        "time": "07:00:00.00",
        "value": 1,
        "key": "1"
      },
      "2": {
        "time": "12:00:00.00",
        "value": null,
        "key": "2"
      }
    },
    "key": "1"
  },
  "2": {
    "event-priority": 16,
    "period": {
      "date": {
        "$value": "2023-07-4-***",
        "day-of-week": null,
        "month": 7,
        "year": 2023,
        "day-of-month": 4
      },
      "type": "Date"
    },
    "name": "July 4th",
    "transitions": {
      "1": {
        "time": "00:00:00.04",
        "value": 2,
        "key": "1"
      },
      "2": {
        "time": "23:59:59.00",
        "value": null,
        "key": "2"
      }
    },
    "key": "2"
  },
  "3": {
    "event-priority": 16,
    "period": {
      "date-range": {
        "end-date": {
          "$value": "2023-03-17-Fri",
          "day-of-week": 5,
          "month": 3,
          "year": 2023,
          "day-of-month": 17
        },
        "start-date": {
          "$value": "2023-03-12-Sun",
          "day-of-week": 7,
          "month": 3,
          "year": 2023,
          "day-of-month": 12
        }
      },
      "type": "DateRange"
    },
    "name": "Spring Break",
    "transitions": {},
    "key": "3"
  }
}
```

#### Remove Special-Events
`POST /services/bacnet/local/objects/schedules/1/special-events`

Corps :
```json
{
  "1": {
    "event-priority": 16,
    "period": {
      "date": {
        "$value": "****-12-25-***",
        "day-of-week": null,
        "month": 12,
        "year": null,
        "day-of-month": 25
      },
      "type": "Date"
    },
    "name": "Christmas",
    "transitions": {
      "1": {
        "time": "07:00:00.00",
        "value": 1,
        "key": "1"
      },
      "2": {
        "time": "12:00:00.00",
        "value": null,
        "key": "2"
      }
    },
    "key": "1"
  },
  "2": {
    "event-priority": 16,
    "period": {
      "date": {
        "$value": "2023-07-4-***",
        "day-of-week": null,
        "month": 7,
        "year": 2023,
        "day-of-month": 4
      },
      "type": "Date"
    },
    "name": "July 4th",
    "transitions": {
      "1": {
        "time": "00:00:00.04",
        "value": 2,
        "key": "1"
      },
      "2": {
        "time": "23:59:59.00",
        "value": null,
        "key": "2"
      }
    },
    "key": "2"
  }
}
```

## Schedules

#### List Schedules
`GET /services/bacnet/local/objects/schedules`
