#!/bin/sh
# Xcode Cloud: после clone ставим CocoaPods (Pods/ в git не коммитим).
set -euo pipefail

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

cd "$CI_PRIMARY_REPOSITORY_PATH"

echo "🔧 Xcode Cloud: installing CocoaPods…"
if ! command -v pod >/dev/null 2>&1; then
  brew install cocoapods
fi

pod --version
echo "🔧 Xcode Cloud: pod install…"
pod install --repo-update

# Firebase plist не в git — подставляем example, чтобы Archive не падал на missing file.
GS_DIR="World Arena. Flags"
GS_PLIST="$GS_DIR/GoogleService-Info.plist"
GS_EXAMPLE="$GS_DIR/GoogleService-Info.example.plist"
if [ ! -f "$GS_PLIST" ] && [ -f "$GS_EXAMPLE" ]; then
  echo "⚠️  GoogleService-Info.plist missing — copying from example for CI build"
  cp "$GS_EXAMPLE" "$GS_PLIST"
fi

echo "✅ ci_post_clone done"
