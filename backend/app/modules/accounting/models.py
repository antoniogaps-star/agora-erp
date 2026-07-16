"""Contabilidad: libro de asientos simple (ingresos/egresos).

Versión pragmática para el MVP: un libro append-only de asientos con tipo (ingreso o
egreso), concepto e importe. El balance es la suma de ingresos menos egresos. La partida
doble completa y el asiento automático desde ventas quedan para una etapa posterior.
"""

from datetime import date
from uuid import UUID

from sqlalchemy import CheckConstraint, Date, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, SyncMixin, UUIDPrimaryKeyMixin

ENTRY_TYPES = ("income", "expense")


class LedgerEntry(UUIDPrimaryKeyMixin, SyncMixin, Base):
    __tablename__ = "ledger_entries"
    __table_args__ = (
        CheckConstraint(f"entry_type IN {ENTRY_TYPES}", name="ck_ledger_entry_type"),
    )

    tenant_id: Mapped[UUID] = mapped_column(
        ForeignKey("tenants.id", ondelete="CASCADE"), index=True, nullable=False
    )
    entry_type: Mapped[str] = mapped_column(String(10), nullable=False)
    concept: Mapped[str] = mapped_column(String(200), nullable=False)
    amount_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    occurred_on: Mapped[date] = mapped_column(Date, nullable=False)
