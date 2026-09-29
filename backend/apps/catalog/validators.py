import re
import zipfile

from django.core.exceptions import ValidationError
from django.utils import timezone

from apps.common.validators import validate_image_file

EPUB_MIMETYPE = b"application/epub+zip"

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


def validate_epub_file(file) -> None:
    """EPUB — это ZIP-архив с обязательным файлом 'mimetype' (спецификация
    EPUB OCF). Проверка по расширению одна не ловит переименованный
    произвольный файл — здесь смотрим на реальную структуру архива, не
    парсим весь EPUB целиком (это уже делает читалка при открытии книги)."""
    file.seek(0)
    try:
        with zipfile.ZipFile(file) as archive:
            content = archive.read("mimetype").strip()
    except (zipfile.BadZipFile, KeyError):
        raise ValidationError("Файл EPUB повреждён или не является EPUB (не ZIP-архив с mimetype).")
    finally:
        file.seek(0)
    if content != EPUB_MIMETYPE:
        raise ValidationError("Файл EPUB повреждён: mimetype не соответствует application/epub+zip.")


def validate_pdf_file(file) -> None:
    file.seek(0)
    header = file.read(5)
    file.seek(0)
    if header != b"%PDF-":
        raise ValidationError("Файл повреждён или не является PDF.")


def validate_fb2_file(file) -> None:
    file.seek(0)
    head = file.read(8192)
    file.seek(0)
    text = head.decode("utf-8", errors="ignore").lower()
    if "<fictionbook" not in text:
        raise ValidationError("Файл повреждён или не является FB2.")


def validate_publication_year(value: int) -> None:
    """`PositiveSmallIntegerField` сам по себе допускает любое значение до
    32767 — этого недостаточно, год издания вроде 9999 технически проходит,
    но не имеет смысла."""
    current_year = timezone.now().year
    if value < MIN_PUBLICATION_YEAR or value > current_year:
        raise ValidationError(f"Год издания должен быть от {MIN_PUBLICATION_YEAR} до {current_year}.")


def validate_isbn_format(value: str) -> None:
    """Контрольная цифра ISBN-10/ISBN-13. Не навешена на модель напрямую —
    часть сидовых книг в базе имеет нестандартные тестовые ISBN
    ('978-5-page-0019' и т.п.), это осознанное решение проекта. Проверка
    применяется в BookAdminSerializer только когда ISBN реально меняется
    (см. validate_isbn), поэтому существующие карточки с такими ISBN
    по-прежнему можно редактировать, не трогая это поле."""
    digits = re.sub(r"[\s-]", "", value)
    if len(digits) == 10:
        if not _isbn10_checksum_valid(digits):
            raise ValidationError("Некорректный ISBN-10: неверная контрольная цифра.")
    elif len(digits) == 13:
        if not _isbn13_checksum_valid(digits):
            raise ValidationError("Некорректный ISBN-13: неверная контрольная цифра.")
    else:
        raise ValidationError("ISBN должен содержать 10 или 13 цифр.")


def _isbn10_checksum_valid(digits: str) -> bool:
    if not re.fullmatch(r"\d{9}[\dXx]", digits):
        return False
    total = sum((10 if ch.upper() == "X" else int(ch)) * (10 - i) for i, ch in enumerate(digits))
    return total % 11 == 0


def _isbn13_checksum_valid(digits: str) -> bool:
    if not digits.isdigit():
        return False
    total = sum(int(ch) * (1 if i % 2 == 0 else 3) for i, ch in enumerate(digits))
    return total % 10 == 0
