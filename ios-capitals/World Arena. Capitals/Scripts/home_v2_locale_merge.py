#!/usr/bin/env python3
"""
Вставляет переводы главной (Quick start) в Localizable.strings после строки home.league_banner.cta.
Пропускает en/ru. С --force удаляет существующий блок /* Home layout (variant 2 / A-B) */ и вставляет заново.
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

RESOURCES = Path(__file__).resolve().parents[1] / "Resources"
DATA_DIR = Path(__file__).resolve().parent / "home_v2_locales"

CTA_RE = re.compile(r'("home\.league_banner\.cta"\s*=\s*"[^"]*";)')

BLOCK_RE = re.compile(
    r"\n/\* Home layout \(variant 2 / A-B\) \*/\n(?:\"home\.[^\"]+\"\s*=\s*\"(?:[^\"\\]|\\.)*\"\s*;\s*\n)+",
    re.MULTILINE,
)


def escape_ios(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def build_block(keys: list[str], trans: dict[str, str]) -> str:
    lines = ["", "/* Home layout (variant 2 / A-B) */"]
    for k in keys:
        if k not in trans:
            raise KeyError(f"Missing key {k} in locale bundle")
        lines.append(f'"{k}" = "{escape_ios(trans[k])}";')
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--force", action="store_true", help="Remove existing Home layout block before insert")
    args = parser.parse_args()

    order_path = DATA_DIR / "_order.json"
    if not order_path.exists():
        print("Missing", order_path)
        return 1
    keys: list[str] = json.loads(order_path.read_text(encoding="utf-8"))

    skip = {"en", "ru"}
    for json_path in sorted(DATA_DIR.glob("*.json")):
        if json_path.name.startswith("_"):
            continue
        loc = json_path.stem
        if loc in skip:
            continue
        strings_path = RESOURCES / f"{loc}.lproj" / "Localizable.strings"
        if not strings_path.exists():
            print("Skip missing file", strings_path)
            continue
        text = strings_path.read_text(encoding="utf-8")
        if args.force and BLOCK_RE.search(text):
            text = BLOCK_RE.sub("", text)
        elif not args.force and '"home.layout.section"' in text:
            print("OK skip (already merged)", loc)
            continue
        trans = json.loads(json_path.read_text(encoding="utf-8"))
        if len(trans) != len(keys):
            print(f"WARN {loc}: key count {len(trans)} expected {len(keys)}")
        m = CTA_RE.search(text)
        if not m:
            print("ERR no home.league_banner.cta in", loc)
            return 1
        block = build_block(keys, trans)
        insert_at = m.end()
        new_text = text[:insert_at] + block + text[insert_at:]
        strings_path.write_text(new_text, encoding="utf-8")
        print("Merged", loc, "(force)" if args.force else "")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
