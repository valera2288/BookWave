import io
import re
import tempfile
import zipfile
from decimal import Decimal
from pathlib import Path
from xml.etree import ElementTree as ET

from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase, override_settings
from django.urls import reverse
from pypdf import PdfReader, PdfWriter
from rest_framework.test import APIRequestFactory, force_authenticate

from apps.catalog.models import Book
from apps.library.models import LibraryEntry
from apps.users.models import User
from config.urls import PUBLIC_MEDIA_PATTERN

from .services import (
    build_epub_excerpt,
    build_fb2_excerpt,
    build_pdf_excerpt,
    select_excerpt_count,
)
from .views import BookFileView


def _make_user(email):
    return User.objects.create_user(email=email, password="testpass123", name="Reader")


def _make_epub(tmp_dir, chapters):
    path = Path(tmp_dir) / "book.epub"
    manifest_items = "".join(
        f'<item id="ch{i}" href="ch{i}.xhtml" media-type="application/xhtml+xml"/>'
        for i in range(len(chapters))
    )
    spine_items = "".join(f'<itemref idref="ch{i}"/>' for i in range(len(chapters)))
    opf = (
        '<?xml version="1.0"?>'
        '<package xmlns="http://www.idpf.org/2007/opf" version="2.0">'
        "<metadata/>"
        f"<manifest>{manifest_items}</manifest>"
        f"<spine>{spine_items}</spine>"
        "</package>"
    )
    with zipfile.ZipFile(path, "w") as z:
        z.writestr("mimetype", "application/epub+zip", compress_type=zipfile.ZIP_STORED)
        z.writestr(
            "META-INF/container.xml",
            '<?xml version="1.0"?>'
            '<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">'
            '<rootfiles><rootfile full-path="OEBPS/content.opf" '
            'media-type="application/oebps-package+xml"/></rootfiles></container>',
        )
        z.writestr("OEBPS/content.opf", opf)
        for i, text in enumerate(chapters):
            z.writestr(f"OEBPS/ch{i}.xhtml", f"<html><body><p>{text}</p></body></html>")
    return path


def _make_pdf(tmp_dir, page_count):
    path = Path(tmp_dir) / "book.pdf"
    writer = PdfWriter()
    for _ in range(page_count):
        writer.add_blank_page(width=200, height=200)
    with open(path, "wb") as f:
        writer.write(f)
    return path


def _make_fb2(tmp_dir, sections):
    path = Path(tmp_dir) / "book.fb2"
    body = "".join(f"<section><p>{text}</p></section>" for text in sections)
    content = (
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<FictionBook xmlns="http://www.gribuser.ru/xml/fictionbook/2.0">'
        "<description><title-info><book-title>Test</book-title></title-info></description>"
        f"<body>{body}</body>"
        "</FictionBook>"
    )
    path.write_text(content, encoding="utf-8")
    return path


class BuildEpubExcerptTests(TestCase):
    def test_truncates_spine_to_ratio_and_stays_valid(self):
        with tempfile.TemporaryDirectory() as tmp:
            src = _make_epub(tmp, ["x" * 1000 for _ in range(4)])
            excerpt = build_epub_excerpt(src)

            with zipfile.ZipFile(io.BytesIO(excerpt)) as z:
                names = z.namelist()
                self.assertIn("mimetype", names)
                self.assertEqual(names[0], "mimetype")
                self.assertIn("OEBPS/ch0.xhtml", names)
                self.assertNotIn("OEBPS/ch3.xhtml", names)
                opf = ET.fromstring(z.read("OEBPS/content.opf"))
                ns = {"opf": "http://www.idpf.org/2007/opf"}
                spine_ids = [
                    el.attrib["idref"] for el in opf.findall(".//opf:spine/opf:itemref", ns)
                ]
                self.assertEqual(spine_ids, ["ch0"])

    def test_never_produces_empty_spine(self):
        with tempfile.TemporaryDirectory() as tmp:
            src = _make_epub(tmp, ["short text"])
            excerpt = build_epub_excerpt(src)

            with zipfile.ZipFile(io.BytesIO(excerpt)) as z:
                self.assertIn("OEBPS/ch0.xhtml", z.namelist())


class SelectExcerptCountTests(TestCase):
    """Фрагмент — 10–15% текста (ТЗ); режется целыми частями, при
    перескоке за 15% берётся вариант ближе к диапазону."""

    def test_stops_once_min_ratio_reached(self):
        self.assertEqual(select_excerpt_count([5, 5, 50, 40]), 2)  # 10%

    def test_excludes_part_when_undershoot_is_closer(self):
        self.assertEqual(select_excerpt_count([8, 10, 82]), 1)  # 8% ближе, чем 18%

    def test_includes_part_when_overshoot_is_closer(self):
        self.assertEqual(select_excerpt_count([4, 12, 84]), 2)  # 16% ближе, чем 4%


class BuildPdfExcerptTests(TestCase):
    def test_keeps_ceil_ratio_of_pages(self):
        with tempfile.TemporaryDirectory() as tmp:
            src = _make_pdf(tmp, page_count=10)
            excerpt = build_pdf_excerpt(src, ratio=0.15)

            reader = PdfReader(io.BytesIO(excerpt))
            self.assertEqual(len(reader.pages), 2)  # ceil(10 * 0.15) = 2

    def test_keeps_at_least_one_page(self):
        with tempfile.TemporaryDirectory() as tmp:
            src = _make_pdf(tmp, page_count=1)
            excerpt = build_pdf_excerpt(src, ratio=0.05)

            reader = PdfReader(io.BytesIO(excerpt))
            self.assertEqual(len(reader.pages), 1)


class BuildFb2ExcerptTests(TestCase):
    def test_truncates_sections_and_keeps_description(self):
        with tempfile.TemporaryDirectory() as tmp:
            src = _make_fb2(tmp, ["x" * 1000 for _ in range(4)])
            excerpt = build_fb2_excerpt(src)

            root = ET.fromstring(excerpt)
            ns = {"fb": "http://www.gribuser.ru/xml/fictionbook/2.0"}
            self.assertIsNotNone(root.find("fb:description", ns))
            sections = root.findall(".//fb:body/fb:section", ns)
            self.assertEqual(len(sections), 1)


@override_settings(DEBUG=True)
class BookFileViewTests(TestCase):
    """DEBUG=True здесь намеренно — прод-ветка (X-Accel-Redirect) не отдаёт
    байты через Django, её незачем и нечем тестировать байт-в-байт;
    поведение переключения полный/фрагмент от DEBUG не зависит."""

    def setUp(self):
        self.tmp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp_dir.cleanup)
        self.override = override_settings(MEDIA_ROOT=self.tmp_dir.name)
        self.override.enable()
        self.addCleanup(self.override.disable)

        epub_path = _make_epub(self.tmp_dir.name, ["x" * 1000 for _ in range(4)])
        self.book = Book.objects.create(
            title="Владелец видит всё",
            price=Decimal("100.00"),
            isbn="9990000000001",
            epub_file=SimpleUploadedFile(
                "book.epub", epub_path.read_bytes(), content_type="application/epub+zip"
            ),
        )
        # На Windows открытый файловый хендл блокирует удаление временной
        # директории в tearDown — закрываем явно перед rmtree (addCleanup
        # выполняется в LIFO-порядке, так что это отработает раньше него).
        self.addCleanup(self.book.epub_file.close)
        self.owner = _make_user("owner@test.local")
        self.guest = _make_user("guest@test.local")
        LibraryEntry.objects.create(user=self.owner, book=self.book)

    def _get(self, user=None):
        factory = APIRequestFactory()
        request = factory.get(
            reverse("book_file", kwargs={"book_id": self.book.id, "file_format": "epub"})
        )
        if user is not None:
            force_authenticate(request, user=user)
        return BookFileView.as_view()(
            request, book_id=self.book.id, file_format="epub"
        )

    def _read(self, response):
        # FileResponse держит файл открытым, пока явно не закрыть — на
        # Windows это блокирует удаление временной директории в tearDown.
        # `response.close()` тут не годится: он шлёт сигнал
        # `request_finished`, а в тестах на него подписан
        # `close_old_connections`, который рвёт общий для теста DB-коннекшен
        # (тест вызывает view напрямую, в обход обычного request-цикла).
        content = b"".join(response.streaming_content)
        for closer in response._resource_closers:
            closer()
        return content

    def test_owner_gets_full_file(self):
        response = self._get(self.owner)
        content = self._read(response)
        self.assertEqual(content, self.book.epub_file.read())

    def test_guest_gets_shorter_excerpt(self):
        response = self._get(user=None)
        content = self._read(response)
        self.assertLess(len(content), len(self.book.epub_file.read()))

        with zipfile.ZipFile(io.BytesIO(content)) as z:
            self.assertIn("OEBPS/ch0.xhtml", z.namelist())
            self.assertNotIn("OEBPS/ch3.xhtml", z.namelist())

    def test_authenticated_non_owner_also_gets_excerpt(self):
        response = self._get(self.guest)
        content = self._read(response)
        self.assertLess(len(content), len(self.book.epub_file.read()))

    def test_unknown_format_is_404(self):
        factory = APIRequestFactory()
        request = factory.get("/api/files/books/1/doc/")
        response = BookFileView.as_view()(request, book_id=self.book.id, file_format="doc")
        self.assertEqual(response.status_code, 404)

    def test_public_media_pattern_excludes_book_files_but_allows_covers(self):
        # ТЗ: «Прямой доступ к файлу книги по статической ссылке должен
        # быть запрещён» — регресс на дыру в dev-раздаче media/. Django в
        # тестах форсит DEBUG=False, так что сама DEBUG-гейтед ветка в
        # config/urls.py тут не выполняется — проверяем паттерн напрямую.
        pattern = re.compile(PUBLIC_MEDIA_PATTERN)
        self.assertIsNone(pattern.match(f"media/{self.book.epub_file.name}"))
        self.assertIsNotNone(pattern.match("media/covers/whatever.jpg"))
