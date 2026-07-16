/** Configuración de la app web, leída de variables de entorno de Vite. */
export const config = {
  apiUrl: import.meta.env.VITE_API_URL ?? "http://localhost:8000",
  apiPrefix: "/api/v1",
} as const;
