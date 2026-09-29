import zipfile
from xml.etree import ElementTree as ET

from django.core.management.base import BaseCommand

from apps.catalog.models import Book
from apps.files.services import (
    EXCERPT_MAX_RATIO,
    EXCERPT_MIN_RATIO,
    _strip_tags,
    select_excerpt_count,
)

_NS = {
    "container": "urn:oasis:names:tc:opendocument:xmlns:container",
    "opf": "http://www.idpf.org/2007/opf",
}


class Command(BaseCommand):
    """Диагностика: для каждой активной книги с EPUB — сколько spine-пунктов
    попадёт во фрагмент и какая доля текста это реально даёт (тот же выбор,
    что в build_epub_excerpt). Флагует книги вне 10–15% (ТЗ)."""

    help = "Проверяет долю текста, попадающую во фрагмент EPUB, по всему каталогу"

    def handle(self, *args, **options):
        for book in Book.objects.filter(is_active=True).order_by("id"):
            if not book.epub_file:
                continue
            try:
                with zipfile.ZipFile(book.epub_file.path) as src:
                    container = ET.fromstring(src.read("META-INF/container.xml"))
                    rootfile = container.find(
                        ".//container:rootfile", _NS
                    ).attrib["full-path"]
                    opf_dir = "/".join(rootfile.split("/")[:-1])
                    opf_root = ET.fromstring(src.read(rootfile))
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

                    lengths = []
                    for item_id in spine_ids:
                        href = manifest.get(item_id)
                        if href is None:
                            continue
                        try:
                            length = len(_strip_tags(src.read(resolve(href))))
                        except KeyError:
                            length = 0
                        lengths.append(length)

                    total = sum(lengths) or 1
                    included = select_excerpt_count(lengths)
                    ratio = sum(lengths[:included]) / total
                    in_range = EXCERPT_MIN_RATIO <= round(ratio, 2) <= EXCERPT_MAX_RATIO
                    flag = "" if in_range and included < len(spine_ids) else " <-- CHECK"
                    self.stdout.write(
                        f"book={book.id} spine={len(spine_ids)} included={included} "
                        f"text_ratio={ratio:.2f}{flag}"
                    )
            except Exception as e:
                self.stdout.write(self.style.ERROR(f"book={book.id} ERROR: {e}"))
