from django.conf import settings
from django.core.mail import send_mail
from django.utils import timezone

from .models import EmailConfirmationToken, PasswordResetToken


def send_email_confirmation(user) -> EmailConfirmationToken:
    token = EmailConfirmationToken.objects.create(user=user)
    link = f"{settings.FRONTEND_CONFIRM_EMAIL_URL_BASE}/{token.token}"
    send_mail(
        subject="Подтвердите e-mail — BookWave",
        message=(
            f"Здравствуйте, {user.name}!\n\n"
            f"Подтвердите e-mail по ссылке: {link}\n\n"
            "Ссылка действительна 3 дня."
        ),
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=[user.email],
    )
    return token


def send_email_change_confirmation(user, new_email: str) -> EmailConfirmationToken:
    """Письмо уходит на НОВЫЙ адрес (ТЗ: "изменение e-mail требует
    повторного подтверждения через письмо на новый адрес") — `user.email`
    не меняется, пока подтверждение не пройдено по ссылке.

    Гасим все более ранние неподтверждённые запросы смены e-mail этого
    пользователя (`used_at=None`) — иначе, если пользователь передумал и
    запросил смену на другой адрес, старая ссылка (действует до 3 дней,
    могла остаться в старом письме/вкладке) при переходе по ней молча
    откатила бы e-mail обратно на прежний адрес без всякого дополнительного
    подтверждения.
    """
    EmailConfirmationToken.objects.filter(
        user=user, new_email__isnull=False, used_at__isnull=True
    ).update(used_at=timezone.now())
    token = EmailConfirmationToken.objects.create(user=user, new_email=new_email)
    link = f"{settings.FRONTEND_CONFIRM_EMAIL_URL_BASE}/{token.token}"
    send_mail(
        subject="Подтвердите новый e-mail — BookWave",
        message=(
            f"Здравствуйте, {user.name}!\n\n"
            f"Подтвердите новый e-mail по ссылке: {link}\n\n"
            "Ссылка действительна 3 дня. Если вы не запрашивали смену "
            "e-mail — проигнорируйте это письмо."
        ),
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=[new_email],
    )
    return token


def send_password_reset_email(user) -> PasswordResetToken:
    token = PasswordResetToken.objects.create(user=user)
    link = f"{settings.FRONTEND_PASSWORD_RESET_URL_BASE}/{token.token}"
    send_mail(
        subject="Восстановление пароля — BookWave",
        message=(
            f"Для сброса пароля перейдите по ссылке: {link}\n\n"
            "Ссылка действительна 30 минут. Если вы не запрашивали сброс "
            "пароля — проигнорируйте это письмо."
        ),
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=[user.email],
    )
    return token
