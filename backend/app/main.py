"""Punto de entrada de la API de Ágora ERP.

Hito 2: la app arranca, expone /health y verifica la conexión a la base de datos.
Los routers de negocio (auth, tenants, users, sync) se añaden en hitos posteriores.
"""

from contextlib import asynccontextmanager
from typing import Any

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.core.config import settings
from app.db.session import engine


@asynccontextmanager
async def lifespan(_: FastAPI) -> Any:
    # Espacio para inicialización/cierre de recursos en hitos futuros.
    yield
    await engine.dispose()


app = FastAPI(
    title="Ágora ERP API",
    version="0.0.1",
    description="ERP multiempresa, offline-first. Etapa base.",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health", tags=["health"])
async def health() -> dict[str, str]:
    """Liveness: la app responde."""
    return {"status": "ok", "env": settings.app_env}


@app.get("/health/db", tags=["health"])
async def health_db() -> dict[str, str]:
    """Readiness: la base de datos responde."""
    async with engine.connect() as conn:
        await conn.execute(text("SELECT 1"))
    return {"status": "ok", "database": "reachable"}
