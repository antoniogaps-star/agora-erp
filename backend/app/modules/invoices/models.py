"""Modelos de facturación: Invoice e InvoiceItem.

Canal online (web/back-office): no se sincroniza offline. Una factura pertenece a un
cliente y agrupa líneas (producto + cantidad). El número es correlativo por empresa.
"""

from uuid import UUID

from sqlalchemy import CheckConstraint, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, SyncMixin, UUIDPrimaryKeyMixin

INVOICE_STATUSES = ("issued", "paid", "cancelled")


class Invoice(UUIDPrimaryKeyMixin, SyncMixin, Base):
    __tablename__ = "invoices"
    __table_args__ = (
        CheckConstraint(f"status IN {INVOICE_STATUSES}", name="ck_invoices_status"),
    )

    tenant_id: Mapped[UUID] = mapped_column(
        ForeignKey("tenants.id", ondelete="CASCADE"), index=True, nullable=False
    )
    customer_id: Mapped[UUID] = mapped_column(
        ForeignKey("customers.id", ondelete="RESTRICT"), index=True, nullable=False
    )
    number: Mapped[int] = mapped_column(Integer, nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="issued", server_default="issued")
    total_cents: Mapped[int] = mapped_column(Integer, nullable=False)


class InvoiceItem(UUIDPrimaryKeyMixin, SyncMixin, Base):
    __tablename__ = "invoice_items"

    tenant_id: Mapped[UUID] = mapped_column(
        ForeignKey("tenants.id", ondelete="CASCADE"), index=True, nullable=False
    )
    invoice_id: Mapped[UUID] = mapped_column(
        ForeignKey("invoices.id", ondelete="CASCADE"), index=True, nullable=False
    )
    product_id: Mapped[UUID] = mapped_column(
        ForeignKey("products.id", ondelete="RESTRICT"), nullable=False
    )
    quantity: Mapped[int] = mapped_column(Integer, nullable=False)
    unit_price_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    total_cents: Mapped[int] = mapped_column(Integer, nullable=False)
