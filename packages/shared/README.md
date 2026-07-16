# packages/shared

Contratos compartidos entre backend, web y móvil: tipos de la API, esquema del protocolo de sincronización, constantes (roles, estados de tenant, códigos de error).

Objetivo: **fuente única de verdad** para evitar que las tres apps diverjan.

## Contenido previsto (se llena en los siguientes hitos)

- Enums/constantes: roles (`owner`/`admin`/`operator`/`viewer`), estados de tenant, códigos de error de la API.
- Formas de los payloads de `sync/push` y `sync/pull`.
- Idealmente derivados del OpenAPI del backend para el consumo en TypeScript.

Ver [`docs/05_API.md`](../../docs/05_API.md).
