export type OrderStatus = "paid" | "cancelled" | "refunded";

export const ORDER_STATUS_LABELS: Record<OrderStatus, string> = {
  paid: "Оплачен",
  cancelled: "Отменён",
  refunded: "Возврат",
};

export const ORDER_STATUSES: OrderStatus[] = ["paid", "cancelled", "refunded"];

export interface OrderListItem {
  id: number;
  buyer_email: string;
  buyer_name: string;
  status: OrderStatus;
  total_amount: string;
  item_count: number;
  created_at: string;
}

export interface OrderBook {
  id: number;
  title: string;
  authors: { id: number; name: string }[];
  cover: string | null;
  price: string;
  average_rating: number | null;
  rating_count: number;
}

export interface OrderItemDetail {
  id: number;
  book: OrderBook;
  price_at_purchase: string;
}

export interface OrderDetail {
  id: number;
  buyer_email: string;
  buyer_name: string;
  status: OrderStatus;
  total_amount: string;
  created_at: string;
  items: OrderItemDetail[];
}
