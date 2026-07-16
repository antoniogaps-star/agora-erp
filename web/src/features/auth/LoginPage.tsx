import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";

import { useAuthStore } from "@/shared/auth/store";

import { login } from "./api";

export function LoginPage() {
  const navigate = useNavigate();
  const setTokens = useAuthStore((s) => s.setTokens);
  const [form, setForm] = useState({ company_slug: "", email: "", password: "" });
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function onSubmit(event: React.FormEvent) {
    event.preventDefault();
    setError(null);
    setLoading(true);
    try {
      const tokens = await login(form);
      setTokens(tokens.access_token, tokens.refresh_token);
      navigate("/");
    } catch {
      setError("Credenciales inválidas");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="center">
      <form className="card" onSubmit={onSubmit}>
        <h1>Ágora ERP · Iniciar sesión</h1>
        <p className="slogan">Dictas. Vendes. Ganas.</p>

        <label htmlFor="company_slug">Empresa</label>
        <input
          id="company_slug"
          value={form.company_slug}
          onChange={(e) => setForm({ ...form, company_slug: e.target.value })}
          placeholder="mi-empresa"
          required
        />

        <label htmlFor="email">Correo</label>
        <input
          id="email"
          type="email"
          value={form.email}
          onChange={(e) => setForm({ ...form, email: e.target.value })}
          required
        />

        <label htmlFor="password">Contraseña</label>
        <input
          id="password"
          type="password"
          value={form.password}
          onChange={(e) => setForm({ ...form, password: e.target.value })}
          required
        />

        {error && <p className="error">{error}</p>}

        <button type="submit" disabled={loading}>
          {loading ? "Entrando…" : "Entrar"}
        </button>
        <Link to="/register">
          <button type="button" className="secondary">
            Crear empresa
          </button>
        </Link>
      </form>
    </div>
  );
}
