#!/bin/bash

# Скрипт для загрузки сгенерированных гимнов на сервер

SERVER_HOST="flags.worldarena.games"
SERVER_USER="root"
SERVER_PATH="/var/www/flags.worldarena.games/anthems"
LOCAL_PATH="./real_anthems_generated"

echo "🚀 Загрузка сгенерированных гимнов на сервер..."

# Проверяем наличие папки с гимнами
if [ ! -d "$LOCAL_PATH" ]; then
    echo "❌ Папка $LOCAL_PATH не найдена!"
    echo "Сначала запустите скрипт create_real_anthems.py"
    exit 1
fi

# Проверяем наличие M4A файлов
m4a_files=$(find "$LOCAL_PATH" -name "*.m4a" | wc -l)
if [ $m4a_files -eq 0 ]; then
    echo "❌ M4A файлы не найдены в $LOCAL_PATH"
    exit 1
fi

echo "📁 Найдено $m4a_files M4A файлов"
echo "📊 Размер файлов:"
du -sh "$LOCAL_PATH"/*.m4a | head -5
if [ $m4a_files -gt 5 ]; then
    echo "   ... и еще $(($m4a_files - 5)) файлов"
fi

# Подтверждение
read -p "🤔 Продолжить загрузку сгенерированных гимнов на сервер? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Отменено пользователем"
    exit 0
fi

echo "📤 Загружаю сгенерированные гимны на сервер..."
./upload_anthems_final.sh

