#!/bin/bash

# Скрипт для загрузки реальных гимнов на сервер
# Использует папку real_anthems_final

SERVER_HOST="flags.worldarena.games"
SERVER_USER="root"
SERVER_PATH="/var/www/flags.worldarena.games/anthems"
LOCAL_PATH="./real_anthems_final"

echo "🚀 Загрузка реальных гимнов на сервер..."

# Проверяем наличие папки с гимнами
if [ ! -d "$LOCAL_PATH" ]; then
    echo "❌ Папка $LOCAL_PATH не найдена!"
    echo "Сначала запустите скрипт download_simple_anthems.py"
    exit 1
fi

# Проверяем наличие M4A файлов
m4a_files=$(find "$LOCAL_PATH" -name "*.m4a" | wc -l)
if [ $m4a_files -eq 0 ]; then
    echo "❌ M4A файлы не найдены в $LOCAL_PATH"
    exit 1
fi

echo "📁 Найдено $m4a_files M4A файлов"

# Показываем список файлов
echo "📋 Файлы для загрузки:"
ls -la "$LOCAL_PATH"/*.m4a | head -10
if [ $m4a_files -gt 10 ]; then
    echo "   ... и еще $(($m4a_files - 10)) файлов"
fi

# Подтверждение
read -p "🤔 Продолжить загрузку на сервер? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Отменено пользователем"
    exit 0
fi

# Создаем резервную копию старых файлов на сервере
echo "💾 Создаю резервную копию старых файлов..."
ssh "$SERVER_USER@$SERVER_HOST" "
    if [ -d '$SERVER_PATH' ]; then
        mkdir -p '$SERVER_PATH.backup.$(date +%Y%m%d_%H%M%S)'
        cp -r '$SERVER_PATH'/* '$SERVER_PATH.backup.$(date +%Y%m%d_%H%M%S)/' 2>/dev/null || true
        echo '✅ Резервная копия создана'
    fi
"

# Создаем папку на сервере
echo "📂 Создаю папку на сервере..."
ssh "$SERVER_USER@$SERVER_HOST" "mkdir -p $SERVER_PATH"

# Загружаем файлы на сервер
echo "📤 Загружаю файлы на сервер..."
scp "$LOCAL_PATH"/*.m4a "$SERVER_USER@$SERVER_HOST:$SERVER_PATH/"

if [ $? -eq 0 ]; then
    echo "✅ Файлы успешно загружены на сервер"
    
    # Проверяем права доступа
    echo "🔐 Настраиваю права доступа..."
    ssh "$SERVER_USER@$SERVER_HOST" "
        chmod 644 $SERVER_PATH/*.m4a
        chown www-data:www-data $SERVER_PATH/*.m4a
    "
    
    # Загружаем manifest.json
    if [ -f "$LOCAL_PATH/manifest.json" ]; then
        echo "📄 Загружаю manifest.json..."
        scp "$LOCAL_PATH/manifest.json" "$SERVER_USER@$SERVER_HOST:$SERVER_PATH/"
        ssh "$SERVER_USER@$SERVER_HOST" "
            chmod 644 $SERVER_PATH/manifest.json
            chown www-data:www-data $SERVER_PATH/manifest.json
        "
    fi
    
    # Проверяем количество загруженных файлов
    server_files=$(ssh "$SERVER_USER@$SERVER_HOST" "ls -1 $SERVER_PATH/*.m4a 2>/dev/null | wc -l")
    echo "📊 Загружено на сервер: $server_files файлов"
    
    # Показываем первые несколько файлов на сервере
    echo "📋 Первые файлы на сервере:"
    ssh "$SERVER_USER@$SERVER_HOST" "ls -la $SERVER_PATH/*.m4a | head -5"
    
    # Создаем .htaccess для правильной обработки M4A файлов
    echo "⚙️ Создаю .htaccess файл..."
    cat > /tmp/htaccess << 'EOF'
# MIME types for audio files
AddType audio/mp4 .m4a
AddType audio/mpeg .mp3
AddType audio/wav .wav
AddType audio/ogg .ogg

# Enable CORS for iOS apps
Header always set Access-Control-Allow-Origin "*"
Header always set Access-Control-Allow-Methods "GET, POST, OPTIONS"
Header always set Access-Control-Allow-Headers "Content-Type, Authorization, X-Requested-With"

# Handle preflight requests
RewriteEngine On
RewriteCond %{REQUEST_METHOD} OPTIONS
RewriteRule ^(.*)$ $1 [R=200,L]

# Cache control for audio files
<FilesMatch "\.(m4a|mp3|wav|ogg)$">
    ExpiresActive On
    ExpiresDefault "access plus 1 month"
    Header set Cache-Control "public, max-age=2592000"
    Header set Accept-Ranges "bytes"
</FilesMatch>

# Enable Range requests for audio streaming
<IfModule mod_headers.c>
    Header set Accept-Ranges "bytes"
</IfModule>

# Compression (если поддерживается)
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE audio/mp4
    AddOutputFilterByType DEFLATE audio/mpeg
    AddOutputFilterByType DEFLATE audio/wav
</IfModule>

# Security headers
Header always set X-Content-Type-Options "nosniff"
Header always set X-Frame-Options "DENY"

# Directory browsing
Options -Indexes
EOF

    scp /tmp/htaccess "$SERVER_USER@$SERVER_HOST:$SERVER_PATH/.htaccess"
    ssh "$SERVER_USER@$SERVER_HOST" "chmod 644 $SERVER_PATH/.htaccess"
    rm /tmp/htaccess
    
    # Создаем тестовый файл для проверки доступности
    echo "🧪 Создаю тестовый файл..."
    ssh "$SERVER_USER@$SERVER_HOST" "
        echo 'Anthems server is working' > $SERVER_PATH/test.txt
        chmod 644 $SERVER_PATH/test.txt
        chown www-data:www-data $SERVER_PATH/test.txt
    "
    
    echo "✅ Настройка сервера завершена"
    echo ""
    echo "🌐 Гимны доступны по адресу:"
    echo "   https://flags.worldarena.games/anthems/"
    echo ""
    echo "🧪 Тест доступности:"
    echo "   curl -I https://flags.worldarena.games/anthems/test.txt"
    echo ""
    echo "🎵 Примеры гимнов:"
    echo "   https://flags.worldarena.games/anthems/anthem_us.m4a"
    echo "   https://flags.worldarena.games/anthems/anthem_de.m4a"
    echo "   https://flags.worldarena.games/anthems/anthem_fr.m4a"
    echo ""
    echo "📱 В приложении они будут автоматически загружаться при воспроизведении"
    
    # Тестируем доступность
    echo ""
    echo "🧪 Проверяю доступность сервера..."
    if curl -s -I "https://flags.worldarena.games/anthems/test.txt" | grep -q "200 OK"; then
        echo "✅ Сервер доступен!"
    else
        echo "⚠️ Возможные проблемы с доступностью сервера"
    fi
    
else
    echo "❌ Ошибка загрузки файлов на сервер"
    exit 1
fi

