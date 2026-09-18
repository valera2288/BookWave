import { useEffect, useState } from "react";

import { extractErrorDetail, type Paginated } from "../../shared/apiTypes";
import Pagination from "../../shared/Pagination";
import { deleteReview, fetchReviews, setReviewHidden } from "./api";
import type { ReviewAdmin } from "./types";

export default function ReviewsPage() {
  const [page, setPage] = useState(1);
  const [data, setData] = useState<Paginated<ReviewAdmin> | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    fetchReviews(page)
      .then((result) => {
        if (!cancelled) setData(result);
      })
      .catch((err) => {
        if (!cancelled) setError(extractErrorDetail(err, "Не удалось загрузить отзывы."));
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [page]);

  const updateLocal = (updated: ReviewAdmin) => {
    setData((prev) =>
      prev
        ? { ...prev, results: prev.results.map((r) => (r.id === updated.id ? updated : r)) }
        : prev,
    );
  };

  const handleToggleHidden = async (review: ReviewAdmin) => {
    setError(null);
    try {
      const updated = await setReviewHidden(review.id, !review.is_hidden);
      updateLocal(updated);
    } catch (err) {
      setError(extractErrorDetail(err, "Не удалось изменить видимость отзыва."));
    }
  };

  const handleDelete = async (review: ReviewAdmin) => {
    if (!window.confirm("Удалить отзыв безвозвратно?")) return;
    setError(null);
    try {
      await deleteReview(review.id);
      setData((prev) =>
        prev ? { ...prev, results: prev.results.filter((r) => r.id !== review.id) } : prev,
      );
    } catch (err) {
      setError(extractErrorDetail(err, "Не удалось удалить отзыв."));
    }
  };

  return (
    <div>
      <div className="page-header">
        <h2>Модерация отзывов</h2>
      </div>

      {error && <p className="error-banner">{error}</p>}

      {loading && !data ? (
        <p className="loading-state">Загрузка…</p>
      ) : data && data.results.length === 0 ? (
        <p className="empty-state">Отзывов нет.</p>
      ) : (
        data && (
          <>
            <table className="data-table">
              <thead>
                <tr>
                  <th>Книга</th>
                  <th>Автор отзыва</th>
                  <th>Оценка</th>
                  <th>Текст</th>
                  <th>Статус</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {data.results.map((review) => (
                  <tr key={review.id}>
                    <td>{review.book_title}</td>
                    <td>
                      {review.user_name}
                      <br />
                      <small>{review.user_email}</small>
                    </td>
                    <td>{review.rating} / 5</td>
                    <td>
                      <span className="truncate-cell" title={review.text || undefined}>
                        {review.text || <em>без текста</em>}
                      </span>
                    </td>
                    <td>
                      <span className={`badge ${review.is_hidden ? "badge-danger" : "badge-success"}`}>
                        {review.is_hidden ? "Скрыт" : "Виден"}
                      </span>
                    </td>
                    <td className="actions-cell">
                      <button type="button" onClick={() => handleToggleHidden(review)}>
                        {review.is_hidden ? "Показать" : "Скрыть"}
                      </button>
                      <button type="button" className="danger" onClick={() => handleDelete(review)}>
                        Удалить
                      </button>
                    </td>
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
