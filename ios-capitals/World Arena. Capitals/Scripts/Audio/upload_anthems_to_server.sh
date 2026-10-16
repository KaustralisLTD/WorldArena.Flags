#!/bin/bash
# Скрипт для загрузки гимнов на сервер

# Конфигурация
SERVER_USER="root"
SERVER_HOST="157.230.11.51"
SERVER_PATH="/var/www/flags.worldarena.games/anthems"
LOCAL_DIR="real_anthems_complete"

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🎵 Загрузка гимнов на сервер${NC}\n"

# Проверка наличия папки
if [ ! -d "$LOCAL_DIR" ]; then
    echo -e "${RED}❌ Папка $LOCAL_DIR не найдена${NC}"
    echo "Сначала запустите: python3 download_real_anthems_complete.py"
    exit 1
fi

# Проверка наличия файлов
FILE_COUNT=$(find "$LOCAL_DIR" -name "anthem_*.m4a" | wc -l)
if [ "$FILE_COUNT" -eq 0 ]; then
    echo -e "${RED}❌ Файлы гимнов не найдены в $LOCAL_DIR${NC}"
    exit 1
fi

echo -e "${YELLOW}📊 Найдено файлов: $FILE_COUNT${NC}\n"

# Подтверждение
read -p "Загрузить файлы на сервер $SERVER_HOST? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Отменено"
    exit 1
fi

# Загрузка файлов
echo -e "${GREEN}📤 Загружаю файлы...${NC}\n"

# Используем rsync для эффективной загрузки
# Используем ssh с принудительным TTY если требуется смена пароля
rsync -avz --progress -e "ssh -t" \
    "$LOCAL_DIR/anthem_"*.m4a \
    "$SERVER_USER@$SERVER_HOST:$SERVER_PATH/"

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}✅ Файлы успешно загружены на сервер${NC}"
    echo -e "${YELLOW}🌐 URL: https://flags.worldarena.games/anthems/${NC}\n"
    
    # Загружаем манифест
    if [ -f "$LOCAL_DIR/manifest.json" ]; then
        echo -e "${GREEN}📋 Загружаю манифест...${NC}"
        scp "$LOCAL_DIR/manifest.json" "$SERVER_USER@$SERVER_HOST:$SERVER_PATH/"
        echo -e "${GREEN}✅ Манифест загружен${NC}\n"
    fi
    
    echo -e "${GREEN}🎉 Готово! Гимны доступны на сервере${NC}"
else
    echo -e "\n${RED}❌ Ошибка загрузки файлов${NC}"
    exit 1
fi
