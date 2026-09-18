const ACCESS_KEY = "bw_admin_access";
const REFRESH_KEY = "bw_admin_refresh";

export interface TokenPayload {
  user_id: string;
  role: "reader" | "admin";
  token_version: number;
  exp: number;
}

export function getAccessToken(): string | null {
  return localStorage.getItem(ACCESS_KEY);
}

export function getRefreshToken(): string | null {
  return localStorage.getItem(REFRESH_KEY);
}

export function saveTokens(access: string, refresh: string): void {
  localStorage.setItem(ACCESS_KEY, access);
  localStorage.setItem(REFRESH_KEY, refresh);
}

export function clearTokens(): void {
  localStorage.removeItem(ACCESS_KEY);
  localStorage.removeItem(REFRESH_KEY);
}

/** JWT не верифицируется на клиенте (для этого нет секрета) — только
 * читается, чтобы сразу показать/скрыть разделы UI. Реальная проверка прав
 * всегда происходит на сервере (`IsAdminRole` на каждом эндпоинте). */
export function decodeToken(token: string): TokenPayload | null {
  try {
    const base64 = token.split(".")[1].replace(/-/g, "+").replace(/_/g, "/");
    return JSON.parse(atob(base64));
  } catch {
    return null;
  }
}
