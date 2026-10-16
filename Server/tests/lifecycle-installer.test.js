const {test}=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs'),os=require('node:os'),path=require('node:path'),{execFileSync}=require('node:child_process');
function fixture(fail=false){
 const root=fs.mkdtempSync(path.join(os.tmpdir(),'flags-installer-')),pkg=path.join(root,'bundle'),api=path.join(root,'Flags','Server'),bin=path.join(root,'bin');
 for(const d of [pkg+'/Server',pkg+'/Server/lifecycle-assets',pkg+'/shared',api,bin])fs.mkdirSync(d,{recursive:true});
 fs.copyFileSync(path.join(__dirname,'../install-flags-experience.sh'),pkg+'/Server/install-flags-experience.sh');
 for(const file of ['server','engagement','notification-inbox','lifecycle','lifecycle-copy'])fs.writeFileSync(pkg+'/Server/'+file+'.js',"// new code\n");
 fs.writeFileSync(pkg+'/Server/config.json','{}');fs.writeFileSync(pkg+'/shared/languages.json','[]');
 fs.writeFileSync(api+'/server.js','// original code\n');fs.writeFileSync(api+'/config.json','{}');fs.writeFileSync(api+'/.env','EXISTING=preserve\n');
 fs.writeFileSync(api+'/db.js',"const fs=require('fs');exports.db={backup:p=>{fs.writeFileSync(p,'snapshot');return Promise.resolve()},close(){}};");
 fs.writeFileSync(bin+'/pm2',`#!/bin/bash\nif [ "$1" = jlist ]; then printf '%s' '${JSON.stringify([{name:'flags-api',pm2_env:{pm_cwd:api}}])}'; else printf '%s\\n' "$*" >> '${root}/pm2.log'; fi\n`,{mode:0o755});
 fs.writeFileSync(bin+'/curl',`#!/bin/bash\nprintf '%s\\n' "$*" >> '${root}/curl.log'\n${fail?`if [ -f '${root}/health-once' ]; then exit 22; fi\ntouch '${root}/health-once'`:''}\nprintf '{"ok":true}'\n`,{mode:0o755});
 return {root,api,pkg,run:(extra={})=>execFileSync('bash',[pkg+'/Server/install-flags-experience.sh'],{env:{...process.env,PATH:bin+':'+process.env.PATH,FLAGS_BACKUP_ROOT:root+'/backups',...extra},stdio:'pipe'}),cleanup:()=>fs.rmSync(root,{recursive:true,force:true})};
}
test('lifecycle installer resolves bundle root, backs up and restarts only Flags',()=>{
 const f=fixture();try{f.run();assert.equal(fs.readFileSync(f.api+'/server.js','utf8'),'// new code\n');
 const env=fs.readFileSync(f.api+'/.env','utf8');assert.ok(env.includes('EXISTING=preserve'));assert.ok(env.includes('LIFECYCLE_EMAILS_ENABLED=false'));assert.ok(env.includes('LIFECYCLE_REWARDS_ENABLED=true'));
 assert.equal(fs.readFileSync(f.root+'/pm2.log','utf8').trim(),'restart flags-api');
 const backup=fs.readdirSync(f.root+'/backups')[0];assert.equal(fs.readFileSync(f.root+'/backups/'+backup+'/duel.db','utf8'),'snapshot');
 }finally{f.cleanup()}
});
test('lifecycle installer restores previous code and settings after failed health check',()=>{
 const f=fixture(true);try{assert.throws(()=>f.run());assert.equal(fs.readFileSync(f.api+'/server.js','utf8'),'// original code\n');assert.equal(fs.readFileSync(f.api+'/.env','utf8'),'EXISTING=preserve\n');assert.equal(fs.readFileSync(f.root+'/pm2.log','utf8').trim(),'restart flags-api\nrestart flags-api');}finally{f.cleanup()}
});

test('explicit full rollout enables email for eligible subscribers only and removes holdout',()=>{
 const f=fixture();try{
 fs.mkdirSync(f.api+'/node_modules/dotenv',{recursive:true});fs.writeFileSync(f.api+'/node_modules/dotenv/index.js','exports.config=()=>({});');
 f.run({FLAGS_ENABLE_LIFECYCLE:'true',MAILGUN_API_KEY:'test-only',MAILGUN_DOMAIN:'example.test'});
 const env=fs.readFileSync(f.api+'/.env','utf8');assert.ok(env.includes('LIFECYCLE_EMAILS_ENABLED=true'));assert.ok(env.includes('LIFECYCLE_HOLDOUT_PERCENT=0'));
 }finally{f.cleanup()}
});
