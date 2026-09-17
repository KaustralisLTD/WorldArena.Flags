#!/bin/sh
# Xcode Cloud post-clone: SPM resolves during xcodebuild; ensure Firebase plist exists.
set -euo pipefail

cd "$CI_PRIMARY_REPOSITORY_PATH"

GS_DIR="World Arena. Flags"
GS_PLIST="$GS_DIR/GoogleService-Info.plist"
GS_EXAMPLE="$GS_DIR/GoogleService-Info.example.plist"
if [ ! -f "$GS_PLIST" ] && [ -f "$GS_EXAMPLE" ]; then
  echo "⚠️  GoogleService-Info.plist missing — copying from example for CI build"
  cp "$GS_EXAMPLE" "$GS_PLIST"
fi

echo "✅ ci_post_clone done (SPM deps, no CocoaPods)"
