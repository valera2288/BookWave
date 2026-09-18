from django.conf import settings
from django.contrib import admin
from django.urls import include, path, re_path
from django.views.static import serve

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/users/", include("apps.users.urls")),
    path("api/catalog/", include("apps.catalog.urls")),
    path("api/files/", include("apps.files.urls")),
    path("api/favorites/", include("apps.favorites.urls")),
    path("api/cart/", include("apps.cart.urls")),
    path("api/orders/", include("apps.orders.urls")),
    path("api/promo/", include("apps.promo.urls")),
    path("api/library/", include("apps.library.urls")),
    path("api/bookmarks/", include("apps.bookmarks.urls")),
    path("api/reviews/", include("apps.reviews.urls")),
    path("api/reports/", include("apps.reports.urls")),
    path("api/notifications/", include("apps.notifications.urls")),
    path("api/banners/", include("apps.banners.urls")),
]

# Файлы книг (books/epub|pdf|fb2/) исключены из общей раздачи media — ТЗ:
# «Прямой доступ к файлу книги по статической ссылке должен быть запрещён»,
# их отдаёт только защищённый apps.files.BookFileView. Обложки и прочее
# остаются публичными. Вынесено в константу, чтобы тест мог проверить сам
# паттерн, а не гонять полный DEBUG-гейтед urlconf (Django в тестах всегда
# форсит DEBUG=False, так что реальную ветку ниже импортом не проверить).
PUBLIC_MEDIA_PATTERN = r"^media/(?!books/)(?P<path>.*)$"

if settings.DEBUG:
    urlpatterns += [
        re_path(PUBLIC_MEDIA_PATTERN, serve, {"document_root": settings.MEDIA_ROOT}),
    ]
