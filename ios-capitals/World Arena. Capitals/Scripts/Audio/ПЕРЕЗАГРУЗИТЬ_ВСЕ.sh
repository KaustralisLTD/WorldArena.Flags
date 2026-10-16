#!/bin/bash
# Скрипт для удаления всех заглушек и перезагрузки реальных гимнов

cd "/Volumes/spilberg/3.Work/9.iOS/Flags.World 06.04.2025/World Arena. Flags/Scripts/Audio"

echo "🗑️  Удаляю все существующие файлы гимнов (включая заглушки)..."
echo ""

# Удаляем все файлы гимнов
rm -f real_anthems_complete/anthem_*.m4a
rm -f real_anthems_complete/temp_*.m4a
rm -f real_anthems_complete/temp_*.*

echo "✅ Все файлы удалены"
echo ""
echo "🚀 Запускаю загрузку реальных гимнов..."
echo ""

python3 download_real_anthems_simple.py
