#!/bin/bash
set -euo pipefail
umask 077
package_dir="$(cd "$(dirname "$0")/.." && pwd)"
meta="$(pm2 jlist | node -e 'let d="";process.stdin.on("data",x=>d+=x);process.stdin.on("end",()=>{const a=JSON.parse(d).filter(p=>["flags-api","duel-api"].includes(p.name));if(a.length!==1)process.exit(2);let p=a[0];if(!p.pm2_env.pm_cwd.toLowerCase().includes("flags")||p.pm2_env.pm_cwd.toLowerCase().includes("capitals"))process.exit(3);console.log(p.name+"\n"+p.pm2_env.pm_cwd)})')"
name="$(printf '%s\n' "$meta" | head -1)"
api_dir="$(printf '%s\n' "$meta" | tail -1)"
backup="${FLAGS_BACKUP_ROOT:-/var/backups}/flags-experience-$(date +%s)"
mkdir -p "$backup/code" "$backup/shared" "$backup/lifecycle-assets"
if [ -d "$api_dir/lifecycle-assets" ]; then cp -a "$api_dir/lifecycle-assets/." "$backup/lifecycle-assets/"; fi
cp -a "$api_dir/"*.js "$api_dir/"*.json "$backup/code/"
if [ -d "$(dirname "$api_dir")/shared" ]; then cp -a "$(dirname "$api_dir")/shared/." "$backup/shared/"; fi
(cd "$api_dir" && node -e 'const {db}=require("./db");db.backup(process.argv[1]).then(()=>db.close()).catch(e=>{console.error(e.message);process.exit(1)})' "$backup/duel.db")
rollback() {
 cp "$backup/code/"*.js "$backup/code/"*.json "$api_dir/"
 if [ -f "$backup/env" ]; then cp "$backup/env" "$api_dir/.env"; else rm -f "$api_dir/.env"; fi
 if [ -d "$backup/shared" ]; then cp -a "$backup/shared/." "$(dirname "$api_dir")/shared/"; fi
 if [ -d "$backup/lifecycle-assets" ]; then mkdir -p "$api_dir/lifecycle-assets"; cp -a "$backup/lifecycle-assets/." "$api_dir/lifecycle-assets/"; fi
 pm2 restart "$name" || true
 printf '\nUpdate failed; previous Flags code restored. Backup: %s\n' "$backup" >&2
}
if [ -f "$api_dir/.env" ]; then cp "$api_dir/.env" "$backup/env"; fi
trap rollback ERR
if ! grep -q '^PROGRESS_EMAILS_ENABLED=' "$api_dir/.env" 2>/dev/null; then
 printf '\nPROGRESS_EMAILS_ENABLED=false\n' >> "$api_dir/.env"
fi
for setting in LIFECYCLE_EMAILS_ENABLED=false LIFECYCLE_REWARDS_ENABLED=true; do
 key="${setting%%=*}"
 if ! grep -q "^${key}=" "$api_dir/.env" 2>/dev/null; then printf '\n%s\n' "$setting" >> "$api_dir/.env"; fi
done
if [ "${FLAGS_ENABLE_LIFECYCLE:-false}" = true ]; then
 (cd "$api_dir" && node -e 'require("dotenv").config({quiet:true});if(!process.env.MAILGUN_API_KEY||!process.env.MAILGUN_DOMAIN){console.error("Mailgun configuration missing; activation stopped");process.exit(1)}')
 node - "$api_dir/.env" <<'JS'
const fs=require('fs'),file=process.argv[2];let text=fs.readFileSync(file,'utf8');
for(const [key,value] of Object.entries({LIFECYCLE_EMAILS_ENABLED:'true',LIFECYCLE_HOLDOUT_PERCENT:'0',LIFECYCLE_REWARDS_ENABLED:'true'})){
 const re=new RegExp('^'+key+'=.*$','gm');text=re.test(text)?text.replace(re,key+'='+value):text+'\n'+key+'='+value+'\n';
}fs.writeFileSync(file,text,{mode:0o600});
JS
fi
cp "$package_dir/Server/"*.js "$package_dir/Server/"*.json "$api_dir/"
mkdir -p "$api_dir/lifecycle-assets"
cp -a "$package_dir/Server/lifecycle-assets/." "$api_dir/lifecycle-assets/"
mkdir -p "$(dirname "$api_dir")/shared"
cp "$package_dir/shared/"*.json "$(dirname "$api_dir")/shared/"
(cd "$api_dir" && node --check server.js && node --check engagement.js && node --check award-mail.js && node --check notification-inbox.js && node --check lifecycle.js && node --check lifecycle-copy.js)
pm2 restart "$name"
for attempt in 1 2 3 4 5; do
 if curl --fail --silent 'http://127.0.0.1:3001/api/v1/health'; then break; fi
 sleep 1
done
curl --fail --silent 'http://127.0.0.1:3001/api/v1/health'
curl --fail --silent 'http://127.0.0.1:3001/api/v1/campaigns'
curl --fail --silent --output /dev/null 'http://127.0.0.1:3001/api/v1/lifecycle/assets/map-ru-v1'
printf '\nFlags updated. Backup: %s\nProgress emails require Mailgun and each player’s explicit subscription.\n' "$backup"
