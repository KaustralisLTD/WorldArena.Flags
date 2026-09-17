#!/usr/bin/env python3
"""
Переводит строки главной (Quick start) с английского в JSON для merge-скрипта.
Требует: pip install deep-translator
Без сети — завершится с ошибкой; тогда используйте английский fallback (см. fill_home_v2_english_fallback.py).
"""
from __future__ import annotations

import json
import time
from pathlib import Path

try:
    from deep_translator import GoogleTranslator
except ImportError:
    raise SystemExit("pip install deep-translator")

ROOT = Path(__file__).resolve().parent
LOC = ROOT / "home_v2_locales"
KEYS: list[str] = json.loads((LOC / "_order.json").read_text(encoding="utf-8"))
EN: dict[str, str] = json.loads((LOC / "_en_source.json").read_text(encoding="utf-8"))

# Коды Google Translate (целевой язык)
TARGETS: dict[str, str] = {
    "ar": "ar",
    "bn": "bn",
    "ca": "ca",
    "cs": "cs",
    "de": "de",
    "el": "el",
    "es": "es",
    "fil": "tl",
    "fr": "fr",
    "hi": "hi",
    "hu": "hu",
    "id": "id",
    "it": "it",
    "ja": "ja",
    "ko": "ko",
    "nl": "nl",
    "pl": "pl",
    "pt-BR": "pt",
    "ro": "ro",
    "sv": "sv",
    "ta": "ta",
    "te": "te",
    "th": "th",
    "tr": "tr",
    "vi": "vi",
    "zh": "zh-CN",
    "zh-Hant": "zh-TW",
}


def main() -> int:
    for loc, gcode in TARGETS.items():
        out_path = LOC / f"{loc}.json"
        if out_path.exists():
            existing = json.loads(out_path.read_text(encoding="utf-8"))
            if len(existing) == len(KEYS) and all(k in existing for k in KEYS):
                print("skip (exists)", loc)
                continue
        translator = GoogleTranslator(source="en", target=gcode)
        result: dict[str, str] = {}
        for i, k in enumerate(KEYS):
            text = EN[k]
            try:
                result[k] = translator.translate(text)
            except Exception as e:
                print(loc, k, e)
                result[k] = text
            if i % 8 == 7:
                time.sleep(0.4)
            else:
                time.sleep(0.08)
        out_path.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
        print("wrote", loc)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
