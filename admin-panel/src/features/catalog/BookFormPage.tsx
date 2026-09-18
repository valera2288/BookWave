import { type ChangeEvent, type FormEvent, useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";

import { extractErrorDetail } from "../../shared/apiTypes";
import { createBook, fetchAuthors, fetchBook, fetchGenres, updateBook } from "./api";
import type { Author, Genre } from "./types";

function appendFile(formData: FormData, key: string, file: File | null) {
  if (file) formData.append(key, file);
}

export default function BookFormPage() {
  const { id } = useParams<{ id: string }>();
  const isEditing = Boolean(id);
  const navigate = useNavigate();

  const [genres, setGenres] = useState<Genre[]>([]);
  const [authors, setAuthors] = useState<Author[]>([]);
  const [loading, setLoading] = useState(isEditing);
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const [title, setTitle] = useState("");
  const [selectedAuthors, setSelectedAuthors] = useState<number[]>([]);
  const [selectedGenres, setSelectedGenres] = useState<number[]>([]);
  const [language, setLanguage] = useState("ru");
  const [publisher, setPublisher] = useState("");
  const [publicationYear, setPublicationYear] = useState("");
  const [pageCount, setPageCount] = useState("");
  const [isbn, setIsbn] = useState("");
  const [price, setPrice] = useState("");
  const [description, setDescription] = useState("");

  const [existingCover, setExistingCover] = useState<string | null>(null);
  const [existingEpub, setExistingEpub] = useState<string | null>(null);
  const [existingPdf, setExistingPdf] = useState<string | null>(null);
  const [existingFb2, setExistingFb2] = useState<string | null>(null);

  const [coverFile, setCoverFile] = useState<File | null>(null);
  const [epubFile, setEpubFile] = useState<File | null>(null);
  const [pdfFile, setPdfFile] = useState<File | null>(null);
  const [fb2File, setFb2File] = useState<File | null>(null);

  useEffect(() => {
    Promise.all([fetchGenres(), fetchAuthors()]).then(([g, a]) => {
      setGenres(g);
      setAuthors(a);
    });
  }, []);

  useEffect(() => {
    if (!id) return;
    fetchBook(Number(id))
      .then((book) => {
        setTitle(book.title);
        setSelectedAuthors(book.authors);
        setSelectedGenres(book.genres);
        setLanguage(book.language);
        setPublisher(book.publisher);
        setPublicationYear(book.publication_year ? String(book.publication_year) : "");
        setPageCount(book.page_count ? String(book.page_count) : "");
        setIsbn(book.isbn);
        setPrice(book.price);
        setDescription(book.description);
        setExistingCover(book.cover);
        setExistingEpub(book.epub_file);
        setExistingPdf(book.pdf_file);
        setExistingFb2(book.fb2_file);
      })
      .catch((err) => setError(extractErrorDetail(err, "Не удалось загрузить книгу.")))
      .finally(() => setLoading(false));
  }, [id]);

  const toggle = (list: number[], setList: (v: number[]) => void, value: number) => {
    setList(list.includes(value) ? list.filter((v) => v !== value) : [...list, value]);
  };

  const handleFileChange =
    (setter: (f: File | null) => void) => (event: ChangeEvent<HTMLInputElement>) => {
      setter(event.target.files?.[0] ?? null);
    };

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError(null);

    if (selectedAuthors.length === 0) {
      setError("Выберите хотя бы одного автора.");
      return;
    }
    if (selectedGenres.length === 0) {
      setError("Выберите хотя бы один жанр.");
      return;
    }
    if (!isEditing && !epubFile) {
      setError("Файл в формате EPUB обязателен.");
      return;
    }

    const formData = new FormData();
    formData.append("title", title);
    selectedAuthors.forEach((a) => formData.append("authors", String(a)));
    selectedGenres.forEach((g) => formData.append("genres", String(g)));
    formData.append("language", language);
    formData.append("publisher", publisher);
    formData.append("isbn", isbn);
    formData.append("price", price);
    formData.append("description", description);
    if (publicationYear) formData.append("publication_year", publicationYear);
    if (pageCount) formData.append("page_count", pageCount);
    appendFile(formData, "cover", coverFile);
    appendFile(formData, "epub_file", epubFile);
    appendFile(formData, "pdf_file", pdfFile);
    appendFile(formData, "fb2_file", fb2File);

    setSubmitting(true);
    try {
      if (isEditing) {
        await updateBook(Number(id), formData);
      } else {
        await createBook(formData);
      }
      navigate("/catalog/books");
    } catch (err) {
      setError(extractErrorDetail(err, "Не удалось сохранить книгу."));
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) return <p className="loading-state">Загрузка…</p>;

  return (
    <div>
      <div className="page-header">
        <h2>{isEditing ? "Редактирование книги" : "Добавление книги"}</h2>
        <Link to="/catalog/books">← К списку книг</Link>
      </div>

      {error && <p className="error-banner">{error}</p>}

      <form className="form-card" onSubmit={handleSubmit}>
        <label className="field">
          <span>Название</span>
          <input value={title} onChange={(e) => setTitle(e.target.value)} required />
        </label>

        <label className="field">
          <span>Авторы</span>
          <div className="checkbox-list">
            {authors.map((a) => (
              <label key={a.id}>
                <input
                  type="checkbox"
                  checked={selectedAuthors.includes(a.id)}
                  onChange={() => toggle(selectedAuthors, setSelectedAuthors, a.id)}
                />
                {a.name}
              </label>
            ))}
          </div>
        </label>

        <label className="field">
          <span>Жанры</span>
          <div className="checkbox-list">
            {genres.map((g) => (
              <label key={g.id}>
                <input
                  type="checkbox"
                  checked={selectedGenres.includes(g.id)}
                  onChange={() => toggle(selectedGenres, setSelectedGenres, g.id)}
                />
                {g.name}
              </label>
            ))}
          </div>
        </label>

        <div className="form-row">
          <label className="field">
            <span>Язык</span>
            <input value={language} onChange={(e) => setLanguage(e.target.value)} required />
          </label>
          <label className="field">
            <span>Издательство</span>
            <input value={publisher} onChange={(e) => setPublisher(e.target.value)} />
          </label>
        </div>

        <div className="form-row">
          <label className="field">
            <span>Год издания</span>
            <input
              type="number"
              value={publicationYear}
              onChange={(e) => setPublicationYear(e.target.value)}
            />
          </label>
          <label className="field">
            <span>Объём, стр.</span>
            <input type="number" value={pageCount} onChange={(e) => setPageCount(e.target.value)} />
          </label>
        </div>

        <div className="form-row">
          <label className="field">
            <span>ISBN</span>
            <input value={isbn} onChange={(e) => setIsbn(e.target.value)} required />
          </label>
          <label className="field">
            <span>Цена, ₽</span>
            <input
              type="number"
              step="0.01"
              min="0.01"
              value={price}
              onChange={(e) => setPrice(e.target.value)}
              required
            />
          </label>
        </div>

        <label className="field">
          <span>Описание</span>
          <textarea
            rows={4}
            value={description}
            onChange={(e) => setDescription(e.target.value)}
          />
        </label>

        <label className="field">
          <span>Обложка (JPG/PNG, до 5 МБ)</span>
          <input type="file" accept="image/jpeg,image/png" onChange={handleFileChange(setCoverFile)} />
          {existingCover && !coverFile && (
            <a className="current-file" href={existingCover} target="_blank" rel="noreferrer">
              Текущая обложка
            </a>
          )}
        </label>

        <label className="field">
          <span>Файл EPUB{!isEditing && " (обязательно)"}</span>
          <input type="file" accept=".epub" onChange={handleFileChange(setEpubFile)} />
          {existingEpub && !epubFile && <span className="current-file">Файл уже загружен</span>}
        </label>

        <label className="field">
          <span>Файл PDF (опционально)</span>
          <input type="file" accept=".pdf" onChange={handleFileChange(setPdfFile)} />
          {existingPdf && !pdfFile && <span className="current-file">Файл уже загружен</span>}
        </label>

        <label className="field">
          <span>Файл FB2 (опционально)</span>
          <input type="file" accept=".fb2" onChange={handleFileChange(setFb2File)} />
          {existingFb2 && !fb2File && <span className="current-file">Файл уже загружен</span>}
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
