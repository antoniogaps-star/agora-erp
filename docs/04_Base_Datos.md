# 04 · Base de Datos

Motor: **PostgreSQL 16+**. Este documento gobierna el modelo de datos y es de lectura obligatoria antes de tocar migraciones.

## Estrategia multi-tenant: base compartida + `tenant_id` + RLS

**Decisión (ADR-002):** todas las empresas comparten las mismas tablas; cada fila lleva `tenant_id`; el aislamiento lo impone **Row-Level Security (RLS)** de PostgreSQL.

**Por qué y no las alternativas:**
- *DB por tenant:* aislamiento máximo pero migraciones y costo operativo insostenibles a escala SaaS.
- *Schema por tenant:* complica migraciones y el motor de sincronización.
- *Tabla compartida + RLS (elegida):* una sola migración para todos, escala a miles de tenants, y el aislamiento **no depende de que el código recuerde filtrar** — Postgres lo fuerza.

**Cómo funciona el aislamiento:**
1. El backend abre la conexión y ejecuta `SET app.current_tenant = '<tenant_id del JWT>'`.
2. Cada tabla con datos de tenant tiene una *policy* RLS: `USING (tenant_id = current_setting('app.current_tenant')::uuid)`.
3. Cualquier `SELECT/INSERT/UPDATE/DELETE` queda automáticamente restringido a ese tenant.

## Convenciones para toda tabla de tenant

| Columna | Tipo | Propósito |
|---------|------|-----------|
| `id` | `uuid` (UUIDv7) | PK, **generada en el cliente** para permitir creación offline |
| `tenant_id` | `uuid` | Empresa dueña del registro (FK a `tenants`) |
| `created_at` | `timestamptz` | Alta |
| `updated_at` | `timestamptz` | Última modificación — clave para *last-write-wins* |
| `is_deleted` | `boolean` | Borrado lógico (tombstone) |
| `version` | `bigint` | Contador de versión para detección de conflictos |

> **UUIDv7 (ADR-003):** ordenable en el tiempo y generable sin coordinación, imprescindible para crear registros sin conexión sin colisiones. No usamos autoincrement.

## Tablas del núcleo (etapa base)

### `tenants`
| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | uuid | PK |
| `name` | text | Nombre de la empresa |
| `slug` | text | Identificador único legible |
| `plan` | text | `free` \| `pyme` \| `business` \| `enterprise` |
| `status` | text | `trial` \| `active` \| `suspended` \| `cancelled` |
| `created_at` / `updated_at` | timestamptz | |

> `tenants` **no** tiene RLS por `tenant_id` (es la tabla raíz); su acceso se controla en la capa de aplicación.

### `users`
| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | uuid | PK |
| `tenant_id` | uuid | FK → tenants (RLS aplica) |
| `email` | citext | Único **por tenant** |
| `password_hash` | text | Argon2 (ver [09_Seguridad](09_Seguridad.md)) |
| `role` | text | `owner` \| `admin` \| `operator` \| `viewer` |
| `is_active` | boolean | |
| `created_at` / `updated_at` | timestamptz | |

Índice único: `(tenant_id, email)`.

### `refresh_tokens` (o sesiones)
Almacena tokens de refresco emitidos, revocables. `tenant_id`, `user_id`, `token_hash`, `expires_at`, `revoked_at`.

### `sync_log` (esqueleto)
Bitácora de cambios para el motor de sincronización: `tenant_id`, `entity`, `entity_id`, `operation`, `version`, `changed_at`. Se detalla en [07_App_Movil](07_App_Movil.md).

## Diagrama de relaciones (núcleo)

```
tenants 1───∞ users
tenants 1───∞ refresh_tokens
tenants 1───∞ sync_log
(todas las tablas de negocio futuras: tenants 1───∞ <tabla>)
```

## Migraciones

- Herramienta: **Alembic**.
- Toda migración que cree una tabla de tenant debe, en el mismo paso: crear columnas estándar + habilitar RLS + crear la *policy*.
- Prohibido introducir tablas de negocio sin `tenant_id` y RLS.

Ver también: [06_Backend](06_Backend.md), [09_Seguridad](09_Seguridad.md).
