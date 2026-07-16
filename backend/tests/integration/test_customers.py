"""Módulo de clientes: REST, aislamiento y sincronización."""

from uuid import uuid4

from httpx import ASGITransport, AsyncClient

from app.main import app


async def _client() -> AsyncClient:
    return AsyncClient(transport=ASGITransport(app=app), base_url="http://test")


async def _auth(client: AsyncClient, slug: str = "empresa") -> dict[str, str]:
    r = await client.post(
        "/api/v1/auth/register",
        json={
            "company_name": "Empresa",
            "company_slug": slug,
            "email": f"o@{slug}.com",
            "password": "password123",
        },
    )
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


async def test_crear_y_listar_clientes() -> None:
    async with await _client() as client:
        h = await _auth(client)
        create = await client.post(
            "/api/v1/customers", headers=h,
            json={"name": "Juan Pérez", "email": "juan@x.com", "phone": "555-1234"},
        )
        assert create.status_code == 201
        listing = await client.get("/api/v1/customers", headers=h)
    assert [c["name"] for c in listing.json()] == ["Juan Pérez"]


async def test_clientes_aislados_entre_tenants() -> None:
    async with await _client() as client:
        ha = await _auth(client, "cli-a")
        await client.post("/api/v1/customers", headers=ha, json={"name": "Cliente A"})
        hb = await _auth(client, "cli-b")
        listing_b = await client.get("/api/v1/customers", headers=hb)
    assert listing_b.json() == []


async def test_sync_cliente_desde_movil() -> None:
    async with await _client() as client:
        h = await _auth(client)
        cid = str(uuid4())
        push = await client.post(
            "/api/v1/sync/push", headers=h,
            json={"changes": [{
                "entity": "customer", "id": cid, "op": "upsert", "version": 1,
                "updated_at": "2026-07-16T12:00:00Z",
                "data": {"name": "Cliente Offline", "email": None, "phone": None},
            }]},
        )
        assert push.json()["results"][0]["status"] == "applied"
        listing = await client.get("/api/v1/customers", headers=h)
    assert [c["name"] for c in listing.json()] == ["Cliente Offline"]
