#!/usr/bin/env python3
"""Копирует английские строки Quick start в JSON для всех локалей (кроме uk — уже в strings; en/ru пропуск)."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
LOC = ROOT / "home_v2_locales"
KEYS: list[str] = json.loads((LOC / "_order.json").read_text(encoding="utf-8"))
EN = json.loads((LOC / "_en_source.json").read_text(encoding="utf-8"))

LOCALES = [
    "ar",
    "bn",
    "ca",
    "cs",
    "de",
    "el",
    "es",
    "fil",
    "fr",
    "hi",
    "hu",
    "id",
    "it",
    "ja",
    "ko",
    "nl",
    "pl",
    "pt-BR",
    "ro",
    "sv",
    "ta",
    "te",
    "th",
    "tr",
    "vi",
    "zh",
    "zh-Hant",
]


def main() -> int:
    for loc in LOCALES:
        dst = LOC / f"{loc}.json"
        dst.write_text(json.dumps(EN, ensure_ascii=False, indent=2), encoding="utf-8")
        print("wrote en fallback", loc)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
