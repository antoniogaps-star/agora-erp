import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";

import { createCustomer, listCustomers } from "./api";

export function CustomersPage() {
  const queryClient = useQueryClient();
  const customers = useQuery({ queryKey: ["customers"], queryFn: listCustomers });
  const [form, setForm] = useState({ name: "", email: "", phone: "" });

  const add = useMutation({
    mutationFn: () =>
      createCustomer({
        name: form.name,
        email: form.email || null,
        phone: form.phone || null,
      }),
    onSuccess: () => {
      setForm({ name: "", email: "", phone: "" });
      queryClient.invalidateQueries({ queryKey: ["customers"] });
    },
  });

  return (
    <div className="page">
      <h1>Clientes</h1>

      <section className="card">
        <h2>Nuevo cliente</h2>
        <form
          className="row"
          onSubmit={(e) => {
            e.preventDefault();
            add.mutate();
          }}
        >
          <input
            placeholder="Nombre"
            value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })}
            required
          />
          <input
            placeholder="Correo"
            value={form.email}
            onChange={(e) => setForm({ ...form, email: e.target.value })}
          />
          <input
            placeholder="Teléfono"
            value={form.phone}
            onChange={(e) => setForm({ ...form, phone: e.target.value })}
          />
          <button type="submit" disabled={add.isPending}>
            Agregar
          </button>
        </form>
      </section>

      <section className="card">
        <table>
          <thead>
            <tr>
              <th>Nombre</th>
              <th>Correo</th>
              <th>Teléfono</th>
            </tr>
          </thead>
          <tbody>
            {customers.data?.map((c) => (
              <tr key={c.id}>
                <td>{c.name}</td>
                <td>{c.email ?? "—"}</td>
                <td>{c.phone ?? "—"}</td>
              </tr>
            ))}
            {customers.data?.length === 0 && (
              <tr>
                <td colSpan={3} className="empty">
                  Sin clientes todavía.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </section>
    </div>
  );
}
