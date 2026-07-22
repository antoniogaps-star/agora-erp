"""Monetización: columna plan_expires_at en tenants + tabla licenses (sin RLS).

Las licencias (claves de activación) NO son por-tenant: se generan antes de
canjearse y el canje las busca globalmente. Por eso, igual que `tenants`, no
llevan RLS; su acceso se controla en la capa de aplicación.

Revision ID: 0007
Revises: 0006
Create Date: 2026-07-21
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "0007"
down_revision: str | None = "0006"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "tenants",
        sa.Column("plan_expires_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_table(
        "licenses",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("code", sa.String(length=40), nullable=False),
        sa.Column("plan", sa.String(length=20), nullable=False),
        sa.Column("months", sa.Integer(), server_default="0", nullable=False),
        sa.Column("redeemed_by", sa.Uuid(), nullable=True),
        sa.Column("redeemed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.CheckConstraint("plan IN ('pyme', 'business', 'enterprise')", name="ck_licenses_plan"),
        sa.ForeignKeyConstraint(["redeemed_by"], ["tenants.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("code", name="uq_licenses_code"),
    )


def downgrade() -> None:
    op.drop_table("licenses")
    op.drop_column("tenants", "plan_expires_at")
