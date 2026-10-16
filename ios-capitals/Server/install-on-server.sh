#!/usr/bin/env bash
set -euo pipefail
api_dir=/opt/worldarena-capitals-api
archive_path=${1:?Pass the uploaded archive path}
if ss -ltnp 2>/dev/null | awk '$4 ~ /:3002$/ {found=1} END {exit !found}'; then
  if ! pm2 describe capitals-api >/dev/null 2>&1; then
    echo 'Port 3002 is already in use by another service; no installation performed.'
    exit 1
  fi
fi
mkdir -p "$api_dir"
if [[ -f "$api_dir/server.js" ]]; then
  tar -czf "/var/backups/capitals-api-$(date +%Y%m%d-%H%M%S).tar.gz" -C "$api_dir" --exclude=node_modules --exclude=data .
fi
tar -xzf "$archive_path" -C "$api_dir"
cd "$api_dir"
node_major=$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || true)
if [[ ! "$node_major" =~ ^(20|22|24)$ ]]; then
  mkdir -p runtime
  runtime_arch=$(uname -m)
  case "$runtime_arch" in x86_64) runtime_arch=x64 ;; aarch64) runtime_arch=arm64 ;; *) echo 'Unsupported server architecture'; exit 1 ;; esac
  curl --fail --silent --show-error https://nodejs.org/dist/latest-v22.x/SHASUMS256.txt -o /tmp/capitals-node-checksums.txt
  runtime_archive=$(awk -v suffix="-linux-$runtime_arch.tar.xz" '$2 ~ suffix "$" {print $2; exit}' /tmp/capitals-node-checksums.txt)
  [[ "$runtime_archive" =~ ^node-v22\.[0-9]+\.[0-9]+-linux-(x64|arm64)\.tar\.xz$ ]] || exit 1
  curl --fail --silent --show-error "https://nodejs.org/dist/latest-v22.x/$runtime_archive" -o "/tmp/$runtime_archive"
  (cd /tmp && awk -v name="$runtime_archive" '$2 == name' capitals-node-checksums.txt | sha256sum -c -)
  tar -xJf "/tmp/$runtime_archive" --strip-components=1 -C runtime
  export PATH="$api_dir/runtime/bin:$PATH"
fi
if [[ ! -f .env ]]; then cp .env.example .env; chmod 600 .env; fi
npm ci --omit=dev
node configure-existing-push.js
mkdir -p data
CAPITALS_NODE_PATH=$(command -v node) pm2 startOrReload ecosystem.config.js --only capitals-api --update-env
healthy=false
for attempt in $(seq 1 20); do
  if curl --fail --silent http://127.0.0.1:3002/api/v1/health; then healthy=true; break; fi
  sleep 1
done
if [[ "$healthy" != true ]]; then
  pm2 logs capitals-api --nostream --lines 30
  echo 'Capitals API failed its startup check; nginx was not changed.'
  exit 1
fi
printf '\nAPI running locally. Add nginx-capitals-api.conf only to the Capitals HTTPS server block, then nginx -t and reload.\n'
