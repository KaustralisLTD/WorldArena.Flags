#!/bin/bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
test_dir="$(mktemp -d /tmp/flags-notification-tests.XXXXXX)"
trap 'rm -rf "$test_dir"' EXIT
app="$test_dir/NotificationLocalization.app/Contents"
mkdir -p "$app/MacOS" "$app/Resources"
cp -R "$project_root/World Arena. Flags/Resources/"*.lproj "$app/Resources/"
cat > "$app/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?><plist version="1.0"><dict><key>CFBundleExecutable</key><string>NotificationLocalization</string><key>CFBundleIdentifier</key><string>games.worldarena.notification-localization-tests</string><key>CFBundleDevelopmentRegion</key><string>en</string></dict></plist>
PLIST
python3 - "$project_root" "$test_dir/main.swift" <<'PY'
from pathlib import Path
import sys
root=Path(sys.argv[1]);source=(root/'World Arena. Flags/Services/NotificationService.swift').read_text()
model=source[source.index('struct AppNotificationLogItem:'):source.index('extension NotificationService {',source.index('struct AppNotificationLogItem:'))]
helper=(root/'World Arena. Flags/Services/NotificationTextLocalization.swift').read_text()
tests=(root/'Tests/NotificationLocalization/main.swift').read_text()
Path(sys.argv[2]).write_text(tests.replace('// PRODUCTION_MODEL',model).replace('// PRODUCTION_HELPER',helper))
PY
xcrun swiftc -module-cache-path "$test_dir/cache" "$test_dir/main.swift" -o "$app/MacOS/NotificationLocalization"
"$app/MacOS/NotificationLocalization"
