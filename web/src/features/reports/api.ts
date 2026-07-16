import { z } from "zod";

import { api } from "@/shared/api/client";

export const summarySchema = z.object({
  sales_count: z.number(),
  sales_total_cents: z.number(),
  products_count: z.number(),
  customers_count: z.number(),
  low_stock_count: z.number(),
});
export type Summary = z.infer<typeof summarySchema>;

export const topProductSchema = z.object({
  product_id: z.string(),
  name: z.string(),
  units_sold: z.number(),
});
export type TopProduct = z.infer<typeof topProductSchema>;

export async function fetchSummary(): Promise<Summary> {
  const { data } = await api.get("/reports/summary");
  return summarySchema.parse(data);
}

export async function fetchTopProducts(): Promise<TopProduct[]> {
  const { data } = await api.get("/reports/top-products");
  return z.array(topProductSchema).parse(data);
}
