# API V2 — Designer

Chemins relatifs à `https://<hôte>/api/rest/v2` sauf mention contraire. Auth : Basic. Voir [INDEX](../INDEX.md).

## Designer

#### List Projects
`GET https://<hôte>/designer/file?op=listProj`

#### File - Upload File
`POST https://<hôte>/designer/file?op=upload&bId=769340&path=proj%2Fblank%2FCopy_of_index.dg5`

En-têtes : `Cache-Control: no-cache`, `Postman-Token: <calculated when request is sent>`, `Content-Length: 0`, `Host: <calculated when request is sent>`, `User-Agent: PostmanRuntime/7.32.1`, `Accept-Encoding: gzip, deflate, br`, `Connection: keep-alive`

Corps (formdata) : ``

#### File - Upload Project
`POST https://<hôte>/designer/file?op=importProj&bId=769340`

En-têtes : `Cache-Control: no-cache`, `Postman-Token: <calculated when request is sent>`, `Content-Length: 0`, `Host: <calculated when request is sent>`, `User-Agent: PostmanRuntime/7.32.1`, `Accept-Encoding: gzip, deflate, br`, `Connection: keep-alive`
