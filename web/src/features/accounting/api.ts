import { z } from "zod";

import { api } from "@/shared/api/client";

export const entrySchema = z.object({
  id: z.string(),
  entry_type: z.string(),
  concept: z.string(),
  amount_cents: z.number(),
  occurred_on: z.string(),
});
export type LedgerEntry = z.infer<typeof entrySchema>;

export const balanceSchema = z.object({
  income_cents: z.number(),
  expense_cents: z.number(),
  balance_cents: z.number(),
});
export type Balance = z.infer<typeof balanceSchema>;

export async function listEntries(): Promise<LedgerEntry[]> {
  const { data } = await api.get("/accounting/entries");
  return z.array(entrySchema).parse(data);
}

export async function fetchBalance(): Promise<Balance> {
  const { data } = await api.get("/accounting/balance");
  return balanceSchema.parse(data);
}

export async function createEntry(input: {
  entry_type: "income" | "expense";
  concept: string;
  amount_cents: number;
  occurred_on: string;
}): Promise<LedgerEntry> {
  const { data } = await api.post("/accounting/entries", input);
  return entrySchema.parse(data);
}
