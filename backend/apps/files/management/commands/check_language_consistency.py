import re
import zipfile
from xml.etree import ElementTree as ET

from django.core.management.base import BaseCommand

from apps.catalog.models import Book
from apps.files.services import _strip_tags

_NS = {
    "container": "urn:oasis:names:tc:opendocument:xmlns:container",
    "opf": "http://www.idpf.org/2007/opf",
}
_CYRILLIC = re.compile(r"[а-яА-ЯёЁ]")
_LATIN = re.compile(r"[a-zA-Z]")


class Command(BaseCommand):
    """Диагностика на конкретную находку (книга 49 — две полные копии
    текста подряд, RU потом EN): для книг с language=ru считает долю
    латиницы против кириллицы по каждому spine-файлу и флагует книгу, если
    в какой-то момент (после начала) латиница резко перевешивает —
    признак второй копии текста на другом языке, приклеенной в конец."""

    help = "Ищет резкий переход кириллица->латиница внутри книг с language=ru"

    def handle(self, *args, **options):
        for book in Book.objects.filter(is_active=True, language="ru").order_by("id"):
            if not book.epub_file:
                continue
            try:
                with zipfile.ZipFile(book.epub_file.path) as z:
                    container = ET.fromstring(z.read("META-INF/container.xml"))
                    rootfile = container.find(".//container:rootfile", _NS).attrib["full-path"]
                    opf_dir = "/".join(rootfile.split("/")[:-1])
                    opf_root = ET.fromstring(z.read(rootfile))
                    manifest = {
                        item.attrib["id"]: item.attrib["href"]
                        for item in opf_root.findall(".//opf:manifest/opf:item", _NS)
                    }
                    spine_ids = [
                        i.attrib["idref"]
                        for i in opf_root.findall(".//opf:spine/opf:itemref", _NS)
                    ]

                    def resolve(href):
                        return f"{opf_dir}/{href}" if opf_dir else href

                    latin_flag_index = None
                    for idx, item_id in enumerate(spine_ids):
                        href = manifest.get(item_id)
                        if not href:
                            continue
                        try:
                            text = _strip_tags(z.read(resolve(href)))
                        except KeyError:
                            continue
                        cyr = len(_CYRILLIC.findall(text))
                        lat = len(_LATIN.findall(text))
                        total_letters = cyr + lat
                        # Игнорируем короткие технические файлы (обложка,
                        # титульный лист почти без текста).
                        if total_letters < 200:
                            continue
                        if lat > cyr and idx > 0:
                            latin_flag_index = idx
                            break

                    if latin_flag_index is not None:
                        self.stdout.write(
                            self.style.WARNING(
                                f"book={book.id} '{book.title}': латиница перевешивает с "
                                f"spine[{latin_flag_index}]/{len(spine_ids)} <-- CHECK"
                            )
                        )
                    else:
                        self.stdout.write(f"book={book.id} '{book.title}': OK")
            except Exception as e:
                self.stdout.write(self.style.ERROR(f"book={book.id} ERROR: {e}"))
