from django.contrib import admin

from .models import Banner


@admin.register(Banner)
class BannerAdmin(admin.ModelAdmin):
    list_display = ["id", "position", "is_active", "starts_at", "ends_at"]
    list_filter = ["is_active"]
    ordering = ["position"]
