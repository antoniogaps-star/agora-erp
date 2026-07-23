import { useQuery } from "@tanstack/react-query";
import { NavLink, Outlet, useNavigate } from "react-router-dom";

import { logout as logoutApi } from "@/features/auth/api";
import { fetchMe } from "@/features/dashboard/api";
import { useAuthStore } from "@/shared/auth/store";
import { useSubscriptionStore } from "@/shared/billing/subscription";

const LINKS = [
  { to: "/", label: "Dashboard", end: true },
  { to: "/inventario", label: "Inventario", end: false },
  { to: "/productos", label: "Productos", end: false },
  { to: "/movimientos", label: "Movimientos", end: false },
  { to: "/reportes", label: "Reportes", end: false },
  { to: "/exportar", label: "Exportar Excel", end: false },
  { to: "/negocios", label: "Negocios", end: false },
  { to: "/usuarios", label: "Usuarios", end: false },
];

export function AppLayout() {
  const navigate = useNavigate();
  const clear = useAuthStore((s) => s.clear);
  const me = useQuery({ queryKey: ["me"], queryFn: fetchMe });
  const subExpired = useSubscriptionStore((s) => s.message);
  const clearSub = useSubscriptionStore((s) => s.clear);

  async function logout() {
    const refresh = useAuthStore.getState().refreshToken;
    if (refresh) {
      try {
        await logoutApi(refresh);
      } catch {
        /* cerramos igual localmente */
      }
    }
    clear();
    navigate("/login");
  }

  return (
    <div>
      <nav className="topnav">
        <span className="brand">Ágora ERP</span>
        <div className="navlinks">
          {LINKS.map((l) => (
            <NavLink
              key={l.to}
              to={l.to}
              end={l.end}
              className={({ isActive }) => (isActive ? "active" : "")}
            >
              {l.label}
            </NavLink>
          ))}
        </div>
        <div className="navuser">
          <span>{me.data?.email}</span>
          <button type="button" className="linkbtn" onClick={logout}>
            Salir
          </button>
        </div>
      </nav>
      {subExpired && (
        <div
          role="alert"
          style={{
            background: "#fff7e6",
            borderBottom: "1px solid #f59e0b",
            color: "#92400e",
            padding: "0.6rem 1rem",
            display: "flex",
            alignItems: "center",
            gap: "0.75rem",
          }}
        >
          <span style={{ flex: 1 }}>⚠️ {subExpired}</span>
          <button
            type="button"
            className="linkbtn"
            onClick={clearSub}
            aria-label="Cerrar aviso"
          >
            Entendido
          </button>
        </div>
      )}
      <main className="content">
        <Outlet />
      </main>
    </div>
  );
}
