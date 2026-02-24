#!/bin/bash
# Диагностика: какой server обрабатывает 443 для flags.worldarena.games
# Запускать на сервере: bash diagnose-nginx-443.sh

echo "=== Все server с listen 443 ==="
grep -rn "listen.*443" /etc/nginx/

echo ""
echo "=== Все server_name с flags ==="
grep -rn "server_name.*flags" /etc/nginx/

echo ""
echo "=== Содержимое sites-enabled ==="
ls -la /etc/nginx/sites-enabled/

echo ""
echo "=== Первые 80 строк flags.worldarena.games ==="
head -80 /etc/nginx/sites-enabled/flags.worldarena.games 2>/dev/null || head -80 /etc/nginx/sites-available/flags.worldarena.games
