from django.core.exceptions import ValidationError

from apps.common.validators import validate_image_file

AVATAR_MAX_SIZE_BYTES = 5 * 1024 * 1024


def validate_avatar_file(file) -> None:
    validate_image_file(
        file,
        max_size_bytes=AVATAR_MAX_SIZE_BYTES,
        format_error="Аватар должен быть в формате JPG или PNG.",
        size_error="Размер аватара не должен превышать 5 МБ.",
    )


class ContainsDigitValidator:
    """ТЗ: пароль — минимум 8 символов (`MinimumLengthValidator`, см.
    `AUTH_PASSWORD_VALIDATORS`), минимум одна цифра — эта проверка."""

    def validate(self, password, user=None):
        if not any(char.isdigit() for char in password):
            raise ValidationError(
                "Пароль должен содержать хотя бы одну цифру.",
                code="password_no_digit",
            )

    def get_help_text(self):
        return "Пароль должен содержать хотя бы одну цифру."
