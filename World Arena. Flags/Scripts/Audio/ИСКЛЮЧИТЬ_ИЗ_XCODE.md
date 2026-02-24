# Исключение файлов гимнов из Xcode проекта

## Проблема

Xcode пытается включить файлы гимнов в бандл приложения, но они должны загружаться с сервера.

## Решение

### Вариант 1: Через Xcode (рекомендуется)

1. Откройте проект в Xcode
2. Выберите папку `Scripts/Audio/real_anthems_complete/` в навигаторе проекта
3. В правой панели (File Inspector) найдите "Target Membership"
4. Снимите галочку с "World Arena. Flags" для всех файлов .m4a и manifest.json
5. Повторите для других папок с гимнами:
   - `Scripts/Audio/real_anthems_ready/`
   - `Scripts/Audio/real_anthems_all/`
   - `Scripts/Audio/real_anthems_v2/`

### Вариант 2: Переместить файлы за пределы проекта

```bash
# Переместить папки с гимнами за пределы проекта
cd "/Volumes/spilberg/3.Work/9.iOS/Flags.World 06.04.2025"
mv "World Arena. Flags/Scripts/Audio/real_anthems_complete" "Scripts/Audio/"
mv "World Arena. Flags/Scripts/Audio/real_anthems_ready" "Scripts/Audio/"
```

### Вариант 3: Удалить файлы из проекта (если они уже на сервере)

Если файлы уже загружены на сервер, можно удалить их из проекта:

```bash
cd "/Volumes/spilberg/3.Work/9.iOS/Flags.World 06.04.2025/World Arena. Flags/Scripts/Audio"
rm -rf real_anthems_complete/
rm -rf real_anthems_ready/
rm -rf real_anthems_all/
rm -rf real_anthems_v2/
```

## Важно

Файлы гимнов **НЕ должны** быть в бандле приложения, так как:
- Они загружаются с сервера при первом воспроизведении
- Кэшируются локально на устройстве
- Размер бандла будет слишком большим (~150-200 MB)
