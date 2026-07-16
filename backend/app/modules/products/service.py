"""Lógica de inventario. El stock siempre se deriva de la suma de movimientos."""

from typing import Any
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.products.models import Product, StockMovement
from app.shared.errors import api_error


async def create_product(
    session: AsyncSession, *, tenant_id: UUID, name: str, price_cents: int, initial_stock: int
) -> Product:
    product = Product(tenant_id=tenant_id, name=name, price_cents=price_cents)
    session.add(product)
    await session.flush()
    if initial_stock:
        session.add(
            StockMovement(
                tenant_id=tenant_id,
                product_id=product.id,
                delta=initial_stock,
                reason="initial",
            )
        )
    await session.flush()
    return product


async def stock_of(session: AsyncSession, product_id: UUID) -> int:
    total = await session.scalar(
        select(func.coalesce(func.sum(StockMovement.delta), 0)).where(
            StockMovement.product_id == product_id,
            StockMovement.is_deleted.is_(False),
        )
    )
    return int(total or 0)


async def list_products_with_stock(session: AsyncSession) -> list[dict[str, Any]]:
    """Devuelve productos activos con su stock (suma de movimientos)."""
    stock_sum = func.coalesce(func.sum(StockMovement.delta), 0)
    rows = await session.execute(
        select(Product, stock_sum)
        .outerjoin(
            StockMovement,
            (StockMovement.product_id == Product.id) & StockMovement.is_deleted.is_(False),
        )
        .where(Product.is_deleted.is_(False))
        .group_by(Product.id)
        .order_by(Product.name)
    )
    return [
        {"id": p.id, "name": p.name, "price_cents": p.price_cents, "stock": int(stock)}
        for p, stock in rows.all()
    ]


async def delete_product(session: AsyncSession, product_id: UUID) -> None:
    """Borrado lógico (tombstone) — se propaga a los demás dispositivos al sincronizar."""
    product = await session.get(Product, product_id)
    if product is None or product.is_deleted:
        raise api_error(404, "PRODUCT_NOT_FOUND", "Producto no encontrado")
    product.is_deleted = True
    product.version += 1
    await session.flush()


async def adjust_stock(
    session: AsyncSession, *, tenant_id: UUID, product_id: UUID, delta: int, reason: str
) -> None:
    product = await session.get(Product, product_id)
    if product is None or product.is_deleted:
        raise api_error(404, "PRODUCT_NOT_FOUND", "Producto no encontrado")
    session.add(
        StockMovement(tenant_id=tenant_id, product_id=product_id, delta=delta, reason=reason)
    )
    await session.flush()
