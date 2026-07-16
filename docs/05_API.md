# 05 · API

Estilo: **REST sobre HTTPS**, JSON, con FastAPI. Documentación automática vía OpenAPI (`/docs`, `/openapi.json`).

## Convenciones

- **Versionado por URL:** todos los endpoints bajo `/api/v1/...`.
- **Nombres de recursos en plural:** `/api/v1/users`, `/api/v1/tenants`.
- **Autenticación:** header `Authorization: Bearer <access_token>` en todo endpoint protegido.
- **Identificadores:** UUID en todo el sistema.
- **Fechas:** ISO-8601 UTC (`timestamptz`).

## Formato de respuesta

Éxito:
```json
{ "data": { ... } }
```

Colección (paginada):
```json
{ "data": [ ... ], "meta": { "page": 1, "page_size": 50, "total": 123 } }
```

Error (uniforme):
```json
{ "error": { "code": "VALIDATION_ERROR", "message": "…", "details": [ ... ] } }
```

Códigos HTTP: `200/201` éxito, `400` validación, `401` no autenticado, `403` sin permiso, `404` no encontrado, `409` conflicto, `422` entidad no procesable, `429` rate limit, `5xx` servidor.

## Autenticación

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/v1/auth/register` | Onboarding: crea tenant + usuario Owner |
| POST | `/api/v1/auth/login` | Devuelve `access_token` + `refresh_token` |
| POST | `/api/v1/auth/refresh` | Renueva el access token |
| POST | `/api/v1/auth/logout` | Revoca el refresh token |

El `access_token` (JWT) incluye claims: `sub` (user_id), `tenant_id`, `role`, `exp`. El backend deriva el tenant **del token**, nunca de un parámetro del cliente. Ver [09_Seguridad](09_Seguridad.md).

## Recursos del núcleo

| Método | Endpoint | Rol mínimo |
|--------|----------|-----------|
| GET | `/api/v1/users` | admin |
| POST | `/api/v1/users` | admin |
| GET/PATCH | `/api/v1/users/{id}` | admin |
| GET/PATCH | `/api/v1/tenants/me` | owner |

## Protocolo de sincronización (esqueleto)

Diseñado para clientes offline. Dos endpoints por dominio sincronizable:

### `POST /api/v1/sync/push`
El cliente envía sus cambios locales (creaciones/ediciones/borrados lógicos):
```json
{
  "changes": [
    { "entity": "customer", "id": "<uuid7>", "op": "upsert",
      "version": 3, "updated_at": "…", "data": { ... } },
    { "entity": "customer", "id": "<uuid7>", "op": "delete",
      "version": 4, "updated_at": "…" }
  ]
}
```
Respuesta: por cada cambio, `applied` | `conflict` (con la versión del servidor para reconciliar).

### `GET /api/v1/sync/pull?since=<cursor>`
Devuelve los cambios del servidor posteriores al cursor del cliente (deltas), incluidos tombstones:
```json
{ "changes": [ ... ], "cursor": "<nuevo_cursor>" }
```

**Resolución de conflictos:** *last-write-wins* por `updated_at` como política base; algunas entidades tendrán política específica en etapas futuras. El detalle vive en [07_App_Movil](07_App_Movil.md).

## Transversales

- **Rate limiting** por tenant/usuario (etapa posterior, pero contemplado).
- **Idempotencia** en `push` mediante `id` + `version` (reenviar no duplica).
- **Paginación** por `page`/`page_size` (o cursor en sync).

Ver también: [06_Backend](06_Backend.md).
