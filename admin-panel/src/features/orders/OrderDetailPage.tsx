import { useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";

import { extractErrorDetail } from "../../shared/apiTypes";
import { fetchOrder, updateOrderStatus } from "./api";
import { ORDER_STATUS_LABELS, ORDER_STATUSES, type OrderDetail, type OrderStatus } from "./types";

export default function OrderDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const orderId = Number(id);

  const [order, setOrder] = useState<OrderDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [savingStatus, setSavingStatus] = useState(false);
  const [statusSaved, setStatusSaved] = useState(false);

  useEffect(() => {
    if (!statusSaved) return;
    const timer = setTimeout(() => setStatusSaved(false), 3000);
    return () => clearTimeout(timer);
  }, [statusSaved]);

  useEffect(() => {
    if (!Number.isFinite(orderId)) {
      navigate("/orders", { replace: true });
      return;
    }
    setLoading(true);
    fetchOrder(orderId)
      .then(setOrder)
      .catch((err) => setError(extractErrorDetail(err, "Не удалось загрузить заказ.")))
      .finally(() => setLoading(false));
  }, [orderId, navigate]);

  const handleStatusChange = async (status: OrderStatus) => {
    if (!order || status === order.status) return;
    setSavingStatus(true);
    setError(null);
    setStatusSaved(false);
    try {
      const updated = await updateOrderStatus(order.id, status);
      setOrder(updated);
      setStatusSaved(true);
    } catch (err) {
      setError(extractErrorDetail(err, "Не удалось изменить статус заказа."));
    } finally {
      setSavingStatus(false);
    }
  };

  if (loading) return <p className="loading-state">Загрузка…</p>;
  if (!order) return <p className="error-banner">{error ?? "Заказ не найден."}</p>;

  return (
    <div>
      <div className="page-header">
        <h2>Заказ #{order.id}</h2>
        <Link to="/orders">← К списку заказов</Link>
      </div>

      {error && <p className="error-banner">{error}</p>}

      <div className="form-row" style={{ marginBottom: 24 }}>
        <div>
          <p>
            <strong>Покупатель:</strong> {order.buyer_name} ({order.buyer_email})
          </p>
          <p>
            <strong>Дата:</strong> {new Date(order.created_at).toLocaleString("ru-RU")}
          </p>
          <p>
            <strong>Итого:</strong> {order.total_amount} ₽
          </p>
        </div>
        <label className="field" style={{ maxWidth: 220 }}>
          <span>Статус заказа</span>
          <select
            value={order.status}
            disabled={savingStatus}
            onChange={(e) => handleStatusChange(e.target.value as OrderStatus)}
          >
            {ORDER_STATUSES.map((s) => (
              <option key={s} value={s}>
                {ORDER_STATUS_LABELS[s]}
              </option>
            ))}
          </select>
          {savingStatus && <small>Сохранение…</small>}
          {statusSaved && <small style={{ color: "var(--success)" }}>Статус обновлён ✓</small>}
        </label>
      </div>

      <h3>Состав заказа</h3>
      <table className="data-table">
        <thead>
          <tr>
            <th>Книга</th>
            <th>Автор</th>
            <th>Цена на момент покупки</th>
          </tr>
        </thead>
        <tbody>
          {order.items.map((item) => (
            <tr key={item.id}>
              <td>{item.book.title}</td>
              <td>{item.book.authors.map((a) => a.name).join(", ")}</td>
              <td>{item.price_at_purchase} ₽</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
