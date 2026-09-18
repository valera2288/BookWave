import zipfile
from xml.etree import ElementTree as ET

from django.core.management.base import BaseCommand

from apps.catalog.models import Book
from apps.files.services import _strip_tags

_NS = {
    "container": "urn:oasis:names:tc:opendocument:xmlns:container",
    "opf": "http://www.idpf.org/2007/opf",
}


class Command(BaseCommand):
    """Диагностика: для каждой активной книги с EPUB — сколько spine-пунктов
    попадёт во фрагмент и какая доля текста это реально даёт. Флагует книги,
    где фрагмент фактически близок к полному тексту (мало пунктов spine)."""

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
                    target = total * 0.12
                    included = 0
                    acc = 0
                    for length in lengths:
                        included += 1
                        acc += length
                        if acc >= target:
                            break

                    ratio = acc / total
                    flag = " <-- CHECK" if ratio > 0.3 or included >= len(spine_ids) else ""
                    self.stdout.write(
                        f"book={book.id} spine={len(spine_ids)} included={included} "
                        f"text_ratio={ratio:.2f}{flag}"
                    )
            except Exception as e:
                self.stdout.write(self.style.ERROR(f"book={book.id} ERROR: {e}"))
