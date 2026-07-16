import { z } from "zod";

import { api } from "@/shared/api/client";

export const invoiceSchema = z.object({
  id: z.string(),
  number: z.number(),
  customer_id: z.string(),
  status: z.string(),
  total_cents: z.number(),
  created_at: z.string(),
});
export type Invoice = z.infer<typeof invoiceSchema>;

export async function listInvoices(): Promise<Invoice[]> {
  const { data } = await api.get("/invoices");
  return z.array(invoiceSchema).parse(data);
}

export async function createInvoice(input: {
  customer_id: string;
  items: { product_id: string; quantity: number }[];
}): Promise<Invoice> {
  const { data } = await api.post("/invoices", input);
  return invoiceSchema.parse(data);
}
