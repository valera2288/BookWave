from django.contrib import admin

from .models import LibraryEntry


@admin.register(LibraryEntry)
class LibraryEntryAdmin(admin.ModelAdmin):
    list_display = ["user", "book", "progress", "progress_updated_at", "added_at"]
    search_fields = ["user__email", "book__title"]
