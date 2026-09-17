#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "World Arena. Flags" / "Resources"
# Unicode minus U+2212 (як у .strings)
OLD = '"Time intro penalty seconds fmt" = "\u2212%1$d";'
NEW = '"Time intro penalty seconds fmt" = "\u2212%1$d%2$@";'

for p in sorted(ROOT.glob("*.lproj/Localizable.strings")):
    t = p.read_text(encoding="utf-8")
    if OLD not in t:
        print("SKIP", p)
        continue
    p.write_text(t.replace(OLD, NEW), encoding="utf-8")
    print("OK", p.parent.name)
