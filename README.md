# Flags World - Кроссплатформенная викторина с флагами

Интерактивная викторина для изучения флагов стран мира с поддержкой веб, iOS и Android платформ.

## 🏗️ Архитектура проекта

```
├── backend/          # Node.js + Express API сервер
├── mobile/           # React Native приложение (iOS/Android)
├── web/             # PWA веб-версия (планируется)
└── shared/          # Общие типы и утилиты (планируется)
```

## 🚀 Этап 1: Настройка бэкенда и базовой структуры

### Backend (Node.js + Express + PostgreSQL)

#### Требования
- Node.js 16+
- PostgreSQL 13+
- Redis (опционально)

#### Установка и запуск

1. **Установка зависимостей:**
```bash
cd backend
npm install
```

2. **Настройка базы данных:**
```bash
# Создайте базу данных PostgreSQL
createdb flags_world

# Скопируйте конфигурацию
cp env.example .env

# Отредактируйте .env файл с вашими настройками базы данных
```

3. **Запуск миграций:**
```bash
npm run migrate
```

4. **Заполнение данными (планируется):**
```bash
npm run seed
```

5. **Запуск сервера:**
```bash
# Development
npm run dev

# Production
npm start
```

Сервер будет доступен по адресу: http://localhost:3000

#### API Endpoints

**Аутентификация:**
- `POST /api/auth/register` - Регистрация
- `POST /api/auth/login` - Авторизация  
- `GET /api/auth/profile` - Профиль пользователя

**Страны и флаги:**
- `GET /api/countries` - Список стран
- `GET /api/countries/for-game` - Страны для игры
- `GET /api/countries/search/:query` - Поиск стран

**Игры:**
- `POST /api/games/start` - Начать игру
- `POST /api/games/finish` - Завершить игру
- `GET /api/games/history` - История игр

**Статистика:**
- `GET /api/statistics` - Общая статистика
- `GET /api/statistics/mistakes` - Ошибки пользователя
- `GET /api/statistics/leaderboard` - Рейтинг

### Mobile (React Native)

#### Требования
- Node.js 16+
- React Native CLI
- Xcode (для iOS)
- Android Studio (для Android)

#### Установка

```bash
cd mobile

# Установка зависимостей
npm install

# iOS
cd ios && pod install && cd ..

# Android
# Убедитесь что Android SDK настроен
```

#### Запуск

```bash
# Metro bundler
npm start

# iOS
npm run ios

# Android  
npm run android
```

## 🗄️ База данных

### Схема таблиц:

- **users** - Пользователи
- **countries** - Страны и флаги (мультиязычные названия)
- **games** - Записи игр
- **game_answers** - Ответы в играх
- **user_mistakes** - Ошибки пользователей
- **user_statistics** - Статистика пользователей

### Поддержка анонимных пользователей

Система поддерживает как авторизованных пользователей (через JWT), так и анонимных (через session_id).

## 🌍 Мультиязычность

Поддерживаемые языки:
- 🇷🇺 Русский (ru)
- 🇺🇸 Английский (en) 
- 🇪🇸 Испанский (es)
- 🇺🇦 Украинский (uk)
- Каталанский (ca)
- 🇨🇳 Китайский (zh)

## 🎮 Функциональность

### Текущий функционал (Этап 1):
- ✅ RESTful API для всех игровых функций
- ✅ Система аутентификации (JWT + session)
- ✅ База данных с полной схемой
- ✅ Поддержка авторизованных и анонимных пользователей
- ✅ Система ошибок и статистики
- ✅ Базовая React Native структура

### Планируется в следующих этапах:
- 📱 Полная реализация React Native UI
- 🌐 PWA веб-версия
- 🎯 Дополнительные режимы игры
- 🏆 Система достижений
- 👥 Социальные функции
- 📊 Расширенная аналитика

## 🔧 Конфигурация

### Backend Environment Variables

```env
PORT=3000
NODE_ENV=development

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=flags_world
DB_USER=postgres
DB_PASSWORD=your_password

# JWT
JWT_SECRET=your-secret-key
JWT_EXPIRES_IN=7d

# Redis (опционально)
REDIS_URL=redis://localhost:6379
```

### Mobile Configuration

API endpoint автоматически определяется:
- Development: `http://localhost:3000`
- Production: `https://api.flagsworld.com`

## 📊 Мониторинг

- Health check: `GET /health`
- Логи запросов через Morgan
- Обработка ошибок с детальной информацией

## 🔄 Следующие шаги

1. **Этап 2**: Реализация React Native UI компонентов
2. **Этап 3**: Интеграция с внешними API для загрузки флагов
3. **Этап 4**: PWA веб-версия
4. **Этап 5**: Деплой и производственная настройка

## 🤝 Разработка

Проект использует современный стек технологий:
- **Backend**: Node.js, Express, PostgreSQL, Redis
- **Mobile**: React Native, TypeScript, Zustand
- **API**: RESTful с поддержкой JSON
- **Auth**: JWT токены + анонимные сессии
- **DB**: PostgreSQL с миграциями

Архитектура спроектирована для легкого масштабирования и добавления новых функций. 