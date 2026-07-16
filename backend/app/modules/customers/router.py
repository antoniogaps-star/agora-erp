"""Endpoints REST de clientes."""

from uuid import UUID

from fastapi import APIRouter, status

from app.modules.customers import service
from app.modules.customers.models import Customer
from app.modules.customers.schemas import CustomerCreate, CustomerRead
from app.shared.deps import Claims, TenantSession

router = APIRouter(prefix="/customers", tags=["customers"])


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
