"""Lógica de facturación."""

from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.customers.models import Customer
from app.modules.invoices.models import Invoice, InvoiceItem
from app.modules.invoices.schemas import InvoiceItemCreate
from app.modules.products.models import Product
from app.shared.errors import api_error


async def create_invoice(
    session: AsyncSession, *, tenant_id: UUID, customer_id: UUID, items: list[InvoiceItemCreate]
) -> Invoice:
    customer = await session.get(Customer, customer_id)
    if customer is None or customer.is_deleted:
        raise api_error(404, "CUSTOMER_NOT_FOUND", "Cliente no encontrado")

    # Número correlativo por empresa (RLS acota a este tenant).
    last = await session.scalar(select(func.coalesce(func.max(Invoice.number), 0)))
    number = int(last or 0) + 1

    invoice = Invoice(
        tenant_id=tenant_id,
        customer_id=customer_id,
        number=number,
        status="issued",
        total_cents=0,
    )
    session.add(invoice)
    await session.flush()

    total = 0
    for line in items:
        product = await session.get(Product, line.product_id)
        if product is None or product.is_deleted:
            raise api_error(404, "PRODUCT_NOT_FOUND", f"Producto {line.product_id} no encontrado")
        line_total = product.price_cents * line.quantity
        total += line_total
        session.add(
            InvoiceItem(
                tenant_id=tenant_id,
                invoice_id=invoice.id,
                product_id=product.id,
                quantity=line.quantity,
                unit_price_cents=product.price_cents,
                total_cents=line_total,
            )
        )

    invoice.total_cents = total
    await session.flush()
    return invoice


async def list_invoices(session: AsyncSession) -> list[Invoice]:
    rows = await session.execute(
        select(Invoice).where(Invoice.is_deleted.is_(False)).order_by(Invoice.number.desc())
    )
    return list(rows.scalars().all())


async def get_invoice_with_items(
    session: AsyncSession, invoice_id: UUID
) -> tuple[Invoice, list[InvoiceItem]]:
    invoice = await session.get(Invoice, invoice_id)
    if invoice is None or invoice.is_deleted:
        raise api_error(404, "INVOICE_NOT_FOUND", "Factura no encontrada")
    rows = await session.execute(
        select(InvoiceItem).where(InvoiceItem.invoice_id == invoice_id)
    )
    return invoice, list(rows.scalars().all())
