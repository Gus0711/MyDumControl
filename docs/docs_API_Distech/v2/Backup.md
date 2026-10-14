# API V2 — Backup

Chemins relatifs à `https://<hôte>/api/rest/v2` sauf mention contraire. Auth : Basic. Voir [INDEX](../INDEX.md).

## Backups

#### List Backups
`GET /services/backup/backups`

#### Create Backup
`POST /services/backup/backups/create`

Corps :
```json
{
  "item": "name_of_the_backup",
  "option": "full"
}
```

#### Restore Backup
`POST /services/backup/backups/restore`

Corps :
```json
{
  "item": "pm_6",
  "excludes": "",
  "remove": "true"
}
```

#### Delete {backupKey}
`DELETE /services/backup/backups/test1`

## Backup

#### Download {backupKey}
`GET /services/backup/store/test1`

#### Upload Backup
`POST /services/backup/store`
