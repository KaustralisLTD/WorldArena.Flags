#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Добавляет Survival result depth progress fmt и переводы Time is up во все .lproj."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "World Arena. Flags" / "Resources"

DEPTH_KEY = '"Survival result depth progress fmt"'
DEPTH_LINE_EN = '"Survival result depth progress fmt" = "%1$d / %2$d";'

TIME_UP = {
    "en": "Time's up",
    "ar": "انتهى الوقت",
    "bn": "সময় শেষ",
    "ca": "S'ha acabat el temps",
    "cs": "Čas vypršel",
    "de": "Zeit ist um",
    "el": "Τέλος χρόνου",
    "es": "Se acabó el tiempo",
    "fil": "Oras na",
    "fr": "Temps écoulé",
    "hi": "समय समाप्त",
    "hu": "Lejárt az idő",
    "id": "Waktu habis",
    "it": "Tempo scaduto",
    "ja": "時間切れ",
    "ko": "시간 종료",
    "nl": "Tijd is om",
    "pl": "Czas minął",
    "pt-BR": "Acabou o tempo",
    "ro": "Timpul a expirat",
    "ru": "Время вышло",
    "sv": "Tiden är ute",
    "ta": "நேரம் முடிந்தது",
    "te": "సమయం అయిపోయింది",
    "th": "หมดเวลา",
    "tr": "Süre doldu",
    "uk": "Час вичерпано",
    "vi": "Hết giờ",
    "zh": "时间到",
    "zh-Hant": "時間到",
}


def esc(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def main() -> None:
    for lproj in sorted(ROOT.glob("*.lproj")):
        path = lproj / "Localizable.strings"
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        lang = lproj.name.replace(".lproj", "")
        changed = False

        if DEPTH_KEY not in text:
            if not text.endswith("\n"):
                text += "\n"
            text += "\n" + DEPTH_LINE_EN + "\n"
            changed = True

        tu = TIME_UP.get(lang, TIME_UP["en"])
        pat = re.compile(r'^"Time is up"\s*=\s*"[^"]*";', re.MULTILINE)
        new_line = f'"Time is up" = "{esc(tu)}";'
        text2, n = pat.subn(new_line, text, count=1)
        if n:
            text = text2
            changed = True

        if changed:
            path.write_text(text, encoding="utf-8")
            print("Patched", path.relative_to(ROOT))


if __name__ == "__main__":
    main()
