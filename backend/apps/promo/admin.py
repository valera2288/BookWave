from django import forms
from django.contrib import admin

from .models import PromoCode, PromoCodeUsage


@admin.register(PromoCode)
class PromoCodeAdmin(admin.ModelAdmin):
    list_display = [
        "code",
        "discount_type",
        "discount_value",
        "min_order_amount",
        "valid_from",
        "valid_until",
        "max_uses",
    ]
    search_fields = ["code"]

    def formfield_for_dbfield(self, db_field, request, **kwargs):
        # Модельные валидаторы уже блокируют сохранение вне диапазона —
        # это только про HTML min/max на виджете (см. тот же приём в
        # apps/catalog/admin.py и apps/reviews/admin.py). `max_uses` —
        # `PositiveIntegerField`, у него `min_value`, а не `widget=...`:
        # `PositiveIntegerField.formfield()` сам подставляет `min_value=0`
        # и перезаписал бы атрибут виджета своим значением.
        if db_field.name == "discount_value":
            kwargs["widget"] = forms.NumberInput(attrs={"min": "0.01", "step": "0.01"})
        elif db_field.name == "min_order_amount":
            kwargs["widget"] = forms.NumberInput(attrs={"min": "0", "step": "0.01"})
        elif db_field.name == "max_uses":
            kwargs["min_value"] = 1
        return super().formfield_for_dbfield(db_field, request, **kwargs)


@admin.register(PromoCodeUsage)
class PromoCodeUsageAdmin(admin.ModelAdmin):
    list_display = ["promo_code", "user", "order", "used_at"]
    search_fields = ["promo_code__code", "user__email"]
