import { useQuery } from "@tanstack/react-query";

import { listProducts, listSales } from "@/features/inventory/api";

function money(cents: number): string {
  return `$${(cents / 100).toFixed(2)}`;
}

function fmtDate(iso: string): string {
  const d = new Date(iso);
  return d.toLocaleString();
}

export function MovementsPage() {
  const sales = useQuery({ queryKey: ["sales"], queryFn: listSales });
  const products = useQuery({ queryKey: ["products"], queryFn: listProducts });

  const nameById = new Map((products.data ?? []).map((p) => [p.id, p.name]));
  const rows = [...(sales.data ?? [])].sort((a, b) => b.created_at.localeCompare(a.created_at));

  return (
    <div className="page">
      <h1>Movimientos</h1>
      <p style={{ color: "#666", marginTop: "-0.5rem" }}>
        Salidas de inventario por ventas (las más recientes primero).
      </p>
      <section className="card">
        <table>
          <thead>
            <tr>
              <th>Fecha</th>
              <th>Producto</th>
              <th>Cantidad</th>
              <th>Total</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((s) => (
              <tr key={s.id}>
                <td>{fmtDate(s.created_at)}</td>
                <td>{nameById.get(s.product_id) ?? s.product_id}</td>
                <td>-{s.quantity}</td>
                <td>{money(s.total_cents)}</td>
              </tr>
            ))}
            {sales.isSuccess && rows.length === 0 && (
              <tr>
                <td colSpan={4} className="empty">
                  Aún no hay movimientos.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </section>
    </div>
  );
}
