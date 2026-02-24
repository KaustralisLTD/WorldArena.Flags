#!/bin/bash
# Добавляет location ^~ /api/ во ВСЕ server-блоки с listen 443 и server_name flags.worldarena
# (на 443 может отвечать другой конфиг — default или порядок include)
# Запускать на сервере: bash fix-nginx-api-443-v2.sh

set -e
API_BLOCK='
    # API дуэлей (^~ = приоритет)
    location ^~ /api/ {
        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
'

echo "Ищем конфиги с listen 443 и flags.worldarena (важен sites-enabled — его читает nginx!)..."
FILES=$(grep -rl "listen.*443" /etc/nginx/sites-enabled /etc/nginx/sites-available 2>/dev/null | xargs grep -l "flags.worldarena" 2>/dev/null || true)
if [ -z "$FILES" ]; then
  echo "Не найдено. Проверьте: grep -r 'listen.*443' /etc/nginx/"
  exit 1
fi

for CONF in $FILES; do
  # Пропустить бэкапы
  [[ "$CONF" == *.bak.* ]] && continue
  # Уже есть наш блок сразу после listen [::]:443 (в пределах 15 строк)?
  if grep -A 15 "listen \[::]:443" "$CONF" 2>/dev/null | grep -q "location ^~ /api/"; then
    echo "Пропуск $CONF — location ^~ /api/ уже есть после listen [::]:443"
    continue
  fi
  BACKUP="${CONF}.bak.$(date +%Y%m%d%H%M%S)"
  cp -a "$CONF" "$BACKUP"
  echo "Правка $CONF (бэкап: $BACKUP)"
  awk '
    /listen \[::\]:443/ && !done {
      print
      print "    # API дуэлей (^~ = приоритет)"
      print "    location ^~ /api/ {"
      print "        proxy_pass http://127.0.0.1:3001;"
      print "        proxy_http_version 1.1;"
      print "        proxy_set_header Host $host;"
      print "        proxy_set_header X-Real-IP $remote_addr;"
      print "        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;"
      print "        proxy_set_header X-Forwarded-Proto $scheme;"
      print "    }"
      print ""
      done=1
      next
    }
    { print }
  ' "$CONF" > "${CONF}.new" && mv "${CONF}.new" "$CONF"
done

nginx -t && systemctl reload nginx
echo "Проверка:"
curl -s -k -H "Host: flags.worldarena.games" https://127.0.0.1/api/v1/health | head -c 80
echo ""
