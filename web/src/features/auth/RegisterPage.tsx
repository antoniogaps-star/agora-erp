import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";

import { useAuthStore } from "@/shared/auth/store";

import { register } from "./api";

export function RegisterPage() {
  const navigate = useNavigate();
  const setTokens = useAuthStore((s) => s.setTokens);
  const [form, setForm] = useState({
    company_name: "",
    company_slug: "",
    email: "",
    password: "",
  });
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function onSubmit(event: React.FormEvent) {
    event.preventDefault();
    setError(null);
    setLoading(true);
    try {
      const tokens = await register(form);
      setTokens(tokens.access_token, tokens.refresh_token);
      navigate("/");
    } catch {
      setError("No se pudo crear la empresa (¿identificador ya en uso?)");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="center">
      <form className="card" onSubmit={onSubmit}>
        <h1>Ágora ERP · Crear empresa</h1>
        <p className="slogan">Dictas. Vendes. Controlas.</p>

        <label htmlFor="company_name">Nombre de la empresa</label>
        <input
          id="company_name"
          value={form.company_name}
          onChange={(e) => setForm({ ...form, company_name: e.target.value })}
          required
        />

        <label htmlFor="company_slug">Identificador (slug)</label>
        <input
          id="company_slug"
          value={form.company_slug}
          onChange={(e) => setForm({ ...form, company_slug: e.target.value })}
          placeholder="mi-empresa"
          required
        />

        <label htmlFor="email">Correo del dueño</label>
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
          minLength={8}
          required
        />

        {error && <p className="error">{error}</p>}

        <button type="submit" disabled={loading}>
          {loading ? "Creando…" : "Crear empresa"}
        </button>
        <Link to="/login">
          <button type="button" className="secondary">
            Ya tengo cuenta
          </button>
        </Link>
      </form>
    </div>
  );
}
