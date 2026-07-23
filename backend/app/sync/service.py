"""Motor de sincronización.

Políticas por entidad (ver ADR-003 y ADR-005):
- product: last-write-wins por `updated_at`. Si el cambio entrante es más antiguo que
  lo que hay en el servidor, se responde `conflict` con la versión del servidor.
- stock_movement y sale: append-only e inmutables → nunca hay conflicto; reaplicar el
  mismo id es idempotente (no duplica). Así dos ventas concurrentes offline se acumulan.

pull devuelve, por entidad, las filas con `updated_at` posterior al cursor del cliente
(incluidos tombstones), y un nuevo cursor.
"""

from datetime import UTC, date, datetime
from typing import Any
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.accounting.models import LedgerEntry
from app.modules.customers.models import Customer
from app.modules.products.models import Product, StockMovement
from app.modules.sales.models import Sale
from app.sync.schemas import Change, ChangeResult, PullResponse, PushRequest, PushResponse

SUPPORTED_ENTITIES = {"product", "stock_movement", "sale", "customer", "ledger_entry"}


# ── Serialización modelo → data ──────────────────────────────
def _product_data(p: Product) -> dict[str, Any]:
    return {"name": p.name, "price_cents": p.price_cents}


def _movement_data(m: StockMovement) -> dict[str, Any]:
    return {"product_id": str(m.product_id), "delta": m.delta, "reason": m.reason}


def _sale_data(s: Sale) -> dict[str, Any]:
    return {
        "product_id": str(s.product_id),
        "quantity": s.quantity,
        "unit_price_cents": s.unit_price_cents,
        "total_cents": s.total_cents,
    }


def _customer_data(c: Customer) -> dict[str, Any]:
    return {"name": c.name, "email": c.email, "phone": c.phone}


def _ledger_data(e: LedgerEntry) -> dict[str, Any]:
    return {
        "entry_type": e.entry_type,
        "concept": e.concept,
        "amount_cents": e.amount_cents,
        "occurred_on": e.occurred_on.isoformat(),
    }


# ── PUSH ─────────────────────────────────────────────────────
async def push(session: AsyncSession, tenant_id: UUID, payload: PushRequest) -> PushResponse:
    results: list[ChangeResult] = []
    for change in payload.changes:
        if change.entity == "product":
            results.append(await _push_product(session, tenant_id, change))
        elif change.entity == "customer":
            results.append(await _push_customer(session, tenant_id, change))
        elif change.entity == "stock_movement":
            results.append(await _push_movement(session, tenant_id, change))
        elif change.entity == "sale":
            results.append(await _push_sale(session, tenant_id, change))
        elif change.entity == "ledger_entry":
            results.append(await _push_ledger(session, tenant_id, change))
        else:
            results.append(
                ChangeResult(id=change.id, entity=change.entity, status="unsupported")
            )
    return PushResponse(results=results)


async def _push_product(session: AsyncSession, tenant_id: UUID, ch: Change) -> ChangeResult:
    data = ch.data or {}
    existing = await session.get(Product, ch.id)
    if existing is None:
        session.add(
            Product(
                id=ch.id,
                tenant_id=tenant_id,
                name=data.get("name", ""),
                price_cents=data.get("price_cents", 0),
                is_deleted=(ch.op == "delete"),
                version=ch.version,
                updated_at=ch.updated_at,
            )
        )
        await session.flush()
        return ChangeResult(id=ch.id, entity="product", status="applied", server_version=ch.version)

    # Last-write-wins: gana el cambio con updated_at mayor o igual.
    if ch.updated_at < existing.updated_at:
        return ChangeResult(
            id=ch.id, entity="product", status="conflict", server_version=existing.version
        )
    existing.name = data.get("name", existing.name)
    existing.price_cents = data.get("price_cents", existing.price_cents)
    existing.is_deleted = ch.op == "delete"
    existing.version = ch.version
    existing.updated_at = ch.updated_at
    await session.flush()
    return ChangeResult(
        id=ch.id, entity="product", status="applied", server_version=existing.version
    )


async def _push_customer(session: AsyncSession, tenant_id: UUID, ch: Change) -> ChangeResult:
    data = ch.data or {}
    existing = await session.get(Customer, ch.id)
    if existing is None:
        session.add(
            Customer(
                id=ch.id,
                tenant_id=tenant_id,
                name=data.get("name", ""),
                email=data.get("email"),
                phone=data.get("phone"),
                is_deleted=(ch.op == "delete"),
                version=ch.version,
                updated_at=ch.updated_at,
            )
        )
        await session.flush()
        return ChangeResult(
            id=ch.id, entity="customer", status="applied", server_version=ch.version
        )

    if ch.updated_at < existing.updated_at:
        return ChangeResult(
            id=ch.id, entity="customer", status="conflict", server_version=existing.version
        )
    existing.name = data.get("name", existing.name)
    existing.email = data.get("email", existing.email)
    existing.phone = data.get("phone", existing.phone)
    existing.is_deleted = ch.op == "delete"
    existing.version = ch.version
    existing.updated_at = ch.updated_at
    await session.flush()
    return ChangeResult(
        id=ch.id, entity="customer", status="applied", server_version=existing.version
    )


async def _push_movement(session: AsyncSession, tenant_id: UUID, ch: Change) -> ChangeResult:
    if await session.get(StockMovement, ch.id) is not None:
        return ChangeResult(id=ch.id, entity="stock_movement", status="applied")
    data = ch.data or {}
    session.add(
        StockMovement(
            id=ch.id,
            tenant_id=tenant_id,
            product_id=UUID(data["product_id"]),
            delta=data["delta"],
            reason=data["reason"],
            version=ch.version,
            updated_at=ch.updated_at,
        )
    )
    await session.flush()
    return ChangeResult(id=ch.id, entity="stock_movement", status="applied")


async def _push_sale(session: AsyncSession, tenant_id: UUID, ch: Change) -> ChangeResult:
    if await session.get(Sale, ch.id) is not None:
        return ChangeResult(id=ch.id, entity="sale", status="applied")
    data = ch.data or {}
    session.add(
        Sale(
            id=ch.id,
            tenant_id=tenant_id,
            product_id=UUID(data["product_id"]),
            quantity=data["quantity"],
            unit_price_cents=data["unit_price_cents"],
            total_cents=data["total_cents"],
            version=ch.version,
            updated_at=ch.updated_at,
        )
    )
    await session.flush()
    return ChangeResult(id=ch.id, entity="sale", status="applied")


async def _push_ledger(session: AsyncSession, tenant_id: UUID, ch: Change) -> ChangeResult:
    """Asiento contable: last-write-wins con soporte de borrado (como customer/product).
    Así el dueño puede corregir o borrar un movimiento desde el móvil o la web."""
    data = ch.data or {}
    existing = await session.get(LedgerEntry, ch.id)
    if existing is None:
        session.add(
            LedgerEntry(
                id=ch.id,
                tenant_id=tenant_id,
                entry_type=data.get("entry_type", "income"),
                concept=data.get("concept", ""),
                amount_cents=data.get("amount_cents", 0),
                occurred_on=(
                    date.fromisoformat(data["occurred_on"])
                    if data.get("occurred_on")
                    else date.today()
                ),
                is_deleted=(ch.op == "delete"),
                version=ch.version,
                updated_at=ch.updated_at,
            )
        )
        await session.flush()
        return ChangeResult(
            id=ch.id, entity="ledger_entry", status="applied", server_version=ch.version
        )

    if ch.updated_at < existing.updated_at:
        return ChangeResult(
            id=ch.id, entity="ledger_entry", status="conflict", server_version=existing.version
        )
    existing.entry_type = data.get("entry_type", existing.entry_type)
    existing.concept = data.get("concept", existing.concept)
    existing.amount_cents = data.get("amount_cents", existing.amount_cents)
    if data.get("occurred_on"):
        existing.occurred_on = date.fromisoformat(data["occurred_on"])
    existing.is_deleted = ch.op == "delete"
    existing.version = ch.version
    existing.updated_at = ch.updated_at
    await session.flush()
    return ChangeResult(
        id=ch.id, entity="ledger_entry", status="applied", server_version=existing.version
    )


# ── PULL ─────────────────────────────────────────────────────
async def pull(session: AsyncSession, since: str | None) -> PullResponse:
    since_dt = datetime.fromisoformat(since) if since else None
    changes: list[Change] = []
    changes += await _pull(session, "product", Product, _product_data, since_dt)
    changes += await _pull(session, "customer", Customer, _customer_data, since_dt)
    changes += await _pull(session, "stock_movement", StockMovement, _movement_data, since_dt)
    changes += await _pull(session, "sale", Sale, _sale_data, since_dt)
    changes += await _pull(session, "ledger_entry", LedgerEntry, _ledger_data, since_dt)
    return PullResponse(changes=changes, cursor=datetime.now(UTC).isoformat())


async def _pull(
    session: AsyncSession, name: str, model: Any, data_fn: Any, since_dt: datetime | None
) -> list[Change]:
    query = select(model)
    if since_dt is not None:
        query = query.where(model.updated_at > since_dt)
    rows = (await session.execute(query)).scalars().all()
    return [
        Change(
            entity=name,
            id=row.id,
            op="delete" if row.is_deleted else "upsert",
            version=row.version,
            updated_at=row.updated_at,
            data=data_fn(row),
        )
        for row in rows
    ]
