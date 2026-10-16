#!/bin/bash
set -euo pipefail
base="$(cd "$(dirname "$0")/.." && pwd)"
bundle="$base/artifacts/flags-experience-server.tar.gz"
mkdir -p "$base/artifacts"
node - "$base" <<'JS'
const fs=require('fs'),path=require('path'),base=process.argv[2];
const langs=require(path.join(base,'shared/languages.json'));
for(const {code} of langs){const file=path.join(base,'Server/lifecycle-assets',`map-${code}-v1.jpg`);if(!fs.existsSync(file)||fs.statSync(file).size<10000)throw Error('Missing localized screenshot: '+code)}
JS
COPYFILE_DISABLE=1 tar -czf "$bundle" -C "$base" Server/server.js Server/db.js Server/push.js Server/mailgun.js Server/profile-page.js Server/streak-freezes.js Server/engagement.js Server/lifecycle.js Server/lifecycle-decision.js Server/lifecycle-copy.js Server/lifecycle-email.js Server/lifecycle-rich-content.js Server/lifecycle-facts.json Server/lifecycle-assets Server/lifecycle-locales.json Server/lifecycle-countries.json Server/notification-inbox.js Server/request-diagnostics.js Server/campaigns.json Server/progress-mail-locales.json Server/install-flags-experience.sh shared/site-locales.json shared/languages.json
remote="/tmp/flags-experience-$(date +%s)"
ssh root@157.230.11.51 "mkdir -p '$remote'"
scp "$bundle" "root@157.230.11.51:$remote/bundle.tar.gz"
ssh root@157.230.11.51 "tar -xzf '$remote/bundle.tar.gz' -C '$remote' && FLAGS_ENABLE_LIFECYCLE=true bash '$remote/Server/install-flags-experience.sh'"
