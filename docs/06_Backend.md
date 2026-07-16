# 06 · Backend

Framework: **FastAPI** (async) · Python 3.12+ · PostgreSQL vía **SQLAlchemy 2.0 + asyncpg**.

## Principios

- **Async de punta a punta** (I/O de red y base de datos no bloqueante).
- **Organización por módulos de negocio** (feature-first), no por capas técnicas globales.
- **La seguridad multi-tenant se aplica en la capa de datos** (RLS), no solo en la de servicio.

## Estructura

```
backend/
├── app/
│   ├── main.py                 # creación de la app, routers, middleware
│   ├── core/
│   │   ├── config.py           # settings por entorno (pydantic-settings)
│   │   ├── security.py         # JWT, hashing Argon2
│   │   └── logging.py
│   ├── db/
│   │   ├── session.py          # engine async, sessionmaker
│   │   ├── base.py             # Base declarativa + mixin de columnas estándar
│   │   └── rls.py              # helper: SET app.current_tenant
│   ├── middleware/
│   │   └── tenant.py           # extrae tenant_id del JWT → contexto de request
│   ├── modules/
│   │   ├── auth/               # router.py · schemas.py · service.py · models.py
│   │   ├── tenants/
│   │   └── users/
│   ├── sync/                   # router.py (push/pull) + service (esqueleto)
│   └── shared/                 # dependencias comunes, excepciones, paginación
├── alembic/
├── tests/
├── pyproject.toml
└── .env.example
```

## Capas por módulo

```
router.py    → HTTP: valida entrada, llama al service, formatea salida
schemas.py   → Pydantic v2: contratos de request/response
service.py   → lógica de negocio, orquesta repositorio/DB
models.py    → modelos SQLAlchemy (mapean a tablas)
```

## Inyección del tenant (pieza crítica)

Flujo por cada request autenticado:
1. Middleware/dependencia lee el `access_token`, valida firma y expiración.
2. Extrae `tenant_id` y `role` de los claims.
3. Al abrir la sesión de base de datos, ejecuta `SET LOCAL app.current_tenant = <tenant_id>`.
4. A partir de ahí, **RLS filtra automáticamente** todas las consultas.

> El `tenant_id` **jamás** se toma de un parámetro, header o body del cliente — solo del token verificado. Esto cierra la vía principal de fuga entre empresas.

## Configuración por entorno

- `pydantic-settings` lee de variables de entorno / `.env`.
- Entornos: `local`, `test`, `staging`, `production`.
- Secretos (claves JWT, credenciales DB) nunca en el repo — ver [09_Seguridad](09_Seguridad.md).

## Migraciones

- **Alembic** con soporte async.
- Cada migración de tabla de tenant incluye: columnas estándar + `ENABLE ROW LEVEL SECURITY` + `CREATE POLICY`.

## Calidad

- `ruff` (lint + formato), `mypy` (tipos), `pytest` + `pytest-asyncio`.
- Ver estrategia completa en [11_Pruebas](11_Pruebas.md).

Ver también: [04_Base_Datos](04_Base_Datos.md), [05_API](05_API.md).
