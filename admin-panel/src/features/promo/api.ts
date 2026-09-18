import { apiClient } from "../../api/client";
import type { PromoCode, PromoWritePayload } from "./types";

export async function fetchPromoCodes(): Promise<PromoCode[]> {
  const { data } = await apiClient.get<PromoCode[]>("promo/admin/");
  return data;
}

export async function fetchPromoCode(id: number): Promise<PromoCode> {
  const { data } = await apiClient.get<PromoCode>(`promo/admin/${id}/`);
  return data;
}

export async function createPromoCode(payload: PromoWritePayload): Promise<PromoCode> {
  const { data } = await apiClient.post<PromoCode>("promo/admin/", payload);
  return data;
}

export async function updatePromoCode(id: number, payload: PromoWritePayload): Promise<PromoCode> {
  const { data } = await apiClient.patch<PromoCode>(`promo/admin/${id}/`, payload);
  return data;
}

export async function deletePromoCode(id: number): Promise<void> {
  await apiClient.delete(`promo/admin/${id}/`);
}
