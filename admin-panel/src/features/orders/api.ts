import { apiClient } from "../../api/client";
import type { Paginated } from "../../shared/apiTypes";
import type { OrderDetail, OrderListItem, OrderStatus } from "./types";

export interface OrderListParams {
  page: number;
  search?: string;
  status?: OrderStatus | "";
  date_from?: string;
  date_to?: string;
}

export async function fetchOrders(params: OrderListParams): Promise<Paginated<OrderListItem>> {
  const { data } = await apiClient.get<Paginated<OrderListItem>>("orders/admin/", {
    params: {
      page: params.page,
      search: params.search || undefined,
      status: params.status || undefined,
      date_from: params.date_from || undefined,
      date_to: params.date_to || undefined,
    },
  });
  return data;
}

export async function fetchOrder(id: number): Promise<OrderDetail> {
  const { data } = await apiClient.get<OrderDetail>(`orders/admin/${id}/`);
  return data;
}

export async function updateOrderStatus(id: number, status: OrderStatus): Promise<OrderDetail> {
  const { data } = await apiClient.patch<OrderDetail>(`orders/admin/${id}/`, { status });
  return data;
}

export async function exportOrders(params: OrderListParams): Promise<void> {
  const response = await apiClient.get("orders/admin/export/", {
    params: {
      search: params.search || undefined,
      status: params.status || undefined,
      date_from: params.date_from || undefined,
      date_to: params.date_to || undefined,
    },
    responseType: "blob",
  });
  const url = URL.createObjectURL(response.data as Blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = "orders.xlsx";
  document.body.appendChild(link);
  link.click();
  link.remove();
  URL.revokeObjectURL(url);
}
