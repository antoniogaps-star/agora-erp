"""Contratos del módulo de facturación."""

from datetime import datetime
from typing import Annotated
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class InvoiceItemCreate(BaseModel):
    product_id: UUID
    quantity: Annotated[int, Field(gt=0)]


class InvoiceCreate(BaseModel):
    customer_id: UUID
    items: Annotated[list[InvoiceItemCreate], Field(min_length=1)]


class InvoiceItemRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    product_id: UUID
    quantity: int
    unit_price_cents: int
    total_cents: int


class InvoiceRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    number: int
    customer_id: UUID
    status: str
    total_cents: int
    created_at: datetime


class InvoiceDetail(InvoiceRead):
    items: list[InvoiceItemRead]
