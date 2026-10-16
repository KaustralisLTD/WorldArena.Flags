#!/bin/bash
# Скрипт для смены пароля root на сервере

SERVER_USER="root"
SERVER_HOST="157.230.11.51"

echo "🔐 Смена пароля root на сервере $SERVER_HOST"
echo ""
echo "ВНИМАНИЕ: Используйте SSH с принудительным TTY для смены пароля"
echo ""

# Используем SSH с принудительным TTY (-t) для интерактивной смены пароля
ssh -t "$SERVER_USER@$SERVER_HOST" "passwd"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Пароль успешно изменен!"
    echo ""
    echo "Теперь можно использовать:"
    echo "  ./upload_anthems_to_server.sh"
else
    echo ""
    echo "❌ Ошибка смены пароля"
    echo ""
    echo "Альтернативный способ:"
    echo "  1. Войдите через DigitalOcean консоль (Console)"
    echo "  2. Выполните: passwd"
    echo "  3. Введите новый пароль дважды"
fi
