# BookWave

Веб- и мобильное приложение для продажи и чтения электронных книг.
Спецификация — [BookWave_TZ.md](BookWave_TZ.md), архитектура —
[ARCHITECTURE.md](ARCHITECTURE.md), план внедрения — [PLAN.md](PLAN.md).

## Структура проекта

Монорепозиторий: backend, admin-панель и мобильное приложение — в одном
корне, каждое в своей папке.

```
BookWave/
├── ARCHITECTURE.md
├── BookWave_TZ.md
├── README.md
│
├── backend/                        # Django + DRF
│   ├── manage.py
│   ├── requirements.txt
│   ├── .env.example
│   ├── config/                     # settings, urls, wsgi/asgi
│   │   ├── settings/
│   │   │   ├── base.py
│   │   │   ├── dev.py
│   │   │   └── prod.py
│   │   ├── urls.py
│   │   ├── wsgi.py
│   │   └── asgi.py
│   ├── apps/                       # domain-oriented apps из ARCHITECTURE.md
│   │   ├── users/                  # auth, роли, JWT lifecycle, профиль
│   │   ├── catalog/                # books, genres, authors, book_authors, book_genres
│   │   ├── files/                  # upload + защищённая выдача (X-Accel-Redirect)
│   │   ├── favorites/
│   │   ├── cart/
│   │   ├── orders/                 # orders, order_items, атомарный checkout
│   │   ├── promo/
│   │   ├── library/                # user_library, progress sync
│   │   ├── bookmarks/
│   │   ├── reviews/
│   │   ├── reports/                # статистика, экспорт xlsx/csv
│   │   ├── notifications/          # email + push, preferences, device_tokens
│   │   └── banners/
│   │       # паттерн на каждый app сейчас (Phase 1):
│   │       #   models.py admin.py views.py urls.py tests.py migrations/
│   │       # serializers.py/permissions.py/services.py добавляются
│   │       #   вместе с первой реальной фичей app'а (Phase 2+)
│   ├── media/                      # локальное файловое хранилище (dev, gitignore)
│   └── static/
│
├── admin-panel/                    # React + TypeScript + Vite SPA
│   ├── package.json
│   ├── vite.config.ts
│   ├── public/
│   └── src/
│       ├── main.tsx
│       ├── App.tsx                 # роутинг (react-router-dom), Phase 1 — placeholder
│       └── api/
│           └── client.ts           # axios-инстанс
│       # routes/, components/, features/{auth,orders,catalog,promo,
│       #   reviews,reports}/ — появятся на Phase 10 вместе с UI разделов
│
└── mobile/                         # Flutter, feature-first, Riverpod
    ├── pubspec.yaml
    ├── android/ ios/ web/ ...      # платформенные проекты (сгенерированы flutter create)
    └── lib/
        ├── main.dart
        ├── app.dart                # MaterialApp, тема, Phase 1 — placeholder-экран
        └── core/                   # сквозные вещи не по фичам
            ├── api/                # Dio-клиент
            ├── theme/              # светлая/тёмная тема
            ├── storage/            # SharedPreferences (тема/язык) + secure storage (JWT)
            └── di/                 # корневые Riverpod-провайдеры
        # lib/features/{onboarding,auth,home,catalog,book_details,favorites,
        #   cart,checkout,library,reader,orders,reviews,profile}/ — появятся
        #   по мере реализации, начиная с auth на Phase 2
```

## Запуск

Скаффолдинг (Phase 1 из [PLAN.md](PLAN.md)) завершён — все три части
поднимаются как пустой каркас. Phase 2 (модели данных и auth) тоже
завершена на backend — JWT-регистрация/вход/сброс пароля уже работают
через API. Экранов в admin-panel/mobile пока нет, они появляются по
фазам `PLAN.md`.

### Backend (Django + DRF)

```
cd backend
python -m venv venv
venv\Scripts\activate          # Windows
pip install -r requirements.txt
copy .env.example .env         # при необходимости отредактировать значения

docker compose up -d           # поднять Postgres (нужен установленный Docker Desktop)
python manage.py migrate
python manage.py runserver
```

Проверить: `http://localhost:8000/admin/` открывается.

### Admin-panel (React + Vite)

```
cd admin-panel
npm install
copy .env.example .env
npm run dev
```

### Mobile (Flutter)

```
cd mobile
flutter pub get
copy .env.example .env
```

`.env` для эмулятора Android — `API_BASE_URL=http://10.0.2.2:8000/api`
(loopback на хост), для desktop/web — `http://localhost:8000/api`. Затем:

```
flutter run
```
