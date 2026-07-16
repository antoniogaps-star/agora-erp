"""Facturación, contabilidad y reportes."""

from httpx import ASGITransport, AsyncClient

from app.main import app


async def _client() -> AsyncClient:
    return AsyncClient(transport=ASGITransport(app=app), base_url="http://test")


async def _auth(client: AsyncClient, slug: str = "negocio") -> dict[str, str]:
    r = await client.post(
        "/api/v1/auth/register",
        json={
            "company_name": "Negocio",
            "company_slug": slug,
            "email": f"o@{slug}.com",
            "password": "password123",
        },
    )
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


async def _product(client: AsyncClient, h: dict, price: int, stock: int = 100) -> str:
    r = await client.post(
        "/api/v1/products", headers=h,
        json={"name": "P", "price_cents": price, "initial_stock": stock},
    )
    return r.json()["id"]


async def _customer(client: AsyncClient, h: dict) -> str:
    r = await client.post("/api/v1/customers", headers=h, json={"name": "Cliente"})
    return r.json()["id"]


# ── Facturación ──────────────────────────────────────────────
async def test_crear_factura_calcula_total_y_numera() -> None:
    async with await _client() as client:
        h = await _auth(client)
        pid = await _product(client, h, price=1000)
        cid = await _customer(client, h)
        inv = await client.post(
            "/api/v1/invoices", headers=h,
            json={"customer_id": cid, "items": [{"product_id": pid, "quantity": 3}]},
        )
        assert inv.status_code == 201
        body = inv.json()
        assert body["number"] == 1
        assert body["total_cents"] == 3000
        assert body["items"][0]["total_cents"] == 3000

        # La segunda factura correlativa.
        inv2 = await client.post(
            "/api/v1/invoices", headers=h,
            json={"customer_id": cid, "items": [{"product_id": pid, "quantity": 1}]},
        )
        assert inv2.json()["number"] == 2


async def test_facturas_aisladas_entre_tenants() -> None:
    async with await _client() as client:
        ha = await _auth(client, "fact-a")
        pid = await _product(client, ha, price=500)
        cid = await _customer(client, ha)
        await client.post(
            "/api/v1/invoices", headers=ha,
            json={"customer_id": cid, "items": [{"product_id": pid, "quantity": 1}]},
        )
        hb = await _auth(client, "fact-b")
        listing_b = await client.get("/api/v1/invoices", headers=hb)
    assert listing_b.json() == []


# ── Contabilidad ─────────────────────────────────────────────
async def test_balance_ingresos_menos_egresos() -> None:
    async with await _client() as client:
        h = await _auth(client)
        await client.post(
            "/api/v1/accounting/entries", headers=h,
            json={"entry_type": "income", "concept": "Venta", "amount_cents": 5000,
                  "occurred_on": "2026-07-16"},
        )
        await client.post(
            "/api/v1/accounting/entries", headers=h,
            json={"entry_type": "expense", "concept": "Renta", "amount_cents": 2000,
                  "occurred_on": "2026-07-16"},
        )
        balance = await client.get("/api/v1/accounting/balance", headers=h)
    body = balance.json()
    assert body == {"income_cents": 5000, "expense_cents": 2000, "balance_cents": 3000}


# ── Reportes ─────────────────────────────────────────────────
async def test_reporte_resumen() -> None:
    async with await _client() as client:
        h = await _auth(client)
        pid = await _product(client, h, price=1000, stock=10)
        await _customer(client, h)
        await client.post("/api/v1/sales", headers=h, json={"product_id": pid, "quantity": 2})

        summary = await client.get("/api/v1/reports/summary", headers=h)
    body = summary.json()
    assert body["sales_count"] == 1
    assert body["sales_total_cents"] == 2000
    assert body["products_count"] == 1
    assert body["customers_count"] == 1


async def test_reporte_top_productos() -> None:
    async with await _client() as client:
        h = await _auth(client)
        pid = await _product(client, h, price=1000, stock=10)
        await client.post("/api/v1/sales", headers=h, json={"product_id": pid, "quantity": 4})
        top = await client.get("/api/v1/reports/top-products", headers=h)
    assert top.json()[0]["units_sold"] == 4
