import { useQuery } from "@tanstack/react-query";

import { fetchSummary, fetchTopProducts } from "./api";

function money(cents: number): string {
  return `$${(cents / 100).toFixed(2)}`;
}

export function ReportsPage() {
  const summary = useQuery({ queryKey: ["report-summary"], queryFn: fetchSummary });
  const top = useQuery({ queryKey: ["report-top"], queryFn: fetchTopProducts });

  const s = summary.data;

  return (
    <div className="page">
      <h1>Reportes</h1>

      <div className="stat-grid" style={{ marginBottom: "1.5rem" }}>
        <div className="stat">
          <div className="value">{s ? money(s.sales_total_cents) : "—"}</div>
          <div className="label">Ventas totales</div>
        </div>
        <div className="stat">
          <div className="value">{s?.sales_count ?? "—"}</div>
          <div className="label">N.º de ventas</div>
        </div>
        <div className="stat">
          <div className="value">{s?.products_count ?? "—"}</div>
          <div className="label">Productos</div>
        </div>
        <div className="stat">
          <div className="value">{s?.customers_count ?? "—"}</div>
          <div className="label">Clientes</div>
        </div>
        <div className="stat">
          <div className="value">{s?.low_stock_count ?? "—"}</div>
          <div className="label">Stock bajo</div>
        </div>
      </div>

      <section className="card">
        <h2>Productos más vendidos</h2>
        <table>
          <thead>
            <tr>
              <th>Producto</th>
              <th>Unidades vendidas</th>
            </tr>
          </thead>
          <tbody>
            {top.data?.map((p) => (
              <tr key={p.product_id}>
                <td>{p.name}</td>
                <td>{p.units_sold}</td>
              </tr>
            ))}
            {top.data?.length === 0 && (
              <tr>
                <td colSpan={2} className="empty">
                  Sin ventas todavía.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </section>
    </div>
  );
}
