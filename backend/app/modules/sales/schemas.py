"""Contratos del módulo de ventas."""

from datetime import datetime
from typing import Annotated
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class SaleCreate(BaseModel):
    product_id: UUID
    quantity: Annotated[int, Field(gt=0)]


class SaleRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    product_id: UUID
    quantity: int
    unit_price_cents: int
    total_cents: int
    created_at: datetime
