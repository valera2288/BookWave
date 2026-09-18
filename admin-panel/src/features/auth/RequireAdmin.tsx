import { Navigate, Outlet } from "react-router-dom";

import { isAdminSession } from "./auth";

export default function RequireAdmin() {
  return isAdminSession() ? <Outlet /> : <Navigate to="/login" replace />;
}
