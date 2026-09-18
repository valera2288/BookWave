import { useEffect, useState } from "react";

import { extractErrorDetail } from "../../shared/apiTypes";
import { downloadSalesReport, fetchSalesReport } from "./api";
import { PERIOD_LABELS, type ReportPeriod, type SalesReport } from "./types";

export default function ReportsPage() {
  const [period, setPeriod] = useState<ReportPeriod>("day");
  const [dateFrom, setDateFrom] = useState("");
  const [dateTo, setDateTo] = useState("");

  const [report, setReport] = useState<SalesReport | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [exporting, setExporting] = useState<"xlsx" | "csv" | null>(null);

  const customIncomplete = period === "custom" && (!dateFrom || !dateTo);

  useEffect(() => {
    if (customIncomplete) return;
    let cancelled = false;
    setLoading(true);
    setError(null);
    fetchSalesReport({ period, date_from: dateFrom, date_to: dateTo })
      .then((result) => {
        if (!cancelled) setReport(result);
      })
      .catch((err) => {
        if (!cancelled) setError(extractErrorDetail(err, "Не удалось сформировать отчёт."));
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [period, dateFrom, dateTo, customIncomplete]);

  const handleExport = async (fileFormat: "xlsx" | "csv") => {
    setExporting(fileFormat);
    setError(null);
    try {
      await downloadSalesReport({ period, date_from: dateFrom, date_to: dateTo }, fileFormat);
    } catch {
      setError("Не удалось скачать отчёт.");
    } finally {
      setExporting(null);
    }
  };

  return (
    <div>
      <div className="page-header">
        <h2>Отчёты о продажах</h2>
      </div>

      <div className="toolbar">
        <label className="field">
          <span>Период</span>
          <select value={period} onChange={(e) => setPeriod(e.target.value as ReportPeriod)}>
            {Object.entries(PERIOD_LABELS).map(([value, label]) => (
              <option key={value} value={value}>
                {label}
              </option>
            ))}
          </select>
        </label>
        {period === "custom" && (
          <>
            <label className="field">
              <span>Дата с</span>
              <input type="date" value={dateFrom} onChange={(e) => setDateFrom(e.target.value)} />
            </label>
            <label className="field">
              <span>Дата по</span>
              <input type="date" value={dateTo} onChange={(e) => setDateTo(e.target.value)} />
            </label>
          </>
        )}
        <button
          type="button"
          disabled={!report || exporting !== null || customIncomplete}
          onClick={() => handleExport("xlsx")}
        >
          {exporting === "xlsx" ? "Скачивание…" : "Скачать .xlsx"}
        </button>
        <button
          type="button"
          disabled={!report || exporting !== null || customIncomplete}
          onClick={() => handleExport("csv")}
        >
          {exporting === "csv" ? "Скачивание…" : "Скачать .csv"}
        </button>
      </div>

      {error && <p className="error-banner">{error}</p>}

      {customIncomplete ? (
        <p className="empty-state">Укажите обе даты диапазона.</p>
      ) : loading && !report ? (
        <p className="loading-state">Формирование отчёта…</p>
      ) : (
        report && (
          <>
            <p>
              Период: {report.date_from} — {report.date_to}
            </p>
            <div className="form-row" style={{ marginBottom: 24 }}>
              <div>
                <p style={{ fontSize: "1.6rem", margin: 0 }}>{report.order_count}</p>
                <p style={{ margin: 0, opacity: 0.7 }}>заказов</p>
              </div>
              <div>
                <p style={{ fontSize: "1.6rem", margin: 0 }}>{report.total_revenue} ₽</p>
                <p style={{ margin: 0, opacity: 0.7 }}>выручка</p>
              </div>
            </div>

            <h3>Топ-10 продаваемых книг</h3>
            {report.top_books.length === 0 ? (
              <p className="empty-state">За этот период продаж не было.</p>
            ) : (
              <table className="data-table">
                <thead>
                  <tr>
                    <th>#</th>
                    <th>Книга</th>
                    <th>Продано, шт.</th>
                    <th>Выручка</th>
                  </tr>
                </thead>
                <tbody>
                  {report.top_books.map((book, index) => (
                    <tr key={book.book_id}>
                      <td>{index + 1}</td>
                      <td>{book.title}</td>
                      <td>{book.quantity_sold}</td>
                      <td>{book.revenue} ₽</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </>
        )
      )}
    </div>
  );
}
