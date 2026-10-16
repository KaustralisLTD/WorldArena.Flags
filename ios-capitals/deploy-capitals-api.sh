#!/usr/bin/env bash
set -euo pipefail
task_dir="$(cd "$(dirname "$0")" && pwd)"
archive="$task_dir/.build/capitals-api.tar.gz"
mkdir -p "$task_dir/.build"
COPYFILE_DISABLE=1 tar --no-xattrs -czf "$archive" -C "$task_dir/Server" --exclude=node_modules --exclude=data --exclude=.env --exclude='*.p8' --exclude='*.p12' .
scp "$archive" root@157.230.11.51:/tmp/capitals-api.tar.gz
scp "$task_dir/Server/install-on-server.sh" root@157.230.11.51:/tmp/install-capitals-api.sh
ssh root@157.230.11.51 'bash /tmp/install-capitals-api.sh /tmp/capitals-api.tar.gz && python3 /opt/worldarena-capitals-api/configure-capitals-nginx.py'
