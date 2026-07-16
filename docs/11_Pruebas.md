# 11 · Pruebas

Estrategia de calidad. El objetivo no es cobertura por cobertura, sino **proteger las decisiones críticas**: aislamiento entre empresas y correcta sincronización offline.

## Pirámide de pruebas

```
        e2e (pocas, flujos clave multi-plataforma)
      integración (API + DB real con RLS)
   unitarias (lógica de servicios, sync, validación)
```

## Backend (FastAPI + PostgreSQL)

- **Unitarias:** servicios, seguridad (JWT, Argon2), lógica de sync. `pytest` + `pytest-asyncio`.
- **Integración:** endpoints contra una **base Postgres real** (no SQLite) para que **RLS se ejerza de verdad**. Cliente `httpx`.
- **Tests de aislamiento de tenants (obligatorios y bloqueantes):**
  - Crear tenant A y tenant B con datos.
  - Autenticado como A, intentar leer/editar datos de B → debe fallar / devolver vacío.
  - Verificar que a nivel SQL, con `app.current_tenant = A`, no se ven filas de B.
  > Si estos tests no pasan, no se despliega. Son el guardián de la decisión multi-tenant.

## Sincronización (transversal)

- **Push idempotente:** reenviar el mismo cambio (`id` + `version`) no duplica.
- **Conflicto last-write-wins:** dado el mismo registro editado en dos orígenes, gana el `updated_at` mayor.
- **Tombstones:** un borrado se propaga en el `pull`.
- **Cursor de pull:** un cliente solo recibe deltas posteriores a su cursor.

## App Móvil (Flutter)

- **Unitarias:** DAOs de Drift, cola outbox, reconciliación.
- **Widget tests:** pantallas clave (login, lista/edición de clientes).
- **Offline:** simular sin red → operar → reconectar → verificar sincronización.

## Panel Web (React + TS)

- **Unitarias/componentes:** `vitest` + Testing Library.
- **Validación de contratos:** esquemas `zod` contra respuestas de la API.

## Integración continua (CI)

GitHub Actions, un job por app:
1. Lint (`ruff` / `eslint` / `flutter analyze`).
2. Tipos (`mypy` / `tsc` / análisis Dart).
3. Tests (incluye levantar Postgres para los de integración/aislamiento).

Un merge a la rama principal requiere CI en verde.

## Datos de prueba

- Fábricas/fixtures que siempre crean datos **con `tenant_id`** para no falsear el aislamiento.
- Semillas mínimas: 2 tenants, varios usuarios y clientes por tenant.

Ver también: [09_Seguridad](09_Seguridad.md), [10_MVP](10_MVP.md).
