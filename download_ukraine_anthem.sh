#!/bin/bash

# Скрипт для скачивания и конвертации официального гимна Украины
# Использование: ./download_ukraine_anthem.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🇺🇦 Скачивание официального гимна Украины..."
echo ""

# Проверяем наличие ffmpeg
if ! command -v ffmpeg &> /dev/null; then
    echo "❌ Ошибка: ffmpeg не установлен"
    echo "   Установите через: brew install ffmpeg"
    exit 1
fi

# URL официального гимна с Wikimedia Commons (U.S. Navy Band)
ANTHEM_URL="https://upload.wikimedia.org/wikipedia/commons/6/6d/National_anthem_of_Ukraine%2C_instrumental.oga"
TEMP_OGG="ukraine_anthem_temp.oga"
OUTPUT_M4A="anthem_ua.m4a"

# Скачиваем оригинальный файл
echo "📥 Скачивание файла с Wikimedia Commons..."
if curl -L -f -o "$TEMP_OGG" "$ANTHEM_URL"; then
    echo "✅ Файл успешно скачан"
else
    echo "❌ Ошибка при скачивании файла"
    exit 1
fi

# Проверяем размер файла
FILE_SIZE=$(stat -f%z "$TEMP_OGG" 2>/dev/null || stat -c%s "$TEMP_OGG" 2>/dev/null)
if [ "$FILE_SIZE" -lt 1000000 ]; then
    echo "⚠️  Предупреждение: файл слишком маленький ($FILE_SIZE байт)"
fi

echo ""
echo "🔄 Конвертация в формат M4A (AAC, 192kbps, 44.1kHz, стерео)..."
if ffmpeg -i "$TEMP_OGG" -c:a aac -b:a 192k -ar 44100 -ac 2 "$OUTPUT_M4A" -y -loglevel error; then
    echo "✅ Конвертация завершена успешно"
else
    echo "❌ Ошибка при конвертации"
    rm -f "$TEMP_OGG"
    exit 1
fi

# Проверяем результат
if [ -f "$OUTPUT_M4A" ]; then
    OUTPUT_SIZE=$(stat -f%z "$OUTPUT_M4A" 2>/dev/null || stat -c%s "$OUTPUT_M4A" 2>/dev/null)
    DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$OUTPUT_M4A" 2>/dev/null | cut -d. -f1)
    
    echo ""
    echo "📊 Информация о файле:"
    echo "   Имя файла: $OUTPUT_M4A"
    echo "   Размер: $(numfmt --to=iec-i --suffix=B $OUTPUT_SIZE)"
    echo "   Длительность: ${DURATION} секунд"
    echo ""
    echo "✅ Гимн готов к использованию!"
    echo ""
    echo "📤 Для загрузки на сервер выполните:"
    echo "   scp $OUTPUT_M4A user@flags.worldarena.games:/path/to/anthems/anthem_ua.m4a"
    echo ""
    echo "   Или используйте FTP/SFTP клиент для загрузки файла в директорию:"
    echo "   /path/to/anthems/anthem_ua.m4a"
else
    echo "❌ Ошибка: файл не был создан"
    exit 1
fi

# Удаляем временный файл
rm -f "$TEMP_OGG"

echo "✨ Готово!"
