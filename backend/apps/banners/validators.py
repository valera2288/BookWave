from apps.common.validators import validate_image_file

BANNER_MAX_SIZE_BYTES = 5 * 1024 * 1024


def validate_banner_image(file) -> None:
    validate_image_file(
        file,
        max_size_bytes=BANNER_MAX_SIZE_BYTES,
        format_error="Изображение баннера должно быть в формате JPG или PNG.",
        size_error="Размер изображения баннера не должен превышать 5 МБ.",
    )
