from .models import DeviceToken, NotificationPreference


def _is_category_enabled(user, category: str) -> bool:
    """Категория считается включённой, пока пользователь явно её не выключил
    в настройках — запись в БД создаётся только при изменении, не заранее
    для каждого пользователя (см. `enabled=True` по умолчанию на модели)."""
    pref = NotificationPreference.objects.filter(user=user, category=category).first()
    return pref.enabled if pref else True


def send_push(user, category: str, title: str, body: str) -> None:
    """Push одному пользователю на все его зарегистрированные устройства,
    с учётом настройки категории. Постоянная реализация — не временная
    заглушка (см. ARCHITECTURE.md, «Открытые вопросы» №9): как email в dev
    (`EMAIL_BACKEND` = console), просто печатает в консоль; переход на
    реальный FCM не планируется."""
    if not _is_category_enabled(user, category):
        return
    tokens = list(user.device_tokens.values_list("token", flat=True))
    if not tokens:
        return
    print(f"[PUSH:{category}] user={user.id} devices={len(tokens)} — {title}: {body}", flush=True)


def send_push_to_category(category: str, title: str, body: str) -> None:
    """Массовая рассылка всем пользователям с хотя бы одним устройством,
    у кого эта категория явно не отключена (например, «новинки» при
    добавлении книги)."""
    disabled_user_ids = set(
        NotificationPreference.objects.filter(
            category=category, enabled=False
        ).values_list("user_id", flat=True)
    )
    recipients = (
        DeviceToken.objects.exclude(user_id__in=disabled_user_ids)
        .values_list("user_id", flat=True)
        .distinct()
    )
    for user_id in recipients:
        device_count = DeviceToken.objects.filter(user_id=user_id).count()
        print(
            f"[PUSH:{category}] user={user_id} devices={device_count} — {title}: {body}",
            flush=True,
        )
