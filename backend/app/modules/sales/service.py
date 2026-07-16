"""Lógica de ventas. Vender crea una Sale y un StockMovement de -cantidad."""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.products import service as products_service
from app.modules.products.models import Product, StockMovement
from app.modules.sales.models import Sale
from app.shared.errors import api_error


async def create_sale(
    session: AsyncSession, *, tenant_id: UUID, product_id: UUID, quantity: int
) -> Sale:
    product = await session.get(Product, product_id)
    if product is None or product.is_deleted:
        raise api_error(404, "PRODUCT_NOT_FOUND", "Producto no encontrado")

    # En el canal online (web) validamos stock suficiente. El canal offline (móvil)
    # registra la venta localmente y la reconcilia al sincronizar.
    current_stock = await products_service.stock_of(session, product_id)
    if current_stock < quantity:
        raise api_error(409, "INSUFFICIENT_STOCK", "Stock insuficiente para la venta")

    sale = Sale(
        tenant_id=tenant_id,
        product_id=product_id,
        quantity=quantity,
        unit_price_cents=product.price_cents,
        total_cents=product.price_cents * quantity,
    )
    session.add(sale)
    session.add(
        StockMovement(
            tenant_id=tenant_id, product_id=product_id, delta=-quantity, reason="sale"
        )
    )
    await session.flush()
    return sale


async def list_sales(session: AsyncSession) -> list[Sale]:
    rows = await session.execute(
        select(Sale).where(Sale.is_deleted.is_(False)).order_by(Sale.created_at.desc())
    )
    return list(rows.scalars().all())
