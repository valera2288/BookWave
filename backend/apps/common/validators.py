import os

from django.core.exceptions import ValidationError
from PIL import Image, UnidentifiedImageError

IMAGE_ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png"}
IMAGE_ALLOWED_FORMATS = {"JPEG", "PNG"}


def validate_image_file(file, *, max_size_bytes: int, format_error: str, size_error: str) -> None:
    """Общая проверка загружаемых изображений (обложка/баннер/аватар):
    формат JPG/PNG и размер файла, плюс сверка, что содержимое
    действительно декодируется как заявленный формат (расширение можно
    подделать). Сообщения об ошибках — от вызывающей стороны, чтобы не
    ломать согласование рода слова («обложка должна»/«баннера должно»/
    «аватар должен»)."""
    ext = os.path.splitext(file.name)[1].lower()
    if ext not in IMAGE_ALLOWED_EXTENSIONS:
        raise ValidationError(format_error)
    if file.size > max_size_bytes:
        raise ValidationError(size_error)

    try:
        image = Image.open(file)
        image.verify()
    except (UnidentifiedImageError, OSError):
        raise ValidationError("Файл повреждён или не является изображением.")
    if image.format not in IMAGE_ALLOWED_FORMATS:
        raise ValidationError(format_error)
    file.seek(0)
