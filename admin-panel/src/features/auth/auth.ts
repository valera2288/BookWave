import { apiClient } from "../../api/client";
import { clearTokens, decodeToken, getAccessToken, saveTokens } from "./tokenStorage";

export class AdminAccessError extends Error {}

export async function login(email: string, password: string): Promise<void> {
  const { data } = await apiClient.post("users/login/", { email, password });
  const payload = decodeToken(data.access);
  if (payload?.role !== "admin") {
    throw new AdminAccessError(
      "Доступ к панели администратора есть только у роли «Администратор».",
    );
  }
  saveTokens(data.access, data.refresh);
}

export function logout(): void {
  clearTokens();
}

export function isAdminSession(): boolean {
  const token = getAccessToken();
  if (!token) return false;
  return decodeToken(token)?.role === "admin";
}
