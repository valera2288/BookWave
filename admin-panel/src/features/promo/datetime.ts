/** ISO-строка с сервера -> значение для <input type="datetime-local"> (локальное время, без секунд/зоны). */
export function toDatetimeLocalValue(iso: string): string {
  const date = new Date(iso);
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

/** Значение <input type="datetime-local"> (наивное локальное время) -> ISO-строка
 * с часовым поясом для сервера. Без этого отправлялась голая строка вроде
 * "2026-09-17T17:50" без указания зоны, и DRF трактовал её как UTC —
 * администратор вводил 17:50 по своему времени, а сохранялось 17:50 UTC
 * (на +3 часа позже для московского пояса). */
export function fromDatetimeLocalValue(value: string): string {
  return new Date(value).toISOString();
}
