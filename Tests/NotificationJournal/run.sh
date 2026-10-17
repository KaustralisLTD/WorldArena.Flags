#!/bin/bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
test_dir="$(mktemp -d /tmp/flags-journal-tests.XXXXXX)"
trap 'rm -rf "$test_dir"' EXIT
python3 - "$project_root" "$test_dir/main.swift" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
source = (root / 'World Arena. Flags/Services/NotificationService.swift').read_text()
helper = source[source.index('enum LegacyNotificationJournalMigration'):source.index('class NotificationService:')]
tests = (root / 'Tests/NotificationJournal/main.swift').read_text()
Path(sys.argv[2]).write_text('import Foundation\n' + helper + tests)
PY
xcrun swift -module-cache-path "$test_dir/cache" "$test_dir/main.swift"
