import { useQuery } from "@tanstack/react-query";

import { listProducts, listSales } from "@/features/inventory/api";

function download(filename: string, rows: (string | number)[][]) {
  // CSV con BOM para que Excel respete acentos.
  const body = rows
    .map((r) => r.map((c) => `"${String(c).replace(/"/g, '""')}"`).join(","))
    .join("\r\n");
  const blob = new Blob(["﻿" + body], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

export function ExportPage() {
  const products = useQuery({ queryKey: ["products"], queryFn: listProducts });
  const sales = useQuery({ queryKey: ["sales"], queryFn: listSales });

  function exportProducts() {
    const rows: (string | number)[][] = [["Producto", "Precio", "Existencias"]];
    for (const p of products.data ?? []) {
      rows.push([p.name, (p.price_cents / 100).toFixed(2), p.stock]);
    }
    download("productos.csv", rows);
  }

  function exportSales() {
    const nameById = new Map((products.data ?? []).map((p) => [p.id, p.name]));
    const rows: (string | number)[][] = [["Fecha", "Producto", "Cantidad", "Total"]];
    for (const s of sales.data ?? []) {
      rows.push([
        new Date(s.created_at).toLocaleString(),
        nameById.get(s.product_id) ?? s.product_id,
        s.quantity,
        (s.total_cents / 100).toFixed(2),
      ]);
    }
    download("ventas.csv", rows);
  }

  return (
    <div className="page">
      <h1>Exportación a Excel</h1>
      <p style={{ color: "#666", marginTop: "-0.5rem" }}>
        Descarga tu información en archivos que abres directamente en Excel.
      </p>
      <section className="card">
        <p>
          <strong>Inventario</strong> — {products.data?.length ?? 0} productos.
        </p>
        <button type="button" onClick={exportProducts} disabled={!products.data}>
          Descargar productos (Excel)
        </button>
        <hr style={{ margin: "1.25rem 0", border: 0, borderTop: "1px solid #eee" }} />
        <p>
          <strong>Ventas</strong> — {sales.data?.length ?? 0} movimientos.
        </p>
        <button type="button" onClick={exportSales} disabled={!sales.data}>
          Descargar ventas (Excel)
        </button>
      </section>
    </div>
  );
}
