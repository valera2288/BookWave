from unittest.mock import patch

from django.test import TestCase
from rest_framework.test import APIRequestFactory, force_authenticate

from apps.users.models import User

from .models import DeviceToken, NotificationPreference
from .services import send_push, send_push_to_category
from .views import (
    DeviceTokenRegisterView,
    NotificationPreferenceListView,
    NotificationPreferenceUpdateView,
)


def _make_user(email):
    return User.objects.create_user(email=email, password="testpass123", name="Reader")


class NotificationPreferenceViewTests(TestCase):
    def test_list_defaults_missing_categories_to_enabled(self):
        user = _make_user("prefs1@test.local")
        request = APIRequestFactory().get("/api/notifications/preferences/")
        force_authenticate(request, user=user)
        response = NotificationPreferenceListView.as_view()(request)

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), len(NotificationPreference.Category.choices))
        self.assertTrue(all(item["enabled"] for item in response.data))

    def test_list_reflects_saved_override(self):
        user = _make_user("prefs2@test.local")
        NotificationPreference.objects.create(
            user=user, category=NotificationPreference.Category.NEW_RELEASES, enabled=False
        )
        request = APIRequestFactory().get("/api/notifications/preferences/")
        force_authenticate(request, user=user)
        response = NotificationPreferenceListView.as_view()(request)

        by_category = {item["category"]: item["enabled"] for item in response.data}
        self.assertFalse(by_category[NotificationPreference.Category.NEW_RELEASES])
        self.assertTrue(by_category[NotificationPreference.Category.ORDER_STATUS])

    def test_patch_creates_and_updates_preference(self):
        user = _make_user("prefs3@test.local")
        request = APIRequestFactory().patch(
            "/api/notifications/preferences/order_status/", {"enabled": False}, format="json"
        )
        force_authenticate(request, user=user)
        response = NotificationPreferenceUpdateView.as_view()(request, category="order_status")

        self.assertEqual(response.status_code, 200)
        self.assertFalse(
            NotificationPreference.objects.get(
                user=user, category=NotificationPreference.Category.ORDER_STATUS
            ).enabled
        )

    def test_patch_unknown_category_is_404(self):
        user = _make_user("prefs4@test.local")
        request = APIRequestFactory().patch(
            "/api/notifications/preferences/not_a_category/", {"enabled": False}, format="json"
        )
        force_authenticate(request, user=user)
        response = NotificationPreferenceUpdateView.as_view()(request, category="not_a_category")

        self.assertEqual(response.status_code, 404)


class DeviceTokenViewTests(TestCase):
    def test_register_creates_token(self):
        user = _make_user("device1@test.local")
        request = APIRequestFactory().post(
            "/api/notifications/device-tokens/",
            {"token": "abc123", "platform": "android"},
            format="json",
        )
        force_authenticate(request, user=user)
        response = DeviceTokenRegisterView.as_view()(request)

        self.assertEqual(response.status_code, 201)
        self.assertEqual(DeviceToken.objects.get(token="abc123").user, user)

    def test_register_reassigns_existing_token_to_new_owner(self):
        old_owner = _make_user("device2a@test.local")
        new_owner = _make_user("device2b@test.local")
        DeviceToken.objects.create(user=old_owner, token="shared-token", platform="android")

        request = APIRequestFactory().post(
            "/api/notifications/device-tokens/",
            {"token": "shared-token", "platform": "android"},
            format="json",
        )
        force_authenticate(request, user=new_owner)
        response = DeviceTokenRegisterView.as_view()(request)

        self.assertEqual(response.status_code, 201)
        self.assertEqual(DeviceToken.objects.count(), 1)
        self.assertEqual(DeviceToken.objects.get(token="shared-token").user, new_owner)

    def test_delete_only_removes_own_token(self):
        owner = _make_user("device3a@test.local")
        stranger = _make_user("device3b@test.local")
        DeviceToken.objects.create(user=owner, token="owner-token", platform="ios")

        request = APIRequestFactory().delete("/api/notifications/device-tokens/?token=owner-token")
        force_authenticate(request, user=stranger)
        DeviceTokenRegisterView.as_view()(request)

        self.assertEqual(DeviceToken.objects.count(), 1, "чужой токен не должен удаляться")


class PushServiceTests(TestCase):
    """`services.send_push*` — dev-заглушка (печать вместо реальной отправки
    через FCM, см. решение по фазе 8): проверяем логику фильтрации по
    настройкам категории, а не факт печати."""

    def test_send_push_skipped_when_no_device_tokens(self):
        user = _make_user("push1@test.local")
        with patch("builtins.print") as mock_print:
            send_push(user, NotificationPreference.Category.ORDER_STATUS, "T", "B")
        mock_print.assert_not_called()

    def test_send_push_skipped_when_category_disabled(self):
        user = _make_user("push2@test.local")
        DeviceToken.objects.create(user=user, token="t1", platform="android")
        NotificationPreference.objects.create(
            user=user, category=NotificationPreference.Category.ORDER_STATUS, enabled=False
        )
        with patch("builtins.print") as mock_print:
            send_push(user, NotificationPreference.Category.ORDER_STATUS, "T", "B")
        mock_print.assert_not_called()

    def test_send_push_to_category_excludes_users_who_disabled_it(self):
        subscribed = _make_user("push3a@test.local")
        unsubscribed = _make_user("push3b@test.local")
        no_device = _make_user("push3c@test.local")
        DeviceToken.objects.create(user=subscribed, token="t2", platform="android")
        DeviceToken.objects.create(user=unsubscribed, token="t3", platform="android")
        NotificationPreference.objects.create(
            user=unsubscribed,
            category=NotificationPreference.Category.NEW_RELEASES,
            enabled=False,
        )

        with patch("builtins.print") as mock_print:
            send_push_to_category(NotificationPreference.Category.NEW_RELEASES, "T", "B")

        printed = "\n".join(str(call.args[0]) for call in mock_print.call_args_list)
        self.assertIn(f"user={subscribed.id}", printed)
        self.assertNotIn(f"user={unsubscribed.id}", printed)
        self.assertNotIn(f"user={no_device.id}", printed)
