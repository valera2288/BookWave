from django.core.exceptions import ValidationError

MIN_REVIEW_TEXT_LENGTH = 10


def validate_review_text_length(value: str) -> None:
    """Текст отзыва необязателен (можно оставить только оценку) — но если
    он есть, не должен быть короче нескольких слов. Верхнюю границу задаёт
    `max_length` на самом поле модели (единый механизм Django для
    TextField/CharField, не нужен отдельный валидатор)."""
    if value and len(value) < MIN_REVIEW_TEXT_LENGTH:
        raise ValidationError(
            f"Текст отзыва должен быть не короче {MIN_REVIEW_TEXT_LENGTH} символов."
        )
