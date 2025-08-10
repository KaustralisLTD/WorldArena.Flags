# 🚀 Flags World Web - Готов к развертыванию!

## ✅ Статус проекта
- ✅ Docker образ успешно собран
- ✅ Контейнер запущен и работает
- ✅ Приложение доступно по адресу: http://localhost:3000/flags/
- ✅ Настроена конфигурация для базового пути `/flags`
- ✅ Статические файлы оптимизированы для продакшена

## 🐳 Быстрый запуск

### Локальное тестирование
```bash
# Запуск контейнера
docker run -d -p 3000:80 --name flags-world-web flags-world-web

# Проверка работы
open http://localhost:3000/flags/
```

### Развертывание на сервере
```bash
# 1. Скопировать Docker образ на сервер
docker save flags-world-web | gzip > flags-world-web.tar.gz
scp flags-world-web.tar.gz user@server:/path/to/deploy/

# 2. На сервере загрузить образ
docker load < flags-world-web.tar.gz

# 3. Запустить контейнер
docker run -d -p 80:80 --name flags-world-web --restart unless-stopped flags-world-web
```

## 🌐 Настройка для worldarena.games/flags

### Вариант 1: Прямое развертывание
```bash
# Запуск на порту 80 с проксированием через веб-сервер
docker run -d -p 8080:80 --name flags-world-web --restart unless-stopped flags-world-web
```

### Вариант 2: Docker Compose
```yaml
version: '3.8'
services:
  flags-world-web:
    image: flags-world-web:latest
    ports:
      - "8080:80"
    restart: unless-stopped
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.flags.rule=PathPrefix(\`/flags\`)"
      - "traefik.http.services.flags.loadbalancer.server.port=80"
```

### Настройка веб-сервера (Apache/Nginx)

#### Apache
```apache
ProxyPass /flags/ http://localhost:8080/flags/
ProxyPassReverse /flags/ http://localhost:8080/flags/
```

#### Nginx
```nginx
location /flags/ {
    proxy_pass http://localhost:8080/flags/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

## 📊 Характеристики образа
- **Размер образа**: ~50MB (оптимизированный)
- **Технологии**: Next.js 14, React 18, TypeScript
- **Веб-сервер**: Nginx Alpine
- **Порт**: 80 (внутри контейнера)
- **Базовый путь**: `/flags`

## 🔧 Управление контейнером

```bash
# Просмотр логов
docker logs flags-world-web

# Остановка
docker stop flags-world-web

# Запуск
docker start flags-world-web

# Удаление
docker rm flags-world-web

# Обновление образа
docker pull flags-world-web:latest
docker stop flags-world-web
docker rm flags-world-web
docker run -d -p 3000:80 --name flags-world-web --restart unless-stopped flags-world-web:latest
```

## 🎯 Готовые URL для тестирования
- **Локально**: http://localhost:3000/flags/
- **Продакшен**: https://worldarena.games/flags/

## 📝 Что включено в сборку
- ✅ Полнофункциональная игра "Угадай флаг"
- ✅ Поддержка 6 языков (RU, EN, ES, UK, CA, ZH)
- ✅ Статистика и достижения
- ✅ Адаптивный дизайн
- ✅ Оптимизация производительности
- ✅ SEO-оптимизация
- ✅ Кеширование статических ресурсов

## 🚀 Следующие шаги
1. Протестировать приложение локально: http://localhost:3000/flags/
2. Скопировать Docker образ на продакшен сервер
3. Настроить проксирование через основной веб-сервер
4. Обновить DNS записи (если необходимо)
5. Протестировать на продакшене: https://worldarena.games/flags/

---

**Проект готов к развертыванию! 🎉** 