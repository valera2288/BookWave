import { type FormEvent, useEffect, useState } from "react";

import { extractErrorDetail } from "./apiTypes";

interface NamedItem {
  id: number;
  name: string;
}

interface SimpleCrudListProps {
  title: string;
  fetchItems: () => Promise<NamedItem[]>;
  createItem: (name: string) => Promise<NamedItem>;
  renameItem: (id: number, name: string) => Promise<NamedItem>;
  deleteItem: (id: number) => Promise<void>;
}

/** Жанры и авторы — одинаковый справочник «название + CRUD» (ТЗ), поэтому
 * общий компонент вместо двух почти идентичных экранов. */
export default function SimpleCrudList({
  title,
  fetchItems,
  createItem,
  renameItem,
  deleteItem,
}: SimpleCrudListProps) {
  const [items, setItems] = useState<NamedItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [newName, setNewName] = useState("");
  const [editingId, setEditingId] = useState<number | null>(null);
  const [editingName, setEditingName] = useState("");
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    fetchItems()
      .then(setItems)
      .catch((err) => setError(extractErrorDetail(err, "Не удалось загрузить список.")))
      .finally(() => setLoading(false));
    // Список грузится один раз при монтировании экрана — конкретный
    // экземпляр `fetchItems`/`createItem`/... передаётся родителем и не
    // меняется между рендерами в этом приложении.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleCreate = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const name = newName.trim();
    if (!name) return;
    setBusy(true);
    setError(null);
    try {
      const created = await createItem(name);
      setItems((prev) => [...prev, created].sort((a, b) => a.name.localeCompare(b.name, "ru")));
      setNewName("");
    } catch (err) {
      setError(extractErrorDetail(err, "Не удалось создать запись."));
    } finally {
      setBusy(false);
    }
  };

  const startEditing = (item: NamedItem) => {
    setEditingId(item.id);
    setEditingName(item.name);
  };

  const handleRename = async (id: number) => {
    const name = editingName.trim();
    if (!name) return;
    setBusy(true);
    setError(null);
    try {
      const updated = await renameItem(id, name);
      setItems((prev) => prev.map((item) => (item.id === id ? updated : item)));
      setEditingId(null);
    } catch (err) {
      setError(extractErrorDetail(err, "Не удалось переименовать запись."));
    } finally {
      setBusy(false);
    }
  };

  const handleDelete = async (id: number) => {
    if (!window.confirm("Удалить запись? Действие необратимо.")) return;
    setBusy(true);
    setError(null);
    try {
      await deleteItem(id);
      setItems((prev) => prev.filter((item) => item.id !== id));
    } catch (err) {
      setError(extractErrorDetail(err, "Не удалось удалить запись."));
    } finally {
      setBusy(false);
    }
  };

  return (
    <div>
      <div className="page-header">
        <h2>{title}</h2>
      </div>

      <form className="toolbar" onSubmit={handleCreate}>
        <label className="field">
          <span>Новое название</span>
          <input value={newName} onChange={(e) => setNewName(e.target.value)} disabled={busy} />
        </label>
        <button type="submit" className="primary" disabled={busy || !newName.trim()}>
          Добавить
        </button>
      </form>

      {error && <p className="error-banner">{error}</p>}

      {loading ? (
        <p className="loading-state">Загрузка…</p>
      ) : items.length === 0 ? (
        <p className="empty-state">Список пуст.</p>
      ) : (
        <table className="data-table">
          <thead>
            <tr>
              <th>Название</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {items.map((item) => (
              <tr key={item.id}>
                <td>
                  {editingId === item.id ? (
                    <input
                      value={editingName}
                      onChange={(e) => setEditingName(e.target.value)}
                      disabled={busy}
                      autoFocus
                    />
                  ) : (
                    item.name
                  )}
                </td>
                <td className="actions-cell">
                  {editingId === item.id ? (
                    <>
                      <button type="button" onClick={() => handleRename(item.id)} disabled={busy}>
                        Сохранить
                      </button>
                      <button
                        type="button"
                        className="ghost"
                        onClick={() => setEditingId(null)}
                        disabled={busy}
                      >
                        Отмена
                      </button>
                    </>
                  ) : (
                    <>
                      <button type="button" onClick={() => startEditing(item)} disabled={busy}>
                        Переименовать
                      </button>
                      <button
                        type="button"
                        className="danger"
                        onClick={() => handleDelete(item.id)}
                        disabled={busy}
                      >
                        Удалить
                      </button>
                    </>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
