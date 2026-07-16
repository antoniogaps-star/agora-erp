"""Contratos del módulo de clientes."""

from typing import Annotated
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class CustomerCreate(BaseModel):
    name: Annotated[str, Field(min_length=1, max_length=200)]
    email: str | None = None
    phone: str | None = None


class CustomerRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    email: str | None
    phone: str | None
