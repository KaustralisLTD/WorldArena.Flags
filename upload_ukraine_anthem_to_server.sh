#!/bin/bash

# Скрипт для загрузки правильного гимна Украины на сервер
# Использование: ./upload_ukraine_anthem_to_server.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Конфигурация сервера (из существующих скриптов проекта)
SERVER_USER="root"
SERVER_HOST="flags.worldarena.games"
SERVER_PATH="/var/www/flags.worldarena.games/anthems"
LOCAL_FILE="anthem_ua_correct.m4a"

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🇺🇦 Загрузка правильного гимна Украины на сервер${NC}\n"

# Проверяем наличие файла
if [ ! -f "$LOCAL_FILE" ]; then
    echo -e "${RED}❌ Файл $LOCAL_FILE не найден!${NC}"
    echo ""
    echo "Сначала выполните:"
    echo "  ./download_ukraine_anthem.sh"
    echo ""
    exit 1
fi

# Показываем информацию о файле
FILE_SIZE=$(stat -f%z "$LOCAL_FILE" 2>/dev/null || stat -c%s "$LOCAL_FILE" 2>/dev/null)
FILE_SIZE_MB=$(echo "scale=2; $FILE_SIZE / 1024 / 1024" | bc)
DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$LOCAL_FILE" 2>/dev/null | cut -d. -f1)

echo -e "${YELLOW}📊 Информация о файле:${NC}"
echo "   Имя: $LOCAL_FILE"
echo "   Размер: ${FILE_SIZE_MB} MB"
echo "   Длительность: ${DURATION} секунд"
echo ""

# Проверяем подключение к серверу (интерактивный режим для ввода пароля)
echo -e "${YELLOW}🔌 Проверка подключения к серверу...${NC}"
echo "   Если потребуется, введите пароль от сервера"
if ! ssh -o ConnectTimeout=10 "$SERVER_USER@$SERVER_HOST" "echo 'OK'" > /dev/null 2>&1; then
    echo -e "${RED}❌ Не удалось подключиться к серверу${NC}"
    echo ""
    echo "Проверьте:"
    echo "  1. Правильность пароля"
    echo "  2. Доступность сервера"
    echo ""
    exit 1
fi

echo -e "${GREEN}✅ Подключение установлено${NC}\n"

# Создаем папку на сервере если её нет
echo -e "${YELLOW}📂 Проверяю папку на сервере...${NC}"
ssh "$SERVER_USER@$SERVER_HOST" "mkdir -p $SERVER_PATH"
echo -e "${GREEN}✅ Папка готова${NC}\n"

# Показываем что будет заменено
echo -e "${YELLOW}⚠️  ВНИМАНИЕ:${NC}"
echo "   Будет заменен файл: $SERVER_PATH/anthem_ua.m4a"
echo "   Старый файл будет переименован в: anthem_ua.m4a.backup"
echo ""

# Подтверждение
read -p "Продолжить загрузку? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Отменено"
    exit 1
fi

# Создаем резервную копию старого файла
echo -e "${YELLOW}💾 Создаю резервную копию старого файла...${NC}"
ssh "$SERVER_USER@$SERVER_HOST" "
    if [ -f $SERVER_PATH/anthem_ua.m4a ]; then
        mv $SERVER_PATH/anthem_ua.m4a $SERVER_PATH/anthem_ua.m4a.backup
        echo 'Резервная копия создана'
    else
        echo 'Старый файл не найден, создаю новый'
    fi
"

# Загружаем файл
echo -e "${GREEN}📤 Загружаю файл на сервер...${NC}"
scp "$LOCAL_FILE" "$SERVER_USER@$SERVER_HOST:$SERVER_PATH/anthem_ua.m4a"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Файл успешно загружен на сервер!${NC}"
    echo ""
    echo -e "${BLUE}📋 Проверка:${NC}"
    echo "   URL: https://flags.worldarena.games/anthems/anthem_ua.m4a"
    echo ""
    echo -e "${YELLOW}💡 Следующие шаги:${NC}"
    echo "   1. Проверьте файл в браузере: https://flags.worldarena.games/anthems/anthem_ua.m4a"
    echo "   2. Очистите кэш приложения на iOS устройстве"
    echo "   3. Перезапустите приложение"
    echo ""
else
    echo -e "${RED}❌ Ошибка при загрузке файла${NC}"
    exit 1
fi
