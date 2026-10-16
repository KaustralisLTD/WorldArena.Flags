#!/usr/bin/env bash
set -euo pipefail
task_dir="$(cd "$(dirname "$0")" && pwd)"
archive="$task_dir/.build/capitals-lifecycle.tar.gz"
mkdir -p "$task_dir/.build"
COPYFILE_DISABLE=1 tar --no-xattrs -czf "$archive" -C "$task_dir/Server" server.js session-boundary.js mailgun.js campaigns.json lifecycle.js lifecycle-decision.js lifecycle-copy.js lifecycle-email.js lifecycle-rich-content.js lifecycle-facts.json lifecycle-locales.json lifecycle-countries.json progress-mail-locales.json lifecycle-assets shared/site-locales.json install-lifecycle.sh
remote="/tmp/capitals-lifecycle-$(date +%s)"
ssh root@157.230.11.51 "mkdir -p '$remote'"
scp "$archive" "root@157.230.11.51:$remote/bundle.tar.gz"
ssh root@157.230.11.51 "tar -xzf '$remote/bundle.tar.gz' -C '$remote' && bash '$remote/install-lifecycle.sh'"
