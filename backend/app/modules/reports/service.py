"""Lógica de reportes: agregaciones de solo lectura (tenant-scoped por RLS)."""

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.customers.models import Customer
from app.modules.products.models import Product, StockMovement
from app.modules.reports.schemas import Summary, TopProduct
from app.modules.sales.models import Sale

LOW_STOCK_THRESHOLD = 5


async def summary(session: AsyncSession) -> Summary:
    sales_count = await session.scalar(
        select(func.count()).select_from(Sale).where(Sale.is_deleted.is_(False))
    )
    sales_total = await session.scalar(
        select(func.coalesce(func.sum(Sale.total_cents), 0)).where(Sale.is_deleted.is_(False))
    )
    products_count = await session.scalar(
        select(func.count()).select_from(Product).where(Product.is_deleted.is_(False))
    )
    customers_count = await session.scalar(
        select(func.count()).select_from(Customer).where(Customer.is_deleted.is_(False))
    )

    # Productos con stock (suma de movimientos) por debajo del umbral.
    stock = func.coalesce(func.sum(StockMovement.delta), 0).label("stock")
    low_stock_subq = (
        select(Product.id, stock)
        .outerjoin(
            StockMovement,
            (StockMovement.product_id == Product.id) & StockMovement.is_deleted.is_(False),
        )
        .where(Product.is_deleted.is_(False))
        .group_by(Product.id)
        .having(func.coalesce(func.sum(StockMovement.delta), 0) < LOW_STOCK_THRESHOLD)
        .subquery()
    )
    low_stock_count = await session.scalar(select(func.count()).select_from(low_stock_subq))

    return Summary(
        sales_count=int(sales_count or 0),
        sales_total_cents=int(sales_total or 0),
        products_count=int(products_count or 0),
        customers_count=int(customers_count or 0),
        low_stock_count=int(low_stock_count or 0),
    )


async def top_products(session: AsyncSession, limit: int = 5) -> list[TopProduct]:
    units = func.coalesce(func.sum(Sale.quantity), 0).label("units")
    rows = await session.execute(
        select(Product.id, Product.name, units)
        .join(Sale, (Sale.product_id == Product.id) & Sale.is_deleted.is_(False))
        .where(Product.is_deleted.is_(False))
        .group_by(Product.id, Product.name)
        .order_by(units.desc())
        .limit(limit)
    )
    return [
        TopProduct(product_id=pid, name=name, units_sold=int(u or 0))
        for pid, name, u in rows.all()
    ]
