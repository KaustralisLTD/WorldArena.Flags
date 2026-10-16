#!/bin/bash

# Скрипт для загрузки гимнов на сервер
# Требует настройки SSH ключей для доступа к серверу

SERVER_HOST="flags.worldarena.games"
SERVER_USER="root"
SERVER_PATH="/var/www/flags.worldarena.games/anthems"
LOCAL_PATH="./real_anthems"

echo "🚀 Загрузка гимнов на сервер..."

# Проверяем наличие папки с гимнами
if [ ! -d "$LOCAL_PATH" ]; then
    echo "❌ Папка $LOCAL_PATH не найдена!"
    echo "Сначала запустите скрипт download_real_anthems.py"
    exit 1
fi

# Проверяем наличие M4A файлов
m4a_files=$(find "$LOCAL_PATH" -name "*.m4a" | wc -l)
if [ $m4a_files -eq 0 ]; then
    echo "❌ M4A файлы не найдены в $LOCAL_PATH"
    exit 1
fi

echo "📁 Найдено $m4a_files M4A файлов"

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
    ssh "$SERVER_USER@$SERVER_HOST" "chmod 644 $SERVER_PATH/*.m4a"
    ssh "$SERVER_USER@$SERVER_HOST" "chown www-data:www-data $SERVER_PATH/*.m4a"
    
    # Проверяем количество загруженных файлов
    server_files=$(ssh "$SERVER_USER@$SERVER_HOST" "ls -1 $SERVER_PATH/*.m4a 2>/dev/null | wc -l")
    echo "📊 Загружено на сервер: $server_files файлов"
    
    # Показываем список файлов на сервере
    echo "📋 Файлы на сервере:"
    ssh "$SERVER_USER@$SERVER_HOST" "ls -la $SERVER_PATH/*.m4a"
    
    # Создаем .htaccess для правильной обработки M4A файлов
    echo "⚙️ Создаю .htaccess файл..."
    cat > /tmp/htaccess << EOF
# MIME types for audio files
AddType audio/mp4 .m4a
AddType audio/mpeg .mp3
AddType audio/wav .wav

# Enable CORS for iOS apps
Header always set Access-Control-Allow-Origin "*"
Header always set Access-Control-Allow-Methods "GET, OPTIONS"
Header always set Access-Control-Allow-Headers "Content-Type"

# Cache control
<FilesMatch "\.(m4a|mp3|wav)$">
    ExpiresActive On
    ExpiresDefault "access plus 1 month"
    Header set Cache-Control "public, max-age=2592000"
</FilesMatch>

# Compression
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE audio/mp4
    AddOutputFilterByType DEFLATE audio/mpeg
    AddOutputFilterByType DEFLATE audio/wav
</IfModule>
EOF

    scp /tmp/htaccess "$SERVER_USER@$SERVER_HOST:$SERVER_PATH/.htaccess"
    ssh "$SERVER_USER@$SERVER_HOST" "chmod 644 $SERVER_PATH/.htaccess"
    rm /tmp/htaccess
    
    echo "✅ Настройка сервера завершена"
    echo ""
    echo "🌐 Гимны доступны по адресу:"
    echo "   https://flags.worldarena.games/anthems/"
    echo ""
    echo "📱 В приложении они будут автоматически загружаться"
    
else
    echo "❌ Ошибка загрузки файлов на сервер"
    exit 1
fi
