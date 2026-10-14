# API V2 — Security (Users)

Chemins relatifs à `https://<hôte>/api/rest/v2` sauf mention contraire. Auth : Basic. Voir [INDEX](../INDEX.md).

## Users › Preferences

#### List - Current User
`GET /services/security/current-user`

#### List Pref General - Current User
`GET /services/security/current-user/files/web-interface/general.json?content=media`

#### List Pref General - Username
`GET /services/security/current-user/files/web-interface/general.json?content=media&username=Distech`

#### List Pref Schedules - Username
`GET /services/security/current-user/files/web-interface/schedules.json?content=media&username=Distech`

#### List Pref Schedules - Current User
`GET /services/security/current-user/files/web-interface/schedules.json?content=media`

#### Modify Pref General - Username
`POST /services/security/current-user/files/web-interface/general.json?content=media&username=Distech&overwrite=true`

Corps :
```json
{
  "theme": "distechDark",
  "measurementSystem": "us",
  "sessionTimeout": "21",
  "enableSessionCheck": false
}
```

#### Modify Pref General - Current User
`POST /services/security/current-user/files/web-interface/general.json?content=media&overwrite=true`

Corps :
```json
{
  "theme": "distechDark",
  "measurementSystem": "us",
  "sessionTimeout": "21",
  "enableSessionCheck": false
}
```

#### Modify Pref Schedules - Username
`POST /services/security/current-user/files/web-interface/schedules.json?content=media&username=Distech&overwrite=true`

Corps :
```json
{
  "selectedSchedule": "test-name",
  "showWeekends": false,
  "firstDayOfWeekSunday": false,
  "timeFormat24h": true,
  "showSummary": false,
  "specialContentMaximized": true
}
```

#### Modify Pref Schedules - Current User
`POST /services/security/current-user/files/web-interface/schedules.json?content=media&overwrite=true`

Corps :
```json
{
  "selectedSchedule": "test-name",
  "showWeekends": false,
  "firstDayOfWeekSunday": false,
  "timeFormat24h": true,
  "showSummary": false,
  "specialContentMaximized": true
}
```

## Users

#### List Users
`GET /services/security/users`

#### List Users (Filtered)
`GET /services/security/users?$select=*($select="")`

#### Create User
`POST /services/security/users/testUser`

Corps :
```json
{
  "key": "testUser",
  "origin": "local",
  "roles": [
    "admin"
  ],
  "language": "en",
  "units": "Us",
  "reset-password": false,
  "enabled": true,
  "first-name": "testFirstName",
  "phone": null,
  "email": "test@test.test",
  "homepage": null,
  "last-name": "testLastName",
  "…": "2 autres clés (policy, password…)"
}
```

#### Set-Password User
`POST /services/security/users/dctest`

Corps :
```json
{
  "password": "<masqué>",
  "reset-password": false
}
```

#### Set-Password Initial
`POST https://<hôte>/auth/local/password`

Corps :
```json
{
  "password": "<masqué>"
}
```

#### Read User
`GET /services/security/users/rlastinger`

#### Delete User
`DELETE /services/security/users/testUser`

## Authorization › Roles

#### List Roles
`GET /services/security/authorization/roles`

## Policies

#### List Security Policies
`GET /services/security/policies/default`

#### List Security Policies Copy
`POST /services/security/policies/default`

Corps :
```json
{
  "key": "default",
  "lockout-enabled": false,
  "lockout-max-attempts": 6,
  "min-numbers": 0,
  "min-characters": 8,
  "min-upper-case": 0,
  "min-lower-case": 0,
  "lockout-duration": 60000,
  "min-special": 0
}
```

## Security (Users)

#### List Security
`GET /services/security`
