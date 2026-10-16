#!/bin/bash
# Скрипт для удаления папок с гимнами из проекта Xcode
# Файлы уже загружены на сервер, поэтому их не нужно включать в бандл

cd "/Volumes/spilberg/3.Work/9.iOS/Flags.World 06.04.2025/World Arena. Flags/Scripts/Audio"

echo "🗑️  Удаляю папки с гимнами из проекта..."
echo ""

# Удаляем папки с гимнами (они уже на сервере)
rm -rf real_anthems_complete/
rm -rf real_anthems_ready/
rm -rf real_anthems_all/
rm -rf real_anthems_v2/
rm -rf temp_anthems/

echo "✅ Папки удалены"
echo ""
echo "📝 Примечание:"
echo "   - Файлы гимнов загружены на сервер"
echo "   - Приложение будет загружать их с https://flags.worldarena.games/anthems/"
echo "   - Теперь можно собирать проект без ошибок"
