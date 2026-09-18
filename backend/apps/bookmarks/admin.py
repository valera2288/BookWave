from django.contrib import admin

from .models import Bookmark


@admin.register(Bookmark)
class BookmarkAdmin(admin.ModelAdmin):
    list_display = ["user", "book", "position", "created_at"]
    search_fields = ["user__email", "book__title"]
