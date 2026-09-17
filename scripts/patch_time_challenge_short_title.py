#!/usr/bin/env python3
"""Добавить/обновить ключ Time Challenge short во всех Localizable.strings."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / "World Arena. Flags" / "Resources"
KEY = "Time Challenge short"

VALUES: dict[str, str] = {
    "en": "Time Challenge",
    "es": "Tiempo",
    "ru": "На время",
    "uk": "На час",
    "ca": "Temps",
    "fr": "Temps",
    "de": "Zeit",
    "it": "Tempo",
    "pt-BR": "Tempo",
    "nl": "Tijd",
    "pl": "Czas",
    "zh": "限时",
    "zh-Hant": "限時",
    "hi": "समय",
    "cs": "Čas",
    "sv": "Tid",
    "ja": "タイム",
    "ar": "وقت",
    "bn": "সময়",
    "hu": "Idő",
    "vi": "Thời gian",
    "el": "Χρόνος",
    "id": "Waktu",
    "ko": "시간",
    "ro": "Timp",
    "th": "เวลา",
    "ta": "நேரம்",
    "te": "సమయం",
    "tr": "Süre",
    "fil": "Oras",
}


def esc(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def patch(path: Path, lang: str) -> bool:
    if lang not in VALUES:
        print(f"SKIP {lang}: no mapping")
        return False
    val = esc(VALUES[lang])
    line = f'"{KEY}" = "{val}";'
    text = path.read_text(encoding="utf-8")

    if re.search(rf'^"{re.escape(KEY)}"\s*=', text, flags=re.MULTILINE):
        text_new, n = re.subn(
            rf'^"{re.escape(KEY)}"\s*=\s*".*";',
            line,
            text,
            flags=re.MULTILINE,
        )
        if n != 1:
            print(f"WARN replace {path}: n={n}")
            return False
    else:
        m = re.search(r'^"Time Challenge"\s*=\s*".*";', text, flags=re.MULTILINE)
        if not m:
            print(f"WARN no anchor Time Challenge in {path}")
            return False
        insert_at = m.end()
        text_new = text[:insert_at] + "\n" + line + text[insert_at:]

    path.write_text(text_new, encoding="utf-8")
    return True


def main() -> None:
    n = 0
    for folder in sorted(RES.glob("*.lproj")):
        lang = folder.name.replace(".lproj", "")
        p = folder / "Localizable.strings"
        if p.exists() and patch(p, lang):
            n += 1
            print(f"OK {lang}")
    print(f"done: {n}")


if __name__ == "__main__":
    main()
