import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";

import { createProduct, createSale, deleteProduct, listProducts } from "./api";

function money(cents: number): string {
  return `$${(cents / 100).toFixed(2)}`;
}

export function InventoryPage() {
  const queryClient = useQueryClient();
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

  const remove = useMutation({
    mutationFn: (productId: string) => deleteProduct(productId),
    onSuccess: refresh,
  });

  return (
    <div className="page">
      <h1>Inventario</h1>

      <section className="card">
        <h2>Nuevo producto</h2>
        <form
          className="row"
          onSubmit={(e) => {
            e.preventDefault();
            addProduct.mutate();
          }}
        >
          <input
            placeholder="Nombre"
            value={name}
            onChange={(e) => setName(e.target.value)}
            required
          />
          <input
            type="number"
            step="0.01"
            min="0"
            placeholder="Precio"
            value={price}
            onChange={(e) => setPrice(e.target.value)}
            required
          />
          <input
            type="number"
            min="0"
            placeholder="Stock inicial"
            value={stock}
            onChange={(e) => setStock(e.target.value)}
          />
          <button type="submit" disabled={addProduct.isPending}>
            Agregar
          </button>
        </form>
      </section>

      <section className="card">
        {error && <p className="error">{error}</p>}
        <table>
          <thead>
            <tr>
              <th>Producto</th>
              <th>Precio</th>
              <th>Stock</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {products.data?.map((p) => (
              <tr key={p.id}>
                <td>{p.name}</td>
                <td>{money(p.price_cents)}</td>
                <td>{p.stock}</td>
                <td style={{ textAlign: "right", whiteSpace: "nowrap" }}>
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
                  <button
                    type="button"
                    aria-label={`Eliminar ${p.name}`}
                    style={{
                      width: "auto",
                      margin: "0 0 0 0.4rem",
                      padding: "0.4rem 0.6rem",
                      background: "transparent",
                      color: "#c0392b",
                    }}
                    onClick={() => {
                      if (confirm(`¿Eliminar "${p.name}"?`)) remove.mutate(p.id);
                    }}
                  >
                    🗑
                  </button>
                </td>
              </tr>
            ))}
            {products.data?.length === 0 && (
              <tr>
                <td colSpan={4} className="empty">
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
