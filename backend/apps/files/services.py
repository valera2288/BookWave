import io
import re
import zipfile
from math import ceil
from pathlib import Path
from xml.etree import ElementTree as ET

from django.conf import settings
from django.http import FileResponse, HttpResponse
from pypdf import PdfReader, PdfWriter

FORMAT_CONTENT_TYPES = {
    "epub": "application/epub+zip",
    "pdf": "application/pdf",
    "fb2": "application/fb2+xml",
}

_EPUB_NAMESPACES = {
    "container": "urn:oasis:names:tc:opendocument:xmlns:container",
    "opf": "http://www.idpf.org/2007/opf",
}

_TAG_RE = re.compile(r"<[^>]+>")

_FB2_NS = "http://www.gribuser.ru/xml/fictionbook/2.0"


def get_book_file_field(book, file_format):
    return {"epub": book.epub_file, "pdf": book.pdf_file, "fb2": book.fb2_file}.get(file_format)


def _strip_tags(html_bytes: bytes) -> str:
    return _TAG_RE.sub(" ", html_bytes.decode("utf-8", errors="ignore"))


def build_epub_excerpt(src_path: Path, ratio: float = 0.12) -> bytes:
    """Первые ~`ratio` от объёма текста EPUB (по символам содержимого
    spine-документов, не по байтам файла — ТЗ). Копирует исходный zip как
    есть и лишь вырезает документы spine после точки отсечения плюс
    соответствующие записи из spine/manifest в content.opf — обложка,
    стили, nav/toc.ncx и все прочие ресурсы остаются нетронутыми, поэтому
    результат — валидный, просто более короткий EPUB."""
    with zipfile.ZipFile(src_path) as src:
        container = ET.fromstring(src.read("META-INF/container.xml"))
        rootfile = container.find(".//container:rootfile", _EPUB_NAMESPACES).attrib["full-path"]
        opf_dir = "/".join(rootfile.split("/")[:-1])
        opf_bytes = src.read(rootfile)
        opf_root = ET.fromstring(opf_bytes)

        manifest = {
            item.attrib["id"]: item.attrib["href"]
            for item in opf_root.findall(".//opf:manifest/opf:item", _EPUB_NAMESPACES)
        }
        spine_ids = [
            itemref.attrib["idref"]
            for itemref in opf_root.findall(".//opf:spine/opf:itemref", _EPUB_NAMESPACES)
        ]

        def resolve(href):
            return f"{opf_dir}/{href}" if opf_dir else href

        lengths = []
        for item_id in spine_ids:
            href = manifest.get(item_id)
            if href is None:
                continue
            try:
                text_len = len(_strip_tags(src.read(resolve(href))))
            except KeyError:
                text_len = 0
            lengths.append((item_id, text_len))

        total = sum(length for _, length in lengths) or 1
        target = total * ratio
        included_ids = set()
        acc = 0
        for item_id, text_len in lengths:
            included_ids.add(item_id)
            acc += text_len
            if acc >= target:
                break
        if not included_ids and spine_ids:
            included_ids = {spine_ids[0]}

        excluded_ids = [i for i in spine_ids if i not in included_ids]
        excluded_paths = {resolve(manifest[i]) for i in excluded_ids if i in manifest}

        new_opf_root = ET.fromstring(opf_bytes)
        for spine_el in new_opf_root.findall(".//opf:spine", _EPUB_NAMESPACES):
            for itemref in list(spine_el.findall("opf:itemref", _EPUB_NAMESPACES)):
                if itemref.attrib.get("idref") not in included_ids:
                    spine_el.remove(itemref)
        for manifest_el in new_opf_root.findall(".//opf:manifest", _EPUB_NAMESPACES):
            for item in list(manifest_el.findall("opf:item", _EPUB_NAMESPACES)):
                if item.attrib.get("id") in excluded_ids:
                    manifest_el.remove(item)

        buffer = io.BytesIO()
        with zipfile.ZipFile(buffer, "w", zipfile.ZIP_DEFLATED) as out:
            # mimetype обязана быть первой записью и без сжатия (спецификация EPUB)
            out.writestr("mimetype", "application/epub+zip", compress_type=zipfile.ZIP_STORED)
            for name in src.namelist():
                if name in ("mimetype",) or name in excluded_paths:
                    continue
                if name == rootfile:
                    out.writestr(
                        name, ET.tostring(new_opf_root, encoding="utf-8", xml_declaration=True)
                    )
                else:
                    out.writestr(name, src.read(name))
        return buffer.getvalue()


def build_pdf_excerpt(src_path: Path, ratio: float = 0.15) -> bytes:
    """Первые `ceil(ratio * страниц)` страниц (минимум одна)."""
    reader = PdfReader(src_path)
    keep = max(1, ceil(len(reader.pages) * ratio))
    writer = PdfWriter()
    for page in reader.pages[:keep]:
        writer.add_page(page)
    buffer = io.BytesIO()
    writer.write(buffer)
    return buffer.getvalue()


def _fb2_tag(name: str, has_ns: bool) -> str:
    return f"{{{_FB2_NS}}}{name}" if has_ns else name


def build_fb2_excerpt(src_path: Path, ratio: float = 0.12) -> bytes:
    """`<description>` остаётся целиком (метаданные), из `<body>` — первые
    секции по порядку до достижения `ratio` от суммарной длины текста."""
    tree = ET.parse(src_path)
    root = tree.getroot()
    has_ns = root.tag.startswith("{")
    body = root.find(_fb2_tag("body", has_ns))
    if body is None:
        return Path(src_path).read_bytes()

    sections = list(body.findall(_fb2_tag("section", has_ns)))
    if not sections:
        return Path(src_path).read_bytes()

    lengths = [len("".join(section.itertext())) for section in sections]
    total = sum(lengths) or 1
    target = total * ratio
    keep_count = 0
    acc = 0
    for length in lengths:
        keep_count += 1
        acc += length
        if acc >= target:
            break

    for section in sections[keep_count:]:
        body.remove(section)

    buffer = io.BytesIO()
    tree.write(buffer, encoding="utf-8", xml_declaration=True)
    return buffer.getvalue()


_EXCERPT_BUILDERS = {
    "epub": build_epub_excerpt,
    "pdf": build_pdf_excerpt,
    "fb2": build_fb2_excerpt,
}


def resolve_file_path(book, file_format: str, *, owns: bool) -> Path:
    """Путь к файлу, который реально нужно отдать: полный — владельцу,
    урезанный (сгенерированный и закэшированный на диске при первом
    обращении) — всем остальным. Кэш инвалидируется, если файл книги
    переуплоатили после генерации фрагмента (по mtime)."""
    file_field = get_book_file_field(book, file_format)
    src_path = Path(file_field.path)
    if owns:
        return src_path

    excerpt_dir = Path(settings.MEDIA_ROOT) / "excerpts"
    excerpt_dir.mkdir(parents=True, exist_ok=True)
    cache_path = excerpt_dir / f"{book.id}-{file_format}.{file_format}"
    if not cache_path.exists() or cache_path.stat().st_mtime < src_path.stat().st_mtime:
        content = _EXCERPT_BUILDERS[file_format](src_path)
        cache_path.write_bytes(content)
    return cache_path


def serve_file(path: Path, *, filename: str, content_type: str):
    """Байты файла книги никогда не идут через Django-воркер вне dev —
    в проде это заголовок X-Accel-Redirect, реальную отдачу берёт на себя
    Nginx (см. `PROTECTED_MEDIA_INTERNAL_LOCATION` в settings и
    ARCHITECTURE.md, «Раздача файлов книг»)."""
    if settings.DEBUG:
        return FileResponse(open(path, "rb"), filename=filename, content_type=content_type)

    response = HttpResponse(content_type=content_type)
    relative = path.relative_to(settings.MEDIA_ROOT)
    response["X-Accel-Redirect"] = (
        f"{settings.PROTECTED_MEDIA_INTERNAL_LOCATION}{relative.as_posix()}"
    )
    response["Content-Disposition"] = f'attachment; filename="{filename}"'
    return response
