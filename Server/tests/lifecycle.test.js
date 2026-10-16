'use strict';
const {test}=require('node:test'),assert=require('node:assert/strict'),Database=require('better-sqlite3');
const copy=require('../lifecycle-copy'),locales=require('../lifecycle-locales.json');
function fixture(sendMail=async()=>{throw Error('no live mail')}){
 const db=new Database(':memory:');db.pragma('foreign_keys = ON');
 db.exec("CREATE TABLE users(username TEXT PRIMARY KEY,email TEXT,is_registered INTEGER);INSERT INTO users VALUES('alice','alice@example.invalid',1),('bob','bob@example.invalid',1);CREATE TABLE duel_challenges(status TEXT,challenger_id TEXT,opponent_id TEXT,created_at TEXT)");
 const routes=new Map(),app={get:(p,h)=>routes.set('GET '+p,h),post:(p,h)=>routes.set('POST '+p,h)};
 let clock=Date.parse('2026-10-16T13:00:00Z');
 const api=require('../lifecycle').install(app,{db},req=>req.user?{username:req.user}:null,sendMail,{now:()=>clock,allowRewards:()=>true});
 function call(path,body={},user='alice',params={},method='POST'){
  const res={code:200,status(n){this.code=n;return this},json(body){this.body=body;return this},set(){return this},type(){return this},sendFile(file){this.file=file;return this},send(body){this.body=body;return this},sendStatus(n){this.code=n;return this}};
  routes.get(method+' /api/v1/lifecycle/'+path)({body,user,params},res);return res;
 }
 const payload={consentAt:clock,locale:'ru',timezone:'UTC',progress:true,offers:true,events:[],capabilities:{bonusRoute:true,regionRoute:true,reviewMistakes:true,capitalsLink:true}};
 return {db,api,call,payload,advance(ms){clock+=ms},now:()=>clock};
}
test('lifecycle: authentication, strict locale, event deduplication and durable unsubscribe',()=>{
 const f=fixture(),{db,call,payload}=f;
 try {
 assert.equal(call('sync',payload,null).code,401);
 assert.equal(call('sync',{...payload,locale:'unknown'}).code,400);
 const event={id:'one',type:'game_completed',at:f.now()-10000,timezone:'UTC',answers:10,correct:8,mode:'classic',difficulty:'easy',region:'Europe',questions:[{code:'FR',correct:false}]};
 assert.equal(call('sync',{...payload,events:[event]}).code,200);call('sync',{...payload,events:[event]});
 assert.equal(db.prepare('SELECT count(*) AS n FROM lifecycle_events').get().n,1);
 const token=db.prepare('SELECT unsubscribe_token FROM lifecycle_prefs').get().unsubscribe_token;
 call('preferences/:token',{},null,{token},'GET');assert.equal(db.prepare('SELECT offers FROM lifecycle_prefs').get().offers,1);
 call('preferences/:token',{},null,{token});call('sync',payload);
 assert.deepEqual(db.prepare('SELECT progress,offers FROM lifecycle_prefs').get(),{progress:0,offers:0});
 call('sync',{...payload,explicitConsent:true});assert.equal(db.prepare('SELECT offers FROM lifecycle_prefs').get().offers,1);
 assert.equal(call('sync',{...payload,events:[{...event,correct:11}]}).code,400);
 }finally{db.close()}
});
test('lifecycle: bonus answers and rewards are owned, resumable and idempotent',()=>{
 const f=fixture(),{db,call,payload}=f;
 try{
 call('sync',payload);db.prepare("INSERT INTO lifecycle_contacts(id,username,journey,channel,kind,period,status,created_at,token) VALUES('offer','alice','daylight_bonus','in_app','marketing','today','sent',?,'token')").run(f.now());
 assert.equal(call('bonus/start',{contactId:'offer'},'bob').code,409);
 let r=call('bonus/start',{contactId:'offer'}).body;const sid=r.sessionId;
 assert.ok(sid);assert.equal(call('bonus/start',{contactId:'offer'}).body.sessionId,sid);
 for(let i=0;i<10;i++){
  f.advance(2000);const q=JSON.parse(db.prepare('SELECT questions FROM lifecycle_bonus_sessions').get().questions)[i];
  r=call('bonus/answer',{sessionId:sid,index:i,answer:q.flag}).body;
  if(i===0){const again=call('bonus/answer',{sessionId:sid,index:0,answer:q.flag}).body;assert.equal(again.question.index,1)}
 }
 assert.equal(r.reward.amount,2);assert.equal(r.correct,10);
 assert.deepEqual(call('bonus/answer',{sessionId:sid,index:9,answer:'FR'}).body.reward,r.reward);
 f.advance(3600000);assert.deepEqual(call('bonus/answer',{sessionId:sid,index:9,answer:'FR'}).body.reward,r.reward,'receipt survives quiz expiry');
 assert.equal(call('bonus/answer',{sessionId:sid,index:0,answer:'FR'},'bob').code,409);
 assert.equal(db.prepare('SELECT count(*) AS n FROM lifecycle_rewards').get().n,1);
 assert.equal(call('sync',payload).body.rewards.length,1);
 }finally{db.close()}
});
test('lifecycle: expiry and consent revoke unfinished bonus eligibility',()=>{
 const f=fixture(),{db,call,payload}=f;
 try{call('sync',payload);db.prepare("INSERT INTO lifecycle_contacts(id,username,journey,channel,kind,period,status,created_at,token) VALUES('offer','alice','daylight_bonus','in_app','marketing','today','sent',?,'token')").run(f.now());
 const {sessionId,question}=call('bonus/start',{contactId:'offer'}).body;
 call('sync',{...payload,offers:false});assert.equal(call('bonus/answer',{sessionId,index:0,answer:question.options[0]}).code,409);
 assert.equal(db.prepare('SELECT count(*) AS n FROM lifecycle_rewards').get().n,0);
 }finally{db.close()}
});
test('lifecycle: all 240 localized variants escape data and have complete emails',()=>{
 assert.equal(Object.keys(locales).length,30);
 for(const lang of Object.keys(locales))for(const journey of copy.readyTemplates()[lang]){
 const m={...copy.message(journey,lang,{games:10,accuracy:90,duels:5}),journey};
 const rendered=copy.email(m,lang,'https://example.invalid/?a=1&b=2','https://example.invalid/unsubscribe');
 assert.ok(m.title&&m.body&&m.button);assert.ok(rendered.html.includes(`lang="${lang}"`));assert.ok(!rendered.html.includes('undefined'));assert.ok(rendered.html.includes('a=1&amp;b=2'));
 }
 assert.throws(()=>copy.message('weekly_passport','unknown'));
});
test('lifecycle: real morning history selects one reusable offer and opt-out hides it',()=>{
 const f=fixture(),{db,api,call,payload}=f;
 try {
 const events=Array.from({length:8},(_,i)=>({id:'morning'+i,type:'game_completed',at:f.now()-i*86400000-4*3600000,timezone:'UTC',answers:10,correct:10,mode:'classic',difficulty:'easy',region:'Europe',questions:[]}));
 call('sync',{...payload,progress:false,events});db.prepare('UPDATE lifecycle_prefs SET tz_since=?').run(f.now()-10*86400000);
 const first=api.select('alice',true);assert.equal(first.message.journey,'daylight_bonus');
 assert.equal(api.select('alice',true).message.id,first.message.id,'refresh cannot issue another contact');
 assert.equal(call('contacts/:id',{},'bob',{id:first.message.id},'GET').code,404);
 call('sync',{...payload,progress:false,offers:false});assert.equal(api.select('alice',true),null);
 assert.equal(call('contacts/:id',{},'alice',{id:first.message.id},'GET').code,404);
 }finally{db.close()}
});
test('lifecycle: server-verified completion telemetry matches answers and survives repeated sync',()=>{
 const f=fixture(),{db,call,payload}=f;
 try{
 call('sync',payload);db.prepare("INSERT INTO lifecycle_contacts(id,username,journey,channel,kind,period,status,created_at,token) VALUES('offer','alice','daylight_bonus','in_app','marketing','today','sent',?,'token')").run(f.now());
 const {sessionId}=call('bonus/start',{contactId:'offer'}).body;
 const questions=JSON.parse(db.prepare('SELECT questions FROM lifecycle_bonus_sessions').get().questions);
 for(let index=0;index<10;index++){f.advance(2000);call('bonus/answer',{sessionId,index,answer:index===0?questions[index].options.find(x=>x!==questions[index].flag):questions[index].flag})}
 const one=call('sync',payload).body,two=call('sync',payload).body;
 assert.deepEqual(one.completions,two.completions);assert.equal(one.completions[0].correct,9);assert.equal(one.rewards.length,0);
 const event=JSON.parse(db.prepare('SELECT payload FROM lifecycle_events').get().payload);assert.equal(event.questions.filter(x=>x.correct).length,9);
 assert.equal(db.prepare('SELECT count(*) AS n FROM lifecycle_bonus_answers').get().n,10);
 }finally{db.close()}
});
test('lifecycle: scheduler sends only opted-in localized mail once and cross-channel cap holds',async()=>{
 const env={...process.env};process.env.LIFECYCLE_EMAILS_ENABLED='true';process.env.MAILGUN_API_KEY='test';process.env.MAILGUN_DOMAIN='example.invalid';
 const sent=[],f=fixture(async(...args)=>sent.push(args)),{db,api,call,payload}=f;
 try{
 const events=Array.from({length:3},(_,i)=>({id:'g'+i,type:'game_completed',at:f.now()-i*86400000-3600000,timezone:'UTC',answers:10,correct:8,mode:'classic',difficulty:'easy',region:'Europe',questions:[]}));
 call('sync',{...payload,offers:false,events});await api.tick();await api.tick();
 assert.equal(sent.length,1);assert.ok(sent[0][3].includes('lang="ru"'));assert.equal(sent[0][4].tag,'lifecycle');
 assert.equal(api.select('alice',true),null,'email contact also suppresses in-app repetition');
 const c=db.prepare('SELECT id FROM lifecycle_contacts').get();assert.equal(call('contacts/:id',{},'alice',{id:c.id},'GET').code,200,'mail deep link reopens owned existing report');
 call('sync',{...payload,offers:false,progress:false,events:[]});f.advance(8*86400000);await api.tick();assert.equal(sent.length,1,'opt-out stops delivery');
 }finally{db.close();for(const k of ['LIFECYCLE_EMAILS_ENABLED','MAILGUN_API_KEY','MAILGUN_DOMAIN']){if(env[k]===undefined)delete process.env[k];else process.env[k]=env[k]}}
});
test('lifecycle: a fresh learning snapshot drives practice and completing it cancels the old offer',()=>{
 const f=fixture(),{db,api,call,payload}=f;
 try{
 const event={id:'weak',type:'game_completed',at:f.now()-10000,timezone:'UTC',answers:30,correct:20,mode:'classic',difficulty:'easy',region:'Europe',questions:[],weakCountries:['FR','DE','ES'],masteredCountries:[]};
 call('sync',{...payload,events:[event]});const offered=api.select('alice',true);assert.equal(offered.message.journey,'mastery_lab');assert.equal(offered.message.action,'mistakes');
 call('sync',{...payload,events:[{...event,id:'improved',at:f.now(),weakCountries:[]}]});assert.equal(api.select('alice',true),null);
 assert.equal(db.prepare('SELECT status FROM lifecycle_contacts WHERE id=?').get(offered.contact.id).status,'goal');
 assert.equal(call('sync',{...payload,events:[{...event,id:'invalid',weakCountries:['ZZ']}]}).code,400);
 }finally{db.close()}
});
test('lifecycle: an old offline opt-in cannot override a newer web unsubscribe',()=>{
 const f=fixture(),{db,call,payload}=f;
 try{
 call('sync',payload);const token=db.prepare('SELECT unsubscribe_token FROM lifecycle_prefs').get().unsubscribe_token;
 f.advance(2000);call('preferences/:token',{},null,{token});
 const stale=call('sync',{...payload,explicitConsent:true}).body;assert.equal(stale.offers,false);assert.equal(stale.progress,false);
 f.advance(1);const fresh=call('sync',{...payload,explicitConsent:true,consentAt:f.now()}).body;assert.equal(fresh.offers,true);
 }finally{db.close()}
});
test('lifecycle: rich emails keep map guidance, sourced country stories and meaningful content in all languages',()=>{
 const library=require('../lifecycle-facts.json').facts;
 assert.equal(library.length,6);
 for(const lang of Object.keys(locales))for(const journey of copy.readyTemplates()[lang]){
  for(const fact of library){assert.ok(fact.text[lang]);assert.ok(fact.source.startsWith('https://'))}
  const m={...copy.message(journey,lang,{games:12,accuracy:88,activeDays:5,regionsPlayed:3,masteredCount:18,focusCountries:['JP','EG'],seenCountries:['JP'],periodStart:Date.parse('2026-10-09T12:00:00Z'),periodEnd:Date.parse('2026-10-16T12:00:00Z')}),journey};
  assert.equal(m.stories.length,2);assert.ok(m.stories.some(x=>x.code==='JP'),'a played country is preferred');
  assert.equal(m.map.image,`map-${lang}-v1.jpg`);assert.equal(m.map.steps.length,3);assert.ok(!m.map.steps[0].includes('undefined'));
  const email=copy.email(m,lang,'https://example.invalid/open','https://example.invalid/prefs');
  assert.ok(email.html.includes(`/map-${lang}-v1`));assert.ok(email.text.includes(m.stories[0].text));
  assert.ok(Buffer.byteLength(email.html)<90000,'keep well below clipping limits');
  if(journey==='daylight_bonus')assert.equal(m.challenge.body,locales[lang].bonusInstructions);
 }
});
test('lifecycle: public image routes reject filenames outside the screenshot allowlist',()=>{
 const f=fixture();try{
  for(const name of ['../.env','map-unknown-v1.jpg','private-profile.png','map-ru-v1.jpg/../../db.js'])assert.equal(f.call('assets/:name',{},null,{name},'GET').code,404);
 }finally{f.db.close()}
});
test('lifecycle: localized image endpoints use extensionless URLs and resolve only public demo assets',()=>{
 const fs=require('node:fs'),f=fixture();try{
 for(const lang of Object.keys(locales)){
  const r=f.call('assets/:name',{},null,{name:`map-${lang}-v1`},'GET');assert.equal(r.code,200);assert.ok(r.file.endsWith(`map-${lang}-v1.jpg`));assert.ok(fs.statSync(r.file).size>10000);
 }
 }finally{f.db.close()}
});
