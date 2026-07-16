import { useQuery } from "@tanstack/react-query";
import { NavLink, Outlet, useNavigate } from "react-router-dom";

import { logout as logoutApi } from "@/features/auth/api";
import { fetchMe } from "@/features/dashboard/api";
import { useAuthStore } from "@/shared/auth/store";

const LINKS = [
  { to: "/", label: "Inventario", end: true },
  { to: "/customers", label: "Clientes", end: false },
  { to: "/invoices", label: "Facturación", end: false },
  { to: "/reports", label: "Reportes", end: false },
  { to: "/accounting", label: "Contabilidad", end: false },
];

export function AppLayout() {
  const navigate = useNavigate();
  const clear = useAuthStore((s) => s.clear);
  const me = useQuery({ queryKey: ["me"], queryFn: fetchMe });

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
      <main className="content">
        <Outlet />
      </main>
    </div>
  );
}
