"""Endpoints de autenticación: /register, /login, /refresh, /logout."""

from typing import Annotated

from fastapi import APIRouter, Depends, Header, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.db.session import get_session
from app.modules.auth import service
from app.modules.auth.schemas import (
    LoginRequest,
    RefreshRequest,
    RegisterRequest,
    ResetPasswordRequest,
    TokenResponse,
)
from app.shared.errors import api_error

router = APIRouter(prefix="/auth", tags=["auth"])

SessionDep = Annotated[AsyncSession, Depends(get_session)]


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(data: RegisterRequest, session: SessionDep) -> TokenResponse:
    tenant, user = await service.register(
        session,
        company_name=data.company_name,
        company_slug=data.company_slug,
        email=data.email,
        password=data.password,
    )
    return await service.issue_tokens(
        session, user_id=user.id, tenant_id=tenant.id, role=user.role
    )


@router.post("/login", response_model=TokenResponse)
async def login(data: LoginRequest, session: SessionDep) -> TokenResponse:
    tenant, user = await service.authenticate(
        session,
        company_slug=data.company_slug,
        email=data.email,
        password=data.password,
    )
    return await service.issue_tokens(
        session, user_id=user.id, tenant_id=tenant.id, role=user.role
    )


@router.get("/admin-status")
async def admin_status() -> dict[str, bool]:
    """Diagnóstico seguro: dice SOLO si el servidor tiene cargado el secreto de
    administrador (true/false). No revela su valor. Sirve para confirmar que Render
    ya tomó la variable LICENSE_ADMIN_SECRET tras guardarla y reiniciar."""
    return {"admin_secret_configured": bool(settings.license_admin_secret)}


@router.post("/reset-password", status_code=status.HTTP_204_NO_CONTENT)
async def reset_password(
    data: ResetPasswordRequest,
    session: SessionDep,
    x_admin_secret: Annotated[str | None, Header()] = None,
) -> None:
    """Restablece la contraseña de una cuenta. Requiere el secreto de administrador
    (el mismo LICENSE_ADMIN_SECRET del servidor). Pensado para que el dueño recupere
    el acceso de un cliente que olvidó su contraseña."""
    if not settings.license_admin_secret:
        # El servidor no tiene (todavía) el secreto: falta configurarlo o Render aún
        # está reiniciando tras guardarlo. Mensaje distinto para no confundir con un typo.
        raise api_error(
            503,
            "ADMIN_NOT_CONFIGURED",
            "El servidor aún no tiene configurado el secreto de administrador "
            "(o está reiniciando tras guardarlo). Espera 1-2 minutos y reintenta.",
        )
    if x_admin_secret != settings.license_admin_secret:
        raise api_error(403, "SECRET_MISMATCH", "El secreto no coincide con el del servidor")
    await service.reset_password(
        session,
        company_slug=data.company_slug,
        email=data.email,
        new_password=data.new_password,
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh(data: RefreshRequest, session: SessionDep) -> TokenResponse:
    return await service.rotate_refresh(session, data.refresh_token)


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(data: RefreshRequest, session: SessionDep) -> None:
    await service.logout(session, data.refresh_token)
