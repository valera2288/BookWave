from django.conf import settings
from django.core.validators import MaxValueValidator
from django.db import models


class LibraryEntry(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="library_entries"
    )
    book = models.ForeignKey("catalog.Book", on_delete=models.CASCADE, related_name="+")
    progress = models.PositiveSmallIntegerField(
        default=0, validators=[MaxValueValidator(100)]
    )  # процент прочитанного, 0–100
    progress_updated_at = models.DateTimeField(null=True, blank=True)
    added_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "user_library"
        verbose_name_plural = "Library entries"
        constraints = [
            models.UniqueConstraint(fields=["user", "book"], name="unique_library_entry")
        ]
