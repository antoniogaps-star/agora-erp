# 12 · Despliegue

Stack completo con Docker Compose: **PostgreSQL + backend (FastAPI) + web (nginx)**.

## Requisitos

- Docker + Docker Compose.

## Levantar todo

Desde la raíz del repositorio:

```bash
# 1. Genera un JWT_SECRET fuerte (el backend se niega a arrancar en producción sin él)
export JWT_SECRET=$(python -c "import secrets; print(secrets.token_urlsafe(64))")

# 2. Construye y levanta el stack
docker compose -f infra/docker-compose.prod.yml up --build -d
```

- **Web:** http://localhost:8080
- **API:** se sirve en el mismo origen bajo `/api/v1` (nginx la proxya al backend).

El backend, al arrancar, **aplica las migraciones** (`alembic upgrade head`) con el rol
dueño y luego sirve la API con el rol de aplicación (no superusuario, para que RLS aísle).

## Variables de entorno

| Variable | Descripción | Por defecto |
|----------|-------------|-------------|
| `JWT_SECRET` | Clave de firma JWT (>= 32 chars). **Obligatoria.** | — |
| `POSTGRES_PASSWORD` | Contraseña del rol dueño `agora` | `agora` (cámbiala en prod) |
| `CORS_ORIGINS` | Orígenes permitidos | `http://localhost:8080` |

> En producción real: usa un gestor de secretos para `JWT_SECRET` y `POSTGRES_PASSWORD`,
> y cambia la contraseña del rol de aplicación (`infra/postgres/initdb/01-app-role.sql`).

## Datos demo

Con el stack arriba:

```bash
docker compose -f infra/docker-compose.prod.yml exec backend python scripts/seed.py
```

Crea la empresa **michilin-demo** (`demo@michilin.com` / `password123`) con productos y
una venta, para probar el panel de inmediato.

## Arquitectura del despliegue

```
Navegador ──▶ web (nginx :8080)
                 │  /            → SPA (React)
                 │  /api/v1/...  → proxy ─▶ backend (:8000) ─▶ db (:5432)
```

La app móvil se conecta a la API por su URL pública:

```bash
flutter run --dart-define=API_URL=https://tu-dominio/api/v1
```

## Despliegue en Railway (PaaS)

El repo trae `railway.json` (apunta al Dockerfile del backend). Pasos:

1. En [railway.app](https://railway.app): **New Project → Deploy from GitHub repo** → `agora-erp`.
2. En el proyecto: **+ New → Database → PostgreSQL**.
3. En el servicio del backend → **Variables**:
   - `DATABASE_URL` = `${{Postgres.DATABASE_URL}}` (referencia a la base; el backend
     normaliza el esquema `postgres://` automáticamente)
   - `APP_ENV` = `production`
   - `JWT_SECRET` = una clave fuerte (>= 32 caracteres)
4. **Settings → Networking → Generate Domain** → obtienes `https://…up.railway.app`.
5. El arranque aplica migraciones solo; siembra datos con
   `python scripts/seed.py https://TU-DOMINIO.up.railway.app`.

> Nota RLS: en Railway hay un solo usuario de base (no superusuario). Como todas las
> tablas usan `FORCE ROW LEVEL SECURITY`, el aislamiento multi-tenant se mantiene
> aunque migraciones y app compartan usuario. No definas `MIGRATION_DATABASE_URL`.

La app móvil se regenera apuntando al dominio: Actions → **APK Android → Run
workflow** con `https://TU-DOMINIO.up.railway.app/api/v1`.

## Notas de producción (pendientes)

- TLS/HTTPS delante de nginx (terminación en un balanceador o certbot).
- Backups de la base de datos.
- Rotación de secretos y del rol de aplicación.

Ver también: [09_Seguridad](09_Seguridad.md), [06_Backend](06_Backend.md).
