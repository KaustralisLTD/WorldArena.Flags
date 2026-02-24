#!/bin/bash

echo "🔧 Настройка nginx для поддержки аудиофайлов..."

# Создаем конфигурацию для nginx
cat > nginx_anthems.conf << 'EOF'
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
EOF

echo "📤 Загружаю конфигурацию на сервер..."
scp nginx_anthems.conf root@flags.worldarena.games:/tmp/

echo "🔧 Применяю конфигурацию..."
ssh root@flags.worldarena.games << 'EOF'
# Добавляем конфигурацию в основной файл сайта
cat /tmp/nginx_anthems.conf >> /etc/nginx/sites-available/flags.worldarena.games

# Проверяем конфигурацию
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Конфигурация nginx корректна"
    # Перезагружаем nginx
    systemctl reload nginx
    echo "✅ nginx перезагружен"
else
    echo "❌ Ошибка в конфигурации nginx"
    exit 1
fi
EOF

echo "🧹 Удаляю временные файлы..."
rm nginx_anthems.conf

echo "✅ Настройка nginx завершена"
echo "🌐 Теперь гимны должны быть доступны по адресу:"
echo "   https://flags.worldarena.games/anthems/anthem_fr.m4a"

