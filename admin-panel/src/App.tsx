import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";

import LoginPage from "./features/auth/LoginPage";
import RequireAdmin from "./features/auth/RequireAdmin";
import AuthorsPage from "./features/catalog/AuthorsPage";
import BookFormPage from "./features/catalog/BookFormPage";
import BooksListPage from "./features/catalog/BooksListPage";
import GenresPage from "./features/catalog/GenresPage";
import OrderDetailPage from "./features/orders/OrderDetailPage";
import OrdersListPage from "./features/orders/OrdersListPage";
import PromoFormPage from "./features/promo/PromoFormPage";
import PromoListPage from "./features/promo/PromoListPage";
import ReportsPage from "./features/reports/ReportsPage";
import ReviewsPage from "./features/reviews/ReviewsPage";
import Layout from "./shared/Layout";

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route element={<RequireAdmin />}>
          <Route element={<Layout />}>
            <Route path="/" element={<Navigate to="/orders" replace />} />
            <Route path="/orders" element={<OrdersListPage />} />
            <Route path="/orders/:id" element={<OrderDetailPage />} />
            <Route path="/catalog/books" element={<BooksListPage />} />
            <Route path="/catalog/books/new" element={<BookFormPage />} />
            <Route path="/catalog/books/:id/edit" element={<BookFormPage />} />
            <Route path="/catalog/genres" element={<GenresPage />} />
            <Route path="/catalog/authors" element={<AuthorsPage />} />
            <Route path="/promo" element={<PromoListPage />} />
            <Route path="/promo/new" element={<PromoFormPage />} />
            <Route path="/promo/:id/edit" element={<PromoFormPage />} />
            <Route path="/reviews" element={<ReviewsPage />} />
            <Route path="/reports" element={<ReportsPage />} />
          </Route>
        </Route>
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
