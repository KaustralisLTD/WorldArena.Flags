# Инструкция по переходу на JSON

## ✅ Что уже сделано

1. ✅ Структуры `CountryData` и `LocalizedCountryData` теперь поддерживают `Codable`
2. ✅ `CountryDatabase` настроен на загрузку из JSON с fallback на Swift код
3. ✅ Создан метод `exportToJSON()` для экспорта данных

## 📝 Шаги для завершения миграции

### Шаг 1: Экспорт данных в JSON

Добавьте временно в любой метод запуска приложения (например, в `AppDelegate` или `SceneDelegate`):

```swift
// В методе application(_:didFinishLaunchingWithOptions:) или scene(_:willConnectTo:options:)
#if DEBUG
// Вызовите один раз для создания JSON файлов
CountryDatabase.exportToJSON()
#endif
```

**Важно:** Вызовите это только один раз! После создания файлов удалите эту строку.

### Шаг 2: Запустите приложение

Запустите приложение в симуляторе или на устройстве. JSON файлы будут созданы в Documents директории.

### Шаг 3: Найдите созданные файлы

Файлы будут в:
- Симулятор: `~/Library/Developer/CoreSimulator/Devices/[DEVICE_ID]/data/Containers/Data/Application/[APP_ID]/Documents/`
- Устройство: Используйте Xcode → Window → Devices and Simulators → Выберите устройство → Download Container

Или используйте Finder:
1. В Xcode: Window → Devices and Simulators
2. Выберите устройство/симулятор
3. Выберите приложение
4. Нажмите "Download Container"
5. Откройте контейнер → AppData → Documents

### Шаг 4: Добавьте JSON файлы в проект

1. Скопируйте 3 файла:
   - `countries_part1.json`
   - `countries_part2.json`
   - `countries_part3.json`

2. В Xcode:
   - Создайте папку `Resources` (если её нет)
   - Перетащите файлы в папку `Resources`
   - Убедитесь, что в диалоге "Add Files" выбрано:
     - ✅ "Copy items if needed"
     - ✅ Ваш Target в "Add to targets"

3. Проверьте Build Phases:
   - Project → Target → Build Phases → Copy Bundle Resources
   - Убедитесь, что все 3 JSON файла там есть

### Шаг 5: Проверьте работу

1. Удалите строку `CountryDatabase.exportToJSON()` из кода
2. Перезапустите приложение
3. В консоли должно появиться: `✅ Загружено X стран из JSON файлов`
4. Если видите `⚠️ Используется fallback на Swift код` - проверьте, что файлы добавлены в Bundle

### Шаг 6: (Опционально) Удалите старые файлы

После успешной миграции можно удалить:
- `CountryDatabasePart1.swift`
- `CountryDatabasePart2.swift`
- `CountryDatabasePart3.swift`

Но рекомендуется оставить их как резерв на некоторое время.

## 🎯 Преимущества

✅ **Нет проблем с синтаксисом Swift** - JSON валидируется автоматически
✅ **Легче редактировать** - можно использовать любой текстовый редактор
✅ **Проще версионировать** - JSON файлы легче читать в Git diff
✅ **Можно использовать внешние инструменты** - Excel, онлайн редакторы JSON и т.д.

## 🔧 Если что-то пошло не так

Если JSON файлы не загружаются:
1. Проверьте, что файлы добавлены в Bundle (Build Phases → Copy Bundle Resources)
2. Проверьте имена файлов (должны быть точно: `countries_part1.json`, без расширения в имени ресурса)
3. Приложение автоматически использует fallback на Swift код, так что всё будет работать

## 📞 Поддержка

Если возникли проблемы, проверьте:
- Консоль Xcode на наличие ошибок загрузки
- Что файлы действительно в Bundle (можно проверить через `Bundle.main.path(forResource:ofType:)`)
