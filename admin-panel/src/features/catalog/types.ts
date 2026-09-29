export interface Genre {
  id: number;
  name: string;
}

export interface Author {
  id: number;
  name: string;
}

export interface BookAdmin {
  id: number;
  title: string;
  authors: number[];
  genres: number[];
  language: string;
  publisher: string;
  publication_year: number | null;
  page_count: number | null;
  isbn: string;
  price: string;
  description: string;
  cover: string | null;
  epub_file: string | null;
  pdf_file: string | null;
  fb2_file: string | null;
  is_active: boolean;
}
