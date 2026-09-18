import zipfile
from io import BytesIO
from xml.etree import ElementTree as ET

from django.core.files.base import ContentFile
from django.core.management.base import BaseCommand

from apps.catalog.models import Book

_NS = {
    "container": "urn:oasis:names:tc:opendocument:xmlns:container",
    "opf": "http://www.idpf.org/2007/opf",
}
ET.register_namespace("", _NS["opf"])


class Command(BaseCommand):
    """Обрезает EPUB, где после полного текста на одном языке идёт ещё одна
    полная копия того же текста на другом языке (двуязычное издание «два
    романа подряд», не путать с параллельным текстом абзац-в-абзац — для
    того другой случай, см. media на Baum) — оставляет только spine-пункты
    до `--keep-until` включительно, остальные вычищает из spine, manifest
    и самого архива."""

    help = "Обрезает spine EPUB после указанного href, удаляя дублирующий язык"

    def add_arguments(self, parser):
        parser.add_argument("book_id", type=int)
        parser.add_argument("--keep-until", type=str, required=True, help="href последнего сохраняемого spine-файла")

    def handle(self, *args, **options):
        book = Book.objects.get(id=options["book_id"])
        keep_until = options["keep_until"]
        src_path = book.epub_file.path

        with zipfile.ZipFile(src_path) as src:
            container = ET.fromstring(src.read("META-INF/container.xml"))
            rootfile = container.find(".//container:rootfile", _NS).attrib["full-path"]
            opf_dir = "/".join(rootfile.split("/")[:-1])
            opf_bytes = src.read(rootfile)
            opf_root = ET.fromstring(opf_bytes)

            manifest = {
                item.attrib["id"]: item.attrib["href"]
                for item in opf_root.findall(".//opf:manifest/opf:item", _NS)
            }
            spine_ids = [
                itemref.attrib["idref"]
                for itemref in opf_root.findall(".//opf:spine/opf:itemref", _NS)
            ]

            def resolve(href):
                return f"{opf_dir}/{href}" if opf_dir else href

            cutoff_index = None
            for i, item_id in enumerate(spine_ids):
                href = manifest.get(item_id)
                if href == keep_until:
                    cutoff_index = i
                    break
            if cutoff_index is None:
                self.stdout.write(self.style.ERROR(f"'{keep_until}' не найден в spine"))
                return

            kept_ids = set(spine_ids[: cutoff_index + 1])
            dropped_ids = [i for i in spine_ids if i not in kept_ids]
            dropped_paths = {resolve(manifest[i]) for i in dropped_ids if i in manifest}

            new_opf_root = ET.fromstring(opf_bytes)
            for spine_el in new_opf_root.findall(".//opf:spine", _NS):
                for itemref in list(spine_el.findall("opf:itemref", _NS)):
                    if itemref.attrib.get("idref") not in kept_ids:
                        spine_el.remove(itemref)
            for manifest_el in new_opf_root.findall(".//opf:manifest", _NS):
                for item in list(manifest_el.findall("opf:item", _NS)):
                    if item.attrib.get("id") in dropped_ids:
                        manifest_el.remove(item)

            buffer = BytesIO()
            with zipfile.ZipFile(buffer, "w", zipfile.ZIP_DEFLATED) as out:
                out.writestr("mimetype", "application/epub+zip", compress_type=zipfile.ZIP_STORED)
                for name in src.namelist():
                    if name == "mimetype" or name in dropped_paths:
                        continue
                    if name == rootfile:
                        out.writestr(
                            name, ET.tostring(new_opf_root, encoding="utf-8", xml_declaration=True)
                        )
                    else:
                        out.writestr(name, src.read(name))

        old_size = book.epub_file.size
        new_bytes = buffer.getvalue()
        book.epub_file.save("book.epub", ContentFile(new_bytes), save=True)
        self.stdout.write(
            f"kept {len(kept_ids)}/{len(spine_ids)} spine items; "
            f"epub {old_size} -> {len(new_bytes)} bytes"
        )
