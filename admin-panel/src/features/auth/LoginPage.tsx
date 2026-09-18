import { type FormEvent, useState } from "react";
import { useNavigate } from "react-router-dom";

import { AdminAccessError, login } from "./auth";
import "./login.css";

function extractErrorMessage(error: unknown): string {
  if (error instanceof AdminAccessError) {
    return error.message;
  }
  if (
    typeof error === "object" &&
    error !== null &&
    "response" in error &&
    typeof (error as { response?: { data?: { detail?: string } } }).response?.data?.detail ===
      "string"
  ) {
    return (error as { response: { data: { detail: string } } }).response.data.detail;
  }
  return "Не удалось войти. Проверьте e-mail и пароль.";
}

export default function LoginPage() {
  const navigate = useNavigate();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      await login(email, password);
      navigate("/orders", { replace: true });
    } catch (err) {
      setError(extractErrorMessage(err));
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="login-page">
      <form className="login-form" onSubmit={handleSubmit}>
        <h1>BookWave — Админ-панель</h1>
        <label className="field">
          <span>Логин (e-mail)</span>
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
            autoFocus
          />
        </label>
        <label className="field">
          <span>Пароль</span>
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />
        </label>
        {error && <p className="login-error">{error}</p>}
        <button type="submit" disabled={submitting}>
          {submitting ? "Вход…" : "Войти"}
        </button>
      </form>
    </div>
  );
}
