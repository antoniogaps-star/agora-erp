"""Lógica (esqueleto) de sincronización.

Diseño para el motor real (etapa posterior):
- `push` recibe los cambios del cliente y, por cada entidad soportada, aplica el
  upsert/delete resolviendo conflictos según la política de esa entidad.
- `pull` devuelve los cambios del servidor posteriores al cursor del cliente (deltas).

Hoy no hay entidades de negocio registradas, así que push responde "unsupported" y pull
devuelve vacío. La sesión ya viene con el tenant fijado (RLS), por lo que cuando se
registren handlers quedarán acotados a la empresa automáticamente.
"""

from datetime import UTC, datetime

from sqlalchemy.ext.asyncio import AsyncSession

from app.sync.schemas import (
    ChangeResult,
    PullResponse,
    PushRequest,
    PushResponse,
)

# Entidades con handler de sincronización. Vacío en el esqueleto; se irá poblando
# (p. ej. "product", "sale", "stock_movement") con el motor real.
SUPPORTED_ENTITIES: set[str] = set()


async def push(session: AsyncSession, payload: PushRequest) -> PushResponse:
    results: list[ChangeResult] = []
    for change in payload.changes:
        if change.entity not in SUPPORTED_ENTITIES:
            results.append(
                ChangeResult(id=change.id, entity=change.entity, status="unsupported")
            )
            continue
        # TODO(motor-sync): aplicar upsert/delete por entidad y resolver conflictos.
    return PushResponse(results=results)


async def pull(session: AsyncSession, since: str | None) -> PullResponse:
    # TODO(motor-sync): devolver los cambios (incluidos tombstones) posteriores a `since`.
    return PullResponse(changes=[], cursor=since or datetime.now(UTC).isoformat())
