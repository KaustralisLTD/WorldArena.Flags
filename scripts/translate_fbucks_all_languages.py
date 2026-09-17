#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Заполняет реальные переводы для fbucks.* во всех локалях на базе en.
Использует GoogleTranslator из deep-translator и сохраняет placeholders.
"""

from __future__ import annotations

import re
import time
from pathlib import Path

from deep_translator import MyMemoryTranslator
from deep_translator.exceptions import TooManyRequests

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / "World Arena. Flags" / "Resources"
EN_FILE = RES / "en.lproj" / "Localizable.strings"

KEY_RE = re.compile(r'^"(?P<key>fbucks\.[^"]+)"\s*=\s*"(?P<value>.*)";\s*$')
LINE_RE = re.compile(r'^"(?P<key>fbucks\.[^"]+)"\s*=\s*"(?P<value>.*)";\s*$', re.MULTILINE)

LANG_TO_MYMEMORY = {
    "ar": "arabic",
    "bn": "bengali",
    "ca": "catalan",
    "cs": "czech",
    "de": "german",
    "el": "greek",
    "es": "spanish",
    "fil": "filipino",
    "fr": "french",
    "hi": "hindi",
    "hu": "hungarian",
    "id": "indonesian",
    "it": "italian",
    "ja": "japanese",
    "ko": "korean",
    "nl": "dutch",
    "pl": "polish",
    "pt-BR": "portuguese brazil",
    "ro": "romanian",
    "ru": "russian",
    "sv": "swedish",
    "ta": "tamil india",
    "te": "telugu",
    "th": "thai",
    "tr": "turkish",
    "uk": "ukrainian",
    "vi": "vietnamese",
    "zh": "chinese simplified",
    "zh-Hant": "chinese traditional",
}


def escape_value(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


def read_en_fbucks_values() -> dict[str, str]:
    values: dict[str, str] = {}
    for line in EN_FILE.read_text(encoding="utf-8").splitlines():
        m = KEY_RE.match(line.strip())
        if m:
            values[m.group("key")] = m.group("value")
    if not values:
        raise RuntimeError("В en.lproj не найдено ключей fbucks.*")
    return values


def protect_placeholders(s: str) -> str:
    s = s.replace("%d%%", "__PERCENT_DBL__")
    s = s.replace("%d", "__PERCENT_D__")
    s = s.replace("%@", "__PERCENT_AT__")
    s = s.replace("→", "__ARROW_RIGHT__")
    return s


def restore_placeholders(s: str) -> str:
    s = s.replace("__ARROW_RIGHT__", "→")
    s = s.replace("__PERCENT_AT__", "%@")
    s = s.replace("__PERCENT_D__", "%d")
    s = s.replace("__PERCENT_DBL__", "%d%%")
    return s


def normalize_translated(s: str) -> str:
    restored = restore_placeholders(s)
    restored = restored.replace("F Bucks", "F-Bucks")
    return restored


def translate_with_retry(translator: MyMemoryTranslator, value: str) -> str:
    protected = protect_placeholders(value)
    attempts = 0
    while True:
        try:
            translated = translator.translate(protected)
            return normalize_translated(translated)
        except TooManyRequests:
            attempts += 1
            wait_s = min(10, 1.5 * attempts)
            time.sleep(wait_s)


def patch_locale_file(path: Path, translated_map: dict[str, str]) -> bool:
    original = path.read_text(encoding="utf-8")

    def repl(match: re.Match[str]) -> str:
        key = match.group("key")
        old_value = match.group("value")
        new_value = translated_map.get(key, old_value)
        return f'"{key}" = "{escape_value(new_value)}";'

    updated = LINE_RE.sub(repl, original)
    if updated == original:
        return False
    path.write_text(updated, encoding="utf-8")
    return True


def main() -> None:
    en_values = read_en_fbucks_values()
    changed = 0

    for lproj in sorted(RES.glob("*.lproj")):
        lang = lproj.name.replace(".lproj", "")
        if lang == "en":
            continue
        target = LANG_TO_MYMEMORY.get(lang)
        if not target:
            print(f"SKIP: no target for {lang}", flush=True)
            continue

        locale_file = lproj / "Localizable.strings"
        if not locale_file.is_file():
            continue

        translator = MyMemoryTranslator(source="english", target=target)
        translated_map: dict[str, str] = {}
        for key, value in en_values.items():
            translated_map[key] = translate_with_retry(translator, value)
            time.sleep(0.25)

        if patch_locale_file(locale_file, translated_map):
            print(f"OK: {locale_file.relative_to(ROOT)}", flush=True)
            changed += 1
        else:
            print(f"NO CHANGE: {locale_file.relative_to(ROOT)}", flush=True)

    print(f"Updated locales: {changed}")


if __name__ == "__main__":
    main()
