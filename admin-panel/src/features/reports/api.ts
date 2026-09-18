import { apiClient } from "../../api/client";
import type { ReportPeriod, SalesReport } from "./types";

export interface ReportParams {
  period: ReportPeriod;
  date_from?: string;
  date_to?: string;
}

export async function fetchSalesReport(params: ReportParams): Promise<SalesReport> {
  const { data } = await apiClient.get<SalesReport>("reports/sales/", {
    params: { period: params.period, date_from: params.date_from, date_to: params.date_to },
  });
  return data;
}

export async function downloadSalesReport(
  params: ReportParams,
  fileFormat: "xlsx" | "csv",
): Promise<void> {
  const response = await apiClient.get("reports/sales/export/", {
    params: {
      period: params.period,
      date_from: params.date_from,
      date_to: params.date_to,
      file_format: fileFormat,
    },
    responseType: "blob",
  });
  const url = URL.createObjectURL(response.data as Blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = `sales-report.${fileFormat}`;
  document.body.appendChild(link);
  link.click();
  link.remove();
  URL.revokeObjectURL(url);
}
