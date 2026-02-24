#!/bin/bash

# Скрипт для исправления прав доступа на файл гимна Украины на сервере
# Используйте если получили ошибку 403 Forbidden

cd "/Volumes/spilberg/3.Work/9.iOS/Flags.World 06.04.2025"

echo "🔐 Исправление прав доступа на файл гимна Украины"
echo ""

echo "Устанавливаю права на файл..."
echo "(Если потребуется - введите пароль от сервера)"
echo ""

ssh root@flags.worldarena.games "
    cd /var/www/flags.worldarena.games/anthems
    
    if [ -f anthem_ua.m4a ]; then
        echo '📁 Файл найден: anthem_ua.m4a'
        echo ''
        
        # Устанавливаем права на файл (644 = rw-r--r--)
        chmod 644 anthem_ua.m4a
        echo '✅ Права установлены: 644'
        
        # Устанавливаем владельца (www-data для веб-сервера)
        chown www-data:www-data anthem_ua.m4a
        echo '✅ Владелец установлен: www-data:www-data'
        
        echo ''
        echo '📊 Текущие права на файл:'
        ls -lah anthem_ua.m4a
        
        echo ''
        echo '✅ Права доступа исправлены!'
    else
        echo '❌ Файл anthem_ua.m4a не найден на сервере'
        echo 'Сначала загрузите файл: ./загрузить_гимн_украины.sh'
        exit 1
    fi
"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ ✅ ✅ ПРАВА ДОСТУПА ИСПРАВЛЕНЫ! ✅ ✅ ✅"
    echo ""
    echo "📋 Проверка:"
    echo "   Откройте в браузере: https://flags.worldarena.games/anthems/anthem_ua.m4a"
    echo "   Теперь файл должен быть доступен (не должно быть ошибки 403)"
    echo ""
else
    echo ""
    echo "❌ Ошибка при исправлении прав"
    exit 1
fi
