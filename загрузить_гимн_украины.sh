#!/bin/bash

# Простой скрипт для загрузки гимна Украины на сервер
# Запустите этот скрипт в Терминале - он попросит ввести пароль если нужно

cd "/Volumes/spilberg/3.Work/9.iOS/Flags.World 06.04.2025"

echo "🇺🇦 Загрузка правильного гимна Украины на сервер"
echo ""

# Проверяем файл
if [ ! -f "anthem_ua_correct.m4a" ]; then
    echo "❌ Файл anthem_ua_correct.m4a не найден!"
    echo "Сначала выполните: ./download_ukraine_anthem.sh"
    exit 1
fi

echo "📊 Файл найден: $(ls -lh anthem_ua_correct.m4a | awk '{print $5}')"
echo ""

# Создаем резервную копию старого файла
echo "💾 Создаю резервную копию старого файла..."
ssh root@flags.worldarena.games "
    cd /var/www/flags.worldarena.games/anthems
    if [ -f anthem_ua.m4a ]; then
        mv anthem_ua.m4a anthem_ua.m4a.backup
        echo '✅ Резервная копия создана'
    else
        echo 'ℹ️  Старый файл не найден'
    fi
"

echo ""
echo "📤 Загружаю новый файл на сервер..."
echo "   (Если потребуется - введите пароль от сервера)"
echo ""

scp anthem_ua_correct.m4a root@flags.worldarena.games:/var/www/flags.worldarena.games/anthems/anthem_ua.m4a

if [ $? -eq 0 ]; then
    echo ""
    echo "🔐 Устанавливаю права доступа на файл..."
    ssh root@flags.worldarena.games "
        chmod 644 /var/www/flags.worldarena.games/anthems/anthem_ua.m4a
        chown www-data:www-data /var/www/flags.worldarena.games/anthems/anthem_ua.m4a
    "
    
    echo ""
    echo "✅ ✅ ✅ ФАЙЛ УСПЕШНО ЗАГРУЖЕН И НАСТРОЕН НА СЕРВЕРЕ! ✅ ✅ ✅"
    echo ""
    echo "📋 Проверка:"
    echo "   Откройте в браузере: https://flags.worldarena.games/anthems/anthem_ua.m4a"
    echo "   Должен загрузиться файл размером ~1.9 MB"
    echo ""
    echo "💡 Следующие шаги:"
    echo "   1. Очистите кэш приложения на iOS устройстве"
    echo "   2. Перезапустите приложение"
    echo "   3. Проверьте воспроизведение гимна Украины"
    echo ""
else
    echo ""
    echo "❌ Ошибка при загрузке файла"
    echo "Проверьте:"
    echo "  1. Правильность пароля"
    echo "  2. Доступность сервера"
    exit 1
fi
