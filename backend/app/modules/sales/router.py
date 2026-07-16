"""Endpoints REST de ventas (canal online, usado por el panel web)."""

from uuid import UUID

from fastapi import APIRouter, status

from app.modules.sales import service
from app.modules.sales.models import Sale
from app.modules.sales.schemas import SaleCreate, SaleRead
from app.shared.deps import Claims, TenantSession

router = APIRouter(prefix="/sales", tags=["sales"])


@router.get("", response_model=list[SaleRead])
async def list_sales(session: TenantSession, claims: Claims) -> list[Sale]:
    return await service.list_sales(session)


@router.post("", response_model=SaleRead, status_code=status.HTTP_201_CREATED)
async def create_sale(data: SaleCreate, session: TenantSession, claims: Claims) -> Sale:
    return await service.create_sale(
        session,
        tenant_id=UUID(claims["tenant_id"]),
        product_id=data.product_id,
        quantity=data.quantity,
    )
