import { z } from "zod";

import { api } from "@/shared/api/client";

export const customerSchema = z.object({
  id: z.string(),
  name: z.string(),
  email: z.string().nullable(),
  phone: z.string().nullable(),
});
export type Customer = z.infer<typeof customerSchema>;

export async function listCustomers(): Promise<Customer[]> {
  const { data } = await api.get("/customers");
  return z.array(customerSchema).parse(data);
}

export async function createCustomer(input: {
  name: string;
  email: string | null;
  phone: string | null;
}): Promise<Customer> {
  const { data } = await api.post("/customers", input);
  return customerSchema.parse(data);
}
