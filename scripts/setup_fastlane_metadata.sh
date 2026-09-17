#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RES_DIR="$ROOT_DIR/World Arena. Flags/Resources"
META_DIR="$ROOT_DIR/fastlane/metadata"
TEMPLATES_DIR="$ROOT_DIR/fastlane/templates"
VERSION="${1:-}"
OVERWRITE="${2:-}"

if [[ -z "$VERSION" ]]; then
  echo "Usage: bash ./scripts/setup_fastlane_metadata.sh <version> [--overwrite]"
  exit 1
fi

mkdir -p "$META_DIR"

MASTER_WHATS_NEW="$TEMPLATES_DIR/master_whats_new.txt"
MASTER_PROMO="$TEMPLATES_DIR/master_promotional_text.txt"

if [[ ! -f "$MASTER_WHATS_NEW" || ! -f "$MASTER_PROMO" ]]; then
  echo "Missing master templates in $TEMPLATES_DIR"
  exit 1
fi

map_locale() {
  local code="$1"
  case "$code" in
    en) echo "en-US" ;;
    zh) echo "zh-Hans" ;;
    de) echo "de-DE" ;;
    es) echo "es-ES" ;;
    fr) echo "fr-FR" ;;
    nl) echo "nl-NL" ;;
    ar) echo "ar-SA" ;;
    bn|fil|ta|te) echo "" ;; # not supported as App Store metadata locales
    *) echo "$code" ;;
  esac
}

while IFS= read -r dir_name; do
  raw="${dir_name%.lproj}"
  locale="$(map_locale "$raw")"
  if [[ -z "$locale" ]]; then
    continue
  fi
  target="$META_DIR/$locale"
  mkdir -p "$target"

  whats_new="$target/whats_new.txt"
  release_notes="$target/release_notes.txt"
  promo="$target/promotional_text.txt"

  if [[ "$OVERWRITE" == "--overwrite" || ! -f "$whats_new" ]]; then
    sed "s/{{VERSION}}/$VERSION/g" "$MASTER_WHATS_NEW" > "$whats_new"
  fi
  if [[ "$OVERWRITE" == "--overwrite" || ! -f "$release_notes" ]]; then
    cp "$whats_new" "$release_notes"
  fi

  if [[ "$OVERWRITE" == "--overwrite" || ! -f "$promo" ]]; then
    cp "$MASTER_PROMO" "$promo"
  fi
done < <(ls -1 "$RES_DIR" | awk '/\.lproj$/')

echo "Metadata scaffold ready at: $META_DIR"
