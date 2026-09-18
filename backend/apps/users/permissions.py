from rest_framework.permissions import BasePermission

from .models import User


class IsAdminRole(BasePermission):
    """Доступ только читателям с business-ролью "admin" (не путать с is_staff)."""

    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.is_authenticated
            and request.user.role == User.Role.ADMIN
        )
