"""Endpoints REST de facturación (canal online)."""

from typing import Any
from uuid import UUID

from fastapi import APIRouter, status

from app.modules.invoices import service
from app.modules.invoices.models import Invoice
from app.modules.invoices.schemas import InvoiceCreate, InvoiceDetail, InvoiceRead
from app.shared.deps import Claims, TenantSession

router = APIRouter(prefix="/invoices", tags=["invoices"])


@router.get("", response_model=list[InvoiceRead])
async def list_invoices(session: TenantSession, claims: Claims) -> list[Invoice]:
    return await service.list_invoices(session)


@router.post("", response_model=InvoiceDetail, status_code=status.HTTP_201_CREATED)
async def create_invoice(
    data: InvoiceCreate, session: TenantSession, claims: Claims
) -> dict[str, Any]:
    invoice = await service.create_invoice(
        session,
        tenant_id=UUID(claims["tenant_id"]),
        customer_id=data.customer_id,
        items=data.items,
    )
    _, items = await service.get_invoice_with_items(session, invoice.id)
    return _detail(invoice, items)


@router.get("/{invoice_id}", response_model=InvoiceDetail)
async def get_invoice(
    invoice_id: UUID, session: TenantSession, claims: Claims
) -> dict[str, Any]:
    invoice, items = await service.get_invoice_with_items(session, invoice_id)
    return _detail(invoice, items)


def _detail(invoice: Invoice, items: list[Any]) -> dict[str, Any]:
    return {
        "id": invoice.id,
        "number": invoice.number,
        "customer_id": invoice.customer_id,
        "status": invoice.status,
        "total_cents": invoice.total_cents,
        "created_at": invoice.created_at,
        "items": [
            {
                "product_id": it.product_id,
                "quantity": it.quantity,
                "unit_price_cents": it.unit_price_cents,
                "total_cents": it.total_cents,
            }
            for it in items
        ],
    }
