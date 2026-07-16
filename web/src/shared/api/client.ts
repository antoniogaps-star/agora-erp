import axios, { AxiosError, type InternalAxiosRequestConfig } from "axios";

import { config } from "@/lib/config";
import { useAuthStore } from "@/shared/auth/store";

/** Cliente HTTP con inyección del bearer y refresco automático ante 401. */
export const api = axios.create({
  baseURL: `${config.apiUrl}${config.apiPrefix}`,
});

api.interceptors.request.use((request) => {
  const token = useAuthStore.getState().accessToken;
  if (token) {
    request.headers.Authorization = `Bearer ${token}`;
  }
  return request;
});

interface RetriableConfig extends InternalAxiosRequestConfig {
  _retried?: boolean;
}

// Un único refresco en vuelo compartido por todas las peticiones. Sin esto, varios
// 401 concurrentes dispararían refrescos en paralelo; con rotación de tokens el
// segundo usaría un refresh ya revocado y cerraría la sesión.
let refreshPromise: Promise<string> | null = null;

async function refreshAccessToken(refreshToken: string): Promise<string> {
  const { data } = await axios.post<{ access_token: string; refresh_token: string }>(
    `${config.apiUrl}${config.apiPrefix}/auth/refresh`,
    { refresh_token: refreshToken },
  );
  useAuthStore.getState().setTokens(data.access_token, data.refresh_token);
  return data.access_token;
}

api.interceptors.response.use(
  (response) => response,
  async (error: AxiosError) => {
    const original = error.config as RetriableConfig | undefined;
    const { refreshToken, clear } = useAuthStore.getState();

    if (error.response?.status === 401 && original && !original._retried && refreshToken) {
      original._retried = true;
      try {
        if (!refreshPromise) {
          refreshPromise = refreshAccessToken(refreshToken).finally(() => {
            refreshPromise = null;
          });
        }
        const access = await refreshPromise;
        original.headers.Authorization = `Bearer ${access}`;
        return api(original);
      } catch {
        clear();
      }
    }
    return Promise.reject(error);
  },
);
