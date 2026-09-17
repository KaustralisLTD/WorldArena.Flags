# Fastlane metadata setup

## Что это дает
- Массовая отправка `What’s New` и `Promotional Text` в App Store Connect.
- Без ручного копирования для 30 языков.
- Без загрузки бинарника и скриншотов.

## 1) Один раз установить fastlane
```bash
cd "/Volumes/spilberg/3.Work/9.iOS/Flags.World 06.04.2025"
bundle install
```

## 2) Настроить переменные окружения
```bash
export APP_IDENTIFIER="World-Arena.-Flags"
export ASC_APPLE_ID="kaustralis.ltd@gmail.com"
export ASC_TEAM_ID="8QK64BF264"
```

## 3) Сгенерировать папки и шаблоны для всех локалей
```bash
bash ./scripts/setup_fastlane_metadata.sh 7.6 --overwrite
```

Скрипт создаст:
- `fastlane/metadata/<locale>/whats_new.txt`
- `fastlane/metadata/<locale>/promotional_text.txt`

На базе ваших `*.lproj` из `Resources`.
Тексты берутся из мастер-шаблонов:
- `fastlane/templates/master_whats_new.txt`
- `fastlane/templates/master_promotional_text.txt`

## 4) Отправить метаданные в App Store Connect
```bash
bundle exec fastlane ios release_metadata version:7.6
```

## Как обновлять в следующих версиях
1. Меняете тексты в `fastlane/metadata/*`.
2. Запускаете:
```bash
bundle exec fastlane ios release_metadata version:X.Y.Z
```
