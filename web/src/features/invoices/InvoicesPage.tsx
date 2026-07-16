import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";

import { listCustomers } from "@/features/customers/api";
import { listProducts } from "@/features/inventory/api";

import { createInvoice, listInvoices } from "./api";

function money(cents: number): string {
  return `$${(cents / 100).toFixed(2)}`;
}

interface Line {
  product_id: string;
  quantity: number;
}

export function InvoicesPage() {
  const queryClient = useQueryClient();
  const invoices = useQuery({ queryKey: ["invoices"], queryFn: listInvoices });
  const customers = useQuery({ queryKey: ["customers"], queryFn: listCustomers });
  const products = useQuery({ queryKey: ["products"], queryFn: listProducts });

  const [customerId, setCustomerId] = useState("");
  const [lines, setLines] = useState<Line[]>([]);
  const [productId, setProductId] = useState("");
  const [qty, setQty] = useState("1");
  const [error, setError] = useState<string | null>(null);

  const customerName = (id: string) =>
    customers.data?.find((c) => c.id === id)?.name ?? id.slice(0, 8);
  const productName = (id: string) =>
    products.data?.find((p) => p.id === id)?.name ?? id.slice(0, 8);

  function addLine() {
    if (!productId) return;
    setLines([...lines, { product_id: productId, quantity: Number(qty) || 1 }]);
    setProductId("");
    setQty("1");
  }

  const create = useMutation({
    mutationFn: () => createInvoice({ customer_id: customerId, items: lines }),
    onSuccess: () => {
      setCustomerId("");
      setLines([]);
      setError(null);
      queryClient.invalidateQueries({ queryKey: ["invoices"] });
    },
    onError: () => setError("No se pudo crear la factura"),
  });

  return (
    <div className="page">
      <h1>Facturación</h1>

      <section className="card">
        <h2>Nueva factura</h2>
        <div className="row" style={{ marginBottom: "0.75rem" }}>
          <select value={customerId} onChange={(e) => setCustomerId(e.target.value)}>
            <option value="">— Cliente —</option>
            {customers.data?.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
        </div>

        <div className="row" style={{ marginBottom: "0.75rem" }}>
          <select value={productId} onChange={(e) => setProductId(e.target.value)}>
            <option value="">— Producto —</option>
            {products.data?.map((p) => (
              <option key={p.id} value={p.id}>
                {p.name} ({money(p.price_cents)})
              </option>
            ))}
          </select>
          <input
            type="number"
            min="1"
            value={qty}
            onChange={(e) => setQty(e.target.value)}
            style={{ maxWidth: 90 }}
          />
          <button type="button" className="secondary" onClick={addLine}>
            + Ítem
          </button>
        </div>

        {lines.length > 0 && (
          <ul>
            {lines.map((l, i) => (
              <li key={i}>
                {productName(l.product_id)} × {l.quantity}
              </li>
            ))}
          </ul>
        )}

        {error && <p className="error">{error}</p>}
        <button
          type="button"
          onClick={() => create.mutate()}
          disabled={!customerId || lines.length === 0 || create.isPending}
        >
          Emitir factura
        </button>
      </section>

      <section className="card">
        <table>
          <thead>
            <tr>
              <th>N.º</th>
              <th>Cliente</th>
              <th>Estado</th>
              <th>Total</th>
            </tr>
          </thead>
          <tbody>
            {invoices.data?.map((inv) => (
              <tr key={inv.id}>
                <td>#{String(inv.number).padStart(4, "0")}</td>
                <td>{customerName(inv.customer_id)}</td>
                <td>{inv.status}</td>
                <td>{money(inv.total_cents)}</td>
              </tr>
            ))}
            {invoices.data?.length === 0 && (
              <tr>
                <td colSpan={4} className="empty">
                  Sin facturas todavía.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </section>
    </div>
  );
}
