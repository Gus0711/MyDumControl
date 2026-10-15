# API V2 — History

Chemins relatifs à `https://<hôte>/api/rest/v2` sauf mention contraire. Auth : Basic. Voir [INDEX](../INDEX.md).

## History

#### List Histories
`GET /services/history/groups/bacnet/histories`

#### List Histories - AV
`GET /services/history/groups/bacnet/histories/Analog%20Value%2077%20Trend%20Log`

#### Read History
`POST /services/history/groups/bacnet/histories/get-history`

Corps :
```json
{
  "history": "trend-log-100107",
  "delta": false,
  "time-range": "2022-01-01T00:00:00/2024-09-25T00:00:00",
  "interval": null,
  "delta-timestamps": "Leading"
}
```

#### Read History - AV
`POST /services/history/groups/bacnet/histories/get-history`

Corps :
```json
{
  "history": "Analog Value 77 Trend Log",
  "delta": false,
  "time-range": "2022-01-01T00:00:00/2024-09-25T00:00:00",
  "interval": null,
  "delta-timestamps": "Leading"
}
```

#### Read History - Table
`POST /services/history/groups/bacnet/histories/get-table`

Corps :
```json
{
  "history": "AV1TL",
  "time-range": "2022-12-21T00:00:00.000+01:00/2022-12-21T23:00:00.000+01:00",
  "limit": 0
}
```

#### Read History - Table AV
`POST /services/history/groups/bacnet/histories/get-table`

Corps :
```json
{
  "history": "Analog Value 77 Trend Log",
  "time-range": "2024-01-21T00:00:00.000+01:00/2024-09-21T23:00:00.000+01:00",
  "limit": 0
}
```
