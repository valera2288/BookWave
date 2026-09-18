import axios from "axios";

import { clearTokens, getAccessToken, getRefreshToken, saveTokens } from "../features/auth/tokenStorage";

export const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL,
});

const PUBLIC_PATHS = ["users/login/", "users/token/refresh/"];
const isPublicPath = (url?: string) => Boolean(url && PUBLIC_PATHS.some((path) => url.includes(path)));

apiClient.interceptors.request.use((config) => {
  if (!isPublicPath(config.url)) {
    const token = getAccessToken();
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
  }
  return config;
});

let refreshing: Promise<string | null> | null = null;

async function refreshAccessToken(): Promise<string | null> {
  const refreshToken = getRefreshToken();
  if (!refreshToken) return null;
  try {
    const { data } = await apiClient.post("users/token/refresh/", { refresh: refreshToken });
    saveTokens(data.access, refreshToken);
    return data.access as string;
  } catch {
    clearTokens();
    return null;
  }
}

apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    const original = error.config;
    const alreadyRetried = original?._retried === true;
    if (error.response?.status !== 401 || isPublicPath(original?.url) || alreadyRetried) {
      return Promise.reject(error);
    }

    // Несколько параллельных 401 не должны запускать несколько refresh —
    // переиспользуем один и тот же Promise, пока он не завершится (тот же
    // приём, что и в мобильном AuthInterceptor).
    refreshing ??= refreshAccessToken().finally(() => {
      refreshing = null;
    });
    const newAccessToken = await refreshing;

    if (!newAccessToken) {
      clearTokens();
      if (window.location.pathname !== "/login") {
        window.location.assign("/login");
      }
      return Promise.reject(error);
    }

    original._retried = true;
    original.headers.Authorization = `Bearer ${newAccessToken}`;
    return apiClient(original);
  },
);
