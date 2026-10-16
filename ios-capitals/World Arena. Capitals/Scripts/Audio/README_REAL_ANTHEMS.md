# 🎵 Загрузка реальных аудио файлов гимнов

## 📋 Обзор

Этот скрипт загружает **реальные** аудио файлы национальных гимнов для всех 51 страны из открытых источников и загружает их на сервер.

## 🚀 Быстрый старт

### Шаг 1: Установка зависимостей

```bash
# macOS
brew install ffmpeg yt-dlp

# Linux
sudo apt-get install ffmpeg python3-pip
pip3 install yt-dlp
```

Подробнее: см. `INSTALL_DEPENDENCIES.md`

### Шаг 2: Загрузка гимнов

```bash
cd "World Arena. Flags/Scripts/Audio"
python3 download_real_anthems_complete.py
```

Скрипт:
- ✅ Загрузит гимны из **Wikimedia Commons** (основной источник, общественное достояние)
- ✅ При необходимости использует **YouTube** через yt-dlp
- ✅ Конвертирует все файлы в формат **M4A** (AAC, 192kbps, 44.1kHz, стерео)
- ✅ Сохранит в папку `real_anthems_complete/`
- ✅ Создаст манифест `manifest.json`

### Шаг 3: Загрузка на сервер

```bash
# Настроить SSH доступ в upload_anthems_to_server.sh (если нужно)
./upload_anthems_to_server.sh
```

Или вручную:
```bash
scp real_anthems_complete/*.m4a root@157.230.11.51:/var/www/flags.worldarena.games/anthems/
```

### Шаг 4: Проверка

```bash
python3 check_server_anthems.py
```

## 📁 Структура файлов

```
Scripts/Audio/
├── download_real_anthems_complete.py  # Главный скрипт загрузки
├── upload_anthems_to_server.sh        # Скрипт загрузки на сервер
├── check_server_anthems.py            # Проверка наличия файлов на сервере
├── real_anthems_complete/             # Папка с загруженными файлами
│   ├── anthem_at.m4a                  # Австрия
│   ├── anthem_us.m4a                  # США
│   ├── ...
│   └── manifest.json                  # Манифест файлов
├── INSTALL_DEPENDENCIES.md            # Инструкция по установке зависимостей
└── README_REAL_ANTHEMS.md             # Эта документация
```

## 🌐 Источники аудио

### 1. Wikimedia Commons (основной)
- ✅ Надежный источник
- ✅ Общественное достояние (Public Domain)
- ✅ Исполнение: United States Navy Band
- ✅ Формат: OGG → конвертируется в M4A

### 2. YouTube (резервный)
- Используется если файл недоступен в Wikimedia Commons
- Поиск по запросу: "{Country} national anthem {Name} official"
- Загрузка через yt-dlp

## 📊 Поддерживаемые страны (51)

### Европа (23 страны)
AT, DE, FR, IT, ES, GB, RU, PL, NL, BE, CH, SE, NO, DK, FI, PT, IE, CZ, HU, RO, BG, HR, RS

### Америка (6 стран)
US, CA, BR, MX, AR, CL

### Азия (16 стран)
CN, JP, KR, IN, TH, IL, SA, AE, IR, PK, BD, VN, ID, PH, MY, SG

### Африка (2 страны)
EG, ZA

### Океания (2 страны)
AU, NZ

### Другие (2 страны)
TR, GR

## 🔧 Технические характеристики

### Формат аудио
- **Контейнер**: M4A
- **Кодек**: AAC
- **Битрейт**: 192 kbps
- **Частота**: 44.1 kHz
- **Каналы**: Стерео
- **Длительность**: до 2 минут

### Размеры файлов
- **Средний размер**: 2-5 MB
- **Общий объем**: ~150-200 MB (51 страна)

## 📱 Использование в приложении

После загрузки на сервер, приложение автоматически:
1. Проверяет локальный кэш
2. Загружает с `https://flags.worldarena.games/anthems/anthem_{code}.m4a`
3. Кэширует на устройстве
4. Воспроизводит через `AVAudioPlayer`

## 🔄 Процесс работы скрипта

1. **Проверка зависимостей**: ffmpeg (обязательно), yt-dlp (опционально)
2. **Загрузка из Wikimedia Commons**: Для всех 51 страны
3. **Конвертация в M4A**: Через ffmpeg с параметрами качества
4. **Резервная загрузка с YouTube**: Если Wikimedia недоступен
5. **Создание манифеста**: JSON файл со списком всех файлов

## 🛠️ Решение проблем

### Ошибка: ffmpeg не найден
```bash
brew install ffmpeg  # macOS
```

### Ошибка: yt-dlp не найден
```bash
pip3 install yt-dlp  # или brew install yt-dlp
```

### Файл не загружается из Wikimedia
- Скрипт автоматически попробует YouTube (если yt-dlp установлен)
- Проверьте интернет соединение
- Некоторые файлы могут быть временно недоступны

### Ошибка конвертации
- Убедитесь что ffmpeg установлен: `ffmpeg -version`
- Проверьте что исходный файл загружен полностью

## 📈 Статистика

После успешной загрузки:
- **51 файл** в формате M4A
- **~150-200 MB** общий размер
- **100% покрытие** всех стран в приложении

## 🔒 Лицензии

- Все гимны в **общественном достоянии** (Public Domain)
- Источники: **Wikimedia Commons** (CC0 лицензия)
- Исполнение: **United States Navy Band** (правительственная организация)
- Отсутствие авторских прав

## 📞 Дополнительная информация

- **Установка зависимостей**: `INSTALL_DEPENDENCIES.md`
- **Проверка сервера**: `check_server_anthems.py`
- **Код приложения**: `AudioManager.swift`

---

**Версия**: 2.0  
**Дата**: 2025  
**Статус**: Готово к использованию
