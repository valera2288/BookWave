import zipfile
from io import BytesIO

from django.core.files.base import ContentFile
from django.core.management.base import BaseCommand
from PIL import Image

from apps.catalog.models import Book


def _compress(data: bytes, *, max_dim: int, quality: int) -> bytes:
    img = Image.open(BytesIO(data)).convert("RGB")
    if max(img.size) > max_dim:
        ratio = max_dim / max(img.size)
        img = img.resize(
            (round(img.width * ratio), round(img.height * ratio)), Image.LANCZOS
        )
    buf = BytesIO()
    img.save(buf, format="JPEG", quality=quality, optimize=True)
    return buf.getvalue()


def _replace_zip_entry(src_path, entry_name: str, new_data: bytes) -> bytes:
    buf = BytesIO()
    with zipfile.ZipFile(src_path) as src, zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as out:
        for item in src.infolist():
            data = new_data if item.filename == entry_name else src.read(item.filename)
            compress_type = zipfile.ZIP_STORED if item.filename == "mimetype" else zipfile.ZIP_DEFLATED
            out.writestr(item.filename, data, compress_type=compress_type)
    return buf.getvalue()


class Command(BaseCommand):
    """Пережимает избыточно тяжёлую обложку одной книги — и отдельное поле
    `cover` (миниатюра в каталоге), и одноимённый файл, встроенный внутрь
    самого EPUB (раздувал в т.ч. кэш фрагмента, см. apps/files/services.py)."""

    help = "Сжимает обложку книги (DB-поле + встроенная в EPUB копия)"

    def add_arguments(self, parser):
        parser.add_argument("book_id", type=int)
        parser.add_argument("--epub-entry", type=str, default="OPS/images/cover.jpg")
        parser.add_argument("--max-dim", type=int, default=900)
        parser.add_argument("--quality", type=int, default=82)

    def handle(self, *args, **options):
        book = Book.objects.get(id=options["book_id"])

        if book.cover:
            original = book.cover.read()
            compressed = _compress(original, max_dim=options["max_dim"], quality=options["quality"])
            book.cover.save("cover.jpg", ContentFile(compressed), save=False)
            self.stdout.write(f"cover: {len(original)} -> {len(compressed)} bytes")

        if book.epub_file:
            entry = options["epub_entry"]
            with zipfile.ZipFile(book.epub_file.path) as z:
                try:
                    original_epub_cover = z.read(entry)
                except KeyError:
                    original_epub_cover = None

            if original_epub_cover is not None:
                compressed_epub_cover = _compress(
                    original_epub_cover, max_dim=options["max_dim"], quality=options["quality"]
                )
                new_epub_bytes = _replace_zip_entry(
                    book.epub_file.path, entry, compressed_epub_cover
                )
                old_epub_size = book.epub_file.size
                book.epub_file.save("book.epub", ContentFile(new_epub_bytes), save=False)
                self.stdout.write(
                    f"epub cover: {len(original_epub_cover)} -> {len(compressed_epub_cover)} bytes; "
                    f"epub total: {old_epub_size} -> {len(new_epub_bytes)} bytes"
                )
            else:
                self.stdout.write(self.style.WARNING(f"entry {entry} not found in epub"))

        book.save()
        self.stdout.write("saved")
