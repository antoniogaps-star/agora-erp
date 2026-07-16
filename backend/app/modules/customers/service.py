"""Lógica de clientes (CRUD básico, tenant-scoped por RLS)."""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.customers.models import Customer
from app.shared.errors import api_error


async def create_customer(
    session: AsyncSession, *, tenant_id: UUID, name: str, email: str | None, phone: str | None
) -> Customer:
    customer = Customer(tenant_id=tenant_id, name=name, email=email, phone=phone)
    session.add(customer)
    await session.flush()
    return customer


async def list_customers(session: AsyncSession) -> list[Customer]:
    rows = await session.execute(
        select(Customer).where(Customer.is_deleted.is_(False)).order_by(Customer.name)
    )
    return list(rows.scalars().all())


async def delete_customer(session: AsyncSession, customer_id: UUID) -> None:
    customer = await session.get(Customer, customer_id)
    if customer is None or customer.is_deleted:
        raise api_error(404, "CUSTOMER_NOT_FOUND", "Cliente no encontrado")
    customer.is_deleted = True
    customer.version += 1
    await session.flush()
