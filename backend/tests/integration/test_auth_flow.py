"""Flujo de autenticación end-to-end contra Postgres real: register → login → /me."""

from httpx import ASGITransport, AsyncClient

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
