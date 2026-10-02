# BookWave

Магазин электронных книг со встроенной читалкой: читатели покупают и читают книги в мобильном приложении, а администратор управляет каталогом, заказами и отчётами через веб-панель.

<p align="center">
  <img src="docs/screenshots/mob_13_home_reader.png" width="190" alt="Главная">
  <img src="docs/screenshots/mob_08_catalog.png" width="190" alt="Каталог">
  <img src="docs/screenshots/mob_11_book_detail.png" width="190" alt="Карточка книги">
  <img src="docs/screenshots/mob_20_reader.png" width="190" alt="Читалка">
</p>

## Возможности

**Читатель (мобильное приложение, Android)**

- регистрация, вход, восстановление пароля по письму; гостевой режим с просмотром каталога;
- каталог с поиском по названию, автору и ISBN, фильтрами (жанр, цена, язык, рейтинг) и сортировкой;
- карточка книги с отзывами и бесплатным ознакомительным фрагментом;
- избранное, корзина, промокоды, оформление заказа с имитацией оплаты и электронным чеком;
- личная библиотека с прогрессом чтения и встроенная читалка: оглавление, закладки, поиск по тексту, размер шрифта, светлая, тёмная и сепия темы;
- отзывы и оценки на купленные книги, история заказов, смена темы и языка (русский и английский).

**Администратор (веб-панель)**

- каталог книг с загрузкой обложек и файлов EPUB, PDF, FB2;
- справочники жанров и авторов, промокоды, заказы со сменой статуса, модерация отзывов;
- отчёты о продажах с выгрузкой в Excel и CSV.

Подробное описание со скриншотами всех экранов — в [руководстве пользователя](USER_GUIDE.md).

## Скриншоты

| Мобильное приложение | | | |
|---|---|---|---|
| <img src="docs/screenshots/mob_04_login.png" width="170"> | <img src="docs/screenshots/mob_16_cart_promo.png" width="170"> | <img src="docs/screenshots/mob_19_library.png" width="170"> | <img src="docs/screenshots/mob_26_settings.png" width="170"> |
| Вход | Корзина с промокодом | Библиотека | Настройки |

| Веб-панель администратора | |
|---|---|
| <img src="docs/screenshots/admin_02_orders.png" width="430"> | <img src="docs/screenshots/admin_11_reports.png" width="430"> |
| Заказы | Отчёт о продажах |

## Технологии

| Часть | Стек |
|---|---|
| Серверная часть | Python 3.13, Django 6.1, Django REST Framework 3.18, JWT (simplejwt), PostgreSQL 17, Gunicorn |
| Мобильное приложение | Flutter (Dart 3.12), Riverpod, Dio, flutter_secure_storage, собственный разбор EPUB |
| Веб-панель | React 19, TypeScript, Vite, React Router, Axios |
| Развёртывание | Docker Compose, Nginx |

Несколько решений, на которые стоит обратить внимание:

- аутентификация по JWT: access-токен живёт 15 минут, refresh-токен 7 дней, смена пароля завершает остальные сессии;
- файлы книг не отдаются по прямым ссылкам: сервер проверяет, что книга есть в библиотеке пользователя;
- оформление заказа выполняется одной транзакцией, при ошибке изменения откатываются;
- прогресс чтения синхронизируется между устройствами, при конфликте побеждает более поздняя запись.

## Структура проекта

```
BookWave/
├── backend/            # Django + DRF
│   ├── config/         # настройки (base, dev, prod), urls, wsgi
│   └── apps/           # users, catalog, files, favorites, cart, orders, promo,
│                       # library, bookmarks, reviews, reports, notifications, banners
├── admin-panel/        # React + TypeScript + Vite
│   └── src/features/   # auth, catalog, orders, promo, reviews, reports
├── mobile/             # Flutter
│   └── lib/
│       ├── core/       # сеть, хранилище, тема, провайдеры
│       └── features/   # auth, home, catalog, book_details, favorites, cart, promo,
│                       # orders, library, reader, reviews, profile, settings, onboarding
├── docs/screenshots/   # скриншоты для документации
├── docker-compose.yml
├── README.md
└── USER_GUIDE.md
```

Бэкенд разделён на приложения по предметным областям, мобильное приложение и веб-панель устроены по фичам: каждая содержит свой слой данных, логику и экраны.

## Быстрый старт

Нужен Docker Desktop (Windows) или Docker Engine с Compose (Linux).

1. Подготовьте настройки сервера:

   ```
   copy backend\.env.example backend\.env
   ```

   В `backend/.env` задайте как минимум `SECRET_KEY` (длинная случайная строка) и пароль базы `POSTGRES_PASSWORD`. Файл `.env` в репозиторий не попадает.
2. Запустите всё одной командой:

   ```
   docker compose up -d --build
   ```

   Поднимутся PostgreSQL, backend (миграции применяются при старте) и Nginx с веб-панелью.
3. Создайте администратора:

   ```
   docker compose exec backend python manage.py createsuperuser
   ```

4. Откройте `http://localhost:8080/` и войдите под созданным e-mail. API доступно по адресу `http://localhost:8000/api/`.

В демонстрационном контуре письма (сброс пароля, электронный чек) не отправляются по почте, а выводятся в журнал: `docker compose logs backend`.

## Запуск для разработки

### Серверная часть

```
cd backend
python -m venv venv
venv\Scripts\activate          # Windows
pip install -r requirements.txt
copy .env.example .env         # отредактируйте значения

docker compose up -d postgres  # только база данных
python manage.py migrate
python manage.py runserver
```

Проверка: `http://localhost:8000/admin/` открывается.

### Веб-панель

```
cd admin-panel
npm install
copy .env.example .env
npm run dev
```

### Мобильное приложение

```
cd mobile
flutter pub get
copy .env.example .env
flutter run
```

Адрес сервера выбирается автоматически (`lib/core/api/api_client.dart`): для desktop-сборки это `localhost`, для Android — IP компьютера в локальной сети. Если он не подходит, например IP сменился, задайте `API_BASE_URL=http://<адрес>:8000/api` в `mobile/.env`.

Сборка APK для установки на устройство:

```
flutter build apk --release
```

Файл появится в `mobile/build/app/outputs/flutter-apk/app-release.apk` (Android 7.0 и новее).

## Тесты

Автотесты бэкенда:

```
cd backend
python manage.py test
```

Они проверяют расчёт и валидацию промокодов, атомарность оформления заказа, доступ к файлам книг и синхронизацию прогресса чтения.

## Настройки окружения

Основные переменные `backend/.env` (шаблон — `backend/.env.example`):

| Переменная | Назначение |
|---|---|
| `DJANGO_ENV` | режим работы: `dev` или `prod` |
| `SECRET_KEY` | секретный ключ Django |
| `DEBUG` | режим отладки |
| `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_HOST`, `POSTGRES_PORT` | подключение к базе данных |
| `ALLOWED_HOSTS` | допустимые адреса сервера через запятую |
| `CORS_ALLOWED_ORIGINS` | адреса, с которых разрешены запросы из браузера |

## Документация

- [Руководство пользователя](USER_GUIDE.md) — установка, работа с приложением и веб-панелью, частые неполадки, со скриншотами.
