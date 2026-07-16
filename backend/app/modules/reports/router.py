"""Endpoints REST de reportes (solo lectura)."""

from fastapi import APIRouter

from app.modules.reports import service
from app.modules.reports.schemas import Summary, TopProduct
from app.shared.deps import Claims, TenantSession

router = APIRouter(prefix="/reports", tags=["reports"])


@router.get("/summary", response_model=Summary)
async def get_summary(session: TenantSession, claims: Claims) -> Summary:
    return await service.summary(session)


@router.get("/top-products", response_model=list[TopProduct])
async def get_top_products(session: TenantSession, claims: Claims) -> list[TopProduct]:
    return await service.top_products(session)
