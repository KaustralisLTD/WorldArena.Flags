# 📦 Установка зависимостей для загрузки гимнов

## Требования

Для загрузки реальных аудио файлов гимнов необходимо установить следующие инструменты:

### 1. ffmpeg (обязательно)

**macOS:**
```bash
brew install ffmpeg
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install ffmpeg
```

**Проверка:**
```bash
ffmpeg -version
```

### 2. yt-dlp (опционально, для загрузки с YouTube)

**Установка через pip:**
```bash
pip3 install yt-dlp
```

**Или через brew (macOS):**
```bash
brew install yt-dlp
```

**Проверка:**
```bash
yt-dlp --version
```

## Быстрая установка всех зависимостей

### macOS:
```bash
brew install ffmpeg yt-dlp
```

### Linux:
```bash
sudo apt-get update
sudo apt-get install ffmpeg python3-pip
pip3 install yt-dlp
```

## Использование

После установки зависимостей запустите скрипт загрузки:

```bash
cd "World Arena. Flags/Scripts/Audio"
python3 download_real_anthems_complete.py
```

Скрипт автоматически:
- Загрузит гимны из Wikimedia Commons (основной источник)
- При необходимости использует YouTube через yt-dlp
- Конвертирует все файлы в формат M4A (AAC, 192kbps)
- Создаст манифест со списком всех файлов

## Примечания

- **ffmpeg** обязателен для конвертации аудио файлов
- **yt-dlp** нужен только если некоторые гимны недоступны в Wikimedia Commons
- Все файлы будут сохранены в папку `real_anthems_complete/`
