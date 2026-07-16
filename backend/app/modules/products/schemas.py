"""Contratos del módulo de inventario."""

from typing import Annotated
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class ProductCreate(BaseModel):
    name: Annotated[str, Field(min_length=1, max_length=200)]
    price_cents: Annotated[int, Field(ge=0)] = 0
    initial_stock: Annotated[int, Field(ge=0)] = 0


class ProductRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    price_cents: int
    stock: int


class StockAdjust(BaseModel):
    delta: int  # positivo suma, negativo resta
    reason: str = "adjustment"


class VoiceParseRequest(BaseModel):
    transcript: Annotated[str, Field(min_length=1, max_length=300)]


class VoiceParseResponse(BaseModel):
    name: str
    pieces: int
    note: str | None = None
