# Game Center Achievements Automation

Автоматизация создания/обновления ачивок Game Center из таблицы:
- источник: `World Arena. Flags/Docs/GameCenter_Achievements_Table.md`
- генерация payload: `fastlane/game_center/achievements.json`
- отправка через App Store Connect API: `scripts/sync_gamecenter_achievements.py`

## 1) Подготовка API ключа App Store Connect

Нужны переменные окружения:

```bash
export APP_IDENTIFIER="World-Arena.-Flags"
export ASC_KEY_ID="KKAL3J897X"
export ASC_ISSUER_ID="7bcc1b1b-f871-4951-aadd-2d15c4fec061"
export ASC_KEY_FILEPATH="/Volumes/spilberg/3.Work/9.iOS/Flags.World 06.04.2025/World Arena. Flags/Docs/AuthKey_KKAL3J897X.p8"
```

## 2) Dry-run (без отправки)

```bash
cd "/Volumes/spilberg/3.Work/9.iOS/Flags.World 06.04.2025"
bundle exec fastlane ios sync_game_center_achievements
```

Что делает:
- парсит markdown-таблицу ачивок;
- пересобирает `fastlane/game_center/achievements.json`;
- проверяет, что будет создано/обновлено;
- готовит локализации и пути миниатюр.

## 3) Реальная отправка в ASC

```bash
bundle exec fastlane ios sync_game_center_achievements apply:true
```

Что отправляется:
- ачивки (`id`, `points`, `reusable`, `hidden`);
- локализации (`title`, `before earned`, `after earned`).

## 4) Миниатюры

В JSON автоматически добавляются:
- `asset_name`
- `asset_imageset_path`

Сейчас миниатюры валидируются по пути (наличие `*.imageset`), чтобы не пропустить отсутствующие ассеты.
Если Apple API в вашем аккаунте разрешит image upload endpoint для achievement images, в скрипт можно сразу добавить auto-upload на этом же пайплайне.

## 5) Файлы пайплайна

- `scripts/export_gamecenter_achievements_from_markdown.py`
- `scripts/sync_gamecenter_achievements.py`
- `fastlane/Fastfile` (lane `sync_game_center_achievements`)
- `fastlane/game_center/achievements.json` (генерируемый файл)
