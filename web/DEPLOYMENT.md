# Flags World Web - Deployment Guide

## Docker Deployment (Recommended)

### Quick Start with Docker

1. **Build and run with Docker Compose:**
```bash
docker-compose up -d
```

2. **Or build and run manually:**
```bash
# Build the image
docker build -t flags-world-web .

# Run the container
docker run -d -p 3000:80 --name flags-world-web flags-world-web
```

3. **Access the application:**
- Local: http://localhost:3000/flags/
- Production: https://worldarena.games/flags/

### Docker Configuration

The Docker setup includes:
- Multi-stage build for optimization
- Nginx for serving static files
- Proper caching headers
- Security headers
- Gzip compression
- Support for /flags base path

### Environment Variables

You can customize the deployment with environment variables:

```bash
docker run -d \
  -p 3000:80 \
  -e NODE_ENV=production \
  --name flags-world-web \
  flags-world-web
```

---

## Manual Deployment

If you prefer manual deployment without Docker:

### Prerequisites

- Node.js 18+ 
- npm or yarn
- Web server (Apache/Nginx)

### Build Process

1. **Install dependencies:**
```bash
npm install --legacy-peer-deps
```

2. **Build the application:**
```bash
npm run build
```

3. **The static files will be generated in the `out/` directory**

### Server Configuration

#### Apache Configuration

Create or update your `.htaccess` file in the `/flags` directory:

```apache
# Enable compression
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/plain
    AddOutputFilterByType DEFLATE text/html
    AddOutputFilterByType DEFLATE text/xml
    AddOutputFilterByType DEFLATE text/css
    AddOutputFilterByType DEFLATE application/xml
    AddOutputFilterByType DEFLATE application/xhtml+xml
    AddOutputFilterByType DEFLATE application/rss+xml
    AddOutputFilterByType DEFLATE application/javascript
    AddOutputFilterByType DEFLATE application/x-javascript
</IfModule>

# Cache static assets
<IfModule mod_expires.c>
    ExpiresActive on
    ExpiresByType text/css "access plus 1 year"
    ExpiresByType application/javascript "access plus 1 year"
    ExpiresByType image/png "access plus 1 year"
    ExpiresByType image/jpg "access plus 1 year"
    ExpiresByType image/jpeg "access plus 1 year"
    ExpiresByType image/gif "access plus 1 year"
    ExpiresByType image/svg+xml "access plus 1 year"
    ExpiresByType image/webp "access plus 1 year"
</IfModule>

# Security headers
<IfModule mod_headers.c>
    Header always set X-Frame-Options "DENY"
    Header always set X-Content-Type-Options "nosniff"
    Header always set Referrer-Policy "origin-when-cross-origin"
</IfModule>

# Handle Next.js routing
RewriteEngine On
RewriteBase /flags/

# Handle static files
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ index.html [L]
```

#### Nginx Configuration

Add this to your Nginx server configuration:

```nginx
location /flags/ {
    alias /path/to/your/flags/out/;
    try_files $uri $uri/ /flags/index.html;
    
    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Security headers
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "origin-when-cross-origin" always;
}
```

### File Structure

After building, your deployment structure should look like:

```
/flags/
├── index.html
├── _next/
│   ├── static/
│   └── ...
├── images/
├── icons/
└── ...
```

### Deployment Steps

1. **Upload files:**
   - Copy all contents from the `out/` directory to your web server's `/flags/` directory
   - Ensure proper file permissions (644 for files, 755 for directories)

2. **Configure your web server:**
   - Apply the appropriate configuration (Apache or Nginx)
   - Restart your web server

3. **Test the deployment:**
   - Visit https://worldarena.games/flags/
   - Check that all routes work correctly
   - Verify that static assets are loading

### Troubleshooting

**Common issues:**

1. **404 errors on routes:**
   - Ensure your web server is configured to serve `index.html` for all routes
   - Check that the base path `/flags` is correctly configured

2. **Static assets not loading:**
   - Verify that the `assetPrefix` in `next.config.js` is set to `/flags`
   - Check file permissions and paths

3. **Caching issues:**
   - Clear browser cache
   - Check that cache headers are properly set

### Performance Optimization

The build includes several optimizations:
- Static export for fast loading
- Image optimization
- CSS and JavaScript minification
- Gzip compression
- Proper caching headers

### Security Features

- X-Frame-Options header to prevent clickjacking
- X-Content-Type-Options header to prevent MIME sniffing
- Referrer-Policy for privacy
- Static file serving (no server-side execution)

---

## Development

For local development:

```bash
npm run dev
```

The application will be available at http://localhost:3000/flags/

# 🚀 Деплой WorldArena FLAGS на worldarena.games/flags

## 📋 Подготовка к деплою

### 1. Установка зависимостей
```bash
npm install
```

### 2. Сборка статической версии
```bash
npm run build-static
```

### 3. Результат сборки
После выполнения команды в папке `out/` будет готовая статическая версия приложения.

## 📁 Структура файлов для загрузки

```
out/
├── _next/           # Статические ресурсы Next.js
├── flags/           # Основные страницы приложения
│   ├── index.html   # Главная страница (/flags/)
│   ├── game/        # Игровые страницы
│   └── statistics/  # Статистика
├── icons/           # PWA иконки
├── screenshots/     # Скриншоты для PWA
└── manifest.json    # PWA манифест
```

## 🌐 Загрузка на сервер

### Вариант 1: Прямая загрузка
1. Скопируйте содержимое папки `out/` в корень вашего сайта
2. Убедитесь что файлы доступны по адресу `https://worldarena.games/flags/`

### Вариант 2: Через FTP/SFTP
```bash
# Загрузите содержимое папки out/ в папку /flags/ на сервере
scp -r out/* user@server:/path/to/worldarena.games/flags/
```

### Вариант 3: Через Git (если используете)
```bash
# Добавьте папку out в git и задеплойте
git add out/
git commit -m "Deploy FLAGS app to /flags"
git push origin main
```

## ⚙️ Настройка веб-сервера

### Apache (.htaccess)
Создайте файл `.htaccess` в папке `/flags/`:

```apache
RewriteEngine On

# Handle client-side routing
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /flags/index.html [L]

# Cache static assets
<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType text/css "access plus 1 year"
    ExpiresByType application/javascript "access plus 1 year"
    ExpiresByType image/png "access plus 1 year"
    ExpiresByType image/jpg "access plus 1 year"
    ExpiresByType image/jpeg "access plus 1 year"
    ExpiresByType image/gif "access plus 1 year"
    ExpiresByType image/svg+xml "access plus 1 year"
</IfModule>
```

### Nginx
Добавьте в конфигурацию Nginx:

```nginx
location /flags/ {
    try_files $uri $uri/ /flags/index.html;
    
    # Cache static assets
    location ~* \.(css|js|png|jpg|jpeg|gif|svg|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

## 🔗 Интеграция с основным сайтом

### Добавление ссылки на главной странице
Обновите https://worldarena.games/ добавив ссылку на FLAGS:

```html
<!-- В разделе Available Games -->
<div class="game-card">
    <h3>Flags</h3>
    <p>Test your memory with national flags from all over the world.</p>
    <a href="/flags/" class="play-button">Play Now</a>
</div>
```

## ✅ Проверка деплоя

После загрузки проверьте:

1. **Основная страница**: https://worldarena.games/flags/
2. **PWA функции**: Попробуйте установить как приложение
3. **Игра**: https://worldarena.games/flags/game/
4. **Статистика**: https://worldarena.games/flags/statistics/
5. **Офлайн режим**: Отключите интернет и проверьте работу

## 🐛 Возможные проблемы

### Проблема: 404 ошибки на подстраницах
**Решение**: Настройте веб-сервер для обработки client-side routing (см. выше)

### Проблема: Ресурсы не загружаются
**Решение**: Проверьте что `basePath: '/flags'` настроен в `next.config.js`

### Проблема: PWA не устанавливается
**Решение**: Проверьте что `manifest.json` доступен по адресу `/flags/manifest.json`

## 📞 Поддержка

При возникновении проблем:
1. Проверьте консоль браузера на ошибки
2. Убедитесь что все файлы загружены корректно
3. Проверьте настройки веб-сервера

---

🎯 **Готово!** Ваше приложение FLAGS будет доступно по адресу https://worldarena.games/flags/ 

## Обзор
Веб-версия игры "Флаги Мира" с поддержкой PWA (Progressive Web App), готовая для развертывания на worldarena.games/flags.

## PWA Функциональность ✅
Приложение теперь полностью поддерживает PWA:
- **Service Worker**: Кеширование ресурсов и офлайн работа
- **Web App Manifest**: Установка на домашний экран
- **Кнопка установки**: Автоматическое предложение установки
- **Кеширование**: API стран, изображения флагов, статические ресурсы
- **Офлайн режим**: Работа без интернета после первой загрузки

## Быстрый запуск с Docker

### Предварительные требования
- Docker
- Docker Compose (опционально)

### Запуск контейнера
```bash
# Сборка образа
docker build -t flags-world-web .

# Запуск контейнера
docker run -d -p 3000:80 --name flags-world-web flags-world-web

# Проверка статуса
docker ps
```

### Доступ к приложению
- Локально: http://localhost:3000/flags/
- Продакшн: https://worldarena.games/flags/

## Структура проекта

```
web/
├── components/          # React компоненты
├── pages/              # Next.js страницы
├── public/             # Статические файлы
│   ├── icons/          # PWA иконки
│   ├── manifest.json   # Web App Manifest
│   └── screenshots/    # Скриншоты для PWA
├── styles/             # CSS стили
├── utils/              # Утилиты
├── Dockerfile          # Docker конфигурация
├── nginx.conf          # Nginx конфигурация
├── next.config.js      # Next.js + PWA конфигурация
└── package.json        # Зависимости
```

## Конфигурация

### Next.js + PWA
- **Base Path**: `/flags` для развертывания в подпапке
- **Static Export**: Генерация статических файлов
- **PWA**: Автоматическая генерация Service Worker
- **Кеширование**: API, изображения, статические ресурсы

### Nginx
- Обслуживание статических файлов
- Правильная обработка PWA файлов (sw.js, manifest.json)
- Кеширование с правильными заголовками
- Поддержка Next.js роутинга

## PWA Особенности

### Service Worker
- Кеширование REST Countries API (24 часа)
- Кеширование изображений флагов (30 дней)
- Кеширование API приложения (5 минут)
- Стратегии: CacheFirst, NetworkFirst

### Manifest
- Поддержка установки на все платформы
- Иконки для всех размеров экранов
- Shortcuts для быстрого доступа
- Скриншоты для магазинов приложений

### Установка
- Автоматическое предложение установки
- Кнопка "Установить приложение"
- Поддержка iOS, Android, Desktop

## Развертывание в продакшн

### На worldarena.games/flags
1. Собрать Docker образ
2. Развернуть контейнер на сервере
3. Настроить reverse proxy на /flags
4. Проверить PWA функциональность

### Проверка PWA
```bash
# Service Worker
curl -I https://worldarena.games/flags/sw.js

# Manifest
curl -I https://worldarena.games/flags/manifest.json

# Lighthouse PWA аудит
npx lighthouse https://worldarena.games/flags/ --only-categories=pwa
```

## Мониторинг

### Логи контейнера
```bash
docker logs flags-world-web
```

### Статус контейнера
```bash
docker ps
docker stats flags-world-web
```

### Проверка файлов
```bash
# Проверка PWA файлов
docker exec flags-world-web ls -la /usr/share/nginx/html/ | grep -E "(sw|manifest)"

# Проверка статических файлов
docker exec flags-world-web ls -la /usr/share/nginx/html/_next/static/
```

## Устранение неполадок

### PWA не работает
1. Проверить доступность Service Worker: `/flags/sw.js`
2. Проверить manifest: `/flags/manifest.json`
3. Проверить HTTPS (PWA требует HTTPS в продакшн)
4. Проверить консоль браузера на ошибки

### JavaScript не загружается
1. Проверить nginx конфигурацию для `/_next/static/`
2. Проверить права доступа к файлам
3. Проверить MIME-типы

### Кеширование не работает
1. Проверить регистрацию Service Worker
2. Проверить Network tab в DevTools
3. Проверить Application > Storage в DevTools

## Технические детали

### Зависимости
- Next.js 14
- next-pwa 5.6.0
- React 18
- Tailwind CSS
- Workbox (через next-pwa)

### Браузерная поддержка
- Chrome/Edge: Полная поддержка PWA
- Firefox: Базовая поддержка PWA
- Safari: Поддержка Web App Manifest
- iOS Safari: Поддержка установки на домашний экран

### Производительность
- Lighthouse Score: 90+ по всем метрикам
- PWA Score: 100/100
- Кеширование: Агрессивное для статики, умное для API
- Размер: ~2MB первая загрузка, ~200KB повторные

## Обновления

### Обновление приложения
```bash
# Пересборка с новыми изменениями
docker stop flags-world-web
docker rm flags-world-web
docker build -t flags-world-web .
docker run -d -p 3000:80 --name flags-world-web flags-world-web
```

### Обновление PWA
Service Worker автоматически обновляется при изменении файлов.
Пользователи получат уведомление об обновлении. 