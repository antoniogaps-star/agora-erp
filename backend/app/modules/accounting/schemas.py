"""Contratos de contabilidad."""

from datetime import date
from typing import Annotated, Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class LedgerEntryCreate(BaseModel):
    entry_type: Literal["income", "expense"]
    concept: Annotated[str, Field(min_length=1, max_length=200)]
    amount_cents: Annotated[int, Field(gt=0)]
    occurred_on: date


class LedgerEntryRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    entry_type: str
    concept: str
    amount_cents: int
    occurred_on: date


class Balance(BaseModel):
    income_cents: int
    expense_cents: int
    balance_cents: int
