import { z } from "zod";

import { api } from "@/shared/api/client";

export const productSchema = z.object({
  id: z.string(),
  name: z.string(),
  price_cents: z.number(),
  stock: z.number(),
});
export type Product = z.infer<typeof productSchema>;

export const saleSchema = z.object({
  id: z.string(),
  product_id: z.string(),
  quantity: z.number(),
  unit_price_cents: z.number(),
  total_cents: z.number(),
  created_at: z.string(),
});
export type Sale = z.infer<typeof saleSchema>;

export async function listProducts(): Promise<Product[]> {
  const { data } = await api.get("/products");
  return z.array(productSchema).parse(data);
}

export async function createProduct(input: {
  name: string;
  price_cents: number;
  initial_stock: number;
}): Promise<Product> {
  const { data } = await api.post("/products", input);
  return productSchema.parse(data);
}

export async function createSale(input: {
  product_id: string;
  quantity: number;
}): Promise<Sale> {
  const { data } = await api.post("/sales", input);
  return saleSchema.parse(data);
}

export async function deleteProduct(id: string): Promise<void> {
  await api.delete(`/products/${id}`);
}

export async function listSales(): Promise<Sale[]> {
  const { data } = await api.get("/sales");
  return z.array(saleSchema).parse(data);
}
