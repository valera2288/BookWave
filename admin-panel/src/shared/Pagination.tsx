const PAGE_SIZE = 25;

interface PaginationProps {
  page: number;
  count: number;
  onChange: (page: number) => void;
}

export default function Pagination({ page, count, onChange }: PaginationProps) {
  const totalPages = Math.max(1, Math.ceil(count / PAGE_SIZE));
  if (totalPages <= 1) return null;

  return (
    <div className="pagination">
      <button type="button" disabled={page <= 1} onClick={() => onChange(page - 1)}>
        Назад
      </button>
      <span>
        Страница {page} из {totalPages} ({count} записей)
      </span>
      <button type="button" disabled={page >= totalPages} onClick={() => onChange(page + 1)}>
        Далее
      </button>
    </div>
  );
}
