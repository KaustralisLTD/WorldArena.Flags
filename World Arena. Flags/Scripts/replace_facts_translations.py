#!/usr/bin/env python3
"""Replace the 68-fact block in de/fr/it/pl/nl/pt-BR/es/uk/ca/zh with translated content.
   Run after write_facts_to_localizable.py. Uses facts_68_translations module if present."""
import os
import re

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BASE = os.path.join(SCRIPT_DIR, "..", "Resources")
LOCALES_TRANSLATE = ["de", "fr", "it", "pl", "nl", "pt-BR", "es", "uk", "ca", "zh"]

if SCRIPT_DIR not in __import__("sys").path:
    __import__("sys").path.insert(0, SCRIPT_DIR)
from facts_68_data import build_block

def remove_facts_block(content):
    """Remove the block from /* 68 interesting facts */ to last FACT_68_DESC."""
    start = content.find("/* 68 interesting facts */")
    if start == -1:
        return content, False
    # Find end: last line that matches "FACT_68_DESC"
    rest = content[start:]
    # Match up to and including the line with FACT_68_DESC
    m = re.search(r'(?s)(/\* 68 interesting facts \*/.*?"FACT_68_DESC" = "[^"]*";)\s*', rest)
    if not m:
        return content, False
    end_pos = start + len(m.group(1))
    new_content = content[:start].rstrip() + "\n" + content[end_pos:].lstrip()
    return new_content, True

def main():
    try:
        from facts_68_translations import TRANSLATIONS
    except ImportError:
        print("No facts_68_translations.py found. Create it with TRANSLATIONS[loc] = list of 68 (title, desc).")
        return
    for loc in LOCALES_TRANSLATE:
        if loc not in TRANSLATIONS:
            print("Skip %s (no translation)" % loc)
            continue
        facts = TRANSLATIONS[loc]
        if len(facts) != 68:
            print("Skip %s (expected 68, got %d)" % (loc, len(facts)))
            continue
        path = os.path.join(BASE, "%s.lproj" % loc, "Localizable.strings")
        if not os.path.isfile(path):
            print("Skip %s (no file)" % path)
            continue
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
        content, removed = remove_facts_block(content)
        if not removed:
            print("Skip %s (no fact block found)" % loc)
            continue
        block = build_block(facts)
        with open(path, "w", encoding="utf-8") as f:
            f.write(content.rstrip() + "\n" + block + "\n")
        print("Replaced 68 facts with translations for %s" % loc)

if __name__ == "__main__":
    main()
