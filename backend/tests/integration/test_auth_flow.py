"""Flujo de autenticación end-to-end contra Postgres real: register → login → /me."""

from httpx import ASGITransport, AsyncClient

from app.core.config import settings
from app.main import app


async def _client() -> AsyncClient:
    return AsyncClient(transport=ASGITransport(app=app), base_url="http://test")


async def test_register_login_me() -> None:
    creds = {
        "company_name": "Michilín",
        "company_slug": "michilin",
        "email": "dueno@michilin.com",
        "password": "password123",
    }
    async with await _client() as client:
        # Registro (onboarding): crea empresa + Owner y devuelve tokens.
        r = await client.post("/api/v1/auth/register", json=creds)
        assert r.status_code == 201, r.text
        access = r.json()["access_token"]

        # El token da acceso al propio perfil.
        me = await client.get("/api/v1/users/me", headers={"Authorization": f"Bearer {access}"})
        assert me.status_code == 200
        body = me.json()
        assert body["email"] == creds["email"]
        assert body["role"] == "owner"

        # Login posterior con slug + email + contraseña.
        login = await client.post(
            "/api/v1/auth/login",
            json={k: creds[k] for k in ("company_slug", "email", "password")},
        )
        assert login.status_code == 200
        assert "access_token" in login.json()


async def test_login_credenciales_invalidas() -> None:
    async with await _client() as client:
        await client.post(
            "/api/v1/auth/register",
            json={
                "company_name": "Michilín",
                "company_slug": "michilin",
                "email": "dueno@michilin.com",
                "password": "password123",
            },
        )
        bad = await client.post(
            "/api/v1/auth/login",
            json={
                "company_slug": "michilin",
                "email": "dueno@michilin.com",
                "password": "mala1234",
            },
        )
    assert bad.status_code == 401
    assert bad.json()["error"]["code"] == "INVALID_CREDENTIALS"


async def test_reset_password_por_admin() -> None:
    """El dueño (con el secreto de admin) restablece la contraseña de una cuenta que
    olvidó su clave, y luego se puede entrar con la nueva."""
    creds = {
        "company_name": "Abarrotes Toño",
        "company_slug": "abarrotestono",
        "email": "dueno@tono.com",
        "password": "vieja12345",
    }
    old_secret = settings.license_admin_secret
    settings.license_admin_secret = "secreto-de-tono"
    try:
        async with await _client() as client:
            reg = await client.post("/api/v1/auth/register", json=creds)
            assert reg.status_code == 201, reg.text

            # Sin secreto correcto: prohibido.
            r = await client.post(
                "/api/v1/auth/reset-password",
                json={
                    "company_slug": creds["company_slug"],
                    "email": creds["email"],
                    "new_password": "nueva12345",
                },
                headers={"X-Admin-Secret": "mal-secreto"},
            )
            assert r.status_code == 403

            # Con secreto correcto: restablece.
            r = await client.post(
                "/api/v1/auth/reset-password",
                json={
                    "company_slug": creds["company_slug"],
                    "email": creds["email"],
                    "new_password": "nueva12345",
                },
                headers={"X-Admin-Secret": "secreto-de-tono"},
            )
            assert r.status_code == 204, r.text

            # La contraseña vieja ya no sirve.
            old = await client.post(
                "/api/v1/auth/login",
                json={
                    "company_slug": creds["company_slug"],
                    "email": creds["email"],
                    "password": "vieja12345",
                },
            )
            assert old.status_code == 401

            # La nueva sí.
            new = await client.post(
                "/api/v1/auth/login",
                json={
                    "company_slug": creds["company_slug"],
                    "email": creds["email"],
                    "password": "nueva12345",
                },
            )
            assert new.status_code == 200, new.text
            assert "access_token" in new.json()
    finally:
        settings.license_admin_secret = old_secret
