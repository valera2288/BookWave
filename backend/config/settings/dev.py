import sys

from .base import *  # noqa: F401,F403

DEBUG = True

# 192.168.0.12 — LAN IP хост-машины, нужен для доступа с BlueStacks
# (единственная Android-цель проекта, см. AGENTS.md): у него нет алиаса
# localhost/10.0.2.2 к хосту, только реальный IP в локальной сети.
ALLOWED_HOSTS = ["localhost", "127.0.0.1", "192.168.0.12"]

EMAIL_BACKEND = "django.core.mail.backends.console.EmailBackend"

# На Windows stdout по умолчанию открыт в codepage консоли (cp1251/cp866 и
# т.п.), а не UTF-8 — console-бэкенд писем падает с UnicodeEncodeError на
# кириллице (título книг, имя пользователя) прямо во время печати чека,
# уже после успешного коммита заказа. Сами письма это не ломает ни на каких
# других ОС, поэтому просто форсируем UTF-8 на stdout/stderr при старте.
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
