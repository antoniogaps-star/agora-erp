import { useQuery } from "@tanstack/react-query";
import { useNavigate } from "react-router-dom";

import { useAuthStore } from "@/shared/auth/store";

import { fetchMe } from "./api";

export function DashboardPage() {
  const navigate = useNavigate();
  const clear = useAuthStore((s) => s.clear);
  const { data, isLoading, isError } = useQuery({ queryKey: ["me"], queryFn: fetchMe });

  function logout() {
    clear();
    navigate("/login");
  }

  return (
    <div className="center">
      <div className="card">
        <h1>Panel</h1>
        {isLoading && <p>Cargando…</p>}
        {isError && <p className="error">No se pudo cargar el perfil.</p>}
        {data && (
          <ul>
            <li>
              <strong>Correo:</strong> {data.email}
            </li>
            <li>
              <strong>Rol:</strong> {data.role}
            </li>
            <li>
              <strong>Empresa (tenant):</strong> {data.tenant_id}
            </li>
          </ul>
        )}
        <button type="button" onClick={logout}>
          Cerrar sesión
        </button>
      </div>
    </div>
  );
}
