#!/bin/bash
# Добавляет location ^~ /api/ в блок server с listen 443 для flags.worldarena.games
# Запускать на сервере: bash fix-nginx-api-443.sh

set -e
CONF="/etc/nginx/sites-available/flags.worldarena.games"

if [ ! -f "$CONF" ]; then
  echo "Файл $CONF не найден."
  exit 1
fi

# Уже есть location /api/ после listen [::]:443 (в блоке 443)?
if grep -A 300 "listen \[::]:443" "$CONF" | grep -q "location.*/api/"; then
  echo "В блоке 443 уже есть location /api/. Перезагрузите nginx: nginx -t && systemctl reload nginx"
  exit 0
fi

BACKUP="${CONF}.bak.$(date +%Y%m%d%H%M%S)"
cp -a "$CONF" "$BACKUP"
echo "Бэкап: $BACKUP"

# Вставить блок после строки "listen [::]:443" в том же server {}
awk '
  /listen \[::\]:443/ && !inserted {
    print
    print "    # API дуэлей (^~ = приоритет над другими location)"
    print "    location ^~ /api/ {"
    print "        proxy_pass http://127.0.0.1:3001;"
    print "        proxy_http_version 1.1;"
    print "        proxy_set_header Host $host;"
    print "        proxy_set_header X-Real-IP $remote_addr;"
    print "        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;"
    print "        proxy_set_header X-Forwarded-Proto $scheme;"
    print "    }"
    print ""
    inserted=1
    next
  }
  { print }
' "$CONF" > "${CONF}.new" && mv "${CONF}.new" "$CONF"

nginx -t && systemctl reload nginx
echo "Готово. Проверка: curl -s -k -H 'Host: flags.worldarena.games' https://127.0.0.1/api/v1/health"
curl -s -k -H "Host: flags.worldarena.games" https://127.0.0.1/api/v1/health | head -c 200
echo ""
