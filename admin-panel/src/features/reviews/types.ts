export interface ReviewAdmin {
  id: number;
  book: number;
  book_title: string;
  user_name: string;
  user_email: string;
  rating: number;
  text: string;
  is_hidden: boolean;
  created_at: string;
}
