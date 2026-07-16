"""Modelos de inventario: Product y StockMovement.

Decisión clave (ADR-005): el stock NO es un campo que se sobrescribe, sino la SUMA de
movimientos (`stock_movements`), una tabla append-only. Así dos ventas concurrentes
offline se acumulan correctamente sin perder ninguna. Ver docs/10_MVP.md.
"""

from uuid import UUID

from sqlalchemy import CheckConstraint, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, SyncMixin, UUIDPrimaryKeyMixin

MOVEMENT_REASONS = ("initial", "purchase", "sale", "adjustment")


class Product(UUIDPrimaryKeyMixin, SyncMixin, Base):
    """Catálogo. Se sincroniza con last-write-wins (el nombre/precio pueden cambiar)."""

    __tablename__ = "products"

    tenant_id: Mapped[UUID] = mapped_column(
        ForeignKey("tenants.id", ondelete="CASCADE"), index=True, nullable=False
    )
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    price_cents: Mapped[int] = mapped_column(Integer, default=0, server_default="0")


class StockMovement(UUIDPrimaryKeyMixin, SyncMixin, Base):
    """Movimiento de inventario (append-only). `delta` suma o resta al stock.

    Es inmutable: nunca entra en conflicto. El stock actual de un producto es
    SUM(delta) de sus movimientos.
    """

    __tablename__ = "stock_movements"
    __table_args__ = (
        CheckConstraint(f"reason IN {MOVEMENT_REASONS}", name="ck_stock_movements_reason"),
    )

    tenant_id: Mapped[UUID] = mapped_column(
        ForeignKey("tenants.id", ondelete="CASCADE"), index=True, nullable=False
    )
    product_id: Mapped[UUID] = mapped_column(
        ForeignKey("products.id", ondelete="CASCADE"), index=True, nullable=False
    )
    delta: Mapped[int] = mapped_column(Integer, nullable=False)
    reason: Mapped[str] = mapped_column(String(20), nullable=False)
