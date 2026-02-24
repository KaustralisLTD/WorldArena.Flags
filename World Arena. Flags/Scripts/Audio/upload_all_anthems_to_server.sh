#!/bin/bash
# Скрипт для загрузки всех гимнов на сервер

# Конфигурация сервера
SERVER_USER="root"
SERVER_HOST="157.230.11.51"
SERVER_PATH="/var/www/flags.worldarena.games/anthems"
LOCAL_DIR="real_anthems_complete"

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🎵 Загрузка гимнов на сервер${NC}\n"

# Проверка наличия папки
if [ ! -d "$LOCAL_DIR" ]; then
    echo -e "${RED}❌ Папка $LOCAL_DIR не найдена${NC}"
    echo "Сначала запустите: python3 download_all_missing_anthems.py"
    exit 1
fi

# Проверка наличия файлов
FILE_COUNT=$(find "$LOCAL_DIR" -name "anthem_*.m4a" | wc -l | tr -d ' ')
if [ "$FILE_COUNT" -eq 0 ]; then
    echo -e "${RED}❌ Файлы гимнов не найдены в $LOCAL_DIR${NC}"
    exit 1
fi

echo -e "${YELLOW}📊 Найдено файлов: $FILE_COUNT${NC}\n"

# Показываем размер папки
TOTAL_SIZE=$(du -sh "$LOCAL_DIR" | cut -f1)
echo -e "${YELLOW}📦 Общий размер: $TOTAL_SIZE${NC}\n"

# Подтверждение
echo -e "${BLUE}Сервер: ${SERVER_USER}@${SERVER_HOST}${NC}"
echo -e "${BLUE}Путь на сервере: ${SERVER_PATH}${NC}\n"
read -p "Загрузить файлы на сервер? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Отменено"
    exit 1
fi

# Проверка подключения к серверу
echo -e "\n${YELLOW}🔌 Проверяю подключение к серверу...${NC}"
if ! ssh -o ConnectTimeout=5 "$SERVER_USER@$SERVER_HOST" "echo 'OK'" > /dev/null 2>&1; then
    echo -e "${RED}❌ Не удалось подключиться к серверу${NC}"
    echo "Проверьте:"
    echo "  1. Доступность сервера"
    echo "  2. SSH ключи или пароль"
    exit 1
fi
echo -e "${GREEN}✅ Подключение установлено${NC}\n"

# Создаем папку на сервере если её нет
echo -e "${YELLOW}📂 Создаю папку на сервере...${NC}"
ssh "$SERVER_USER@$SERVER_HOST" "mkdir -p $SERVER_PATH"
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Ошибка создания папки на сервере${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Папка создана${NC}\n"

# Загрузка файлов
echo -e "${GREEN}📤 Загружаю файлы на сервер...${NC}\n"

# Используем rsync для эффективной загрузки с прогрессом
rsync -avz --progress -e "ssh" \
    "$LOCAL_DIR/anthem_"*.m4a \
    "$SERVER_USER@$SERVER_HOST:$SERVER_PATH/"

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}✅ Файлы успешно загружены на сервер${NC}"
    
    # Настраиваем права доступа
    echo -e "\n${YELLOW}🔐 Настраиваю права доступа...${NC}"
    ssh "$SERVER_USER@$SERVER_HOST" "
        chmod 644 $SERVER_PATH/anthem_*.m4a 2>/dev/null
        chown www-data:www-data $SERVER_PATH/anthem_*.m4a 2>/dev/null
    "
    echo -e "${GREEN}✅ Права доступа настроены${NC}"
    
    # Проверяем количество загруженных файлов
    echo -e "\n${YELLOW}📊 Проверяю загруженные файлы...${NC}"
    SERVER_COUNT=$(ssh "$SERVER_USER@$SERVER_HOST" "ls -1 $SERVER_PATH/anthem_*.m4a 2>/dev/null | wc -l | tr -d ' '")
    echo -e "${GREEN}✅ На сервере: $SERVER_COUNT файлов${NC}"
    
    echo -e "\n${GREEN}🎉 Готово! Все файлы загружены на сервер${NC}"
    echo -e "${BLUE}🌐 Проверьте: https://flags.worldarena.games/anthems/anthem_XX.m4a${NC}"
else
    echo -e "\n${RED}❌ Ошибка загрузки файлов${NC}"
    exit 1
fi
