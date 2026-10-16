#!/bin/bash
# Тестовый скрипт для загрузки одного гимна

cd "/Volumes/spilberg/3.Work/9.iOS/Flags.World 06.04.2025/World Arena. Flags/Scripts/Audio"

echo "🧪 Тестирую загрузку гимна Австрии..."

# Создаем папку если нет
mkdir -p real_anthems_complete

# Загружаем один гимн через yt-dlp
# Загружаем гимн
yt-dlp \
    -f "bestaudio[ext=m4a]/bestaudio[ext=mp4]/bestaudio/best" \
    --extract-audio \
    --audio-format m4a \
    --audio-quality 192k \
    --default-search "ytsearch1:" \
    --max-downloads 1 \
    --no-playlist \
    -o "real_anthems_complete/temp_at.%(ext)s" \
    "Austria national anthem Land der Berge Land am Strome official instrumental" 2>&1

# Проверяем наличие файла (даже если yt-dlp вернул ошибку из-за "Aborting")
FILE=$(find real_anthems_complete -name "temp_at.*" -type f | head -1)

if [ -n "$FILE" ]; then
    SIZE=$(stat -f%z "$FILE" 2>/dev/null || stat -c%s "$FILE" 2>/dev/null)
    echo ""
    echo "✅ Загрузка успешна!"
    echo "📁 Файл: $FILE"
    echo "📦 Размер: $((SIZE / 1024)) KB"
    
    # Переименовываем если нужно
    if [[ "$FILE" != *.m4a ]]; then
        echo "🔄 Конвертирую в M4A..."
        ffmpeg -i "$FILE" -acodec aac -b:a 192k -ar 44100 -ac 2 -y "real_anthems_complete/anthem_at.m4a" 2>/dev/null
        if [ -f "real_anthems_complete/anthem_at.m4a" ]; then
            rm "$FILE"
            echo "✅ Готово! Файл: real_anthems_complete/anthem_at.m4a"
        else
            echo "❌ Ошибка конвертации"
        fi
    else
        mv "$FILE" "real_anthems_complete/anthem_at.m4a"
        echo "✅ Готово! Файл: real_anthems_complete/anthem_at.m4a"
    fi
else
    echo ""
    echo "❌ Файл не найден после загрузки"
    exit 1
fi
