# 🚀 Быстрый старт системы гимнов

## Установка и настройка

### 1. Запуск автоматической настройки
```bash
cd "World Arena. Flags/Resources/Audio"
./setup_anthems.sh
```

Этот скрипт автоматически:
- ✅ Проверит зависимости (Python3, pip3, ffmpeg)
- ✅ Установит необходимые пакеты
- ✅ Загрузит гимны из общедоступных источников
- ✅ Конвертирует в M4A формат
- ✅ Предложит загрузить на сервер

### 2. Ручная установка (если автоматическая не работает)

#### Установка зависимостей:
```bash
# macOS
brew install ffmpeg python3

# Ubuntu/Debian
sudo apt update
sudo apt install ffmpeg python3 python3-pip

# CentOS/RHEL
sudo yum install ffmpeg python3 python3-pip
```

#### Установка Python пакетов:
```bash
pip3 install requests
```

#### Загрузка гимнов:
```bash
python3 download_real_anthems.py
```

#### Загрузка на сервер (опционально):
```bash
./upload_to_server.sh
```

## Результат

После выполнения у вас будет:
- 📁 Папка `real_anthems/` с M4A файлами гимнов
- 🌐 Гимны на сервере (если выбрана загрузка)
- 📱 Автоматическая работа в приложении

## Проверка

### Локальные файлы:
```bash
ls -la real_anthems/*.m4a
```

### Сервер (если загружено):
```bash
curl -I https://flags.worldarena.games/anthems/anthem_ru.m4a
```

## Использование в приложении

Гимны автоматически загружаются при первом воспроизведении:

```swift
// Воспроизведение гимна России
AudioManager.shared.playAnthem(for: "ru")

// Остановка
AudioManager.shared.stopAudio()
```

## Устранение проблем

### Ошибка "ffmpeg не найден":
```bash
# macOS
brew install ffmpeg

# Ubuntu
sudo apt install ffmpeg
```

### Ошибка "Python не найден":
```bash
# macOS
brew install python3

# Ubuntu
sudo apt install python3
```

### Ошибка загрузки:
- Проверьте интернет соединение
- Попробуйте позже (серверы могут быть перегружены)
- Используйте VPN если есть блокировки

### Ошибка загрузки на сервер:
- Проверьте SSH ключи
- Убедитесь в доступе к серверу
- Проверьте права доступа

## Поддержка

- 📖 Полная документация: `README_ANTHEMS.md`
- 🔧 Код: `AudioManager.swift`
- 📁 Файлы: `real_anthems/`
