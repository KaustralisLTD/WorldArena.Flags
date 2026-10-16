#!/bin/bash
# Скрипт для очистки кэша Xcode

echo "🧹 Очистка кэша Xcode..."

# Очищаем DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/World_Arena._Flags-*

# Очищаем модули
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex

echo "✅ Кэш очищен"
echo ""
echo "Теперь в Xcode:"
echo "1. Product → Clean Build Folder (Shift+Cmd+K)"
echo "2. Закройте и откройте проект заново"
echo "3. Product → Build (Cmd+B)"
