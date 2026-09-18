from django.contrib import admin

from .models import DeviceToken, NotificationPreference


@admin.register(NotificationPreference)
class NotificationPreferenceAdmin(admin.ModelAdmin):
    list_display = ["user", "category", "enabled"]
    list_filter = ["category", "enabled"]
    search_fields = ["user__email"]


@admin.register(DeviceToken)
class DeviceTokenAdmin(admin.ModelAdmin):
    list_display = ["user", "platform", "created_at"]
    search_fields = ["user__email"]
