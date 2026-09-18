from pathlib import Path

from django.core.files.base import ContentFile
from django.core.management.base import BaseCommand

from apps.catalog.models import Book

# (book_id, filename in --source-dir)
PLAN = [
    (3, "Uells_Mashina-vremeni-sbornik-.403082.fb2.epub"),
    (4, "Uells_Voyna-mirov.584331.fb2.epub"),
    (6, "Baum_Volshebnik-iz-Strany-Oz_2_Chudesnaya-Strana-Oz.312314.fb2.epub"),
    (7, "Konan-Doyl_Povesti-o-Sherloke-Holmse_1_Etyud-v-bagrovyh-tonah.775187.fb2.epub"),
    (8, "Tolstoy_Voyna-i-mir.820555.fb2.epub"),
    (9, "Konan-Doyl_Professor-Chellendzher_1_Zateryannyy-mir.581363.fb2.epub"),
    (11, "Vern_Kapitan-Nemo_1_Deti-kapitana-Granta.524243.fb2.epub"),
    (12, "Vern_Pyatnadcatiletniy-kapitan.126598.fb2.epub"),
    (13, "Pushkin_Lyubimye-knigi-Lva-Tolstogo-S-14-do-20-let-_1_Evgeniy-Onegin.791573.fb2.epub"),
    (14, "Pushkin_Kapitanskaya-dochka.270213.fb2.epub"),
    (15, "Tolstoy_Detstvo-Otrochestvo-Yunost_1_Detstvo.411600.fb2.epub"),
    (16, "Dostoevskiy_BVL-Seriya-vtoraya_83_Prestuplenie-i-nakazanie.261797.fb2.epub"),
    (17, "Tolstoy_Anna-Karenina.767629.fb2.epub"),
    (18, "Tolstoy_Voskresenie.485688.fb2.epub"),
    (19, "Tolstoy_Sevastopolskie-rasskazy.411607.fb2.epub"),
    (20, "Tolstoy_Kazaki.56227.fb2.epub"),
    (21, "Konan-Doyl_Povesti-o-Sherloke-Holmse_3_Sobaka-Baskerviley.547464.fb2.epub"),
    (22, "Konan-Doyl_Povesti-o-Sherloke-Holmse_2_Znak-chetyreh.547480.fb2.epub"),
    (23, "Konan-Doyl_Sherlok-Holms-s-illyustraciyami_3_Priklyucheniya-Sherloka-Holmsa.181935.fb2.epub"),
    (24, "Baum_Volshebnik-iz-Strany-Oz_3_Ozma-iz-Strany-Oz.419041.fb2.epub"),
    (25, "Baum_Volshebnik-iz-Strany-Oz_6_Izumrudnyy-Gorod-Strany-Oz.312727.fb2.epub"),
    (26, "Uells_Chelovek-nevidimka.541272.fb2.epub"),
    (27, "Uells_Ostrov-doktora-Moro.625902.fb2.epub"),
    (28, "Uells_Pervye-lyudi-na-Lune.385024.fb2.epub"),
    (48, "Ostin_Gordost-i-predubezhdenie.368729.fb2.epub"),
    # id=5 ("Удивительный волшебник из страны Оз") сюда намеренно не входит —
    # соответствующий файл пользователя оказался параллельным русско-
    # английским текстом (вёрстка HTML-таблицей, без <p>), непригодным для
    # читалки; для этой книги остаётся английский текст с Project Gutenberg.
]


class Command(BaseCommand):
    """Заливает реальные EPUB-файлы книг из локальной папки (--source-dir)
    поверх текущего содержимого каталога — см. PLAN за соответствием
    книга-файл. В отличие от `reseed_gutenberg`, файлы не скачиваются, а
    читаются с диска."""

    help = "Импортирует локальные EPUB-файлы книг из папки пользователя"

    def add_arguments(self, parser):
        parser.add_argument("source_dir", type=str)

    def handle(self, *args, **options):
        source_dir = Path(options["source_dir"])
        for book_id, filename in PLAN:
            path = source_dir / filename
            try:
                if not path.exists():
                    raise FileNotFoundError(f"файл не найден: {path}")
                book = Book.objects.get(id=book_id)
                data = path.read_bytes()
                book.epub_file.save(path.name, ContentFile(data), save=False)
                book.language = "ru"
                book.save()
                self.stdout.write(f"OK   book={book_id} size={len(data)} -> {book.title}")
            except Exception as e:
                self.stdout.write(self.style.ERROR(f"FAIL book={book_id} file={filename}: {e}"))
