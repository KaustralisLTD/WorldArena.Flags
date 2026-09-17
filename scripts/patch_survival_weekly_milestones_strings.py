#!/usr/bin/env python3
"""Додати/оновити рядки тижневого Survival (сходинки 25–200) у всіх Localizable.strings."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / "World Arena. Flags" / "Resources"

KEY_BODY = "Survival weekly all milestones met body"
KEY_ALL = "Survival weekly reward all claimed"
KEY_HINT = "Survival weekly reward hint"

# en — дефолт для більшості мов
EN_BODY = "You've reached every weekly depth goal — up to 200 flags in one run. Brilliant!"
EN_ALL = "All weekly survival bonuses claimed (up to +4000 XP)."
EN_HINT = (
    "Each milestone — 25, 50, 100, then 200 flags in one run — gives +1000 XP once per week."
)

STRINGS: dict[str, tuple[str, str, str]] = {
    "en": (EN_BODY, EN_ALL, EN_HINT),
    "uk": (
        "Ти вже закрив усі тижневі цілі — до 200 прапорів за один забіг. Чудово!",
        "Усі тижневі бонуси отримано (до +4000 XP).",
        "За кожну сходинку — 25, 50, 100 і 200 прапорів за один забіг — +1000 XP раз на тиждень.",
    ),
    "ru": (
        "Вы выполнили все недельные цели — до 200 флагов за забег. Отлично!",
        "Все недельные бонусы получены (до +4000 XP).",
        "За каждую ступень — 25, 50, 100 и 200 флагов за один забег — +1000 XP раз в неделю.",
    ),
}


def esc(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def patch(path: Path, lang: str) -> bool:
    body, all_claimed, hint = STRINGS.get(lang, (EN_BODY, EN_ALL, EN_HINT))
    text = path.read_text(encoding="utf-8")

    if not re.search(r'^"Survival weekly best fmt"\s*=', text, flags=re.MULTILINE):
        print(f"SKIP no anchor: {path}")
        return False

    if not re.search(rf'^"{re.escape(KEY_BODY)}"\s*=', text, flags=re.MULTILINE):
        insert = (
            f'\n"{KEY_BODY}" = "{esc(body)}";\n'
            f'"{KEY_ALL}" = "{esc(all_claimed)}";'
        )
        text, n = re.subn(
            r'^("Survival weekly best fmt"\s*=\s*"[^"]*";)',
            rf"\1{insert}",
            text,
            count=1,
            flags=re.MULTILINE,
        )
        if n != 1:
            print(f"WARN insert {path} n={n}")
            return False
    else:
        text, _ = re.subn(
            rf'^"{re.escape(KEY_BODY)}"\s*=\s*".*";',
            f'"{KEY_BODY}" = "{esc(body)}";',
            text,
            flags=re.MULTILINE,
        )
        text, _ = re.subn(
            rf'^"{re.escape(KEY_ALL)}"\s*=\s*".*";',
            f'"{KEY_ALL}" = "{esc(all_claimed)}";',
            text,
            flags=re.MULTILINE,
        )

    text, nh = re.subn(
        rf'^"{re.escape(KEY_HINT)}"\s*=\s*".*";',
        f'"{KEY_HINT}" = "{esc(hint)}";',
        text,
        flags=re.MULTILINE,
    )
    if nh != 1:
        print(f"WARN hint {path} nh={nh}")
        return False

    path.write_text(text, encoding="utf-8")
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
