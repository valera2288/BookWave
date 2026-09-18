from django.conf import settings
from django.db import models


class Bookmark(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="bookmarks"
    )
    book = models.ForeignKey("catalog.Book", on_delete=models.CASCADE, related_name="+")
    position = models.CharField(max_length=255)  # позиция в тексте (CFI/глава+смещение), непрозрачна для backend
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "bookmarks"
        ordering = ["-created_at"]
