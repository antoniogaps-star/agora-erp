import { useQuery } from "@tanstack/react-query";

import { listProducts } from "@/features/inventory/api";

function money(cents: number): string {
  return `$${(cents / 100).toFixed(2)}`;
}

export function ProductsPage() {
  const products = useQuery({ queryKey: ["products"], queryFn: listProducts });
  const rows = products.data ?? [];

  return (
    <div className="page">
      <h1>Productos</h1>
      <p style={{ color: "#666", marginTop: "-0.5rem" }}>
        Catálogo de productos con su precio y existencias.
      </p>
      <section className="card">
        <table>
          <thead>
            <tr>
              <th>Producto</th>
              <th>Precio</th>
              <th>Existencias</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((p) => (
              <tr key={p.id}>
                <td>{p.name}</td>
                <td>{money(p.price_cents)}</td>
                <td style={{ color: p.stock <= 5 ? "#b91c1c" : undefined }}>{p.stock}</td>
              </tr>
            ))}
            {products.isSuccess && rows.length === 0 && (
              <tr>
                <td colSpan={3} className="empty">
                  Aún no hay productos.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </section>
    </div>
  );
}
