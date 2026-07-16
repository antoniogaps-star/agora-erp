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

api.interceptors.response.use(
  (response) => response,
  async (error: AxiosError) => {
    const original = error.config as RetriableConfig | undefined;
    const { refreshToken, setTokens, clear } = useAuthStore.getState();

    // Un 401 en una petición normal: intentar refrescar el token una sola vez.
    if (error.response?.status === 401 && original && !original._retried && refreshToken) {
      original._retried = true;
      try {
        const { data } = await axios.post<{ access_token: string; refresh_token: string }>(
          `${config.apiUrl}${config.apiPrefix}/auth/refresh`,
          { refresh_token: refreshToken },
        );
        setTokens(data.access_token, data.refresh_token);
        original.headers.Authorization = `Bearer ${data.access_token}`;
        return api(original);
      } catch {
        clear();
      }
    }
    return Promise.reject(error);
  },
);
