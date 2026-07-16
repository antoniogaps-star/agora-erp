"""Endpoints REST de inventario (canal online, usado por el panel web)."""

from typing import Any
from uuid import UUID

from fastapi import APIRouter, status

from app.modules.products import service, voice_ai
from app.modules.products.schemas import (
    ProductCreate,
    ProductRead,
    StockAdjust,
    VoiceParseRequest,
    VoiceParseResponse,
)
from app.shared.deps import Claims, TenantSession

router = APIRouter(prefix="/products", tags=["products"])


@router.get("", response_model=list[ProductRead])
async def list_products(session: TenantSession, claims: Claims) -> list[dict[str, Any]]:
    return await service.list_products_with_stock(session)


@router.post("", response_model=ProductRead, status_code=status.HTTP_201_CREATED)
async def create_product(
    data: ProductCreate, session: TenantSession, claims: Claims
) -> dict[str, Any]:
    product = await service.create_product(
        session,
        tenant_id=UUID(claims["tenant_id"]),
        name=data.name,
        price_cents=data.price_cents,
        initial_stock=data.initial_stock,
    )
    return {
        "id": product.id,
        "name": product.name,
        "price_cents": product.price_cents,
        "stock": data.initial_stock,
    }


@router.post("/voice-parse", response_model=VoiceParseResponse)
async def voice_parse(data: VoiceParseRequest, claims: Claims) -> dict[str, Any]:
    """Interpreta con IA un dictado de inventario → {name, pieces, note}."""
    return await voice_ai.parse_product(data.transcript)


@router.delete("/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_product(
    product_id: UUID, session: TenantSession, claims: Claims
) -> None:
    await service.delete_product(session, product_id)


@router.post("/{product_id}/adjust", status_code=status.HTTP_204_NO_CONTENT)
async def adjust_stock(
    product_id: UUID, data: StockAdjust, session: TenantSession, claims: Claims
) -> None:
    await service.adjust_stock(
        session,
        tenant_id=UUID(claims["tenant_id"]),
        product_id=product_id,
        delta=data.delta,
        reason=data.reason,
    )
