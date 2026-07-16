"""MVP Inventario + Ventas: REST (web) y sincronización (móvil).

Incluye el criterio de aceptación crítico del MVP: dos ventas concurrentes offline del
mismo producto deben acumularse (no perderse) al sincronizar — ver docs/10_MVP.md.
"""

from uuid import uuid4

from httpx import ASGITransport, AsyncClient

from app.main import app


async def _client() -> AsyncClient:
    return AsyncClient(transport=ASGITransport(app=app), base_url="http://test")


async def _auth(client: AsyncClient, slug: str = "tienda") -> dict[str, str]:
    r = await client.post(
        "/api/v1/auth/register",
        json={
            "company_name": "Tienda",
            "company_slug": slug,
            "email": f"owner@{slug}.com",
            "password": "password123",
        },
    )
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


# ── REST (canal web) ─────────────────────────────────────────
async def test_crear_producto_y_vender_descuenta_stock() -> None:
    async with await _client() as client:
        h = await _auth(client)
        create = await client.post(
            "/api/v1/products", headers=h,
            json={"name": "Café", "price_cents": 500, "initial_stock": 10},
        )
        assert create.status_code == 201
        product_id = create.json()["id"]

        # Vender 3 → stock 7
        sale = await client.post(
            "/api/v1/sales", headers=h,
            json={"product_id": product_id, "quantity": 3},
        )
        assert sale.status_code == 201
        assert sale.json()["total_cents"] == 1500

        products = await client.get("/api/v1/products", headers=h)
        stock = next(p["stock"] for p in products.json() if p["id"] == product_id)
        assert stock == 7


async def test_borrar_producto_lo_quita_de_la_lista() -> None:
    async with await _client() as client:
        h = await _auth(client)
        create = await client.post(
            "/api/v1/products", headers=h,
            json={"name": "Temporal", "price_cents": 100, "initial_stock": 5},
        )
        pid = create.json()["id"]
        assert len((await client.get("/api/v1/products", headers=h)).json()) == 1

        deleted = await client.delete(f"/api/v1/products/{pid}", headers=h)
        assert deleted.status_code == 204

        after = await client.get("/api/v1/products", headers=h)
    assert after.json() == []


async def test_venta_sin_stock_suficiente_rechazada() -> None:
    async with await _client() as client:
        h = await _auth(client)
        create = await client.post(
            "/api/v1/products", headers=h,
            json={"name": "Té", "price_cents": 300, "initial_stock": 1},
        )
        product_id = create.json()["id"]
        sale = await client.post(
            "/api/v1/sales", headers=h, json={"product_id": product_id, "quantity": 5}
        )
    assert sale.status_code == 409
    assert sale.json()["error"]["code"] == "INSUFFICIENT_STOCK"


# ── SINCRONIZACIÓN (canal móvil) ─────────────────────────────
async def test_dos_ventas_offline_concurrentes_se_acumulan() -> None:
    """Criterio MVP: dos dispositivos venden 1 unidad offline; el stock refleja AMBAS."""
    async with await _client() as client:
        h = await _auth(client)
        create = await client.post(
            "/api/v1/products", headers=h,
            json={"name": "Refresco", "price_cents": 200, "initial_stock": 10},
        )
        product_id = create.json()["id"]

        def sale_change(qty: int) -> list[dict]:
            sale_id, mov_id = str(uuid4()), str(uuid4())
            return [
                {
                    "entity": "sale", "id": sale_id, "op": "upsert", "version": 1,
                    "updated_at": "2026-07-15T12:00:00Z",
                    "data": {"product_id": product_id, "quantity": qty,
                             "unit_price_cents": 200, "total_cents": 200 * qty},
                },
                {
                    "entity": "stock_movement", "id": mov_id, "op": "upsert", "version": 1,
                    "updated_at": "2026-07-15T12:00:00Z",
                    "data": {"product_id": product_id, "delta": -qty, "reason": "sale"},
                },
            ]

        # Dispositivo A y dispositivo B, cada uno vendió 1 estando sin conexión.
        push_a = await client.post(
            "/api/v1/sync/push", headers=h, json={"changes": sale_change(1)}
        )
        push_b = await client.post(
            "/api/v1/sync/push", headers=h, json={"changes": sale_change(1)}
        )
        assert push_a.status_code == 200 and push_b.status_code == 200

        products = await client.get("/api/v1/products", headers=h)
        stock = next(p["stock"] for p in products.json() if p["id"] == product_id)
        assert stock == 8, "Las dos ventas concurrentes deben restar ambas (10-1-1)"


async def test_push_movimiento_idempotente() -> None:
    """Reenviar el mismo movimiento no duplica el descuento."""
    async with await _client() as client:
        h = await _auth(client)
        create = await client.post(
            "/api/v1/products", headers=h,
            json={"name": "Agua", "price_cents": 100, "initial_stock": 5},
        )
        product_id = create.json()["id"]
        mov_id = str(uuid4())
        change = {
            "changes": [{
                "entity": "stock_movement", "id": mov_id, "op": "upsert", "version": 1,
                "updated_at": "2026-07-15T12:00:00Z",
                "data": {"product_id": product_id, "delta": -2, "reason": "sale"},
            }]
        }
        await client.post("/api/v1/sync/push", headers=h, json=change)
        await client.post("/api/v1/sync/push", headers=h, json=change)  # reenvío

        products = await client.get("/api/v1/products", headers=h)
        stock = next(p["stock"] for p in products.json() if p["id"] == product_id)
    assert stock == 3, "El reenvío no debe descontar dos veces (5-2)"


async def test_inventario_aislado_entre_tenants() -> None:
    async with await _client() as client:
        ha = await _auth(client, "tienda-a")
        await client.post(
            "/api/v1/products", headers=ha,
            json={"name": "Secreto A", "price_cents": 999, "initial_stock": 1},
        )
        hb = await _auth(client, "tienda-b")
        products_b = await client.get("/api/v1/products", headers=hb)
    assert products_b.json() == [], "El tenant B no debe ver productos del tenant A"
