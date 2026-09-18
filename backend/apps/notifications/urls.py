from django.urls import path

from . import views

urlpatterns = [
    path(
        "preferences/",
        views.NotificationPreferenceListView.as_view(),
        name="preference_list",
    ),
    path(
        "preferences/<str:category>/",
        views.NotificationPreferenceUpdateView.as_view(),
        name="preference_update",
    ),
    path(
        "device-tokens/",
        views.DeviceTokenRegisterView.as_view(),
        name="device_token_register",
    ),
]
