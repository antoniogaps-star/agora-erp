"""Endpoints de autenticación: /register, /login, /refresh."""

from typing import Annotated
from uuid import UUID

import jwt
from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token, create_refresh_token, decode_token
from app.db.session import get_session
from app.modules.auth import service
from app.modules.auth.schemas import (
    LoginRequest,
    RefreshRequest,
    RegisterRequest,
    TokenResponse,
)
from app.shared.errors import api_error

router = APIRouter(prefix="/auth", tags=["auth"])

SessionDep = Annotated[AsyncSession, Depends(get_session)]


def _tokens_for(user_id: UUID, tenant_id: UUID, role: str) -> TokenResponse:
    return TokenResponse(
        access_token=create_access_token(user_id=user_id, tenant_id=tenant_id, role=role),
        refresh_token=create_refresh_token(user_id=user_id, tenant_id=tenant_id, role=role),
    )


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(data: RegisterRequest, session: SessionDep) -> TokenResponse:
    tenant, user = await service.register(
        session,
        company_name=data.company_name,
        company_slug=data.company_slug,
        email=data.email,
        password=data.password,
    )
    return _tokens_for(user.id, tenant.id, user.role)


@router.post("/login", response_model=TokenResponse)
async def login(data: LoginRequest, session: SessionDep) -> TokenResponse:
    tenant, user = await service.authenticate(
        session,
        company_slug=data.company_slug,
        email=data.email,
        password=data.password,
    )
    return _tokens_for(user.id, tenant.id, user.role)


@router.post("/refresh", response_model=TokenResponse)
async def refresh(data: RefreshRequest) -> TokenResponse:
    try:
        payload = decode_token(data.refresh_token)
    except jwt.PyJWTError as exc:
        raise api_error(401, "INVALID_TOKEN", "Refresh token inválido o expirado") from exc
    if payload.get("type") != "refresh":
        raise api_error(401, "INVALID_TOKEN", "Se requiere un refresh token")
    return TokenResponse(
        access_token=create_access_token(
            user_id=UUID(payload["sub"]),
            tenant_id=UUID(payload["tenant_id"]),
            role=payload["role"],
        ),
        refresh_token=data.refresh_token,
    )
