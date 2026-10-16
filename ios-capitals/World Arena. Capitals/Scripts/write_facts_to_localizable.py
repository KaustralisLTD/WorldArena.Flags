#!/usr/bin/env python3
"""Append 68 fact keys (FACT_01_TITLE/DESC ... FACT_68) to each locale's Localizable.strings.
   Uses same 68 English keys; values are translated per locale. Run once."""
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BASE = os.path.join(SCRIPT_DIR, "..", "Resources")
LOCALES = ["en", "ru", "de", "fr", "it", "pl", "nl", "pt-BR", "es", "uk", "ca", "zh"]

# Import canonical data and builder
sys_path_save = os.path.abspath(SCRIPT_DIR)
if sys_path_save not in __import__("sys").path:
    __import__("sys").path.insert(0, SCRIPT_DIR)
from facts_68_data import FACTS_EN, FACTS_RU, build_block

# All locales: same 68 keys, translated values. Others use EN until we add translations.
ALL_FACTS = {"en": FACTS_EN, "ru": FACTS_RU}
for loc in ["de", "fr", "it", "pl", "nl", "pt-BR", "es", "uk", "ca", "zh"]:
    ALL_FACTS[loc] = ALL_FACTS.get(loc, FACTS_EN)

def main():
    assert len(FACTS_EN) == 68, "FACTS_EN must have 68 items, got %d" % len(FACTS_EN)
    assert len(FACTS_RU) == 68, "FACTS_RU must have 68 items, got %d" % len(FACTS_RU)
    for loc in LOCALES:
        path = os.path.join(BASE, "%s.lproj" % loc, "Localizable.strings")
        if not os.path.isfile(path):
            print("Skip %s (no file)" % path)
            continue
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
        if "FACT_01_TITLE" in content:
            print("Skip %s (already has facts)" % loc)
            continue
        facts = ALL_FACTS[loc]
        assert len(facts) == 68, "Locale %s has %d facts" % (loc, len(facts))
        block = build_block(facts)
        with open(path, "a", encoding="utf-8") as f:
            f.write(block)
        print("Appended 68 facts to %s" % loc)

if __name__ == "__main__":
    main()
