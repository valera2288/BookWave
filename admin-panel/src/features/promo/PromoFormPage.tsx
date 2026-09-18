import { type FormEvent, useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";

import { extractErrorDetail } from "../../shared/apiTypes";
import { createPromoCode, fetchPromoCode, updatePromoCode } from "./api";
import { fromDatetimeLocalValue, toDatetimeLocalValue } from "./datetime";
import type { DiscountType } from "./types";

export default function PromoFormPage() {
  const { id } = useParams<{ id: string }>();
  const isEditing = Boolean(id);
  const navigate = useNavigate();

  const [loading, setLoading] = useState(isEditing);
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const [code, setCode] = useState("");
  const [discountType, setDiscountType] = useState<DiscountType>("percent");
  const [discountValue, setDiscountValue] = useState("");
  const [minOrderAmount, setMinOrderAmount] = useState("0");
  const [validFrom, setValidFrom] = useState("");
  const [validUntil, setValidUntil] = useState("");
  const [maxUses, setMaxUses] = useState("");

  useEffect(() => {
    if (!id) return;
    fetchPromoCode(Number(id))
      .then((promo) => {
        setCode(promo.code);
        setDiscountType(promo.discount_type);
        setDiscountValue(promo.discount_value);
        setMinOrderAmount(promo.min_order_amount);
        setValidFrom(toDatetimeLocalValue(promo.valid_from));
        setValidUntil(toDatetimeLocalValue(promo.valid_until));
        setMaxUses(promo.max_uses !== null ? String(promo.max_uses) : "");
      })
      .catch((err) => setError(extractErrorDetail(err, "Не удалось загрузить промокод.")))
      .finally(() => setLoading(false));
  }, [id]);

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      const payload = {
        code,
        discount_type: discountType,
        discount_value: discountValue,
        min_order_amount: minOrderAmount || "0",
        valid_from: fromDatetimeLocalValue(validFrom),
        valid_until: fromDatetimeLocalValue(validUntil),
        max_uses: maxUses ? Number(maxUses) : null,
      };
      if (isEditing) {
        await updatePromoCode(Number(id), payload);
      } else {
        await createPromoCode(payload);
      }
      navigate("/promo");
    } catch (err) {
      setError(extractErrorDetail(err, "Не удалось сохранить промокод."));
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) return <p className="loading-state">Загрузка…</p>;

  return (
    <div>
      <div className="page-header">
        <h2>{isEditing ? "Редактирование промокода" : "Новый промокод"}</h2>
        <Link to="/promo">← К списку промокодов</Link>
      </div>

      {error && <p className="error-banner">{error}</p>}

      <form className="form-card" onSubmit={handleSubmit}>
        <label className="field">
          <span>Код</span>
          <input value={code} onChange={(e) => setCode(e.target.value.toUpperCase())} required />
        </label>

        <div className="form-row">
          <label className="field">
            <span>Тип скидки</span>
            <select value={discountType} onChange={(e) => setDiscountType(e.target.value as DiscountType)}>
              <option value="percent">Процент</option>
              <option value="fixed">Фиксированная сумма</option>
            </select>
          </label>
          <label className="field">
            <span>Размер скидки{discountType === "percent" ? " (%)" : " (₽)"}</span>
            <input
              type="number"
              step="0.01"
              min="0.01"
              value={discountValue}
              onChange={(e) => setDiscountValue(e.target.value)}
              required
            />
          </label>
        </div>

        <label className="field">
          <span>Минимальная сумма заказа, ₽</span>
          <input
            type="number"
            step="0.01"
            min="0"
            value={minOrderAmount}
            onChange={(e) => setMinOrderAmount(e.target.value)}
          />
        </label>

        <div className="form-row">
          <label className="field">
            <span>Действует с</span>
            <input
              type="datetime-local"
              value={validFrom}
              onChange={(e) => setValidFrom(e.target.value)}
              required
            />
          </label>
          <label className="field">
            <span>Действует по</span>
            <input
              type="datetime-local"
              value={validUntil}
              onChange={(e) => setValidUntil(e.target.value)}
              required
            />
          </label>
        </div>

        <label className="field">
          <span>Максимум использований (пусто — без ограничения)</span>
          <input
            type="number"
            min="1"
            value={maxUses}
            onChange={(e) => setMaxUses(e.target.value)}
          />
        </label>

        <div className="form-actions">
          <button type="submit" className="primary" disabled={submitting}>
            {submitting ? "Сохранение…" : "Сохранить"}
          </button>
        </div>
      </form>
    </div>
  );
}
