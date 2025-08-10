# 🌍 Флаги Мира - Веб-версия

Progressive Web App для изучения флагов стран мира с помощью интерактивной викторины.

## 🚀 Особенности

### PWA функциональность
- ✅ Установка как нативное приложение
- ✅ Офлайн режим с Service Worker
- ✅ Push уведомления
- ✅ Адаптивный дизайн для всех устройств

### Игровые режимы
- 🎯 **Классический** - стандартная викторина
- ⚡ **На время** - ограниченное время на ответ
- 🔥 **Выживание** - игра до первой ошибки
- 📚 **Работа над ошибками** - повторение проблемных стран

### Функции
- 🌍 6 регионов мира (Европа, Азия, Африка, Америка, Океания)
- 📊 Детальная статистика и прогресс
- 🏆 Система достижений и рейтингов
- 🌐 Мультиязычность (6 языков)
- 🎨 Темная/светлая тема
- 📱 Responsive дизайн

## 🛠 Технологии

- **Frontend**: Next.js 14, React 18, TypeScript
- **Стили**: Tailwind CSS, Framer Motion
- **Состояние**: Zustand с persist
- **API**: Axios, React Query
- **PWA**: next-pwa, Workbox
- **Данные**: REST Countries API

## 📦 Установка

```bash
# Клонирование репозитория
git clone https://github.com/your-repo/flags-world.git
cd flags-world/web

# Установка зависимостей
npm install

# Копирование переменных окружения
cp .env.example .env.local

# Запуск в режиме разработки
npm run dev
```

## 🔧 Скрипты

```bash
# Разработка
npm run dev          # Запуск dev сервера
npm run type-check   # Проверка типов TypeScript

# Продакшн
npm run build        # Сборка для продакшна
npm run start        # Запуск продакшн сервера
npm run export       # Статический экспорт

# Анализ
npm run analyze      # Анализ размера бандла
npm run lint         # Проверка ESLint
```

## 🌐 Деплой

### Vercel (рекомендуется)
```bash
# Установка Vercel CLI
npm i -g vercel

# Деплой
vercel --prod
```

### Netlify
```bash
# Сборка
npm run build
npm run export

# Загрузка папки out/ в Netlify
```

### Docker
```bash
# Сборка образа
docker build -t flags-world-web .

# Запуск контейнера
docker run -p 3000:3000 flags-world-web
```

## 📱 PWA Установка

### Desktop
1. Откройте сайт в Chrome/Edge
2. Нажмите на иконку установки в адресной строке
3. Следуйте инструкциям

### Mobile
1. Откройте сайт в браузере
2. Нажмите "Поделиться" → "Добавить на главный экран"
3. Подтвердите установку

## 🔧 Конфигурация

### Environment Variables
```env
NEXT_PUBLIC_API_URL=http://localhost:3001/api
NEXT_PUBLIC_REST_COUNTRIES_URL=https://restcountries.com/v3.1
NEXT_PUBLIC_APP_NAME=Флаги Мира
NEXT_PUBLIC_PWA_ENABLED=true
```

### PWA Настройки
- **Manifest**: `public/manifest.json`
- **Service Worker**: автоматически генерируется next-pwa
- **Icons**: `public/icons/` (все размеры)
- **Кэширование**: настроено в `next.config.js`

## 📊 Производительность

### Lighthouse Score
- 🟢 Performance: 95+
- 🟢 Accessibility: 100
- 🟢 Best Practices: 100
- 🟢 SEO: 100
- 🟢 PWA: 100

### Оптимизации
- Code splitting и lazy loading
- Image optimization (WebP, AVIF)
- Service Worker кэширование
- Bundle analyzer
- Tree shaking

## 🌍 Интернационализация

Поддерживаемые языки:
- 🇷🇺 Русский (по умолчанию)
- 🇺🇸 English
- 🇪🇸 Español
- 🇫🇷 Français
- 🇩🇪 Deutsch
- 🇨🇳 中文

## 🤝 Вклад в проект

1. Fork репозитория
2. Создайте feature branch (`git checkout -b feature/amazing-feature`)
3. Commit изменения (`git commit -m 'Add amazing feature'`)
4. Push в branch (`git push origin feature/amazing-feature`)
5. Откройте Pull Request

## 📄 Лицензия

MIT License - см. [LICENSE](LICENSE) файл.

## 🆘 Поддержка

- 📧 Email: support@flagsworld.com
- 🐛 Issues: [GitHub Issues](https://github.com/your-repo/flags-world/issues)
- 💬 Telegram: [@flagsworld_support](https://t.me/flagsworld_support)

---

Сделано с ❤️ для изучения географии 