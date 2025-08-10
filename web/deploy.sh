#!/bin/bash

# Скрипт развертывания FLAGS WORLD на DigitalOcean
# Использование: ./deploy.sh [domain]

set -e

DOMAIN=${1:-"your-domain.com"}
PROJECT_DIR="/var/www/flags-world"
NGINX_CONF="/etc/nginx/sites-available/flags-world"

echo "🚀 Начинаем развертывание FLAGS WORLD..."

# 1. Создание директории проекта
echo "📁 Создание директории проекта..."
sudo mkdir -p $PROJECT_DIR
sudo mkdir -p $PROJECT_DIR/logs

# 2. Остановка старых контейнеров
echo "🛑 Остановка старых контейнеров..."
cd $PROJECT_DIR
sudo docker-compose -f docker-compose.prod.yml down || true

# 3. Сборка и запуск новых контейнеров
echo "🔨 Сборка и запуск контейнеров..."
sudo docker-compose -f docker-compose.prod.yml build --no-cache
sudo docker-compose -f docker-compose.prod.yml up -d

# 4. Настройка Nginx прокси
echo "⚙️ Настройка Nginx..."
sudo tee $NGINX_CONF > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    # Redirect to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;
    
    # SSL Configuration (will be added by Certbot)
    
    # Proxy to Docker container
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Security headers
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "origin-when-cross-origin" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Logs
    access_log $PROJECT_DIR/logs/access.log;
    error_log $PROJECT_DIR/logs/error.log;
}
EOF

# 5. Активация конфигурации Nginx
echo "🔗 Активация конфигурации Nginx..."
sudo ln -sf $NGINX_CONF /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# 6. Настройка SSL с Certbot
echo "🔒 Настройка SSL сертификата..."
sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN

# 7. Настройка автообновления SSL
echo "🔄 Настройка автообновления SSL..."
(crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -

# 8. Настройка файрвола
echo "🔥 Настройка файрвола..."
sudo ufw allow 'Nginx Full'
sudo ufw allow ssh
sudo ufw --force enable

# 9. Проверка статуса
echo "✅ Проверка статуса..."
sudo docker-compose -f docker-compose.prod.yml ps
curl -I http://localhost:3000/health || echo "⚠️ Health check failed"

echo ""
echo "🎉 Развертывание завершено!"
echo "🌐 Сайт доступен по адресу: https://$DOMAIN"
echo "📊 Логи: $PROJECT_DIR/logs/"
echo "🐳 Docker статус: sudo docker-compose -f docker-compose.prod.yml ps"
echo ""
echo "📋 Полезные команды:"
echo "  Перезапуск: sudo docker-compose -f docker-compose.prod.yml restart"
echo "  Логи: sudo docker-compose -f docker-compose.prod.yml logs -f"
echo "  Обновление: git pull && sudo docker-compose -f docker-compose.prod.yml up -d --build" 