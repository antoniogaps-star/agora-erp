# Ágora ERP

ERP **multiempresa**, **offline-first**, **seguro**, **escalable** y **preparado para SaaS**.

| App | Stack | Carpeta |
|-----|-------|---------|
| Backend / API | FastAPI + PostgreSQL | [`backend/`](backend/) |
| Panel Web | React + TypeScript (Vite) | [`web/`](web/) |
| App Móvil | Flutter + SQLite | [`mobile/`](mobile/) |
| Contratos compartidos | TypeScript / JSON Schema | [`packages/shared/`](packages/shared/) |
| Infraestructura local | Docker Compose | [`infra/`](infra/) |

## Documentación

La especificación vive en [`docs/`](docs/). **Léela antes de escribir código.** Empieza por [`docs/00_Indice.md`](docs/00_Indice.md).

Las decisiones de arquitectura están registradas en [`docs/adr/`](docs/adr/).

## Estado del proyecto

**Etapa 0 — Base (scaffolding).** Estructura del monorepo y autenticación multi-tenant. Sin módulos de negocio todavía. Ver el plan en [`docs/10_MVP.md`](docs/10_MVP.md).

## Arranque rápido (desarrollo)

Requisitos: Docker, Python 3.12+, Node 20+, Flutter 3.x.

```bash
# 1. Levantar PostgreSQL local
docker compose -f infra/docker-compose.yml up -d

# 2. Backend  (ver backend/README.md)
# 3. Web      (ver web/README.md)
# 4. Móvil    (ver mobile/README.md)
```

> Cada app tiene su propio README con instrucciones detalladas. El monorepo mantiene las apps autónomas: no hay build system global.
