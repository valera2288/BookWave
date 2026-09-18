import { apiClient } from "../../api/client";
import type { Paginated } from "../../shared/apiTypes";
import type { Author, BookAdmin, Genre } from "./types";

export async function fetchGenres(): Promise<Genre[]> {
  const { data } = await apiClient.get<Genre[]>("catalog/admin/genres/");
  return data;
}

export async function createGenre(name: string): Promise<Genre> {
  const { data } = await apiClient.post<Genre>("catalog/admin/genres/", { name });
  return data;
}

export async function renameGenre(id: number, name: string): Promise<Genre> {
  const { data } = await apiClient.patch<Genre>(`catalog/admin/genres/${id}/`, { name });
  return data;
}

export async function deleteGenre(id: number): Promise<void> {
  await apiClient.delete(`catalog/admin/genres/${id}/`);
}

export async function fetchAuthors(): Promise<Author[]> {
  const { data } = await apiClient.get<Author[]>("catalog/admin/authors/");
  return data;
}

export async function createAuthor(name: string): Promise<Author> {
  const { data } = await apiClient.post<Author>("catalog/admin/authors/", { name });
  return data;
}

export async function renameAuthor(id: number, name: string): Promise<Author> {
  const { data } = await apiClient.patch<Author>(`catalog/admin/authors/${id}/`, { name });
  return data;
}

export async function deleteAuthor(id: number): Promise<void> {
  await apiClient.delete(`catalog/admin/authors/${id}/`);
}

export interface BookListParams {
  page: number;
  search?: string;
  genre?: number | "";
}

export async function fetchBooks(params: BookListParams): Promise<Paginated<BookAdmin>> {
  const { data } = await apiClient.get<Paginated<BookAdmin>>("catalog/admin/books/", {
    params: {
      page: params.page,
      search: params.search || undefined,
      genre: params.genre || undefined,
    },
  });
  return data;
}

export async function fetchBook(id: number): Promise<BookAdmin> {
  const { data } = await apiClient.get<BookAdmin>(`catalog/admin/books/${id}/`);
  return data;
}

export async function createBook(formData: FormData): Promise<BookAdmin> {
  const { data } = await apiClient.post<BookAdmin>("catalog/admin/books/", formData);
  return data;
}

export async function updateBook(id: number, formData: FormData): Promise<BookAdmin> {
  const { data } = await apiClient.patch<BookAdmin>(`catalog/admin/books/${id}/`, formData);
  return data;
}

export async function deleteBook(id: number): Promise<void> {
  await apiClient.delete(`catalog/admin/books/${id}/`);
}
