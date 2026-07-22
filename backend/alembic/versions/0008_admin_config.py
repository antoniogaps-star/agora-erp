"""Secreto de administrador configurable desde la app: tabla admin_config (sin RLS).

Permite que el dueño fije el secreto de administrador desde la propia app (no desde
variables de entorno del servidor). Fila única (id=1) con el HASH del secreto. Igual
que `tenants` y `licenses`, no lleva RLS: no es por-tenant.

Revision ID: 0008
Revises: 0007
Create Date: 2026-07-22
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "0008"
down_revision: str | None = "0007"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "admin_config",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("secret_hash", sa.String(length=255), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
    )


def downgrade() -> None:
    op.drop_table("admin_config")
