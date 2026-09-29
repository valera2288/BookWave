from django.db import models

from .validators import validate_banner_image


class Banner(models.Model):
    image = models.ImageField(upload_to="banners/", validators=[validate_banner_image])
    link_book = models.ForeignKey(
        "catalog.Book", on_delete=models.SET_NULL, null=True, blank=True, related_name="+"
    )
    # Раздел каталога для мобильного приложения: "catalog" или
    # "catalog?genre=<id>" (см. HomeScreen._openBannerLink); внешние
    # http-ссылки приложение пока не открывает.
    link_url = models.CharField(max_length=255, blank=True)
    starts_at = models.DateTimeField(null=True, blank=True)
    ends_at = models.DateTimeField(null=True, blank=True)
    position = models.PositiveSmallIntegerField(default=0)
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = "banners"
        ordering = ["position"]
