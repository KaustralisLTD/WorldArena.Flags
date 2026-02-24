#!/bin/bash
# Скрипт для исправления прав доступа к файлам гимнов на сервере

SERVER_USER="root"
SERVER_HOST="157.230.11.51"
SERVER_PATH="/var/www/flags.worldarena.games/anthems"

echo "🔧 Исправление прав доступа к файлам гимнов на сервере"
echo ""

# Подключаемся к серверу и исправляем права
ssh "$SERVER_USER@$SERVER_HOST" << 'EOF'
    echo "📁 Проверяю папку с гимнами..."
    cd /var/www/flags.worldarena.games/anthems
    
    # Проверяем что папка существует
    if [ ! -d "/var/www/flags.worldarena.games/anthems" ]; then
        echo "❌ Папка не найдена, создаю..."
        mkdir -p /var/www/flags.worldarena.games/anthems
    fi
    
    echo "🔐 Устанавливаю права доступа..."
    
    # Устанавливаем права на папку
    chmod 755 /var/www/flags.worldarena.games/anthems
    
    # Устанавливаем права на файлы
    chmod 644 /var/www/flags.worldarena.games/anthems/*.m4a 2>/dev/null
    chmod 644 /var/www/flags.worldarena.games/anthems/manifest.json 2>/dev/null
    
    # Устанавливаем владельца (www-data для nginx/apache)
    chown -R www-data:www-data /var/www/flags.worldarena.games/anthems
    
    echo "📊 Проверяю файлы..."
    ls -lah /var/www/flags.worldarena.games/anthems/ | head -10
    
    echo ""
    echo "✅ Права доступа установлены"
    echo ""
    echo "📋 Количество файлов:"
    ls -1 /var/www/flags.worldarena.games/anthems/*.m4a 2>/dev/null | wc -l
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Права доступа исправлены!"
    echo ""
    echo "🧪 Проверяю доступность файлов..."
    python3 check_server_anthems.py
else
    echo ""
    echo "❌ Ошибка исправления прав доступа"
fi
