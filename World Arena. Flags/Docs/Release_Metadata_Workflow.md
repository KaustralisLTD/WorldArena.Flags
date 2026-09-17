# Release Metadata Workflow

## Что присылать в чат на новый релиз

Скопируй и отправь:

```text
Новый релиз:
- Версия: X.Y
- Что нового (RU, финальный текст):
1) ...
2) ...
3) ...
- Нужно:
1) обновить release_notes/whats_new
2) перевести на все поддерживаемые языки metadata
3) проверить лимит promotional_text (170)
4) подготовить команды для загрузки в App Store Connect
```

## Что делаем каждый релиз

1. Обновляем русский текст `Что нового`.
2. Обновляем `promotional_text` (лимит 170 символов).
3. Генерируем переводы для всех поддерживаемых App Store Connect локалей.
4. Проверяем файлы в `fastlane/metadata/<locale>/`:
   - `release_notes.txt` (используется App Store как What's New)
   - `whats_new.txt` (локальная копия)
   - `promotional_text.txt`
5. Запускаем загрузку в App Store Connect.

## Команды запуска

```bash
cd "/Volumes/spilberg/3.Work/9.iOS/Flags.World 06.04.2025"

export ASC_APPLE_ID="kaustralis.ltd@gmail.com"
export ASC_TEAM_ID="8QK64BF264"
export APP_IDENTIFIER="World-Arena.-Flags"
export FASTLANE_SKIP_UPDATE_CHECK=1
export FASTLANE_HIDE_CHANGELOG=1
```

После обновления текстов:

```bash
python3 "./scripts/translate_metadata_blocks.py" X.Y
bundle exec fastlane ios release_metadata version:X.Y --verbose
```

## Важно

- Для поля **What's New** fastlane использует `release_notes.txt`.
- `promotional_text.txt` должен быть не длиннее 170 символов.
- Не прерывать fastlane (`Ctrl+C`) во время загрузки.

## Что НЕ запускать перед публикацией

Не запускать:

```bash
bash ./scripts/setup_fastlane_metadata.sh X.Y --overwrite
```

Этот флаг может перезаписать локали шаблонным текстом.

## Быстрая проверка успешной загрузки

В конце лога должно быть:

- `fastlane.tools finished successfully`

и в App Store Connect обновятся:

- Promotional Text
- What's New (release notes)
