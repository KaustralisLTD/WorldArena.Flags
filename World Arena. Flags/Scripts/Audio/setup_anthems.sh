#!/bin/bash

# Главный скрипт для настройки системы гимнов
# Выполняет все необходимые шаги для загрузки и размещения гимнов

set -e  # Остановка при ошибке

echo "🎵 Настройка системы гимнов стран"
echo "=================================="

# Проверяем наличие необходимых инструментов
check_dependencies() {
    echo "🔍 Проверяю зависимости..."
    
    # Проверяем Python
    if ! command -v python3 &> /dev/null; then
        echo "❌ Python3 не найден. Установите Python 3.7+"
        exit 1
    fi
    
    # Проверяем pip
    if ! command -v pip3 &> /dev/null; then
        echo "❌ pip3 не найден. Установите pip"
        exit 1
    fi
    
    # Проверяем ffmpeg
    if ! command -v ffmpeg &> /dev/null; then
        echo "❌ ffmpeg не найден. Установите ffmpeg:"
        echo "   macOS: brew install ffmpeg"
        echo "   Ubuntu: sudo apt install ffmpeg"
        echo "   CentOS: sudo yum install ffmpeg"
        exit 1
    fi
    
    echo "✅ Все зависимости найдены"
}

# Устанавливаем Python зависимости
install_python_deps() {
    echo "📦 Устанавливаю Python зависимости..."
    pip3 install requests
    echo "✅ Зависимости установлены"
}

# Загружаем гимны
download_anthems() {
    echo "📥 Загружаю гимны стран..."
    
    if [ -f "download_real_anthems.py" ]; then
        python3 download_real_anthems.py
    else
        echo "❌ Файл download_real_anthems.py не найден"
        exit 1
    fi
}

# Проверяем результаты загрузки
check_download_results() {
    echo "📊 Проверяю результаты загрузки..."
    
    if [ ! -d "real_anthems" ]; then
        echo "❌ Папка real_anthems не создана"
        exit 1
    fi
    
    m4a_count=$(find real_anthems -name "*.m4a" | wc -l)
    echo "📁 Найдено $m4a_count M4A файлов"
    
    if [ $m4a_count -eq 0 ]; then
        echo "❌ M4A файлы не найдены"
        exit 1
    fi
    
    # Показываем статистику
    total_size=0
    for file in real_anthems/*.m4a; do
        if [ -f "$file" ]; then
            size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
            total_size=$((total_size + size))
        fi
    done
    
    total_size_mb=$((total_size / 1024 / 1024))
    echo "💾 Общий размер: ${total_size_mb} MB"
}

# Спрашиваем о загрузке на сервер
ask_upload_to_server() {
    echo ""
    echo "🌐 Загрузить гимны на сервер?"
    echo "   Это потребует SSH доступ к flags.worldarena.games"
    read -p "   (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        upload_to_server
    else
        echo "⏭️ Пропускаю загрузку на сервер"
        echo "   Файлы готовы в папке real_anthems/"
    fi
}

# Загружаем на сервер
upload_to_server() {
    echo "🚀 Загружаю гимны на сервер..."
    
    if [ -f "upload_to_server.sh" ]; then
        chmod +x upload_to_server.sh
        ./upload_to_server.sh
    else
        echo "❌ Файл upload_to_server.sh не найден"
        exit 1
    fi
}

# Создаем инструкции
create_instructions() {
    echo ""
    echo "📋 Инструкции по использованию:"
    echo "================================"
    echo ""
    echo "1. В приложении гимны будут автоматически загружаться с сервера"
    echo "2. Файлы кэшируются локально для быстрого доступа"
    echo "3. При отсутствии интернета включается симуляция воспроизведения"
    echo ""
    echo "📁 Локальные файлы: real_anthems/"
    echo "🌐 Сервер: https://flags.worldarena.games/anthems/"
    echo ""
    echo "🔧 Управление кэшем в коде:"
    echo "   AudioManager.shared.clearCache()     // Очистить кэш"
    echo "   AudioManager.shared.getCacheSize()   // Размер кэша"
    echo ""
    echo "✅ Настройка завершена!"
}

# Главная функция
main() {
    check_dependencies
    install_python_deps
    download_anthems
    check_download_results
    ask_upload_to_server
    create_instructions
}

# Запуск
main "$@"
