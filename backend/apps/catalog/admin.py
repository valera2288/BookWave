from django import forms
from django.contrib import admin
from django.utils import timezone

from .models import Author, Book, Genre


@admin.register(Author)
class AuthorAdmin(admin.ModelAdmin):
    list_display = ["name"]
    search_fields = ["name"]


@admin.register(Genre)
class GenreAdmin(admin.ModelAdmin):
    list_display = ["name"]
    search_fields = ["name"]


@admin.register(Book)
class BookAdmin(admin.ModelAdmin):
    list_display = ["title", "isbn", "price", "is_active", "created_at"]
    list_filter = ["is_active", "language", "genres"]
    search_fields = ["title", "isbn", "authors__name"]
    filter_horizontal = ["authors", "genres"]

    def formfield_for_dbfield(self, db_field, request, **kwargs):
        # Модельные валидаторы уже блокируют сохранение вне диапазона —
        # это только про HTML min/max на виджете, чтобы браузер не давал
        # крутить число за разумную границу до отправки формы. Для
        # publication_year/page_count — именно `min_value`/`max_value`, а
        # не `widget=NumberInput(attrs=...)`: `PositiveIntegerField.
        # formfield()`/`PositiveSmallIntegerField.formfield()` сами
        # подставляют `min_value=0` и перетёрли бы атрибут виджета своим
        # значением. `price` — `DecimalField`, такого поведения нет.
        if db_field.name == "publication_year":
            kwargs["min_value"] = 1000
            kwargs["max_value"] = timezone.now().year
        elif db_field.name == "page_count":
            kwargs["min_value"] = 1
            kwargs["max_value"] = 20000
        elif db_field.name == "price":
            kwargs["widget"] = forms.NumberInput(attrs={"min": "0.01", "step": "0.01"})
        return super().formfield_for_dbfield(db_field, request, **kwargs)
