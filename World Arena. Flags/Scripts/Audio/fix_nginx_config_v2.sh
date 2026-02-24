#!/bin/bash

echo "🔧 Настройка nginx для поддержки аудиофайлов (версия 2)..."

# Сначала проверим текущую конфигурацию
echo "📋 Проверяю текущую конфигурацию nginx..."
ssh root@flags.worldarena.games "cat /etc/nginx/sites-available/flags.worldarena.games"

echo ""
echo "🔧 Создаю исправленную конфигурацию..."

# Создаем полную конфигурацию сайта
cat > flags.worldarena.games.conf << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name flags.worldarena.games;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name flags.worldarena.games;

    # SSL конфигурация (оставляем как есть)
    ssl_certificate /etc/letsencrypt/live/flags.worldarena.games/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/flags.worldarena.games/privkey.pem;

    root /var/www/flags.worldarena.games;
    index index.html index.htm;

    # Основные настройки
    location / {
        try_files $uri $uri/ =404;
    }

    # Конфигурация для папки anthems
    location /anthems/ {
        alias /var/www/flags.worldarena.games/anthems/;
        
        # MIME типы для аудио
        location ~* \.m4a$ {
            add_header Content-Type "audio/mp4";
            add_header Access-Control-Allow-Origin "*";
            add_header Access-Control-Allow-Methods "GET, OPTIONS";
            add_header Access-Control-Allow-Headers "Range";
            
            # Поддержка Range запросов для стриминга
            if ($request_method = 'OPTIONS') {
                add_header Access-Control-Allow-Origin "*";
                add_header Access-Control-Allow-Methods "GET, OPTIONS";
                add_header Access-Control-Allow-Headers "Range";
                add_header Access-Control-Max-Age 1728000;
                add_header Content-Type "text/plain; charset=utf-8";
                add_header Content-Length 0;
                return 204;
            }
            
            # Кэширование
            expires 1M;
            add_header Cache-Control "public, immutable";
            
            # Gzip сжатие
            gzip on;
            gzip_types audio/mp4;
        }
        
        # Запрещаем доступ к .htaccess
        location ~ /\.ht {
            deny all;
        }
    }

    # Запрещаем доступ к скрытым файлам
    location ~ /\. {
        deny all;
    }
}
EOF

echo "📤 Загружаю конфигурацию на сервер..."
scp flags.worldarena.games.conf root@flags.worldarena.games:/tmp/

echo "🔧 Применяю конфигурацию..."
ssh root@flags.worldarena.games << 'EOF'
# Создаем резервную копию
cp /etc/nginx/sites-available/flags.worldarena.games /etc/nginx/sites-available/flags.worldarena.games.backup

# Заменяем конфигурацию
cp /tmp/flags.worldarena.games.conf /etc/nginx/sites-available/flags.worldarena.games

# Проверяем конфигурацию
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Конфигурация nginx корректна"
    # Перезагружаем nginx
    systemctl reload nginx
    echo "✅ nginx перезагружен"
else
    echo "❌ Ошибка в конфигурации nginx, восстанавливаю резервную копию"
    cp /etc/nginx/sites-available/flags.worldarena.games.backup /etc/nginx/sites-available/flags.worldarena.games
    nginx -t
    systemctl reload nginx
    exit 1
fi
EOF

echo "🧹 Удаляю временные файлы..."
rm flags.worldarena.games.conf

echo "✅ Настройка nginx завершена"
echo "🌐 Теперь гимны должны быть доступны по адресу:"
echo "   https://flags.worldarena.games/anthems/anthem_fr.m4a"

