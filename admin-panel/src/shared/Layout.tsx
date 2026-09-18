import { NavLink, Outlet, useLocation, useNavigate } from "react-router-dom";

import { logout } from "../features/auth/auth";
import ErrorBoundary from "./ErrorBoundary";

const NAV_ITEMS = [
  { to: "/orders", label: "Заказы" },
  { to: "/catalog/books", label: "Книги" },
  { to: "/catalog/genres", label: "Жанры" },
  { to: "/catalog/authors", label: "Авторы" },
  { to: "/promo", label: "Промокоды" },
  { to: "/reviews", label: "Отзывы" },
  { to: "/reports", label: "Отчёты" },
];

export default function Layout() {
  const navigate = useNavigate();
  const location = useLocation();

  const handleLogout = () => {
    if (!window.confirm("Выйти из аккаунта администратора?")) return;
    logout();
    navigate("/login", { replace: true });
  };

  return (
    <div className="app-layout">
      <aside className="app-sidebar">
        <h1>BookWave Admin</h1>
        {NAV_ITEMS.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            className={({ isActive }) => (isActive ? "active" : undefined)}
          >
            {item.label}
          </NavLink>
        ))}
        <button type="button" className="ghost logout-btn" onClick={handleLogout}>
          Выйти
        </button>
      </aside>
      <main className="app-content">
        <ErrorBoundary key={location.pathname}>
          <Outlet />
        </ErrorBoundary>
      </main>
    </div>
  );
}
