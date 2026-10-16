#!/usr/bin/env python3
"""
Проверка полноты локализаций относительно английской базы.

Что проверяет:
1) Есть ли Localizable.strings для каждого языка.
2) Какие ключи отсутствуют в языке.
3) Какие ключи лишние (нет в английской базе).
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path


KEY_VALUE_RE = re.compile(r'^\s*"((?:[^"\\]|\\.)*)"\s*=\s*"(?:[^"\\]|\\.)*"\s*;\s*$')


def parse_strings(path: Path) -> set[str]:
    keys: set[str] = set()
    if not path.exists():
        return keys

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("//") or line.startswith("/*") or line.startswith("*"):
            continue
        match = KEY_VALUE_RE.match(line)
        if match:
            keys.add(match.group(1))
    return keys


def main() -> int:
    parser = argparse.ArgumentParser(description="Check iOS localization completeness.")
    parser.add_argument(
        "--root",
        type=Path,
        default=Path("World Arena. Flags/Resources"),
        help="Path to Resources folder with *.lproj directories",
    )
    parser.add_argument(
        "--base-locale",
        default="en",
        help="Base locale code used as canonical key set (default: en)",
    )
    parser.add_argument(
        "--locales",
        nargs="+",
        default=["ru", "uk", "es", "ca", "zh", "de", "fr", "it", "pt-BR", "pl", "nl"],
        help="Locales to verify against base",
    )
    args = parser.parse_args()

    resources_root: Path = args.root
    base_path = resources_root / f"{args.base_locale}.lproj" / "Localizable.strings"
    if not base_path.exists():
        print(f"ERROR: base file not found: {base_path}")
        return 2

    base_keys = parse_strings(base_path)
    if not base_keys:
        print(f"ERROR: no keys parsed from base file: {base_path}")
        return 2

    print(f"Base locale: {args.base_locale} ({len(base_keys)} keys)")
    print("-" * 60)

    has_issues = False
    for locale in args.locales:
        locale_path = resources_root / f"{locale}.lproj" / "Localizable.strings"
        if not locale_path.exists():
            has_issues = True
            print(f"[{locale}] MISSING FILE: {locale_path}")
            continue

        locale_keys = parse_strings(locale_path)
        missing = sorted(base_keys - locale_keys)
        extra = sorted(locale_keys - base_keys)

        status = "OK" if not missing else "MISSING"
        print(f"[{locale}] {status} | keys={len(locale_keys)} | missing={len(missing)} | extra={len(extra)}")

        if missing:
            has_issues = True
            preview = ", ".join(missing[:10])
            suffix = " ..." if len(missing) > 10 else ""
            print(f"  missing sample: {preview}{suffix}")

        if extra:
            preview = ", ".join(extra[:10])
            suffix = " ..." if len(extra) > 10 else ""
            print(f"  extra sample: {preview}{suffix}")

    print("-" * 60)
    if has_issues:
        print("Result: localization gaps found.")
        return 1

    print("Result: all locales are complete.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

