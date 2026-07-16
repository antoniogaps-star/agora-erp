import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";

import { createEntry, fetchBalance, listEntries } from "./api";

function money(cents: number): string {
  return `$${(cents / 100).toFixed(2)}`;
}

const TODAY = new Date().toISOString().slice(0, 10);

export function AccountingPage() {
  const queryClient = useQueryClient();
  const entries = useQuery({ queryKey: ["ledger"], queryFn: listEntries });
  const balance = useQuery({ queryKey: ["balance"], queryFn: fetchBalance });

  const [form, setForm] = useState({
    entry_type: "income" as "income" | "expense",
    concept: "",
    amount: "",
    occurred_on: TODAY,
  });

  const add = useMutation({
    mutationFn: () =>
      createEntry({
        entry_type: form.entry_type,
        concept: form.concept,
        amount_cents: Math.round(Number(form.amount) * 100),
        occurred_on: form.occurred_on,
      }),
    onSuccess: () => {
      setForm({ ...form, concept: "", amount: "" });
      queryClient.invalidateQueries({ queryKey: ["ledger"] });
      queryClient.invalidateQueries({ queryKey: ["balance"] });
    },
  });

  const b = balance.data;

  return (
    <div className="page">
      <h1>Contabilidad</h1>

      <div className="stat-grid" style={{ marginBottom: "1.5rem" }}>
        <div className="stat">
          <div className="value" style={{ color: "#1a9d54" }}>{b ? money(b.income_cents) : "—"}</div>
          <div className="label">Ingresos</div>
        </div>
        <div className="stat">
          <div className="value" style={{ color: "#c0392b" }}>{b ? money(b.expense_cents) : "—"}</div>
          <div className="label">Egresos</div>
        </div>
        <div className="stat">
          <div className="value">{b ? money(b.balance_cents) : "—"}</div>
          <div className="label">Balance</div>
        </div>
      </div>

      <section className="card">
        <h2>Nuevo asiento</h2>
        <form
          className="row"
          onSubmit={(e) => {
            e.preventDefault();
            add.mutate();
          }}
        >
          <select
            value={form.entry_type}
            onChange={(e) => setForm({ ...form, entry_type: e.target.value as "income" | "expense" })}
          >
            <option value="income">Ingreso</option>
            <option value="expense">Egreso</option>
          </select>
          <input
            placeholder="Concepto"
            value={form.concept}
            onChange={(e) => setForm({ ...form, concept: e.target.value })}
            required
          />
          <input
            type="number"
            step="0.01"
            min="0"
            placeholder="Importe"
            value={form.amount}
            onChange={(e) => setForm({ ...form, amount: e.target.value })}
            required
          />
          <input
            type="date"
            value={form.occurred_on}
            onChange={(e) => setForm({ ...form, occurred_on: e.target.value })}
          />
          <button type="submit" disabled={add.isPending}>
            Registrar
          </button>
        </form>
      </section>

      <section className="card">
        <table>
          <thead>
            <tr>
              <th>Fecha</th>
              <th>Tipo</th>
              <th>Concepto</th>
              <th>Importe</th>
            </tr>
          </thead>
          <tbody>
            {entries.data?.map((e) => (
              <tr key={e.id}>
                <td>{e.occurred_on}</td>
                <td>{e.entry_type === "income" ? "Ingreso" : "Egreso"}</td>
                <td>{e.concept}</td>
                <td>{money(e.amount_cents)}</td>
              </tr>
            ))}
            {entries.data?.length === 0 && (
              <tr>
                <td colSpan={4} className="empty">
                  Sin asientos todavía.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </section>
    </div>
  );
}
