const {test}=require('node:test');
const assert=require('node:assert/strict');
const Database=require('better-sqlite3');
const engagement=require('../engagement');
const copies=require('../progress-mail-locales.json');
test('all 30 languages render escaped statistics, correct accuracy and RTL',()=>{
 assert.equal(Object.keys(copies).length,30);
 for(const lang of Object.keys(copies)) {
  const report=engagement.render({locale:lang,username:'<script>alert(1)</script>',games:10,answers:100,correct:90,previous:{answers:100,correct:80},wins:8,duels:10,profileURL:'https://flags.worldarena.games/profile/AB123',unsubscribeURL:'https://flags.worldarena.games/api/v1/progress-mail/preferences/token'});
  assert.ok(report.html.includes('80% → 90%'));
  assert.ok(report.html.includes('8 / 10'));
  assert.ok(!report.html.includes('<script>'));
  assert.ok(report.html.includes(`lang="${lang}"`));
  assert.ok(report.text.includes('profile/AB123'));
 }
 assert.equal(engagement.locale('zh-TW'),'zh-Hant');
 assert.equal(engagement.accuracy({answers:0,correct:0}),null);
 assert.deepEqual([9,10,24,25,49,50,99,100].map(engagement.milestone),[0,10,10,25,25,50,50,100]);
});
test('email settings require authentication, validate progress and preserve unsubscribe',()=>{
 const db=new Database(':memory:');
 db.exec("CREATE TABLE users(username TEXT PRIMARY KEY,email TEXT,is_registered INTEGER,display_name TEXT,friend_code TEXT); INSERT INTO users VALUES('alice','alice@example.invalid',1,'Alice','AB123')");
 db.exec("CREATE TABLE duel_challenges(status TEXT,challenger_id TEXT,opponent_id TEXT)");
 const routes=new Map();const app={get:(p,h)=>routes.set('GET '+p,h),post:(p,h)=>routes.set('POST '+p,h)};
 engagement.install(app,{db},req=>req.headers.authorization==='Bearer valid'?{username:'alice'}:null,()=>{throw Error('must never send during tests')});
 function call(method,path,body={},headers={},params={}) {const res={code:200,status(c){this.code=c;return this},json(x){this.body=x;return this},type(){return this},send(x){this.body=x;return this},sendStatus(c){this.code=c;return this},set(){return this}};routes.get(method+' '+path)({body,headers,params},res);return res;}
 const p='/api/v1/progress-mail',body={enabled:true,locale:'ru',games:10,answers:100,correct:90};
 assert.equal(call('POST',p,body).code,401);
 assert.equal(call('POST',p,{...body,correct:101},{authorization:'Bearer valid'}).code,400);
 assert.equal(call('POST',p,body,{authorization:'Bearer valid'}).code,200);
 let row=db.prepare('SELECT * FROM progress_mail').get();assert.equal(row.enabled,1);
 const params={token:row.unsubscribe_token};
 call('GET','/api/v1/progress-mail/preferences/:token',{}, {},params);
 assert.equal(db.prepare('SELECT enabled FROM progress_mail').get().enabled,1,'GET scanners cannot unsubscribe');
 call('POST','/api/v1/progress-mail/preferences/:token',{}, {},params);
 call('POST',p,body,{authorization:'Bearer valid'});
 assert.equal(db.prepare('SELECT enabled FROM progress_mail').get().enabled,-1,'background sync cannot re-subscribe');
 db.close();
});
test('badge counts real unread messages, deduplicates delivery retries and resets only for recipient',()=>{
 const inbox=require('../notification-inbox'),db=new Database(':memory:');
 db.exec("CREATE TABLE users(username TEXT PRIMARY KEY,device_token TEXT);INSERT INTO users VALUES('alice','token-a'),('bob','token-b')");
 let push={payload:{type:'duel_challenge',challengeId:'match1'},alert:{title:'Duel',body:'A real invitation'}};
 inbox.record(db,'token-a',push);assert.equal(push.badge,1);
 inbox.record(db,'token-a',push);assert.equal(push.badge,1);
 inbox.record(db,'token-a',{payload:{type:'duel_result',challengeId:'match0'},alert:{title:'Result',body:'A real result'}});
 const routes=new Map(),app={get:(p,h)=>routes.set('GET '+p,h),post:(p,h)=>routes.set('POST '+p,h)};
 inbox.install(app,db,req=>req.user?{username:req.user}:null);
 const res={code:200,status(n){this.code=n;return this},json(x){this.body=x;return this},set(){return this}};
 routes.get('GET /api/v1/notifications')({user:'alice'},res);assert.equal(res.body.unread,2);
 routes.get('POST /api/v1/notifications/read')({user:'bob'},res);
 routes.get('GET /api/v1/notifications')({user:'alice'},res);assert.equal(res.body.unread,2);
 routes.get('POST /api/v1/notifications/read')({user:'alice'},res);
 routes.get('GET /api/v1/notifications')({user:'alice'},res);assert.equal(res.body.unread,0);
 db.close();
});
test('digest sends only a new milestone, obeys weekly cooldown and never invents accuracy',async()=>{
 const old={...process.env};process.env.PROGRESS_EMAILS_ENABLED='true';process.env.MAILGUN_API_KEY='test-only';process.env.MAILGUN_DOMAIN='example.invalid';
 const db=new Database(':memory:'),sent=[];
 try {
  db.exec("CREATE TABLE users(username TEXT PRIMARY KEY,email TEXT,is_registered INTEGER,display_name TEXT,friend_code TEXT);INSERT INTO users VALUES('alice','alice@example.invalid',1,'Alice','AB123');CREATE TABLE duel_challenges(status TEXT,challenger_id TEXT,opponent_id TEXT,challenger_score INTEGER,opponent_score INTEGER,challenger_time_ms INTEGER,opponent_time_ms INTEGER)");
  const {tick}=engagement.install({get(){},post(){}},{db},()=>null,async(...args)=>sent.push(args));
  db.prepare('INSERT INTO progress_mail(username,enabled,locale,games,answers,correct,baseline,unsubscribe_token) VALUES(?,?,?,?,?,?,?,?)').run('alice',1,'ru',10,100,90,JSON.stringify({games:0,answers:100,correct:80,duels:0}),'token');
  await tick();assert.equal(sent.length,1);assert.ok(sent[0][3].includes('80% → 90%'));
  await tick();assert.equal(sent.length,1,'same milestone cannot resend');
  db.prepare('UPDATE progress_mail SET games=25').run();await tick();assert.equal(sent.length,1,'new milestone still obeys cooldown');
  db.prepare('UPDATE progress_mail SET last_sent=0,retry_after=0').run();await tick();assert.equal(sent.length,2);
  db.prepare('UPDATE progress_mail SET games=50,enabled=0,last_sent=0,retry_after=0').run();await tick();assert.equal(sent.length,2,'opt-out is respected');
 } finally {db.close();for(const key of ['PROGRESS_EMAILS_ENABLED','MAILGUN_API_KEY','MAILGUN_DOMAIN']) {if(old[key]===undefined)delete process.env[key];else process.env[key]=old[key];}}
});

test('APNs setter-only alert preserves inbox and badge without reading a missing getter',()=>{
 const db=new Database(':memory:');try{
 db.exec("CREATE TABLE users(username TEXT PRIMARY KEY,device_token TEXT);INSERT INTO users VALUES('alice','device');");
 const n={aps:{},payload:{type:'duel_challenge',challengeId:'real-apn'}};
 Object.defineProperty(n,'alert',{set(value){this.aps.alert=value}});
 const alert={title:'Duel',body:'A friend challenged you'};n.alert=alert;
 assert.equal(n.alert,undefined);
 require('../notification-inbox').record(db,'device',n,alert);
 assert.equal(n.badge,1);assert.equal(db.prepare('SELECT title FROM notification_inbox').get().title,'Duel');
 }finally{db.close()}
});

test('individual read receipts preserve other unread items and recipient isolation',()=>{
 const db=new Database(':memory:'),inbox=require('../notification-inbox');
 try{
 db.exec("CREATE TABLE users(username TEXT PRIMARY KEY,device_token TEXT);INSERT INTO users VALUES('alice','a'),('bob','b')");
 inbox.recordForUser(db,'alice',{id:'one',title:'Result',body:'Won',kind:'duel_result',target:'match'});
 inbox.recordForUser(db,'alice',{id:'two',title:'News',body:'New feature'});
 inbox.recordForUser(db,'bob',{id:'three',title:'Private',body:'For Bob'});
 const routes=new Map();inbox.install({get:(p,h)=>routes.set('GET '+p,h),post:(p,h)=>routes.set('POST '+p,h)},db,r=>r.user?{username:r.user}:null);
 function call(method,body,user='alice'){const res={code:200,status(c){this.code=c;return this},json(x){this.body=x;return this},set(){return this}};routes.get(method+' /api/v1/notifications'+(method==='POST'?'/read':''))({user,body},res);return res;}
 call('POST',{ids:['one','three']});let r=call('GET');assert.equal(r.body.unread,1);assert.equal(r.body.items.find(x=>x.id==='one').target,'match');
 assert.equal(call('GET',{},'bob').body.unread,1);assert.equal(call('POST',{ids:'all'}).code,400);
 call('POST',{ids:[]});assert.equal(call('GET').body.unread,1);
 inbox.recordForUser(db,'alice',{id:'one',title:'Retry',body:'Same event'});assert.equal(call('GET').body.unread,1,'delivery retry does not reopen a read event');
 }finally{db.close()}
});

test('accepted invitations stop counting as new while the result stays unread',()=>{
 const db=new Database(':memory:'),inbox=require('../notification-inbox');
 try{
 db.exec("CREATE TABLE users(username TEXT PRIMARY KEY,device_token TEXT);INSERT INTO users VALUES('alice','a');CREATE TABLE duel_challenges(id TEXT PRIMARY KEY,status TEXT,opponent_score INTEGER);INSERT INTO duel_challenges VALUES('match','pending',NULL)");
 inbox.recordForUser(db,'alice',{id:'invite',title:'Duel',body:'Invitation',kind:'duel_challenge',target:'match'});
 const routes=new Map();inbox.install({get:(p,h)=>routes.set(p,h),post(){}},db,()=>({username:'alice'}));
 const res={set(){return this},json(x){this.body=x;return this}};
 routes.get('/api/v1/notifications')({},res);assert.equal(res.body.unread,1);
 db.prepare("UPDATE duel_challenges SET status='completed',opponent_score=10").run();
 inbox.recordForUser(db,'alice',{id:'result',title:'Result',body:'10 : 8',kind:'duel_result',target:'match'});
 routes.get('/api/v1/notifications')({},res);assert.equal(res.body.unread,1);assert.equal(res.body.items.find(x=>x.id==='invite').readAt!==null,true);assert.equal(res.body.items.find(x=>x.id==='result').readAt,null);
 }finally{db.close()}
});
