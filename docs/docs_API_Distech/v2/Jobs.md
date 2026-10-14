# API V2 — Jobs

Chemins relatifs à `https://<hôte>/api/rest/v2` sauf mention contraire. Auth : Basic. Voir [INDEX](../INDEX.md).

## Jobs

#### Jobs-CR
`GET https://{{cloudrelayHostname}}/api/v1/devices/{{deviceId}}/request`

En-têtes : `Remote-Query: {{basePath}}/services/jobs`, `Host: {{cloudrelayHostname}}`

#### Jobs
`GET /services/jobs`

Exemple de réponse (200 OK) :
```json
{
  "scavenger-period": 900,
  "jobs": {
    "0": {
      "key": "0",
      "owner": "",
      "start-time": 1695152211827,
      "end-time": 1695152221836,
      "description": "",
      "cancellable": true,
      "name": "discover-remote-devices",
      "progress": 100,
      "progress-message": "Discovery completed",
      "group": "",
      "status": "Completed"
    },
    "1": {
      "key": "1",
      "owner": "",
      "start-time": 1695152231537,
      "end-time": -1,
      "description": "",
      "cancellable": true,
      "name": "discover-remote-devices",
      "progress": 20,
      "progress-message": "8 seconds left to discovery",
      "group": "",
      "status": "Running"
    }
  }
}
```

#### JobCleanup-Period
`POST /services/jobs`

Corps :
```json
{
  "scavenger-period": 600
}
```

#### List Jobs
`GET /services/jobs/jobs`

Exemple de réponse (200 OK) :
```json
{
  "scavenger-period": 600,
  "jobs": {
    "0": {
      "key": "0",
      "owner": "",
      "start-time": 1695152211827,
      "end-time": 1695152221836,
      "description": "",
      "cancellable": true,
      "name": "discover-remote-devices",
      "progress": 100,
      "progress-message": "Discovery completed",
      "group": "",
      "status": "Completed"
    },
    "1": {
      "key": "1",
      "owner": "",
      "start-time": 1695152231537,
      "end-time": 1695152241540,
      "description": "",
      "cancellable": true,
      "name": "discover-remote-devices",
      "progress": 100,
      "progress-message": "Discovery completed",
      "group": "",
      "status": "Completed"
    }
  }
}
```

#### Read Job - 0
`GET /services/jobs/jobs/0`

#### Read Job - 1
`GET /services/jobs/jobs/1`

#### Read Job - 0 (alternative)
`GET /services/jobs?$select=jobs($select=0)&$select=jobs($select=1)`

#### CleanUp - Jobs
`POST /services/jobs/jobs/cleanup-completed-jobs`
