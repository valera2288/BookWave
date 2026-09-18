export type ReportPeriod = "day" | "week" | "month" | "custom";

export const PERIOD_LABELS: Record<ReportPeriod, string> = {
  day: "День",
  week: "Неделя",
  month: "Месяц",
  custom: "Произвольный диапазон",
};

export interface TopBook {
  book_id: number;
  title: string;
  quantity_sold: number;
  revenue: string;
}

export interface SalesReport {
  period: ReportPeriod;
  date_from: string;
  date_to: string;
  order_count: number;
  total_revenue: string;
  top_books: TopBook[];
}
