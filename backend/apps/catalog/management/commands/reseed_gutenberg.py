import urllib.request

from django.core.files.base import ContentFile
from django.core.management.base import BaseCommand

from apps.catalog.models import Author, Book, Genre

GUTENBERG_URL = "https://www.gutenberg.org/cache/epub/{gid}/pg{gid}.epub"
GUTENBERG_COVER_URL = "https://www.gutenberg.org/cache/epub/{gid}/pg{gid}.cover.medium.jpg"

# (book_id, gutenberg_id, new_title_or_None, new_author_name_or_None,
#  language, new_genre_name_or_None)
PLAN = [
    # --- Группа A: только обновление содержимого, название/автор не меняются ---
    (8, 2600, None, None, "en", None),
    (9, 139, None, None, "en", None),
    (11, 2083, None, None, "en", None),
    (12, 9150, None, None, "en", None),
    (13, 23997, None, None, "en", None),
    (14, 13511, None, None, "en", None),
    (17, 1399, None, None, "en", None),
    (18, 1938, None, None, "en", None),
    (19, 47197, None, None, "en", None),
    (20, 4761, None, None, "en", None),
    # --- Группа B1: язык/микс демо-данных (решение пользователя, 2026-09-17) —
    # на Gutenberg в русском разделе всего 9 книг, из них художественная
    # проза с реальным текстом (не только аудио) — только "Детство" Толстого;
    # "Белые ночи"/"Записки из подполья" Достоевского значатся как русские,
    # но на деле это только аудиокниги без текстового файла — проверено
    # напрямую по листингу файлов, не по описанию в поиске ---
    (15, 19681, "Детство", "Лев Толстой", "ru", "Роман"),
    (16, 2554, "Преступление и наказание", "Фёдор Достоевский", "en", "Роман"),
    # --- Группа C: полная замена (Толкин/Азимов/Кристи не в public domain,
    # решение пользователя — заменить на реальных public domain авторов) ---
    (3, 35, "Машина времени", "Герберт Уэллс", "en", None),
    (4, 36, "Война миров", "Герберт Уэллс", "en", None),
    (26, 5230, "Человек-невидимка", "Герберт Уэллс", "en", None),
    (27, 159, "Остров доктора Моро", "Герберт Уэллс", "en", None),
    (28, 1013, "Первые люди на Луне", "Герберт Уэллс", "en", None),
    (5, 55, "Удивительный волшебник из страны Оз", "Лаймен Фрэнк Баум", "en", None),
    (6, 19466, "Страна Оз", "Лаймен Фрэнк Баум", "en", None),
    (24, 486, "Озма из страны Оз", "Лаймен Фрэнк Баум", "en", None),
    (25, 517, "Изумрудный город страны Оз", "Лаймен Фрэнк Баум", "en", None),
    (7, 244, "Этюд в багровых тонах", "Артур Конан Дойл", "en", None),
    (21, 2852, "Собака Баскервилей", "Артур Конан Дойл", "en", None),
    (22, 2097, "Знак четырёх", "Артур Конан Дойл", "en", None),
    (23, 1661, "Приключения Шерлока Холмса", "Артур Конан Дойл", "en", None),
]


class Command(BaseCommand):
    """Разовая замена синтетических тестовых EPUB-заглушек в каталоге на
    реальные public domain книги с Project Gutenberg (см. memory:
    bookwave-gutenberg-epub-seeder). Толкин/Азимов/Кристи не в public domain
    — по решению пользователя эти карточки переведены на других авторов
    (Уэллс/Баум/Дойл), чтобы название и автор карточки правдиво
    соответствовали содержимому файла."""

    help = "Заменяет тестовые EPUB-заглушки книг на реальные тексты с Project Gutenberg"

    def add_arguments(self, parser):
        parser.add_argument(
            "--covers-only",
            action="store_true",
            help="Не перекачивать EPUB повторно — только обложки (для дозаливки после первого запуска).",
        )

    def fetch(self, url, min_size):
        req = urllib.request.Request(url, headers={"User-Agent": "BookWave-dev/1.0"})
        with urllib.request.urlopen(req, timeout=60) as resp:
            data = resp.read()
        if len(data) < min_size:
            raise ValueError(f"Подозрительно маленький файл ({len(data)} байт): {url}")
        return data

    def fetch_epub(self, gid):
        return self.fetch(GUTENBERG_URL.format(gid=gid), min_size=5000)

    def fetch_cover(self, gid):
        # Не у каждой книги Gutenberg есть готовая обложка — это не критично
        # для основной задачи (реальный текст), поэтому ошибка здесь не
        # прерывает обработку книги, только логируется отдельно.
        return self.fetch(GUTENBERG_COVER_URL.format(gid=gid), min_size=500)

    def handle(self, *args, **options):
        covers_only = options["covers_only"]
        for book_id, gid, new_title, new_author_name, language, new_genre_name in PLAN:
            try:
                book = Book.objects.get(id=book_id)
                size_note = ""

                if not covers_only:
                    data = self.fetch_epub(gid)
                    book.epub_file.save(f"gutenberg-{gid}.epub", ContentFile(data), save=False)
                    book.language = language
                    if new_title:
                        book.title = new_title
                    size_note = f"size={len(data)} "

                try:
                    cover_data = self.fetch_cover(gid)
                    book.cover.save(f"gutenberg-{gid}-cover.jpg", ContentFile(cover_data), save=False)
                    cover_note = f"cover={len(cover_data)}"
                except Exception as cover_error:
                    cover_note = f"cover FAILED: {cover_error}"

                book.save()
                if new_author_name:
                    author, _ = Author.objects.get_or_create(name=new_author_name)
                    book.authors.set([author])
                if new_genre_name:
                    genre, _ = Genre.objects.get_or_create(name=new_genre_name)
                    book.genres.set([genre])
                self.stdout.write(
                    f"OK   book={book_id} gutenberg={gid} {size_note}{cover_note} -> {book.title}"
                )
            except Exception as e:
                self.stdout.write(self.style.ERROR(f"FAIL book={book_id} gutenberg={gid}: {e}"))
