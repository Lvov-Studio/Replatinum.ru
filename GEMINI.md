# 📱 PlatinumStore — Flutter App (Replatinum.ru)

> Этот файл читается автоматически при открытии проекта. Содержит всю ключевую информацию по проекту.

---

## 🌐 Проект

| Параметр | Значение |
|---|---|
| **Название** | PlatinumStore |
| **Тип** | Flutter мобильное приложение (iOS + Android) |
| **Сайт** | https://replatinum.ru |
| **Организация** | Lvov-Studio |
| **Статус** | В активной разработке |

---

## 📦 Git & GitHub

| Параметр | Значение |
|---|---|
| **Репозиторий** | https://github.com/Lvov-Studio/Replatinum.ru |
| **Организация** | Lvov-Studio |
| **Ветка по умолчанию** | `main` |
| **Remote** | `origin` → `https://github.com/Lvov-Studio/Replatinum.ru.git` |
| **Git путь** | `C:\Program Files\Git\bin\git.exe` |
| **Локальный путь** | `D:\Gemini\platinumstore_app` |

### Как пушить изменения:
```powershell
# Всегда использовать полный путь к git (он не прописан в PATH по умолчанию)
& "C:\Program Files\Git\bin\git.exe" add .
& "C:\Program Files\Git\bin\git.exe" commit -m "описание изменений"
& "C:\Program Files\Git\bin\git.exe" push
```

> ⚠️ `git` недоступен напрямую в PowerShell через PATH — всегда использовать полный путь `& "C:\Program Files\Git\bin\git.exe"`

---

## 🌐 API & Бэкенд

| Параметр | Значение |
|---|---|
| **Base URL** | `https://replatinum.ru/local/api/mobile/v1/` |
| **Тип API** | REST, PHP-скрипты |
| **HTTP клиент** | Dio ^5.9.2 |
| **Формат ответа** | `{ "status": "success", "data": [...] }` |

### Эндпоинты:
| Метод | URL | Описание |
|---|---|---|
| GET | `get_categories.php` | Список категорий |
| GET | `get_products.php` | Список товаров |
| GET | `get_product_detail.php?id=` | Детали товара |
| GET | `search.php?q=` | Поиск товаров |
| GET | `get_slider.php` | Баннеры для слайдера |
| POST | `create_order.php` | Создание заказа |

---

## 🏗️ Архитектура

```
lib/
├── core/
│   └── theme/
│       ├── app_colors.dart     # Палитра цветов
│       └── app_theme.dart      # MaterialTheme конфиг
├── data/
│   ├── api/
│   │   └── api_service.dart    # Dio HTTP клиент
│   └── models/
│       ├── banner_model.dart
│       ├── category_model.dart
│       ├── product_model.dart
│       └── product_detail_model.dart
├── providers/                  # Бизнес-логика (Provider pattern)
│   ├── cart_provider.dart      # Корзина
│   ├── category_provider.dart  # Категории
│   └── product_provider.dart   # Товары
└── ui/
    ├── screens/
    │   ├── main_screen.dart             # Bottom nav + IndexedStack
    │   ├── home_screen.dart             # Главная (баннеры + категории)
    │   ├── catalog_screen.dart          # Каталог (GridView)
    │   ├── product_detail_screen.dart   # Карточка товара
    │   ├── cart_screen.dart             # Корзина
    │   ├── checkout_bottom_sheet.dart   # Оформление заказа
    │   ├── success_screen.dart          # Экран успешного заказа
    │   ├── product_search_delegate.dart # Поиск (SearchDelegate)
    │   └── placeholder_screens.dart    # Заглушки (Профиль)
    └── widgets/
        ├── banner_slider.dart   # Карусель баннеров (carousel_slider)
        └── custom_app_bar.dart  # AppBar с логотипом
```

---

## 🎨 Дизайн-система

### Цветовая палитра:
| Название | HEX | Использование |
|---|---|---|
| `darkAccent` | `#2E2E35` | AppBar, верхняя панель |
| `primaryAccent` | `#85C635` | Кнопки, активные элементы, цена |
| `background` | `#F8F9FA` | Фон приложения |
| `mainText` | `#333333` | Основной текст |
| `secondaryText` | `#6C757D` | Второстепенный текст |
| `border` | `#E9ECEF` | Рамки карточек |

### Шрифты: Google Fonts (через пакет `google_fonts`)

---

## 📦 Зависимости

```yaml
dependencies:
  flutter_sdk: flutter
  cupertino_icons: ^1.0.8
  dio: ^5.9.2                    # HTTP запросы
  provider: ^6.1.5               # State management
  google_fonts: ^8.1.0           # Шрифты
  cached_network_image: ^3.4.1   # Кэширование картинок
  flutter_html: ^3.0.0           # Рендер HTML в описании товара
  url_launcher: ^6.3.2           # Открытие ссылок
  carousel_slider: ^5.0.0        # Баннерный слайдер
```

---

## ✅ Что готово / ⚠️ Что нет

### ✅ Готово:
- Главная страница (баннеры + категории горизонтально)
- Каталог товаров (GridView 2 колонки)
- Карточка товара (детали, HTML описание, фото)
- Корзина (добавление, удаление, количество, сумма)
- Оформление заказа (форма: имя, телефон, email)
- Поиск по каталогу (SearchDelegate)
- Нижняя навигация с бейджем на корзине
- Дизайн-система (цвета, тема)

### ⚠️ Не реализовано / Нужно доделать:
- **Профиль** — `placeholder_screens.dart` (просто заглушка)
- **Фильтрация по категориям** — `onTap` пустой в `home_screen.dart` (комментарий: `// Переход к товарам категории`)
- **Авторизация** — закомментирована в `api_service.dart` (Bearer token)
- **Пагинация** — все товары грузятся одним запросом
- **Избранное** — не реализовано

---

## 🚀 Запуск проекта

```powershell
# Установить зависимости
flutter pub get

# Запустить на эмуляторе / устройстве
flutter run

# Сборка APK (Android)
flutter build apk --release
```

---

## 📝 История изменений

| Дата | Описание |
|---|---|
| 2026-09-06 | Первый коммит. Инициализация Git, пуш на GitHub `Lvov-Studio/Replatinum.ru` |
