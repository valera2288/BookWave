from django.core.exceptions import ValidationError
from django.utils import timezone

from apps.common.validators import validate_image_file

COVER_MAX_SIZE_BYTES = 5 * 1024 * 1024
BOOK_FILE_MAX_SIZE_BYTES = 100 * 1024 * 1024
MIN_PUBLICATION_YEAR = 1000


def validate_cover_file(file) -> None:
    validate_image_file(
        file,
        max_size_bytes=COVER_MAX_SIZE_BYTES,
        format_error="Обложка должна быть в формате JPG или PNG.",
        size_error="Размер обложки не должен превышать 5 МБ.",
    )


def validate_book_file_size(file) -> None:
    if file.size > BOOK_FILE_MAX_SIZE_BYTES:
        raise ValidationError("Размер файла книги не должен превышать 100 МБ.")


def validate_publication_year(value: int) -> None:
    """`PositiveSmallIntegerField` сам по себе допускает любое значение до
    32767 — этого недостаточно, год издания вроде 9999 технически проходит,
    но не имеет смысла."""
    current_year = timezone.now().year
    if value < MIN_PUBLICATION_YEAR or value > current_year:
        raise ValidationError(f"Год издания должен быть от {MIN_PUBLICATION_YEAR} до {current_year}.")
