import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";

import { extractErrorDetail, type Paginated } from "../../shared/apiTypes";
import Pagination from "../../shared/Pagination";
import { useDebouncedValue } from "../../shared/useDebouncedValue";
import { exportOrders, fetchOrders } from "./api";
import { ORDER_STATUS_LABELS, ORDER_STATUSES, type OrderListItem, type OrderStatus } from "./types";

export default function OrdersListPage() {
  const navigate = useNavigate();
  const [page, setPage] = useState(1);
  const [searchInput, setSearchInput] = useState("");
  const search = useDebouncedValue(searchInput);
  const [status, setStatus] = useState<OrderStatus | "">("");
  const [dateFrom, setDateFrom] = useState("");
  const [dateTo, setDateTo] = useState("");

  const [data, setData] = useState<Paginated<OrderListItem> | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [exporting, setExporting] = useState(false);

  useEffect(() => {
    setPage(1);
  }, [search, status, dateFrom, dateTo]);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(null);
    fetchOrders({ page, search, status, date_from: dateFrom, date_to: dateTo })
      .then((result) => {
        if (!cancelled) setData(result);
      })
      .catch((err) => {
        if (!cancelled) setError(extractErrorDetail(err, "Не удалось загрузить заказы."));
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [page, search, status, dateFrom, dateTo]);

  const handleExport = async () => {
    setExporting(true);
    setError(null);
    try {
      await exportOrders({ page, search, status, date_from: dateFrom, date_to: dateTo });
    } catch {
      setError("Не удалось скачать таблицу заказов.");
    } finally {
      setExporting(false);
    }
  };

  return (
    <div>
      <div className="page-header">
        <h2>Заказы</h2>
        <button type="button" onClick={handleExport} disabled={exporting}>
          {exporting ? "Экспорт…" : "Экспорт в Excel"}
        </button>
      </div>

      <div className="toolbar">
        <label className="field">
          <span>Поиск</span>
          <input
            placeholder="Номер заказа или e-mail"
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
          />
        </label>
        <label className="field">
          <span>Статус</span>
          <select value={status} onChange={(e) => setStatus(e.target.value as OrderStatus | "")}>
            <option value="">Все</option>
            {ORDER_STATUSES.map((s) => (
              <option key={s} value={s}>
                {ORDER_STATUS_LABELS[s]}
              </option>
            ))}
          </select>
        </label>
        <label className="field">
          <span>Дата с</span>
          <input type="date" value={dateFrom} onChange={(e) => setDateFrom(e.target.value)} />
        </label>
        <label className="field">
          <span>Дата по</span>
          <input type="date" value={dateTo} onChange={(e) => setDateTo(e.target.value)} />
        </label>
      </div>

      {error && <p className="error-banner">{error}</p>}

      {loading && !data ? (
        <p className="loading-state">Загрузка…</p>
      ) : data && data.results.length === 0 ? (
        <p className="empty-state">Заказов не найдено.</p>
      ) : (
        data && (
          <>
            <table className="data-table">
              <thead>
                <tr>
                  <th>№</th>
                  <th>Покупатель</th>
                  <th>Сумма</th>
                  <th>Статус</th>
                  <th>Дата</th>
                </tr>
              </thead>
              <tbody>
                {data.results.map((order) => (
                  <tr
                    key={order.id}
                    className="row-link"
                    onClick={() => navigate(`/orders/${order.id}`)}
                  >
                    <td>#{order.id}</td>
                    <td>
                      {order.buyer_name}
                      <br />
                      <small>{order.buyer_email}</small>
                    </td>
                    <td>{order.total_amount} ₽</td>
                    <td>
                      <span className={`badge ${statusBadgeClass(order.status)}`}>
                        {ORDER_STATUS_LABELS[order.status]}
                      </span>
                    </td>
                    <td>{new Date(order.created_at).toLocaleString("ru-RU")}</td>
                  </tr>
                ))}
              </tbody>
            </table>
            <Pagination page={page} count={data.count} onChange={setPage} />
          </>
        )
      )}
    </div>
  );
}

function statusBadgeClass(status: OrderStatus): string {
  if (status === "paid") return "badge-success";
  if (status === "cancelled") return "badge-danger";
  return "badge-warning";
}
