export interface Paginated<T> {
  count: number;
  next: string | null;
  previous: string | null;
  results: T[];
}

export function extractErrorDetail(error: unknown, fallback: string): string {
  if (
    typeof error === "object" &&
    error !== null &&
    "response" in error &&
    typeof (error as { response?: { data?: unknown } }).response?.data === "object"
  ) {
    const data = (error as { response: { data: Record<string, unknown> } }).response.data;
    if (typeof data.detail === "string") return data.detail;
    const firstFieldError = Object.values(data).find(
      (value) => Array.isArray(value) && typeof value[0] === "string",
    ) as string[] | undefined;
    if (firstFieldError) return firstFieldError[0];
  }
  return fallback;
}
