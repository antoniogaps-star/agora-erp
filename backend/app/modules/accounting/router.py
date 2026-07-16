"""Endpoints REST de contabilidad."""

from uuid import UUID

from fastapi import APIRouter, status

from app.modules.accounting import service
from app.modules.accounting.models import LedgerEntry
from app.modules.accounting.schemas import Balance, LedgerEntryCreate, LedgerEntryRead
from app.shared.deps import Claims, TenantSession

router = APIRouter(prefix="/accounting", tags=["accounting"])


@router.get("/entries", response_model=list[LedgerEntryRead])
async def list_entries(session: TenantSession, claims: Claims) -> list[LedgerEntry]:
    return await service.list_entries(session)


@router.post("/entries", response_model=LedgerEntryRead, status_code=status.HTTP_201_CREATED)
async def create_entry(
    data: LedgerEntryCreate, session: TenantSession, claims: Claims
) -> LedgerEntry:
    return await service.create_entry(
        session,
        tenant_id=UUID(claims["tenant_id"]),
        entry_type=data.entry_type,
        concept=data.concept,
        amount_cents=data.amount_cents,
        occurred_on=data.occurred_on,
    )


@router.get("/balance", response_model=Balance)
async def get_balance(session: TenantSession, claims: Claims) -> Balance:
    return await service.balance(session)
