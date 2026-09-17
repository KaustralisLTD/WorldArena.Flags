# Машинный перевод Localizable.strings

## Основной способ (с API, как у вас)

Нужен **именно** Python из venv, где стоит `deep-translator`. Системный `python3` без пакета **не переведёт** строки (или используйте только `--cache-only` при полном кэше).

```bash
python3 -m venv /tmp/l10n-venv
/tmp/l10n-venv/bin/pip install deep-translator
```

Пакетный прогон (полный путь к скрипту, `--batch 30 --sleep 0.35`):

```bash
PY="/tmp/l10n-venv/bin/python3"
SCR="/Volumes/spilberg/3.Work/9.iOS/Flags.World 06.04.2025/World Arena. Flags/Scripts/machine_translate_strings.py"
for t in id ko ro th ta te tr fil zh-Hant; do
  echo "========== $t =========="
  PYTHONUNBUFFERED=1 "$PY" "$SCR" --target "$t" --batch 30 --sleep 0.35 || exit 1
done
```

Кэш по умолчанию: `Scripts/.translate_cache_<target>.json` (пишется каждые `--batch` строк). Обрыв — снова та же команда по тому же языку, докачает.

`--limit 50` — тест на первых 50 уникальных строках.

## Почему «не работало» при другом запуске

| Было | Проблема |
|------|-----------|
| `python3 machine_translate_strings.py` без venv | Нет `deep_translator` → выход или только `--cache-only` |
| `--cache-only` для `fil` / `zh-Hant` при пустом кэше | Скрипт завершится с ошибкой «кэш неполный» — нужен прогон **без** `--cache-only` тем же `PY` |
| Дефолт `--batch` 25 vs ваши 30 | Только другая частота сохранения кэша; сейчас в скрипте дефолт **30** как у вас |

## Только сборка из кэша (без сети)

Если `.translate_cache_<target>.json` уже полный:

```bash
python3 /path/to/machine_translate_strings.py --target ro --cache-only
```

Здесь `deep_translator` не нужен.

## Xcode 16 и папка `Scripts`

Корень таргета — **синхронизируемая группа**: всё внутри `World Arena. Flags/` может попасть в **Copy Bundle Resources**.  
**Не держите `.venv-l10n` / `site-packages` внутри `World Arena. Flags/`** — иначе сотни файлов с одинаковыми именами (`LICENSE`, `__init__.py`…) дают *Multiple commands produce*.  
В проекте папка **`Scripts`** и файл **`Resources/Audio/.gitignore`** исключены из таргета через `PBXFileSystemSynchronizedBuildFileExceptionSet`. Venv — только **`/tmp/l10n-venv`** или **снаружи** `World Arena. Flags/`.

## `fil` и `zh-Hant`

В `machine_translate_strings.py` для Google задано: **`fil` → `tl`**, **`zh-Hant` → `zh-TW`** (`GOOGLE_TRANSLATE_TARGET`), папки по-прежнему `fil.lproj`, `zh-Hant.lproj`.

## После генерации

Пройтись по **streak / серия**, **Following / Friends**, **1st–3rd**, **F-Bucks**, бренду **World Arena Flags**, длинным HELP.
