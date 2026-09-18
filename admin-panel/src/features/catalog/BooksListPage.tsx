import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";

import { extractErrorDetail, type Paginated } from "../../shared/apiTypes";
import Pagination from "../../shared/Pagination";
import { useDebouncedValue } from "../../shared/useDebouncedValue";
import { deleteBook, fetchAuthors, fetchBooks, fetchGenres } from "./api";
import type { Author, BookAdmin, Genre } from "./types";

export default function BooksListPage() {
  const navigate = useNavigate();
  const [page, setPage] = useState(1);
  const [searchInput, setSearchInput] = useState("");
  const search = useDebouncedValue(searchInput);
  const [genreFilter, setGenreFilter] = useState<number | "">("");

  const [genres, setGenres] = useState<Genre[]>([]);
  const [authors, setAuthors] = useState<Author[]>([]);
  const [data, setData] = useState<Paginated<BookAdmin> | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    Promise.all([fetchGenres(), fetchAuthors()]).then(([g, a]) => {
      setGenres(g);
      setAuthors(a);
    });
  }, []);

  useEffect(() => {
    setPage(1);
  }, [search, genreFilter]);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(null);
    fetchBooks({ page, search, genre: genreFilter })
      .then((result) => {
        if (!cancelled) setData(result);
      })
      .catch((err) => {
        if (!cancelled) setError(extractErrorDetail(err, "Не удалось загрузить книги."));
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [page, search, genreFilter]);

  const genreName = (id: number) => genres.find((g) => g.id === id)?.name ?? `#${id}`;
  const authorName = (id: number) => authors.find((a) => a.id === id)?.name ?? `#${id}`;

  const handleDelete = async (book: BookAdmin) => {
    if (!window.confirm(`Удалить книгу «${book.title}»? Она перестанет отображаться в каталоге.`)) {
      return;
    }
    try {
      await deleteBook(book.id);
      // Мягкое удаление на сервере (is_active=False) — сама книга в БД
      // остаётся, но в списке управления каталогом ей больше делать нечего,
      // поэтому просто убираем строку локально, не перезапрашивая список.
      setData((prev) => (prev ? { ...prev, results: prev.results.filter((b) => b.id !== book.id) } : prev));
    } catch (err) {
      setError(extractErrorDetail(err, "Не удалось удалить книгу."));
    }
  };

  return (
    <div>
      <div className="page-header">
        <h2>Книги</h2>
        <button type="button" className="primary" onClick={() => navigate("/catalog/books/new")}>
          Добавить книгу
        </button>
      </div>

      <div className="toolbar">
        <label className="field">
          <span>Поиск</span>
          <input
            placeholder="Название или автор"
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
          />
        </label>
        <label className="field">
          <span>Жанр</span>
          <select
            value={genreFilter}
            onChange={(e) => setGenreFilter(e.target.value ? Number(e.target.value) : "")}
          >
            <option value="">Все</option>
            {genres.map((g) => (
              <option key={g.id} value={g.id}>
                {g.name}
              </option>
            ))}
          </select>
        </label>
      </div>

      {error && <p className="error-banner">{error}</p>}

      {loading && !data ? (
        <p className="loading-state">Загрузка…</p>
      ) : data && data.results.length === 0 ? (
        <p className="empty-state">Книги не найдены.</p>
      ) : (
        data && (
          <>
            <table className="data-table">
              <thead>
                <tr>
                  <th />
                  <th>Название</th>
                  <th>Авторы</th>
                  <th>Жанры</th>
                  <th>Цена</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {data.results.map((book) => (
                  <tr key={book.id}>
                    <td>
                      {book.cover && (
                        <img src={book.cover} alt="" style={{ width: 36, borderRadius: 4 }} />
                      )}
                    </td>
                    <td>{book.title}</td>
                    <td>{book.authors.map(authorName).join(", ")}</td>
                    <td>{book.genres.map(genreName).join(", ")}</td>
                    <td>{book.price} ₽</td>
                    <td className="actions-cell">
                      <Link to={`/catalog/books/${book.id}/edit`}>
                        <button type="button">Редактировать</button>
                      </Link>
                      <button type="button" className="danger" onClick={() => handleDelete(book)}>
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
