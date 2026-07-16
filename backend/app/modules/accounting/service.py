"""Lógica de contabilidad: asientos y balance."""

from datetime import date
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.accounting.models import LedgerEntry
from app.modules.accounting.schemas import Balance


async def create_entry(
    session: AsyncSession, *, tenant_id: UUID, entry_type: str, concept: str,
    amount_cents: int, occurred_on: date
) -> LedgerEntry:
    entry = LedgerEntry(
        tenant_id=tenant_id,
        entry_type=entry_type,
        concept=concept,
        amount_cents=amount_cents,
        occurred_on=occurred_on,
    )
    session.add(entry)
    await session.flush()
    return entry


async def list_entries(session: AsyncSession) -> list[LedgerEntry]:
    rows = await session.execute(
        select(LedgerEntry)
        .where(LedgerEntry.is_deleted.is_(False))
        .order_by(LedgerEntry.occurred_on.desc())
    )
    return list(rows.scalars().all())


async def balance(session: AsyncSession) -> Balance:
    async def _sum(entry_type: str) -> int:
        total = await session.scalar(
            select(func.coalesce(func.sum(LedgerEntry.amount_cents), 0)).where(
                LedgerEntry.entry_type == entry_type,
                LedgerEntry.is_deleted.is_(False),
            )
        )
        return int(total or 0)

    income = await _sum("income")
    expense = await _sum("expense")
    return Balance(income_cents=income, expense_cents=expense, balance_cents=income - expense)
