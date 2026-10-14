# API V2 — Certificates

Chemins relatifs à `https://<hôte>/api/rest/v2` sauf mention contraire. Auth : Basic. Voir [INDEX](../INDEX.md).

## User Trusted

#### List User Trust
`GET /services/certificates/user-trusted`

## User Keychain

#### List User Keychain
`GET /services/certificates/user-keychain`

#### User Keychain Upload
`POST /services/certificates/user-keychain/store?password=<masqué>`

Corps (formdata) : ``

#### User Keychain Delete
`DELETE /services/certificates/user-keychain/ZuulTest3`

## Certificates

#### List Certificates
`GET /services/certificates`
