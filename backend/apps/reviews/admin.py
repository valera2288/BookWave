from django.contrib import admin

from .models import Review


@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = ["user", "book", "rating", "is_hidden", "created_at"]
    list_filter = ["is_hidden", "rating"]
    search_fields = ["user__email", "book__title"]

    def formfield_for_dbfield(self, db_field, request, **kwargs):
        # `MinValueValidator`/`MaxValueValidator` на модели уже блокируют
        # сохранение вне 1..5 — это только про виджет: браузерные стрелочки
        # number-инпута иначе крутятся без ограничения (Django не выводит
        # `min`/`max` в HTML из произвольных валидаторов сам). Именно
        # `min_value`/`max_value`, а не `widget=NumberInput(attrs=...)` —
        # `PositiveSmallIntegerField.formfield()` сам подставляет
        # `min_value=0` и переопределил бы атрибут виджета своим значением.
        if db_field.name == "rating":
            kwargs["min_value"] = 1
            kwargs["max_value"] = 5
        return super().formfield_for_dbfield(db_field, request, **kwargs)
