import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { useNavigate } from "react-router-dom";

import { logout as logoutApi } from "@/features/auth/api";
import { fetchMe } from "@/features/dashboard/api";
import { useAuthStore } from "@/shared/auth/store";

import { createProduct, createSale, listProducts } from "./api";

export function InventoryPage() {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const clear = useAuthStore((s) => s.clear);

  const me = useQuery({ queryKey: ["me"], queryFn: fetchMe });
  const products = useQuery({ queryKey: ["products"], queryFn: listProducts });

  const [name, setName] = useState("");
  const [price, setPrice] = useState("");
  const [stock, setStock] = useState("");
  const [error, setError] = useState<string | null>(null);

  const refresh = () => queryClient.invalidateQueries({ queryKey: ["products"] });

  const addProduct = useMutation({
    mutationFn: () =>
      createProduct({
        name,
        price_cents: Math.round(Number(price) * 100),
        initial_stock: Number(stock) || 0,
      }),
    onSuccess: () => {
      setName("");
      setPrice("");
      setStock("");
      refresh();
    },
  });

  const sell = useMutation({
    mutationFn: (productId: string) => createSale({ product_id: productId, quantity: 1 }),
    onSuccess: refresh,
    onError: () => setError("Stock insuficiente"),
  });

  async function logout() {
    const refresh = useAuthStore.getState().refreshToken;
    if (refresh) {
      try {
        await logoutApi(refresh); // revoca el refresh en el servidor
      } catch {
        // aunque falle, cerramos sesión localmente
      }
    }
    clear();
    navigate("/login");
  }

  return (
    <div style={{ maxWidth: 720, margin: "0 auto", padding: "1.5rem" }}>
      <header
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          marginBottom: "1.5rem",
        }}
      >
        <h1 style={{ margin: 0, fontSize: "1.4rem" }}>Ágora ERP · Inventario</h1>
        <div style={{ display: "flex", gap: "1rem", alignItems: "center" }}>
          <span style={{ fontSize: "0.85rem", color: "#555" }}>{me.data?.email}</span>
          <button type="button" className="secondary" style={{ width: "auto", margin: 0 }} onClick={logout}>
            Salir
          </button>
        </div>
      </header>

      <section className="card" style={{ maxWidth: "100%", marginBottom: "1.5rem" }}>
        <h1 style={{ fontSize: "1.1rem" }}>Nuevo producto</h1>
        <form
          onSubmit={(e) => {
            e.preventDefault();
            addProduct.mutate();
          }}
          style={{ display: "grid", gridTemplateColumns: "2fr 1fr 1fr auto", gap: "0.75rem", alignItems: "end" }}
        >
          <div>
            <label>Nombre</label>
            <input value={name} onChange={(e) => setName(e.target.value)} required />
          </div>
          <div>
            <label>Precio</label>
            <input type="number" step="0.01" min="0" value={price} onChange={(e) => setPrice(e.target.value)} required />
          </div>
          <div>
            <label>Stock inicial</label>
            <input type="number" min="0" value={stock} onChange={(e) => setStock(e.target.value)} />
          </div>
          <button type="submit" style={{ width: "auto", margin: 0 }} disabled={addProduct.isPending}>
            Agregar
          </button>
        </form>
      </section>

      <section className="card" style={{ maxWidth: "100%" }}>
        <h1 style={{ fontSize: "1.1rem" }}>Productos</h1>
        {error && <p className="error">{error}</p>}
        {products.isLoading && <p>Cargando…</p>}
        <table style={{ width: "100%", borderCollapse: "collapse" }}>
          <thead>
            <tr style={{ textAlign: "left", borderBottom: "1px solid #eee" }}>
              <th style={{ padding: "0.5rem 0" }}>Producto</th>
              <th>Precio</th>
              <th>Stock</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {products.data?.map((p) => (
              <tr key={p.id} style={{ borderBottom: "1px solid #f3f3f3" }}>
                <td style={{ padding: "0.5rem 0" }}>{p.name}</td>
                <td>${(p.price_cents / 100).toFixed(2)}</td>
                <td>{p.stock}</td>
                <td style={{ textAlign: "right" }}>
                  <button
                    type="button"
                    style={{ width: "auto", margin: 0, padding: "0.4rem 0.8rem" }}
                    disabled={sell.isPending || p.stock < 1}
                    onClick={() => {
                      setError(null);
                      sell.mutate(p.id);
                    }}
                  >
                    Vender 1
                  </button>
                </td>
              </tr>
            ))}
            {products.data?.length === 0 && (
              <tr>
                <td colSpan={4} style={{ padding: "1rem 0", color: "#888" }}>
                  Sin productos todavía.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </section>
    </div>
  );
}
