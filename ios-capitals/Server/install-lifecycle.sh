#!/usr/bin/env bash
set -euo pipefail
umask 077
api_dir=/opt/worldarena-capitals-api
bundle_dir="$(cd "$(dirname "$0")" && pwd)"
backup="/var/backups/capitals-lifecycle-$(date +%Y%m%d-%H%M%S)"
[[ -f "$api_dir/server.js" ]] || { echo 'Existing Capitals API not found; no installation performed.'; exit 1; }
pm2 describe capitals-api >/dev/null
pm2 jlist | node -e 'let s="";process.stdin.on("data",d=>s+=d);process.stdin.on("end",()=>{const apps=JSON.parse(s).filter(p=>p.name==="capitals-api");if(apps.length!==1||apps[0].pm2_env.pm_cwd!=="/opt/worldarena-capitals-api")process.exit(1);})' 
if [[ -x "$api_dir/runtime/bin/node" ]]; then export PATH="$api_dir/runtime/bin:$PATH"; fi
mkdir -p "$backup/code" "$backup/shared" "$backup/assets"
cp "$api_dir/"*.js "$api_dir/"*.json "$backup/code/"
[[ ! -f "$api_dir/.env" ]] || cp "$api_dir/.env" "$backup/env"
[[ ! -d "$api_dir/shared" ]] || cp -a "$api_dir/shared/." "$backup/shared/"
[[ ! -d "$api_dir/lifecycle-assets" ]] || cp -a "$api_dir/lifecycle-assets/." "$backup/assets/"
(cd "$api_dir" && node -e 'const {db}=require("./db");db.backup(process.argv[1]).then(()=>db.close()).catch(e=>{console.error(e.message);process.exit(1)})' "$backup/capitals.db")
rollback() {
 cp "$backup/code/"*.js "$backup/code/"*.json "$api_dir/"
 [[ ! -f "$backup/env" ]] || cp "$backup/env" "$api_dir/.env"
 mkdir -p "$api_dir/shared" "$api_dir/lifecycle-assets"
 cp -a "$backup/shared/." "$api_dir/shared/"; cp -a "$backup/assets/." "$api_dir/lifecycle-assets/"
 pm2 restart capitals-api --update-env || true
 echo "Capitals update failed; previous code/settings restored. Backup: $backup" >&2
}
trap rollback ERR
# Reuse only the existing team's Mailgun transport if Capitals has none; preserve all Capitals-specific settings.
(cd "$api_dir" && node - "$api_dir/.env" <<'JS'
const fs=require('fs'),dotenv=require('dotenv'),cp=require('child_process'),path=require('path'),file=process.argv[2];
let text=fs.existsSync(file)?fs.readFileSync(file,'utf8'):'';const current=dotenv.parse(text);
let inherited={};
if(!current.MAILGUN_API_KEY||!current.MAILGUN_DOMAIN){
 const candidates=JSON.parse(cp.execFileSync('pm2',['jlist'],{encoding:'utf8'})).filter(p=>p.name==='flags-api');
 if(candidates.length===1){const source=path.join(candidates[0].pm2_env.pm_cwd,'.env');if(fs.existsSync(source))inherited=dotenv.parse(fs.readFileSync(source));}
}
function set(k,v){const re=new RegExp('^'+k+'=.*$','gm');text=re.test(text)?text.replace(re,k+'='+v):text+'\n'+k+'='+v+'\n';}
for(const k of ['MAILGUN_API_KEY','MAILGUN_DOMAIN','MAILGUN_EU'])if(!current[k]&&inherited[k]){current[k]=inherited[k];set(k,inherited[k]);}
if(!current.MAILGUN_API_KEY||!current.MAILGUN_DOMAIN)throw Error('Capitals Mailgun transport is missing; no activation performed');
if(!current.MAILGUN_FROM)set('MAILGUN_FROM','World Arena Capitals <noreply@'+current.MAILGUN_DOMAIN+'>');
for(const [k,v] of Object.entries({LIFECYCLE_EMAILS_ENABLED:'true',LIFECYCLE_REWARDS_ENABLED:'true',LIFECYCLE_HOLDOUT_PERCENT:'0'}))set(k,v);
fs.writeFileSync(file,text,{mode:0o600});
JS
)
for name in server.js session-boundary.js mailgun.js campaigns.json lifecycle.js lifecycle-decision.js lifecycle-copy.js lifecycle-email.js lifecycle-rich-content.js lifecycle-facts.json lifecycle-locales.json lifecycle-countries.json progress-mail-locales.json; do cp "$bundle_dir/$name" "$api_dir/$name"; done
mkdir -p "$api_dir/lifecycle-assets" "$api_dir/shared"
cp -a "$bundle_dir/lifecycle-assets/." "$api_dir/lifecycle-assets/"
cp "$bundle_dir/shared/site-locales.json" "$api_dir/shared/site-locales.json"
(cd "$api_dir" && node --check server.js && node --check lifecycle.js && node --check mailgun.js && node --check session-boundary.js)
pm2 restart capitals-api --update-env
for attempt in $(seq 1 15); do curl --fail --silent http://127.0.0.1:3002/api/v1/health && break; sleep 1; done
curl --fail --silent http://127.0.0.1:3002/api/v1/health
curl --fail --silent --output /dev/null http://127.0.0.1:3002/api/v1/lifecycle/assets/map-ru-v1
printf '\nCapitals lifecycle installed, emails enabled for subscribed players. Backup: %s\n' "$backup"
