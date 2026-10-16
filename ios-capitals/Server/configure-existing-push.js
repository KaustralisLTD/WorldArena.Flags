const fs=require('node:fs');
const {execFileSync}=require('node:child_process');
const file='.env';
let content=fs.readFileSync(file,'utf8');
try {
  const apps=JSON.parse(execFileSync('pm2',['jlist'],{encoding:'utf8',stdio:['ignore','pipe','ignore']}));
  const candidates=apps.filter(a=>a.name==='flags-api' || a.name==='duel-api' || a.pm2_env?.pm_cwd==='/var/www/flags.worldarena.games/duel-api').map(a=>{
    const e=a.pm2_env || {};
    const envFile=require('node:path').join(e.pm_cwd || '', '.env');
    const local=fs.existsSync(envFile) ? require('dotenv').parse(fs.readFileSync(envFile)) : {};
    return {...e,...local};
  });
  const source=candidates.find(e=>e.APNS_TEAM_ID==='8QK64BF264' && e.APNS_KEY_ID && e.APNS_KEY_P8_PATH && fs.existsSync(e.APNS_KEY_P8_PATH));
  if(source) {
    for(const key of ['APNS_KEY_ID','APNS_TEAM_ID','APNS_KEY_P8_PATH']) {
      const existing=content.match(new RegExp('^'+key+'=(.*)$','m'));
      if(!existing || !existing[1].trim()) {
        content=content.replace(new RegExp('^'+key+'=.*$','m'),'');
        content+='\n'+key+'='+JSON.stringify(source[key]);
      }
    }
    console.log('Existing Apple team push key configured for the separate Capitals topic.');
  } else console.log('APNs key not found in PM2; push configuration requires the existing key path.');
  const mail=candidates.find(e=>e.MAILGUN_API_KEY && e.MAILGUN_DOMAIN);
  if(mail) for(const key of ['MAILGUN_API_KEY','MAILGUN_DOMAIN','MAILGUN_EU']) {
    if(!mail[key]) continue;
    const existing=content.match(new RegExp('^'+key+'=(.*)$','m'));
    if(!existing || !existing[1].trim()) {
      content=content.replace(new RegExp('^'+key+'=.*$','m'),'');
      content+='\n'+key+'='+JSON.stringify(mail[key]);
    }
  }
  fs.writeFileSync(file,content+'\n',{mode:0o600});
  fs.chmodSync(file,0o600);
} catch {console.log('Could not inspect existing push configuration; Capitals can run without push.');}
