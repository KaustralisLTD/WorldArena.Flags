'use strict';
const crypto=require('node:crypto');
const decision=require('./lifecycle-decision');
const countries=require('./lifecycle-countries.json');
const templates=require('./lifecycle-copy');
const DAY=86400000;
const ids=['first_route','daylight_bonus','mastery_lab','weekly_passport','duel_brief','welcome_back','next_continent','capital_bridge'];
const uid=()=>crypto.randomUUID();
const parse=(s,fallback)=>{try{return JSON.parse(s)}catch{return fallback}};
const timeZone=z=>{try{new Intl.DateTimeFormat('en',{timeZone:z}).format();return typeof z==='string'&&z.length<80}catch{return false}};
function install(app,store,authenticate,sendMail,{now=()=>Date.now(),allowRewards=()=>process.env.LIFECYCLE_REWARDS_ENABLED==='true'}={}) {
 const db=store.db;
 require('./notification-inbox').initialize(db);
 db.exec(`CREATE TABLE IF NOT EXISTS lifecycle_prefs(username TEXT PRIMARY KEY REFERENCES users(username) ON DELETE CASCADE,locale TEXT NOT NULL,timezone TEXT NOT NULL,tz_since INTEGER NOT NULL,progress INTEGER NOT NULL DEFAULT 0,offers INTEGER NOT NULL DEFAULT 0,progress_blocked INTEGER NOT NULL DEFAULT 0,offers_blocked INTEGER NOT NULL DEFAULT 0,blocked_at INTEGER NOT NULL DEFAULT 0,capabilities TEXT NOT NULL DEFAULT '{}',unsubscribe_token TEXT UNIQUE NOT NULL);
 CREATE TABLE IF NOT EXISTS lifecycle_events(username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,id TEXT NOT NULL,at INTEGER NOT NULL,received_at INTEGER NOT NULL,payload TEXT NOT NULL,PRIMARY KEY(username,id));
 CREATE TABLE IF NOT EXISTS lifecycle_contacts(id TEXT PRIMARY KEY,username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,journey TEXT NOT NULL,channel TEXT NOT NULL,kind TEXT NOT NULL,period TEXT NOT NULL,status TEXT NOT NULL,created_at INTEGER NOT NULL,token TEXT UNIQUE NOT NULL,viewed_at INTEGER,goal_at INTEGER,retry_at INTEGER NOT NULL DEFAULT 0,UNIQUE(username,journey,period));
 CREATE TABLE IF NOT EXISTS lifecycle_bonus_sessions(id TEXT PRIMARY KEY,username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,contact_id TEXT NOT NULL UNIQUE REFERENCES lifecycle_contacts(id) ON DELETE CASCADE,created_at INTEGER NOT NULL,expires_at INTEGER NOT NULL,questions TEXT NOT NULL,next_index INTEGER NOT NULL DEFAULT 0,correct INTEGER NOT NULL DEFAULT 0,finished_at INTEGER);
 CREATE TABLE IF NOT EXISTS lifecycle_bonus_answers(session_id TEXT NOT NULL REFERENCES lifecycle_bonus_sessions(id) ON DELETE CASCADE,question_index INTEGER NOT NULL,answer TEXT NOT NULL,PRIMARY KEY(session_id,question_index));
 CREATE TABLE IF NOT EXISTS lifecycle_rewards(id TEXT PRIMARY KEY,username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,session_id TEXT NOT NULL UNIQUE REFERENCES lifecycle_bonus_sessions(id) ON DELETE CASCADE,base INTEGER NOT NULL,bonus INTEGER NOT NULL,created_at INTEGER NOT NULL);
 CREATE INDEX IF NOT EXISTS lifecycle_events_recent ON lifecycle_events(username,at);
 CREATE INDEX IF NOT EXISTS lifecycle_events_expiry ON lifecycle_events(at);
 CREATE INDEX IF NOT EXISTS lifecycle_contacts_recent ON lifecycle_contacts(username,created_at);`);
 try{db.exec('ALTER TABLE lifecycle_prefs ADD COLUMN blocked_at INTEGER NOT NULL DEFAULT 0')}catch(e){if(!String(e.message).includes('duplicate column'))throw e;}
 function session(req,res){const s=authenticate(req);if(!s)res.status(401).json({error:'Sign in required'});return s;}
 function profile(username,inApp=false){
  const p=db.prepare('SELECT p.*,u.email,u.is_registered FROM lifecycle_prefs p JOIN users u USING(username) WHERE username=?').get(username);if(!p)return null;
  const events=db.prepare('SELECT payload FROM lifecycle_events WHERE username=? AND at>? ORDER BY at').all(username,now()-28*DAY).map(x=>parse(x.payload,{}));
  const contacts=db.prepare('SELECT journey,channel,kind,created_at AS at,status,viewed_at FROM lifecycle_contacts WHERE username=? AND created_at>?').all(username,now()-35*DAY).filter(c=>['sent','viewed','goal','holdout','planned','sending','failed'].includes(c.status));
  const duels=db.prepare("SELECT * FROM duel_challenges WHERE status='completed' AND (challenger_id=? OR opponent_id=?) AND datetime(created_at)>=datetime(? / 1000,'unixepoch')").all(username,username,now()-7*DAY);
  const latestLearning=[...events].reverse().find(e=>Array.isArray(e.weakCountries));
  const wrong=new Set(latestLearning?.weakCountries||[]),mastered=new Set(latestLearning?.masteredCountries||[]);
  const countryMasteryRatio=Math.max(0,...['Europe','Asia','Americas','Africa','Oceania'].map(region=>{
   const pool=countries.filter(c=>c.region===region);return pool.length?pool.filter(c=>mastered.has(c.code)).length/pool.length:0;
  }));
  const rewards=db.prepare('SELECT COUNT(*) AS n FROM lifecycle_rewards WHERE username=? AND created_at>?').get(username,now()-7*DAY).n;
  const capabilities=parse(p.capabilities,{});
  const localDay=decision.localParts(now(),p.timezone).day;
  const morningClassic=events.some(e=>e.mode==='classic'&&e.region!=='My Mistakes'&&decision.localParts(e.at,e.timezone).day===localDay&&decision.bucket(decision.localParts(e.at,e.timezone).hour)==='morning');
  const lastClickedEmail=Math.max(0,...contacts.filter(c=>c.channel==='email'&&c.viewed_at).map(c=>c.viewed_at));
  const unresponsiveEmails=contacts.filter(c=>c.channel==='email'&&['sent','goal'].includes(c.status)&&!c.viewed_at&&c.at>lastClickedEmail).length;
  const completedGoals=contacts.filter(c=>c.status==='goal'&&['first_route','capital_bridge'].includes(c.journey)).map(c=>({first_route:'complete_second_active_day',welcome_back:'complete_return_game',mastery_lab:'correct_repeated_mistakes',weekly_passport:'open_map_then_play',duel_brief:'complete_next_opt_in_duel',next_continent:'complete_new_region_game',daylight_bonus:'complete_verified_bonus_game',capital_bridge:'start_capitals_first_game'}[c.journey]));
  return {raw:p,events,duels,model:{holdoutPercent:process.env.LIFECYCLE_HOLDOUT_PERCENT==='0'?0:10,id:username,registered:p.is_registered===1,timezone:p.timezone,timezoneStableDays:(now()-p.tz_since)/DAY,locale:p.locale,readyTemplates:templates.readyTemplates(),progressConsent:p.progress===1,marketingConsent:p.offers===1,emailVerified:!!p.email,emailAvailable:!!p.email,inAppAvailable:inApp,contacts,completedGoals,capabilities:{...capabilities,signedRewardOffer:allowRewards()&&capabilities.bonusRoute===true,rewardLedger:allowRewards()},firstDailyRewardClaimed:morningClassic,rewardBudgetAvailable:rewards<2,mistakeCountryCount:wrong.size,countryMasteryRatio,weeklyReportDue:true,duelSummaryDue:true,completedDuels7d:duels.length,unresponsiveEmails}};
 }
 function material(contact,p){
  const a=decision.analyze(p.events,p.raw.timezone,now());
  const comparable=a.comparable && a.comparable.current.answers===a.current.answers && a.comparable.previous.answers===a.previous.answers ? a.comparable : null;
  const wins=p.duels.filter(d=>{
   const own=d.challenger_id===p.raw.username;
   const score=own?d.challenger_score:d.opponent_score,other=own?d.opponent_score:d.challenger_score;
   const time=own?d.challenger_time_ms:d.opponent_time_ms,otherTime=own?d.opponent_time_ms:d.challenger_time_ms;
   return Number.isFinite(score)&&Number.isFinite(other)&&(score>other||(score===other&&Number.isFinite(time)&&Number.isFinite(otherTime)&&time<otherTime));
  }).length;
  const recent=a.events.filter(e=>e.at>=now()-7*DAY),seenCountries=[...new Set(recent.flatMap(e=>(e.questions||[]).map(q=>q.code)))];
  const regionsPlayed=new Set(seenCountries.map(code=>countries.find(c=>c.code===code)?.region).filter(Boolean)).size;
  const activeDays=new Set(recent.map(e=>decision.localParts(e.at,e.timezone||p.raw.timezone).day)).size;
  const learning=[...p.events].reverse().find(e=>Array.isArray(e.masteredCountries));
  const scoreWins=p.duels.filter(d=>{const own=d.challenger_id===p.raw.username;const a=own?d.challenger_score:d.opponent_score,b=own?d.opponent_score:d.challenger_score;return Number.isFinite(a)&&Number.isFinite(b)&&a>b}).length;
  const morningDays=new Set(a.events.filter(e=>decision.bucket(decision.localParts(e.at,e.timezone||p.raw.timezone).hour)==='morning').map(e=>decision.localParts(e.at,e.timezone||p.raw.timezone).day)).size;
  const data={habitDays:a.activeDays,morningDays,games:a.current.games,accuracy:a.current.accuracy,previousAccuracy:comparable?.previous.accuracy,currentAccuracy:comparable?.current.accuracy,duels:p.duels.length,wins,scoreWins,speedWins:wins-scoreWins,activeDays,regionsPlayed,seenCountries,focusCountries:learning?.weakCountries||[],masteredCount:learning?.masteredCountries?.length,periodStart:now()-7*DAY,periodEnd:now(),timezone:p.raw.timezone,storyPeriod:contact.id};
  const localizedTitles={},localizedBodies={};
  for(const code of Object.keys(require('./lifecycle-locales.json'))){
   const message=templates.message(contact.journey,code,data);
   localizedTitles[code]=message.title;
   localizedBodies[code]=[message.body,...(message.facts||[]).map(f=>f.label+': '+f.value)].join('\n');
  }
  return {notificationDetails:{localizedTitles,localizedBodies},id:contact.id,journey:contact.journey,...templates.message(contact.journey,p.raw.locale,data),action:{daylight_bonus:'bonus',mastery_lab:'mistakes',duel_brief:'duels',capital_bridge:'capitals'}[contact.journey]||'map'};
 }
 function select(username,inApp){
  const p=profile(username,inApp);if(!p)return null;
  // Refreshes return the same owned offer rather than creating another contact.
  if(inApp){
   const active=db.prepare("SELECT * FROM lifecycle_contacts WHERE username=? AND channel='in_app' AND status IN ('sent','viewed') AND created_at>? ORDER BY created_at DESC LIMIT 1").get(username,now()-DAY);
   if(active?.journey==='mastery_lab'&&p.model.mistakeCountryCount<3){db.prepare("UPDATE lifecycle_contacts SET status='goal',goal_at=? WHERE id=?").run(now(),active.id);return null;}
   if(active && (active.kind==='progress'?p.raw.progress:p.raw.offers)===1 && (active.journey!=='daylight_bonus'||(allowRewards()&&decision.localParts(now(),p.raw.timezone).hour<16&&decision.localParts(now(),p.raw.timezone).day===decision.localParts(active.created_at,p.raw.timezone).day)))return {contact:active,p,message:material(active,p)};
  }
  const result=decision.decide(p.model,p.events,now());if(!['eligible','holdout'].includes(result.status))return null;
  const period=new Date(now()).toISOString().slice(0,10),contact={id:uid(),username,journey:result.journey,channel:result.channel,kind:result.journey==='weekly_passport'?'progress':'marketing',period,status:result.status==='holdout'?'holdout':inApp?'sent':'planned',created_at:now(),token:crypto.randomBytes(32).toString('hex')};
  const insert=db.prepare('INSERT OR IGNORE INTO lifecycle_contacts(id,username,journey,channel,kind,period,status,created_at,token) VALUES(@id,@username,@journey,@channel,@kind,@period,@status,@created_at,@token)').run(contact);
  if(!insert.changes||contact.status==='holdout')return null;
  const message=material(contact,p);
  if(inApp)require('./notification-inbox').recordForUser(db,username,{id:'lifecycle:'+contact.id,title:message.title,body:[message.body,...(message.facts||[]).map(f=>f.label+': '+f.value)].join('\n'),kind:'lifecycle',target:contact.id,createdAt:contact.created_at,details:message.notificationDetails});
  return {contact,p,message};
 }
 app.get('/api/v1/lifecycle/assets/:name',(req,res)=>{
  const allowed=/^(?:map-(?:en|ru|uk|de|es|fr|it|pt-BR|nl|pl|ca|cs|el|sv|ro|hu|tr|ar|hi|bn|ta|te|th|vi|id|fil|ja|ko|zh|zh-Hant)-v1\.jpg|(?:flags|capitals)-logo-v1\.png)$/;
  const file=req.params.name.startsWith('map-')?req.params.name+'.jpg':req.params.name+'.png';
  if(!allowed.test(file))return res.sendStatus(404);
  res.set('Cache-Control','public,max-age=604800,immutable');
  res.sendFile(require('node:path').join(__dirname,'lifecycle-assets',file));
 });
 app.post('/api/v1/lifecycle/sync',(req,res)=>{
  const s=session(req,res);if(!s)return;const b=req.body||{};
  if(!templates.supports(b.locale)||!timeZone(b.timezone)||typeof b.progress!=='boolean'||typeof b.offers!=='boolean'||!Array.isArray(b.events)||b.events.length>100)return res.status(400).json({error:'Invalid lifecycle payload'});
  const events=[];
  for(const event of b.events){
   if(typeof event.id!=='string'||event.id.length>80||!event.id||event.type!=='game_completed'||!Number.isSafeInteger(event.at)||event.at>now()+300000||event.at<now()-35*DAY||!timeZone(event.timezone)||!Number.isInteger(event.answers)||event.answers<1||event.answers>1000||!Number.isInteger(event.correct)||event.correct<0||event.correct>event.answers||!['classic','timeChallenge','survival','duel'].includes(event.mode)||typeof event.difficulty!=='string'||event.difficulty.length>40||typeof event.region!=='string'||event.region.length>120)return res.status(400).json({error:'Invalid game event'});
   if(!Array.isArray(event.questions)||event.questions.length>event.answers||event.questions.some(q=>!countries.some(c=>c.code===q.code)||typeof q.correct!=='boolean'))return res.status(400).json({error:'Invalid question event'});
   const snapshot={};
   for(const key of ['weakCountries','masteredCountries'])if(event[key]!==undefined){
    if(!Array.isArray(event[key])||event[key].length>300||event[key].some(code=>!countries.some(c=>c.code===code)))return res.status(400).json({error:'Invalid learning snapshot'});
    snapshot[key]=[...new Set(event[key])];
   }
   events.push({...snapshot,id:event.id,type:event.type,at:event.at,timezone:event.timezone,answers:event.answers,correct:event.correct,mode:event.mode,difficulty:event.difficulty,region:event.region,questions:event.questions});
  }
  const old=db.prepare('SELECT blocked_at FROM lifecycle_prefs WHERE username=?').get(s.username);
  const consent=b.explicitConsent===true&&Number.isSafeInteger(b.consentAt)&&b.consentAt<=now()+300000&&b.consentAt>=now()-35*DAY&&b.consentAt>=(old?.blocked_at||0);
  const capabilities=Object.fromEntries(['bonusRoute','regionRoute','reviewMistakes','capitalsLink'].map(k=>[k,b.capabilities?.[k]===true]));
  db.transaction(()=>{
   db.prepare(`INSERT INTO lifecycle_prefs(username,locale,timezone,tz_since,progress,offers,capabilities,unsubscribe_token) VALUES(?,?,?,?,?,?,?,?) ON CONFLICT(username) DO UPDATE SET locale=excluded.locale,timezone=excluded.timezone,tz_since=CASE WHEN lifecycle_prefs.timezone<>excluded.timezone THEN excluded.tz_since ELSE lifecycle_prefs.tz_since END,progress=CASE WHEN lifecycle_prefs.progress_blocked=1 AND ?=0 THEN 0 ELSE excluded.progress END,offers=CASE WHEN lifecycle_prefs.offers_blocked=1 AND ?=0 THEN 0 ELSE excluded.offers END,progress_blocked=CASE WHEN ?=1 THEN 0 ELSE lifecycle_prefs.progress_blocked END,offers_blocked=CASE WHEN ?=1 THEN 0 ELSE lifecycle_prefs.offers_blocked END,capabilities=excluded.capabilities`).run(s.username,b.locale,b.timezone,now(),b.progress?1:0,b.offers?1:0,JSON.stringify(capabilities),crypto.randomBytes(32).toString('hex'),consent?1:0,consent?1:0,consent?1:0,consent?1:0);
   const put=db.prepare('INSERT OR IGNORE INTO lifecycle_events VALUES(?,?,?,?,?)');
   for(const e of events)put.run(s.username,e.id,e.at,now(),JSON.stringify(e));
   db.prepare('DELETE FROM lifecycle_events WHERE at<?').run(now()-56*DAY);
   if(events.length){
    db.prepare("UPDATE lifecycle_contacts SET status='goal',goal_at=? WHERE username=? AND journey IN ('first_route','welcome_back','weekly_passport') AND status IN ('sent','viewed') AND (journey<>'weekly_passport' OR viewed_at IS NOT NULL) AND created_at<?").run(now(),s.username,Math.max(...events.map(e=>e.at)));
   }
  })();
  // Upgraded clients use the new programme exclusively; legacy clients keep their existing setting.
  if(db.prepare("SELECT name FROM sqlite_master WHERE name='progress_mail'").get())db.prepare('UPDATE progress_mail SET enabled=0 WHERE username=?').run(s.username);
  const p=db.prepare('SELECT progress,offers FROM lifecycle_prefs WHERE username=?').get(s.username);
  const rewards=db.prepare('SELECT id,base+bonus AS amount,created_at AS createdAt FROM lifecycle_rewards WHERE username=?').all(s.username);
  const completions=db.prepare('SELECT id,correct,next_index AS total,finished_at AS completedAt FROM lifecycle_bonus_sessions WHERE username=? AND finished_at IS NOT NULL').all(s.username);
  res.json({accepted:events.map(e=>e.id),progress:p.progress===1,offers:p.offers===1,rewards,completions});
 });
 app.get('/api/v1/lifecycle/message',(req,res)=>{const s=session(req,res);if(!s)return;res.set('Cache-Control','no-store');res.json({message:select(s.username,true)?.message||null});});
 app.get('/api/v1/lifecycle/contacts/:id',(req,res)=>{
  const s=session(req,res);if(!s)return;
  const c=db.prepare("SELECT * FROM lifecycle_contacts WHERE id=? AND username=? AND status IN ('sent','viewed') AND created_at>?").get(req.params.id,s.username,now()-DAY);
  const p=profile(s.username,true);
  if(!c||!p||(c.kind==='progress'?p.raw.progress:p.raw.offers)!==1)return res.status(404).json({message:null});
  res.set('Cache-Control','no-store').json({message:material(c,p)});
 });
 app.post('/api/v1/lifecycle/contacts/:id/action',(req,res)=>{const s=session(req,res);if(!s)return;const c=db.prepare('SELECT * FROM lifecycle_contacts WHERE id=? AND username=?').get(req.params.id,s.username);if(!c)return res.sendStatus(404);db.prepare("UPDATE lifecycle_contacts SET viewed_at=?,status=CASE WHEN status='sent' THEN 'viewed' ELSE status END WHERE id=?").run(now(),c.id);db.prepare("UPDATE notification_inbox SET read_at=? WHERE username=? AND id=? AND read_at IS NULL").run(now(),s.username,'lifecycle:'+c.id);res.json({ok:true});});
 const publicQuestion=row=>{const qs=parse(row.questions,[]),q=qs[row.next_index];return q?{index:row.next_index,total:qs.length,flag:q.flag,options:q.options}:null};
 app.post('/api/v1/lifecycle/bonus/start',(req,res)=>{
  const s=session(req,res);if(!s)return;if(!allowRewards())return res.status(409).json({errorCode:'lifecycle.bonus.unavailable'});
  const c=db.prepare("SELECT * FROM lifecycle_contacts WHERE id=? AND username=? AND journey='daylight_bonus' AND status IN ('sent','viewed','goal')").get(req.body.contactId,s.username);
  const p=profile(s.username,true);if(!c||!p||p.raw.offers!==1||now()-c.created_at>DAY)return res.status(409).json({errorCode:'lifecycle.bonus.unavailable'});
  const hour=decision.localParts(now(),p.raw.timezone).hour;
  if(p.raw.tz_since>c.created_at||decision.localParts(now(),p.raw.timezone).day!==decision.localParts(c.created_at,p.raw.timezone).day||hour<12||hour>=16)return res.status(409).json({errorCode:'lifecycle.bonus.unavailable'});
  let row=db.prepare('SELECT * FROM lifecycle_bonus_sessions WHERE contact_id=?').get(c.id);
  if(!row){
   const recent=db.prepare('SELECT created_at FROM lifecycle_rewards WHERE username=? AND created_at>?').all(s.username,now()-7*DAY);
   if(recent.length>=2||recent.some(r=>decision.localParts(r.created_at,p.raw.timezone).day===decision.localParts(now(),p.raw.timezone).day))return res.status(409).json({errorCode:'lifecycle.bonus.unavailable'});
   const pool=countries.filter(x=>['Europe','Asia','Americas','Africa','Oceania'].includes(x.region));
   const shuffled=pool.map(x=>({x,k:crypto.randomBytes(8).toString('hex')})).sort((a,b)=>a.k.localeCompare(b.k)).map(x=>x.x);
   const questions=shuffled.slice(0,10).map((target,i)=>({flag:target.code,options:[target,...shuffled.slice(10+i*3,13+i*3)].map(x=>({code:x.code,k:crypto.randomBytes(4).toString('hex')})).sort((a,b)=>a.k.localeCompare(b.k)).map(x=>x.code)}));
   row={id:uid(),username:s.username,contact_id:c.id,created_at:now(),expires_at:now()+1800000,questions:JSON.stringify(questions),next_index:0,correct:0};
   db.prepare('INSERT INTO lifecycle_bonus_sessions(id,username,contact_id,created_at,expires_at,questions) VALUES(@id,@username,@contact_id,@created_at,@expires_at,@questions)').run(row);
  }
  if(row.expires_at<now()&&!row.finished_at)return res.status(409).json({errorCode:'lifecycle.bonus.unavailable'});
  const reward=db.prepare('SELECT id,base+bonus AS amount FROM lifecycle_rewards WHERE session_id=?').get(row.id);
  res.json({sessionId:row.id,question:publicQuestion(row),done:!!row.finished_at,correct:row.correct,reward:reward||null});
 });
 app.post('/api/v1/lifecycle/bonus/answer',(req,res)=>{
  const s=session(req,res);if(!s)return;
  const result=db.transaction(()=>{
   const row=db.prepare('SELECT * FROM lifecycle_bonus_sessions WHERE id=? AND username=?').get(req.body.sessionId,s.username);
   if(!row)return {error:true};
   const existing=db.prepare('SELECT id,base+bonus AS amount FROM lifecycle_rewards WHERE session_id=?').get(row.id);
   if(row.finished_at)return {done:true,correct:row.correct,total:10,reward:existing||null};
   const prefNow=db.prepare('SELECT offers,timezone,tz_since FROM lifecycle_prefs WHERE username=?').get(s.username);
   const hourNow=prefNow?decision.localParts(now(),prefNow.timezone).hour:0;
   if(row.expires_at<now()||!prefNow||prefNow.offers!==1||prefNow.tz_since>row.created_at||hourNow<12||hourNow>=16||!allowRewards())return {error:true};
   // A lost HTTP response can be retried without consuming a second answer.
   if(Number.isInteger(req.body.index)&&req.body.index>=0&&req.body.index<row.next_index)return {done:false,question:publicQuestion(row)};
   const qs=parse(row.questions,[]),q=qs[row.next_index];
   if(req.body.index!==row.next_index||!q?.options.includes(req.body.answer))return {error:true};
   db.prepare('INSERT INTO lifecycle_bonus_answers VALUES(?,?,?)').run(row.id,row.next_index,req.body.answer);
   const correct=row.correct+(q.flag===req.body.answer?1:0),index=row.next_index+1;
   db.prepare('UPDATE lifecycle_bonus_sessions SET next_index=?,correct=? WHERE id=?').run(index,correct,row.id);
   if(index<qs.length)return {done:false,question:publicQuestion({...row,next_index:index,correct})};
   db.prepare('UPDATE lifecycle_bonus_sessions SET finished_at=? WHERE id=?').run(now(),row.id);
   const chosen=db.prepare('SELECT answer FROM lifecycle_bonus_answers WHERE session_id=? ORDER BY question_index').all(row.id);
   const verifiedEvent={id:'bonus:'+row.id,type:'game_completed',at:now(),timezone:prefNow.timezone,answers:qs.length,correct,mode:'classic',difficulty:'bonus',region:'All Regions',questions:qs.map((q,i)=>({code:q.flag,correct:chosen[i].answer===q.flag}))};
   db.prepare('INSERT OR IGNORE INTO lifecycle_events VALUES(?,?,?,?,?)').run(s.username,verifiedEvent.id,now(),now(),JSON.stringify(verifiedEvent));
   let reward=null;
   const pref=db.prepare('SELECT offers,timezone FROM lifecycle_prefs WHERE username=?').get(s.username);
   const receipts=db.prepare('SELECT created_at FROM lifecycle_rewards WHERE username=? AND created_at>?').all(s.username,now()-7*DAY);
   if(correct===qs.length&&allowRewards()&&pref.offers===1&&receipts.length<2&&!receipts.some(r=>decision.localParts(r.created_at,pref.timezone).day===decision.localParts(now(),pref.timezone).day)){
    reward={id:uid(),amount:2};db.prepare('INSERT INTO lifecycle_rewards VALUES(?,?,?,?,?,?)').run(reward.id,s.username,row.id,1,1,now());
   }
   db.prepare("UPDATE lifecycle_contacts SET status='goal',goal_at=? WHERE id=?").run(now(),row.contact_id);
   return {done:true,correct,total:qs.length,reward};
  })();
  if(result.error)return res.status(409).json({errorCode:'lifecycle.bonus.unavailable'});res.json(result);
 });
 app.get('/api/v1/lifecycle/preferences/:token',(req,res)=>{
  const p=db.prepare('SELECT locale FROM lifecycle_prefs WHERE unsubscribe_token=?').get(req.params.token);if(!p)return res.sendStatus(404);
  res.type('html').send(templates.preferences(p.locale));
 });
 app.post('/api/v1/lifecycle/preferences/:token',(req,res)=>{
  const pref=db.prepare('SELECT locale FROM lifecycle_prefs WHERE unsubscribe_token=?').get(req.params.token);
  const result=db.prepare('UPDATE lifecycle_prefs SET progress=0,offers=0,progress_blocked=1,offers_blocked=1,blocked_at=? WHERE unsubscribe_token=?').run(now(),req.params.token);
  res.status(result.changes?200:404).type('html').send(pref?templates.unsubscribed(pref.locale):'World Arena');
 });
 app.get('/api/v1/lifecycle/open/:token',(req,res)=>{
  const c=db.prepare('SELECT * FROM lifecycle_contacts WHERE token=?').get(req.params.token);if(!c)return res.sendStatus(404);
  const p=profile(c.username,false);res.set('Cache-Control','no-store').type('html').send(templates.landing(p?.raw.locale||'en',c.id));
 });
 let busy=false;
 async function tick(){
  if(busy||process.env.LIFECYCLE_EMAILS_ENABLED!=='true'||!process.env.MAILGUN_API_KEY||!process.env.MAILGUN_DOMAIN)return;busy=true;
  try{for(const row of db.prepare('SELECT username FROM lifecycle_prefs WHERE progress=1 OR offers=1').all()){
   const selected=select(row.username,false);if(!selected||selected.contact.channel!=='email')continue;
   const {contact,p,message}=selected;
   const claimed=db.prepare("UPDATE lifecycle_contacts SET status='sending',retry_at=? WHERE id=? AND status='planned'").run(now()+DAY,contact.id);if(!claimed.changes)continue;
   const content=templates.email(message,p.raw.locale,`https://flags.worldarena.games/api/v1/lifecycle/open/${contact.token}`,`https://flags.worldarena.games/api/v1/lifecycle/preferences/${p.raw.unsubscribe_token}`);
   try{await sendMail(p.raw.email,content.subject,content.text,content.html,{unsubscribeURL:`https://flags.worldarena.games/api/v1/lifecycle/preferences/${p.raw.unsubscribe_token}`,tag:"lifecycle"});db.prepare("UPDATE lifecycle_contacts SET status='sent' WHERE id=?").run(contact.id)}catch{db.prepare("UPDATE lifecycle_contacts SET status='failed' WHERE id=?").run(contact.id);continue}
   try{require('./notification-inbox').recordForUser(db,contact.username,{id:'lifecycle:'+contact.id,title:message.title,body:[message.body,...(message.facts||[]).map(f=>f.label+': '+f.value)].join('\n'),kind:'lifecycle',target:contact.id,createdAt:contact.created_at,details:message.notificationDetails})}catch(e){console.error('[lifecycle-inbox]',e.message)}
  }}finally{busy=false;}
 }
 try {
  for(const c of db.prepare("SELECT c.* FROM lifecycle_contacts c LEFT JOIN notification_inbox n ON n.id='lifecycle:'||c.id WHERE n.id IS NULL AND c.channel='email' AND c.status IN ('sent','viewed','goal') ORDER BY c.created_at DESC LIMIT 1000").all()) {
   const p=profile(c.username,false);if(!p)continue;
   const m=material(c,p);require('./notification-inbox').recordForUser(db,c.username,{id:'lifecycle:'+c.id,title:m.title,body:m.body,kind:'lifecycle',target:c.id,createdAt:c.created_at,readAt:now(),details:m.notificationDetails});
  }
 }catch(e){console.error('[lifecycle-inbox-history]',e.message)}
 const timer=setInterval(()=>tick().catch(e=>console.error('[lifecycle]',e.message)),600000);timer.unref();
 return {tick,profile,select};
}
module.exports={install};
