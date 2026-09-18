export type DiscountType = "percent" | "fixed";

export const DISCOUNT_TYPE_LABELS: Record<DiscountType, string> = {
  percent: "Процент",
  fixed: "Фиксированная сумма",
};

export type PromoStatus = "active" | "expired" | "exhausted";

export const PROMO_STATUS_LABELS: Record<PromoStatus, string> = {
  active: "Активен",
  expired: "Истёк",
  exhausted: "Исчерпан",
};

export interface PromoCode {
  id: number;
  code: string;
  discount_type: DiscountType;
  discount_value: string;
  min_order_amount: string;
  valid_from: string;
  valid_until: string;
  max_uses: number | null;
  usage_count: number;
  status: PromoStatus;
}

export interface PromoWritePayload {
  code: string;
  discount_type: DiscountType;
  discount_value: string;
  min_order_amount: string;
  valid_from: string;
  valid_until: string;
  max_uses: number | null;
}
