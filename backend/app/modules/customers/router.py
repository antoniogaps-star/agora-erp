"""Endpoints REST de clientes."""

from uuid import UUID

from fastapi import APIRouter, Depends, status

from app.modules.billing.deps import require_active_subscription
from app.modules.customers import service
from app.modules.customers.models import Customer
from app.modules.customers.schemas import CustomerCreate, CustomerRead
from app.shared.deps import Claims, TenantSession

router = APIRouter(
    prefix="/customers",
    tags=["customers"],
    dependencies=[Depends(require_active_subscription)],
)


@router.get("", response_model=list[CustomerRead])
async def list_customers(session: TenantSession, claims: Claims) -> list[Customer]:
    return await service.list_customers(session)


@router.post("", response_model=CustomerRead, status_code=status.HTTP_201_CREATED)
async def create_customer(
    data: CustomerCreate, session: TenantSession, claims: Claims
) -> Customer:
    return await service.create_customer(
        session,
        tenant_id=UUID(claims["tenant_id"]),
        name=data.name,
        email=data.email,
        phone=data.phone,
    )


@router.delete("/{customer_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_customer(
    customer_id: UUID, session: TenantSession, claims: Claims
) -> None:
    await service.delete_customer(session, customer_id)
