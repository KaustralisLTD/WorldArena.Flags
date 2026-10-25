#!/usr/bin/env python3
"""Check saved AI review coverage against the current catalog values.

Hashes establish which exact text was reviewed, not linguistic correctness.
"""
import hashlib
import json
from notification_catalog import ROOT, catalog


def audit():
    ledger = json.loads((ROOT / 'docs/app-localization-editorial-progress.json').read_text())
    rows = []
    errors = []
    total = reviewed = changed = 0
    for path in sorted((ROOT / 'World Arena. Flags/Resources').glob('*.lproj/Localizable.strings')):
        locale = path.parent.name[:-6]
        values = catalog(path)
        record = ledger['languages'].get(locale, {})
        hashes = record.get('reviewed', {})
        pending = [key for key, value in values.items()
                   if hashes.get(key) != hashlib.sha256(value.encode()).hexdigest()]
        obsolete = sorted(hashes.keys() - values.keys())
        stale_changes = [key for key, edit in record.get('changes', {}).items()
                         if values.get(key) != edit['after']]
        count = len(values) - len(pending)
        total += len(values)
        reviewed += count
        changed += len(record.get('changes', {}))
        rows.append(dict(locale=locale, entries=len(values), reviewed=count, pending=len(pending)))
        if pending or obsolete or stale_changes or record.get('status') != 'complete':
            errors.append(dict(locale=locale, pending=pending, obsolete=obsolete,
                               stale_changes=stale_changes))
        if record.get('total') != len(values) or record.get('pending_count') != len(pending):
            errors.append(dict(locale=locale, error='Inconsistent recorded totals'))
    expected = dict(catalog_entries=total, reviewed_entries=reviewed, changed_entries=changed)
    if any(ledger.get(key) != value for key, value in expected.items()):
        errors.append(dict(error='Inconsistent summary totals', expected=expected))
    if ledger.get('status') != 'complete':
        errors.append(dict(error='Editorial review is not marked complete'))
    return dict(**expected, languages=rows, errors=errors)


if __name__ == '__main__':
    result = audit()
    print(json.dumps(result, ensure_ascii=False, indent=2))
    raise SystemExit(bool(result['errors']))
