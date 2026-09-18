import os
import shutil
import subprocess
import tarfile
from datetime import datetime, timezone

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError


class Command(BaseCommand):
    """Резервное копирование БД (pg_dump) и файлового хранилища (media/).

    Требование ТЗ: регулярное резервное копирование БД и файлового
    хранилища на внешний носитель/в облако (BookWave_TZ.md, «Требования к
    обеспечению надёжного функционирования программы»). Каталог назначения
    — внешний носитель или примонтированное облачное хранилище; сама
    доставка туда (rclone, примонтированный диск и т.п.) — вне зоны
    ответственности Django-команды, здесь только создание архивов.
    """

    help = "Создаёт дамп PostgreSQL и архив media/ в каталоге BACKUP_DIR"

    def handle(self, *args, **options):
        backup_dir = os.getenv("BACKUP_DIR", str(settings.BASE_DIR / "backups"))
        os.makedirs(backup_dir, exist_ok=True)

        timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")

        db_dump_path = self._dump_database(backup_dir, timestamp)
        media_archive_path = self._archive_media(backup_dir, timestamp)

        self.stdout.write(self.style.SUCCESS(f"Дамп БД: {db_dump_path}"))
        self.stdout.write(self.style.SUCCESS(f"Архив media/: {media_archive_path}"))

    def _dump_database(self, backup_dir, timestamp):
        db = settings.DATABASES["default"]
        dump_path = os.path.join(backup_dir, f"db_{timestamp}.dump")

        pg_dump = shutil.which("pg_dump")
        if pg_dump is None:
            raise CommandError("pg_dump не найден в PATH — установите клиент PostgreSQL")

        env = os.environ.copy()
        if db.get("PASSWORD"):
            env["PGPASSWORD"] = db["PASSWORD"]

        command = [
            pg_dump,
            "-h", db.get("HOST") or "localhost",
            "-p", str(db.get("PORT") or "5432"),
            "-U", db.get("USER"),
            "-F", "c",
            "-f", dump_path,
            db.get("NAME"),
        ]
        result = subprocess.run(command, env=env, capture_output=True, text=True)
        if result.returncode != 0:
            raise CommandError(f"pg_dump завершился с ошибкой: {result.stderr}")
        return dump_path

    def _archive_media(self, backup_dir, timestamp):
        media_root = settings.MEDIA_ROOT
        archive_path = os.path.join(backup_dir, f"media_{timestamp}.tar.gz")
        with tarfile.open(archive_path, "w:gz") as tar:
            tar.add(media_root, arcname="media")
        return archive_path
