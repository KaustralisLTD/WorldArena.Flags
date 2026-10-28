'use strict';
const copies = require('./notification-locales.json');
function locale(value) {
 const raw=String(value||'').split(',')[0].split(';')[0].trim().replace(/_/g,'-').toLowerCase();
 if(raw==='tl'||raw.startsWith('tl-')||raw==='fil'||raw.startsWith('fil-'))return 'fil';
 if(raw.startsWith('pt'))return 'pt-BR';
 if(raw.startsWith('zh'))return /hant|^zh-(tw|hk|mo)(-|$)/.test(raw)?'zh-Hant':'zh';
 const code=raw.split('-')[0];return Object.hasOwn(copies,code)?code:'en';
}
function saveLocale(db,username,value) {
 if(typeof value==='string'&&value.trim())db.prepare('UPDATE users SET notification_locale=? WHERE username=?').run(locale(value),username);
}
function recipientLocale(db,{token,username}) {
 const row=token?db.prepare('SELECT username,notification_locale FROM users WHERE device_token=?').get(token):db.prepare('SELECT username,notification_locale FROM users WHERE username=?').get(username);
 if(row?.notification_locale)return locale(row.notification_locale);
 if(row)for(const table of ['lifecycle_prefs','progress_mail']) {
  if(db.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name=?").get(table)){
   const saved=db.prepare(`SELECT locale FROM ${table} WHERE username=?`).get(row.username);if(saved?.locale)return locale(saved.locale);
  }
 }
 return 'en';
}
function text(language,key,args=[]) {
 const template=copies[locale(language)][key]??copies.en[key]??key;
 let index=0;return template.replace(/%@/g,()=>String(args[index++]??''));
}
function detailsFor(kind,details={},fallback={}) {
 const d=details && typeof details==='object' && !Array.isArray(details)?{...details}:{};
 if(kind==='duel_result' && !Number.isInteger(d.myScore)){
  const match=String(fallback.body||'').match(/^You (won|lost) against (.+)\. Your score: ([0-9]+); opponent: ([0-9]+)\.$/);
  if(match)Object.assign(d,{opponentName:match[2],myScore:Number(match[3]),opponentScore:Number(match[4]),iWon:match[1]==='won'});
 }
 if(kind==='friend_request'&&!d.senderName){const suffix=' added you as a friend. Open the app to add them back or decline.';if(fallback.body?.endsWith(suffix))d.senderName=fallback.body.slice(0,-suffix.length);}
 if(kind==='duel_challenge'&&!d.opponentName){const suffix=' challenged you to a duel';if(fallback.body?.endsWith(suffix))d.opponentName=fallback.body.slice(0,-suffix.length);}
 if(kind==='nudge'){
  if(!d.senderName&&fallback.title?.endsWith(' reminds you'))d.senderName=fallback.title.slice(0,-' reminds you'.length);
  if(!Number.isInteger(d.phraseID))for(let i=1;i<=16;i++)if(Object.values(copies).some(c=>c['nudge_phrase_'+i]===fallback.body)){d.phraseID=i-1;break;}
 }
 return d;
}
function render(kind,rawDetails,language,fallback={title:'World Arena',body:''}) {
 const d=detailsFor(kind,rawDetails||{},fallback),t=(key,args)=>text(language,key,args);
 if(d.localizedTitles?.[locale(language)]&&d.localizedBodies?.[locale(language)])return {title:d.localizedTitles[locale(language)],body:d.localizedBodies[locale(language)]};
 if(kind==='duel_challenge')return {title:t('Duel'),body:d.opponentName?t('Duel challenge from %@',[d.opponentName]):fallback.body};
 if(kind==='duel_result'&&Number.isInteger(d.myScore)&&Number.isInteger(d.opponentScore))return {title:t(d.iWon===true?'Victory':d.iWon===false?'Defeat':'Duel'),body:`${t('You')}: ${d.myScore} · ${d.opponentName||'—'}: ${d.opponentScore}`};
 if(kind==='friend_request')return {title:t('friends.requests.title'),body:[d.senderName,t('friends.requests.body')].filter(Boolean).join(': ')};
 if(kind==='nudge'&&Number.isInteger(d.phraseID)&&d.phraseID>=0&&d.phraseID<16)return {title:d.senderName?t('notification.nudge.title',[d.senderName]):fallback.title,body:t('nudge_phrase_'+(d.phraseID+1))};
 if(kind==='progress'&&Number.isInteger(d.level))return {title:t('Уровень')+' '+d.level,body:t('Well done! Keep practicing!')+(Number.isInteger(d.xp)?` · ${d.xp} XP`:'')};
 if(kind==='progress'&&(d.league||d.leagueID)){
  const keys=['Бронзовая лига','Серебряная лига','Золотая лига','Лига Мастеров','Лига Чемпионов Мира'];
  const ids={'Бронза':keys[0],'Серебро':keys[1],'Золото':keys[2],'Платина':'Платина','Алмаз':'Алмаз','Мастер':keys[3]};
  const raw=d.leagueID||d.league,key=ids[raw]||[...keys,'Платина','Алмаз'].find(k=>k===raw||Object.values(copies).some(c=>c[k]===raw));
  return {title:t('Лиги'),body:[key?t(key):t('league.weekly_result.title.week_finished'),Number.isInteger(d.rank)?'#'+d.rank:null].filter(Boolean).join(' · ')};
 }
 return {title:fallback.title,body:fallback.body};
}
module.exports={locale,text,saveLocale,recipientLocale,detailsFor,render};

// Recover known old campaign copy without inventing new scores or dates.
const legacyCampaigns=new Map();
function legacyLifecycleDetails(journey,row) {
 const templates=require('./lifecycle-copy');
 if(!legacyCampaigns.has(journey)){
  const phrases=require('./lifecycle-locales.json'),labels=require('./progress-mail-locales.json'),site=require('../shared/site-locales.json');
  const samples={};
  for(const code of Object.keys(copies)){
   if(!templates.supports(code))continue;
   let m;try{m=templates.message(journey,code)}catch(_){continue;}
   samples[code]={title:m.title,body:m.body,labels:[labels[code].games,labels[code].accuracy,labels[code].wins,labels[code].wins+' · '+site[code].ui.score,labels[code].wins+' · '+site[code].ui.time,phrases[code].activeDays,phrases[code].regionsPlayed,'F-Bucks','']};
  }
  legacyCampaigns.set(journey,samples);
 }
 const samples=legacyCampaigns.get(journey),lines=String(row.body||'').split('\n');
 const origin=Object.values(samples).find(s=>s.title===row.title&&s.body===lines[0]);
 if(!origin)return null; // An administrator's custom message is not template copy.
 const localizedTitles={},localizedBodies={};
 for(const [code,sample] of Object.entries(samples)){
  localizedTitles[code]=sample.title;
  localizedBodies[code]=[sample.body,...lines.slice(1).map(line=>{
   const index=origin.labels.findIndex(label=>line.startsWith(label+': '));
   return index<0?line:sample.labels[index]+line.slice(origin.labels[index].length);
  })].join('\n');
 }
 return {localizedTitles,localizedBodies};
}
module.exports.legacyLifecycleDetails=legacyLifecycleDetails;
