import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";

import { extractErrorDetail } from "../../shared/apiTypes";
import { deletePromoCode, fetchPromoCodes } from "./api";
import { DISCOUNT_TYPE_LABELS, PROMO_STATUS_LABELS, type PromoCode, type PromoStatus } from "./types";

export default function PromoListPage() {
  const navigate = useNavigate();
  const [items, setItems] = useState<PromoCode[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchPromoCodes()
      .then(setItems)
      .catch((err) => setError(extractErrorDetail(err, "Не удалось загрузить промокоды.")))
      .finally(() => setLoading(false));
  }, []);

  const handleDelete = async (promo: PromoCode) => {
    if (!window.confirm(`Удалить промокод «${promo.code}»?`)) return;
    try {
      await deletePromoCode(promo.id);
      setItems((prev) => prev.filter((p) => p.id !== promo.id));
    } catch (err) {
      setError(extractErrorDetail(err, "Не удалось удалить промокод."));
    }
  };

  return (
    <div>
      <div className="page-header">
        <h2>Промокоды</h2>
        <button type="button" className="primary" onClick={() => navigate("/promo/new")}>
          Создать промокод
        </button>
      </div>

      {error && <p className="error-banner">{error}</p>}

      {loading ? (
        <p className="loading-state">Загрузка…</p>
      ) : items.length === 0 ? (
        <p className="empty-state">Промокодов пока нет.</p>
      ) : (
        <table className="data-table">
          <thead>
            <tr>
              <th>Код</th>
              <th>Скидка</th>
              <th>Мин. сумма заказа</th>
              <th>Срок действия</th>
              <th>Использований</th>
              <th>Статус</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {items.map((promo) => (
              <tr key={promo.id}>
                <td>{promo.code}</td>
                <td>
                  {promo.discount_value}
                  {promo.discount_type === "percent" ? "%" : " ₽"} (
                  {DISCOUNT_TYPE_LABELS[promo.discount_type]})
                </td>
                <td>{promo.min_order_amount} ₽</td>
                <td>
                  {new Date(promo.valid_from).toLocaleDateString("ru-RU")} —{" "}
                  {new Date(promo.valid_until).toLocaleDateString("ru-RU")}
                </td>
                <td>
                  {promo.usage_count}
                  {promo.max_uses !== null ? ` / ${promo.max_uses}` : ""}
                </td>
                <td>
                  <span className={`badge ${statusBadgeClass(promo.status)}`}>
                    {PROMO_STATUS_LABELS[promo.status]}
                  </span>
                </td>
                <td className="actions-cell">
                  <Link to={`/promo/${promo.id}/edit`}>
                    <button type="button">Изменить</button>
                  </Link>
                  <button type="button" className="danger" onClick={() => handleDelete(promo)}>
                    Удалить
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}

function statusBadgeClass(status: PromoStatus): string {
  if (status === "active") return "badge-success";
  if (status === "expired") return "badge-neutral";
  return "badge-danger";
}
