"""Lógica de autenticación: onboarding (register) y login.

Punto clave multi-tenant: el email es único POR empresa. Por eso login y register
resuelven primero el tenant por su `slug` (la tabla `tenants` no tiene RLS), fijan
`app.current_tenant`, y solo entonces operan sobre `users` — que RLS ya acota a esa
empresa. El tenant nunca se toma de un token aún inexistente en estos endpoints públicos.
"""

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_password, verify_password
from app.db.rls import set_tenant
from app.modules.tenants.models import Tenant
from app.modules.users.models import User
from app.shared.errors import api_error


async def register(session: AsyncSession, *, company_name: str, company_slug: str,
                   email: str, password: str) -> tuple[Tenant, User]:
    async with session.begin():
        exists = await session.scalar(select(Tenant.id).where(Tenant.slug == company_slug))
        if exists is not None:
            raise api_error(409, "SLUG_TAKEN", "Ya existe una empresa con ese identificador")

        tenant = Tenant(name=company_name, slug=company_slug, plan="free", status="trial")
        session.add(tenant)
        await session.flush()  # asigna tenant.id

        await set_tenant(session, tenant.id)
        user = User(
            tenant_id=tenant.id,
            email=email,
            password_hash=hash_password(password),
            role="owner",
        )
        session.add(user)
        await session.flush()
    return tenant, user


async def authenticate(session: AsyncSession, *, company_slug: str, email: str,
                       password: str) -> tuple[Tenant, User]:
    # Mensaje de error genérico para no revelar si existe la empresa o el email.
    invalid = api_error(401, "INVALID_CREDENTIALS", "Credenciales inválidas")
    async with session.begin():
        tenant = await session.scalar(select(Tenant).where(Tenant.slug == company_slug))
        if tenant is None:
            raise invalid

        await set_tenant(session, tenant.id)
        user = await session.scalar(
            select(User).where(User.email == email, User.is_deleted.is_(False))
        )
        if user is None or not user.is_active or not verify_password(user.password_hash, password):
            raise invalid
    return tenant, user
