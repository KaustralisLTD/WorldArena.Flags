#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./Scripts/deploy_legal_pages.sh root@your-server /var/www/worldarena.games
#
# It uploads:
#   privacy-policy/index.html  -> /privacy-policy/index.html
#   terms-of-use/index.html    -> /terms-of-use/index.html

SERVER="${1:-}"
REMOTE_ROOT="${2:-}"

if [[ -z "$SERVER" || -z "$REMOTE_ROOT" ]]; then
  echo "Usage: $0 <user@host> <remote_web_root>"
  echo "Example: $0 root@worldarena.games /var/www/worldarena.games"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

LOCAL_PRIVACY="$PROJECT_DIR/privacy-policy/index.html"
LOCAL_TERMS="$PROJECT_DIR/terms-of-use/index.html"

if [[ ! -f "$LOCAL_PRIVACY" || ! -f "$LOCAL_TERMS" ]]; then
  echo "Legal pages are missing. Expected:"
  echo "  $LOCAL_PRIVACY"
  echo "  $LOCAL_TERMS"
  exit 1
fi

echo "Uploading legal pages to $SERVER:$REMOTE_ROOT ..."
ssh "$SERVER" "mkdir -p '$REMOTE_ROOT/privacy-policy' '$REMOTE_ROOT/terms-of-use'"
scp "$LOCAL_PRIVACY" "$SERVER:$REMOTE_ROOT/privacy-policy/index.html"
scp "$LOCAL_TERMS" "$SERVER:$REMOTE_ROOT/terms-of-use/index.html"

echo "Done."
echo "Check:"
echo "  https://worldarena.games/privacy-policy.html"
echo "  https://worldarena.games/terms-of-use.html"
