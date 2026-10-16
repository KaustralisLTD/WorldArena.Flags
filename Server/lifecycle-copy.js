'use strict';
const phrases=require('./lifecycle-locales.json'),labels=require('./progress-mail-locales.json'),site=require('../shared/site-locales.json');
const rich=require('./lifecycle-rich-content');
const ids=['first_route','daylight_bonus','mastery_lab','weekly_passport','duel_brief','welcome_back','next_continent','capital_bridge'];
const esc=x=>String(x??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const supports=code=>Object.hasOwn(phrases,code);
function message(id,code,data={}){
 if(!supports(code)||!ids.includes(id))throw Error('Untranslated lifecycle message');
 const p=phrases[code],t=labels[code],s=site[code].explore,n=x=>new Intl.NumberFormat(code).format(x);

 const comparison=data.previousAccuracy!=null&&data.currentAccuracy!=null?`${data.previousAccuracy}% → ${data.currentAccuracy}%`:data.accuracy!=null?`${data.accuracy}%`:null;
 const body={first_route:s.setupBody,daylight_bonus:p.bonusBody,mastery_lab:p.masteryBody,weekly_passport:p.weeklyBody,duel_brief:p.duelBody,welcome_back:p.returnBody,next_continent:s.everyBody,capital_bridge:p.capitalBody}[id];
 const facts=[];
 if(id==='daylight_bonus')facts.push({label:'F-Bucks',value:'1 + 1 = 2'},{label:'',value:'12:00–16:00'});
 else if(id==='duel_brief'){
  facts.push({label:t.wins,value:`${n(data.wins||0)} / ${n(data.duels||0)}`});
  if(Number.isInteger(data.scoreWins))facts.push({label:t.wins+' · '+site[code].ui.score,value:n(data.scoreWins)});
  if(Number.isInteger(data.speedWins))facts.push({label:t.wins+' · '+site[code].ui.time,value:n(data.speedWins)});
 }else{
  if(Number.isInteger(data.games))facts.push({label:t.games,value:n(data.games)});
  if(comparison)facts.push({label:t.accuracy,value:comparison});
  if(Number.isInteger(data.activeDays))facts.push({label:p.activeDays,value:n(data.activeDays)});
  if(Number.isInteger(data.regionsPlayed))facts.push({label:p.regionsPlayed,value:n(data.regionsPlayed)});
 }
 const focusCountries=(data.focusCountries||[]).slice(0,4).map(c=>({code:c,name:rich.countryName(c,code),flag:rich.flag(c)}));
 const map={title:p.mapTitle,body:p.mapBody,caption:p.mapCaption,image:`map-${code}-v1.jpg`,steps:[p.profileLabel+' → '+p.mapCTA+'. '+p.mapTap,p.mapGreener,p.masteryExplanation],mastered:Number.isInteger(data.masteredCount)?{label:p.countriesMastered,value:n(data.masteredCount)}:null};
 const stories=rich.stories(code,id,data);
 const insight=id==='daylight_bonus'&&Number.isInteger(data.habitDays)&&Number.isInteger(data.morningDays)?p.habitIntro.replaceAll('{morning}',n(data.morningDays)).replaceAll('{days}',n(data.habitDays)):null;
 let period=null;
 if(data.periodStart&&data.periodEnd){const formatter=new Intl.DateTimeFormat(code,{month:'short',day:'numeric',timeZone:data.timezone||'UTC'});period=formatter.formatRange(data.periodStart,data.periodEnd);}

 const button=id==='duel_brief'?p.duelCTA:id==='mastery_lab'?p.practiceCTA:['first_route','weekly_passport','welcome_back','next_continent'].includes(id)?p.mapCTA:s.play;
 return {title:p[id],body,button,subject:p[id]+' · World Arena',facts,period,focusCountries,map,stories,insight,challenge:['duel_brief','capital_bridge','welcome_back'].includes(id)?null:{title:id==='daylight_bonus'?p.nextStep:p.challengeTitle,body:id==='daylight_bonus'?p.bonusInstructions:p.challengeBody},storyIntro:site[code].explore.storyBody,storyTitle:p.factsTitle};
}
function email(m,code,url,unsubscribe,options={}){
 if(!supports(code))throw Error('Untranslated lifecycle email');
 return require('./lifecycle-email').render(m,code,url,unsubscribe,options);
}

function preferences(code){const t=labels[code];return `<!doctype html><html lang="${code}" dir="${code==='ar'?'rtl':'ltr'}"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><body style="font:18px system-ui;padding:32px"><h1>${esc(t.preferences)}</h1><form method="post"><button style="font:inherit;padding:16px">${esc(phrases[code].unsubscribeCTA)}</button></form></body></html>`;}
function unsubscribed(code){return `<!doctype html><html lang="${code}" dir="${code==='ar'?'rtl':'ltr'}"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><body style="font:18px system-ui;padding:32px"><h1>World Arena Flags</h1><p>${esc(phrases[code].unsubscribed)}</p></body></html>`;}
function landing(code,id){const t=labels[code];return `<!doctype html><html lang="${code}" dir="${code==='ar'?'rtl':'ltr'}"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><body style="font:18px system-ui;padding:32px;background:#edf4ef;color:#0a3439"><h1>World Arena Flags</h1><a href="worldarenaflags://campaign/${esc(id)}">${esc(t.cta)}</a><p><a href="https://apps.apple.com/app/id6744296834">App Store</a></p></body></html>`;}
module.exports={supports,message,email,preferences,unsubscribed,landing,readyTemplates:()=>Object.fromEntries(Object.keys(phrases).map(k=>[k,ids]))};
