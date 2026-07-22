import { useQuery } from "@tanstack/react-query";

import { fetchMe } from "@/features/dashboard/api";

export function BusinessPage() {
  const me = useQuery({ queryKey: ["me"], queryFn: fetchMe });

  return (
    <div className="page">
      <h1>Gestión de negocios</h1>
      <p style={{ color: "#666", marginTop: "-0.5rem" }}>
        Administra tus negocios (sucursales) desde un solo lugar.
      </p>

      <section className="card">
        <h2>Negocio actual</h2>
        <table>
          <tbody>
            <tr>
              <th style={{ width: "40%" }}>Identificador del negocio</th>
              <td>{me.data?.tenant_id ?? "—"}</td>
            </tr>
            <tr>
              <th>Dueño</th>
              <td>{me.data?.email ?? "—"}</td>
            </tr>
          </tbody>
        </table>
      </section>

      <section className="card">
        <h2>Más negocios</h2>
        <p>
          Administrar varios negocios (2 a 6 según tu plan) estará disponible aquí. Cada
          negocio lleva su inventario y sus ventas por separado, con un control centralizado.
        </p>
        <p style={{ color: "#666" }}>
          Los planes <strong>Profesional</strong> (hasta 3) y <strong>Empresarial</strong>{" "}
          (hasta 6) habilitan varios negocios.
        </p>
      </section>
    </div>
  );
}
