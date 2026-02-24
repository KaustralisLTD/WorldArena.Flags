#!/bin/bash
# Деплой API дуэлей на 157.230.11.51
# Запуск: ./deploy-to-server.sh
# Требуется: ssh-доступ к root@157.230.11.51 (ключ или пароль)

set -e
SERVER="root@157.230.11.51"
REMOTE_DIR="/var/www/flags.worldarena.games/duel-api"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== 1. Создание каталога на сервере (если нет) ==="
ssh "$SERVER" "mkdir -p $REMOTE_DIR"

echo "=== 2. Копирование файлов на сервер ==="
scp -o StrictHostKeyChecking=accept-new "$SCRIPT_DIR/package.json" "$SCRIPT_DIR/server.js" "$SERVER:$REMOTE_DIR/"

echo ""
echo "=== 3. Установка зависимостей и перезапуск на сервере ==="
ssh "$SERVER" "cd $REMOTE_DIR && npm install --production && pm2 restart duel-api || (PORT=3001 pm2 start server.js --name duel-api && pm2 save)"

echo ""
echo "=== 4. Проверка health ==="
curl -s "https://flags.worldarena.games/api/v1/health" || curl -s "http://157.230.11.51:3001/api/v1/health" || true

echo ""
echo "Готово. Если nginx ещё не настроен, добавьте в конфиг сайта блок из nginx-duel-api.conf и выполните: sudo nginx -t && sudo systemctl reload nginx"
