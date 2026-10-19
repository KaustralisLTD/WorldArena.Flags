'use strict';
const crypto = require('node:crypto');
const {locale} = require('./engagement');
const copies = require('./progress-mail-locales.json');
const inbox = require('./notification-inbox');
const esc = x => String(x ?? '').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
function render(user,event,language,unsubscribeURL) {
 const lang=locale(language),t=copies[lang],level=event.type==='level';
 const titles={en:level?'Level 100. A milestone worth celebrating.':'Your week in World Arena',ru:level?'Уровень 100. Рубеж, которым стоит гордиться.':'Ваша неделя в World Arena',uk:level?'Рівень 100. Рубіж, яким варто пишатися.':'Ваш тиждень у World Arena'};
 const title=titles[lang]||t.title;
 const value=level?'100':`#${event.rank}`;
 const summary=level?`${event.xp.toLocaleString(lang)} XP`:`${esc(event.league)} · ${event.participants} 👥`;
 const url='https://flags.worldarena.games/profile/'+encodeURIComponent(user.friend_code);
 const metrics=`<table role="presentation" width="100%" style="margin:24px 0;background:#17384a;border-radius:18px"><tr><td align="center" style="padding:28px"><div style="font-size:64px;font-weight:bold;color:#fff1c9">${value}</div><p style="font-size:20px;color:#a7f6eb">${summary}</p></td></tr></table>`;
 const html=`<!doctype html><html lang="${lang}" dir="${lang==='ar'?'rtl':'ltr'}"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><body style="margin:0;background:#eef3f5;font:17px Arial,sans-serif;color:#eaf7f8"><table role="presentation" width="100%"><tr><td align="center" style="padding:24px 12px"><table role="presentation" width="100%" style="max-width:600px;background:#081c2d;border-radius:28px"><tr><td style="padding:32px"><p style="letter-spacing:3px;color:#42e1cc;font-weight:bold">FLAGS · WORLD ARENA</p><div style="text-align:center;font-size:72px;padding:20px">🏆</div><h1 style="font-size:32px;line-height:1.2">${esc(title)}</h1><p>${esc(user.display_name||user.username)}, ${esc(t.milestone)}</p>${metrics}<p style="line-height:1.65;color:#c2d4df">${esc(t.saved)}</p><p style="padding:16px 0"><a href="${url}" style="display:inline-block;background:#3de0c9;color:#071c2e;font-weight:bold;border-radius:16px;padding:18px 26px;text-decoration:none">${esc(t.cta)} →</a></p><a href="${esc(unsubscribeURL)}" style="font-size:13px;color:#a9c3d2">${esc(t.preferences)}</a></td></tr></table></td></tr></table></body></html>`;
 return {subject:title+' · Flags',html,text:`${title}\n${user.display_name||user.username}\n${level?'100':event.rank}\n${level?event.xp+' XP':event.league}\n${t.milestone}\n${t.saved}\n${url}\n${t.preferences}: ${unsubscribeURL}`,title,body:level?`100 · ${event.xp} XP`:`#${event.rank} · ${event.league}`};
}
function install(app,store,authenticate,sendMail,{now=()=>Date.now(),enabled=()=>process.env.LIFECYCLE_EMAILS_ENABLED==='true' || process.env.PROGRESS_EMAILS_ENABLED==='true',configured=()=>!!process.env.MAILGUN_API_KEY&&!!process.env.MAILGUN_DOMAIN}={}) {
 const db=store.db;inbox.initialize(db);
 db.exec(`CREATE TABLE IF NOT EXISTS award_mail(username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,event_key TEXT NOT NULL,payload TEXT NOT NULL,status TEXT NOT NULL DEFAULT 'pending',created_at INTEGER NOT NULL,attempts INTEGER NOT NULL DEFAULT 0,retry_at INTEGER NOT NULL DEFAULT 0,PRIMARY KEY(username,event_key))`);
 app.post('/api/v1/award-mail',(req,res)=>{
  const user=authenticate(req);if(!user)return res.status(401).json({error:'Sign in required'});
  const e=req.body;
  if(!e || !['level','league'].includes(e.type))return res.status(400).json({error:'Invalid award'});
  const level=e.type==='level';
  if(level && (!Number.isSafeInteger(e.xp)||e.xp<99000||e.xp>1e9))return res.status(400).json({error:'Invalid level'});
  if(!level && (typeof e.week!=='string'||!/^\d{4}-W?\d{1,2}$/.test(e.week)||!Number.isSafeInteger(e.rank)||e.rank<1||e.rank>1000||!Number.isSafeInteger(e.participants)||e.participants<e.rank||e.participants>1000||typeof e.league!=='string'||e.league.length>100))return res.status(400).json({error:'Invalid league result'});
  if(!db.prepare("SELECT 1 FROM sqlite_master WHERE type='table' AND name='lifecycle_prefs'").get())return res.status(503).json({error:'Preferences not ready'});
  const consent=db.prepare('SELECT progress,progress_blocked FROM lifecycle_prefs WHERE username=?').get(user.username);
  if(!consent)return res.status(409).json({error:'Sync email preferences first'});
  // An opted-out player's past milestones must not accumulate into a burst of
  // congratulations when they subscribe months later.
  if(consent.progress!==1||consent.progress_blocked===1)return res.json({ok:true,subscribed:false});
  const key=level?'level:100':'league:'+e.week;
  const payload=level?{type:'level',xp:e.xp}:{type:'league',week:e.week,rank:e.rank,participants:e.participants,league:e.league};
  db.prepare('INSERT OR IGNORE INTO award_mail(username,event_key,payload,created_at) VALUES(?,?,?,?)').run(user.username,key,JSON.stringify(payload),now());
  res.json({ok:true});
 });
 let busy=false;
 async function tick(){
  if(busy||!enabled()||!configured())return;busy=true;
  try{
   if(!db.prepare("SELECT 1 FROM sqlite_master WHERE type='table' AND name='lifecycle_prefs'").get())return;
   db.prepare("UPDATE award_mail SET status='expired' WHERE status='pending' AND created_at<?").run(now()-14*86400000);
   const rows=db.prepare(`SELECT a.*,u.email,u.display_name,u.friend_code,p.locale,p.unsubscribe_token FROM award_mail a JOIN users u ON u.username=a.username JOIN lifecycle_prefs p ON p.username=a.username WHERE a.status='pending' AND a.attempts<6 AND a.retry_at<=? AND u.is_registered=1 AND u.email IS NOT NULL AND p.progress=1 AND p.progress_blocked=0 ORDER BY a.created_at LIMIT 25`).all(now());
   for(const row of rows){
    const e=JSON.parse(row.payload),url='https://flags.worldarena.games/api/v1/lifecycle/preferences/'+row.unsubscribe_token,content=render(row,e,row.locale,url);
    const claim=db.prepare("UPDATE award_mail SET status='sending',attempts=attempts+1 WHERE username=? AND event_key=? AND status='pending'").run(row.username,row.event_key);if(!claim.changes)continue;
    try{await sendMail(row.email,content.subject,content.text,content.html,{unsubscribeURL:url,tag:'lifecycle'});db.prepare("UPDATE award_mail SET status='sent' WHERE username=? AND event_key=?").run(row.username,row.event_key)}
    catch(error){db.prepare("UPDATE award_mail SET status='pending',retry_at=? WHERE username=? AND event_key=?").run(now()+Math.min(86400000,300000*2**row.attempts),row.username,row.event_key);continue}
    try{inbox.recordForUser(db,row.username,{id:'award:'+crypto.createHash('sha256').update(row.username+':'+row.event_key).digest('hex'),title:content.title,body:content.body,kind:'progress',details:e.type==='level'?{level:100,xp:e.xp}:{rank:e.rank,participants:e.participants,league:e.league,week:e.week}})}catch(error){console.error('[award inbox]',error.message)}
   }
  }finally{busy=false}
 }
 // A crash during provider delivery has an unknown outcome. Do not automatically
 // replay 'sending' records and risk a duplicate congratulation email.
 const timer=setInterval(()=>tick().catch(e=>console.error('[award mail]',e.message)),60000);timer.unref();
 return {tick};
}
module.exports={install,render};
