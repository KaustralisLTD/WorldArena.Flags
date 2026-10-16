#!/bin/bash
# Скрипт для проверки состояния сервера и файлов гимнов

SERVER_USER="root"
SERVER_HOST="157.230.11.51"
SERVER_PATH="/var/www/flags.worldarena.games/anthems"

echo "🔍 Проверка состояния сервера и файлов гимнов"
echo ""

ssh "$SERVER_USER@$SERVER_HOST" << 'EOF'
    echo "📁 Проверка папки с гимнами:"
    ls -lah /var/www/flags.worldarena.games/anthems/ 2>/dev/null | head -10
    
    echo ""
    echo "📊 Количество файлов .m4a:"
    ls -1 /var/www/flags.worldarena.games/anthems/*.m4a 2>/dev/null | wc -l
    
    echo ""
    echo "🔐 Права доступа:"
    ls -ld /var/www/flags.worldarena.games/anthems/
    
    echo ""
    echo "🌐 Проверка веб-сервера:"
    systemctl status nginx 2>/dev/null | head -5 || systemctl status apache2 2>/dev/null | head -5
    
    echo ""
    echo "📋 Конфигурация nginx для anthems:"
    grep -r "anthems" /etc/nginx/sites-enabled/ 2>/dev/null | head -5 || echo "Конфигурация не найдена"
EOF
