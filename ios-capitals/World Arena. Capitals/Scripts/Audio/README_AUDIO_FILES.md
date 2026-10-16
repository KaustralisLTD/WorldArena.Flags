# 🎵 Реальные аудио файлы гимнов стран

## 📋 Обзор

Система загрузки и размещения реальных аудио файлов гимнов для всех 51 страны в приложении Flags World.

## 🚀 Быстрый старт

### Шаг 1: Загрузка гимнов

```bash
cd "World Arena. Flags/Scripts/Audio"
python3 download_all_anthems.py
```

Этот скрипт:
- ✅ Загрузит гимны из Wikimedia Commons (общественное достояние)
- ✅ Конвертирует их в формат M4A (AAC, 192kbps, 44.1kHz)
- ✅ Сохранит в папку `real_anthems_all/`
- ✅ Создаст манифест `manifest.json`

### Шаг 2: Загрузка на сервер

```bash
# Настроить SSH доступ в upload_anthems_to_server.sh
# Затем запустить:
./upload_anthems_to_server.sh
```

Или вручную:
```bash
scp real_anthems_all/*.m4a user@server:/var/www/flags.worldarena.games/anthems/
```

## 📁 Структура файлов

```
Scripts/Audio/
├── download_all_anthems.py      # Скрипт загрузки всех гимнов
├── upload_anthems_to_server.sh   # Скрипт загрузки на сервер
├── real_anthems_all/            # Папка с загруженными файлами
│   ├── anthem_at.m4a            # Австрия
│   ├── anthem_us.m4a            # США
│   ├── ...
│   └── manifest.json            # Манифест файлов
└── README_AUDIO_FILES.md        # Эта документация
```

## 🌐 Серверная структура

Файлы должны быть доступны по URL:
```
https://flags.worldarena.games/anthems/anthem_{code}.m4a
```

Примеры:
- `https://flags.worldarena.games/anthems/anthem_at.m4a` (Австрия)
- `https://flags.worldarena.games/anthems/anthem_pl.m4a` (Польша)
- `https://flags.worldarena.games/anthems/anthem_nl.m4a` (Нидерланды)

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
- **Длительность**: 1-3 минуты

### Размеры файлов
- **Средний размер**: 2-5 MB
- **Общий объем**: ~150-200 MB (51 страна)
- **Кэш**: Автоматическое управление iOS

## 📱 Использование в приложении

### Текущая реализация

Приложение использует `AudioManager` для:
1. Проверки локального кэша
2. Загрузки с сервера `https://flags.worldarena.games/anthems/`
3. Кэширования на устройстве
4. Воспроизведения через `AVAudioPlayer`

### Пример кода

```swift
// Воспроизвести гимн Польши
AudioManager.shared.playAnthem(for: "pl")

// Проверить состояние
@ObservedObject var audioManager = AudioManager.shared

if audioManager.isDownloading {
    ProgressView("Загрузка гимна...")
}

if audioManager.isPlaying {
    Button("Пауза") {
        audioManager.pauseAudio()
    }
}
```

## 🔄 Процесс работы

1. **Запрос**: `AudioManager.shared.playAnthem(for: "pl")`
2. **Проверка кэша**: Ищет `anthem_pl.m4a` в локальном кэше
3. **Загрузка**: Если нет - загружает с `https://flags.worldarena.games/anthems/anthem_pl.m4a`
4. **Сохранение**: Сохраняет в кэш для быстрого доступа
5. **Воспроизведение**: Запускает через `AVAudioPlayer`

## 🛠️ Разработка

### Добавление новой страны

1. Добавить URL в `ANTHEM_SOURCES` в `download_all_anthems.py`
2. Запустить скрипт загрузки
3. Загрузить файл на сервер
4. Обновить манифест

### Обновление существующего гимна

1. Заменить файл в `real_anthems_all/`
2. Загрузить на сервер (перезаписать)
3. Очистить локальный кэш (опционально)

## 🔒 Безопасность и лицензии

- ✅ Все гимны в **общественном достоянии** (Public Domain)
- ✅ Источники: **Wikimedia Commons** (CC0 лицензия)
- ✅ Исполнение: **United States Navy Band** (правительственная организация)
- ✅ Отсутствие авторских прав

## 📈 Статистика

После загрузки всех 51 гимна:
- **Общий размер**: ~150-200 MB
- **Средний размер файла**: 2-5 MB
- **Формат**: M4A (AAC, 192kbps)
- **Качество**: Высокое (стерео, 44.1kHz)

## 🆘 Решение проблем

### Файл не загружается
1. Проверить интернет соединение
2. Проверить сервер: `curl -I https://flags.worldarena.games/anthems/anthem_pl.m4a`
3. Очистить кэш: `AudioManager.shared.clearCache()`

### Ошибка воспроизведения
1. Проверить формат файла (должен быть M4A)
2. Проверить целостность файла
3. Очистить кэш и перезагрузить

### Медленная загрузка
1. Использовать кэш (файлы загружаются один раз)
2. Проверить скорость интернета
3. Оптимизировать размер файлов

## 📞 Дополнительная информация

- **Документация**: `ANTHEMS_SETUP.md`
- **Код**: `AudioManager.swift`
- **Скрипты**: `download_all_anthems.py`, `upload_anthems_to_server.sh`

---

**Версия**: 2.0  
**Дата**: 2025  
**Статус**: Готово к использованию
