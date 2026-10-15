# API V2 — Email

Chemins relatifs à `https://<hôte>/api/rest/v2` sauf mention contraire. Auth : Basic. Voir [INDEX](../INDEX.md).

## Email

#### List Accounts
`GET /services/email/accounts`

#### Create Account
`POST /services/email/accounts/DC-Test2`

Corps :
```json
{
  "key": "DC Test2",
  "connection-timeout": 180,
  "hostname": "hostname",
  "password": "<masqué>",
  "port": 587,
  "from": "dc-test@bsystems",
  "connection-security": "StartTls",
  "enabled": true,
  "authentication": true,
  "username": "dc-test@bsystems"
}
```

#### Delete Account
`DELETE /services/email/accounts/DC-Test2`
