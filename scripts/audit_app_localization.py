#!/usr/bin/env python3
"""Check every app catalog, including empty values and argument identity/width."""
import argparse
import collections
import json
import re
from pathlib import Path

from notification_catalog import ROOT, catalog

# Spaces are intentionally excluded: prose such as '80% de precisión' is not
# a printf format. All format strings used by this app omit the space flag.
FORMAT = re.compile(r'%%|%(?:(\d+)\$)?([-+0#]*\d*(?:\.\d+)?)(ll|l|z)?([@diufgs])')
MARKER = re.compile(r'ZXQ\d+QXZ|__\s*PERTINATE|__PERCENT|__ARROW')

def signature(value):
    arguments = collections.Counter()
    next_index = 1
    for match in FORMAT.finditer(value):
        if match[0] == '%%':
            arguments[('literal-percent', '', '', '')] += 1
            continue
        explicit, width, length, kind = match.groups()
        index = int(explicit) if explicit else next_index
        if not explicit:
            next_index += 1
        arguments[(str(index), width, length or '', kind)] += 1
    return arguments

def audit(root):
    paths = sorted(root.glob('*.lproj/Localizable.strings'))
    catalogs = {p.parent.name[:-6]: catalog(p) for p in paths}
    base = catalogs['en']
    errors = []
    rows = []
    for locale, values in catalogs.items():
        missing = sorted(base.keys() - values.keys())
        empty = sorted(k for k, value in values.items() if not value.strip())
        formats = sorted(k for k in base.keys() & values.keys()
                         if signature(base[k]) != signature(values[k]))
        markers = sorted(k for k, value in values.items() if MARKER.search(value))
        row = dict(locale=locale, missing=missing, empty=empty,
                   format_mismatches=formats, unresolved_markers=markers)
        rows.append(row)
        if missing or empty or formats or markers:
            errors.append(row)
    return dict(locales=len(catalogs), base_keys=len(base), errors=errors, languages=rows)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', type=Path, default=ROOT/'World Arena. Flags/Resources')
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    result = audit(args.root)
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n')
    print(json.dumps({k:v for k,v in result.items() if k!='languages'}, ensure_ascii=False))
    raise SystemExit(bool(result['errors']))
