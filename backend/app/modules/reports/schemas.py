"""Contratos de reportes."""

from uuid import UUID

from pydantic import BaseModel


class Summary(BaseModel):
    sales_count: int
    sales_total_cents: int
    products_count: int
    customers_count: int
    low_stock_count: int


class TopProduct(BaseModel):
    product_id: UUID
    name: str
    units_sold: int
