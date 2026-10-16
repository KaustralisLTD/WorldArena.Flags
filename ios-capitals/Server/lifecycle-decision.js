'use strict';
// Shared deterministic lifecycle selection; delivery and reward checks live in lifecycle.js.
const crypto=require('node:crypto');
const DAY=86400000;
function localParts(time,zone) {
 const parts=new Intl.DateTimeFormat('en-CA',{timeZone:zone,year:'numeric',month:'2-digit',day:'2-digit',hour:'2-digit',hourCycle:'h23'}).formatToParts(new Date(time));
 const value=k=>parts.find(p=>p.type===k).value;
 return {day:`${value('year')}-${value('month')}-${value('day')}`,hour:Number(value('hour'))};
}
function bucket(hour) {return hour>=6&&hour<12?'morning':hour>=12&&hour<17?'afternoon':hour>=17&&hour<22?'evening':'night';}
function analyze(events,zone,now=Date.now()) {
 const seen=new Set();const valid=events.filter(e=>{
  if(!e.id||seen.has(e.id)||e.type!=='game_completed'||!Number.isFinite(e.at)||e.at>now||e.at<now-28*DAY||!Number.isInteger(e.answers)||e.answers<=0||!Number.isInteger(e.correct)||e.correct<0||e.correct>e.answers)return false;
  seen.add(e.id);return true;
 }).sort((a,b)=>a.at-b.at);
 const days=new Map();
 for(const event of valid){const p=localParts(event.at,event.timezone||zone),counts=days.get(p.day)||{};const b=bucket(p.hour);counts[b]=(counts[b]||0)+1;days.set(p.day,counts);}
 const weights={morning:0,afternoon:0,evening:0,night:0};
 for(const counts of days.values()) {const max=Math.max(...Object.values(counts));const winners=Object.keys(counts).filter(k=>counts[k]===max);for(const b of winners)weights[b]+=1/winners.length;}
 const winner=Object.keys(weights).sort((a,b)=>weights[b]-weights[a])[0];
 const confidence=days.size?weights[winner]/days.size:0;
 const current=valid.filter(e=>e.at>=now-7*DAY),previous=valid.filter(e=>e.at>=now-14*DAY&&e.at<now-7*DAY);
 const stats=xs=>{const answers=xs.reduce((n,e)=>n+e.answers,0),correct=xs.reduce((n,e)=>n+e.correct,0);return {games:xs.length,answers,correct,accuracy:answers>=30?Math.round(100*correct/answers):null};};
 const groups=xs=>{const map=new Map();for(const e of xs){if(!e.mode||!e.difficulty||!e.region)continue;const key=JSON.stringify([e.mode,e.difficulty,e.region]);map.set(key,[...(map.get(key)||[]),e]);}return map;};
 const currentGroups=groups(current),previousGroups=groups(previous);
 let comparable=null;
 for(const [context,rows] of currentGroups){const cs=stats(rows),ps=stats(previousGroups.get(context)||[]);if(cs.accuracy!==null&&ps.accuracy!==null&&(!comparable||cs.answers>comparable.current.answers))comparable={context:JSON.parse(context),current:cs,previous:ps};}
 return {comparable,events:valid,activeDays:days.size,dominant:days.size>=8&&confidence>=0.7?winner:null,confidence,current:stats(current),previous:stats(previous),lastPlayed:valid.at(-1)?.at||null,playedToday:days.has(localParts(now,zone).day)};
}
function chooseChannel(p,campaign,now) {
 const category=campaign==='weekly_passport'?'progress':'coaching';
 if(category==='progress'?!p.progressConsent:!p.marketingConsent)return null;
 const contacts=p.contacts||[];
 const prior=contacts.filter(x=>x.kind==='marketing'||x.kind==='progress');
 const inWeek=prior.filter(x=>x.channel==='email'&&x.at>now-7*DAY);
 if((p.unresponsiveEmails||0)>=3)return p.inAppAvailable?'in_app':null;
 const cooldown=campaign==='daylight_bonus'?DAY:campaign==='weekly_passport'||campaign==='duel_brief'?7*DAY:14*DAY;
 if(prior.some(x=>x.journey===campaign&&x.at>now-cooldown))return null;
 if(p.inAppAvailable&&!p.gameInProgress)return 'in_app';
 const hour=localParts(now,p.timezone).hour;
 if(hour<9||hour>=21)return null;
 if(p.emailVerified&&p.emailAvailable&&inWeek.length<2&&!prior.some(x=>x.at>now-DAY))return 'email';
 if(p.pushConsent&&!prior.some(x=>x.channel==='push'&&x.at>now-DAY)&&prior.filter(x=>x.channel==='push'&&x.at>now-7*DAY).length<3)return 'push';
 return null;
}
function decide(profile,events,now=Date.now()) {
 const p=profile;
 if(!p.timezone)return {status:'observe',reason:'timezone_missing'};
 let a;try{a=analyze(events,p.timezone,now)}catch{return {status:'observe',reason:'timezone_invalid'}}
 if(!p.registered)return {status:'observe',reason:'email_requires_registered_account',analysis:a};
 if(p.suspended||p.unsubscribed||p.gameInProgress)return {status:'suppress',reason:'account_or_context',analysis:a};
 const lastContact=(p.contacts||[]).filter(x=>x.kind==='marketing'||x.kind==='progress').sort((x,y)=>y.at-x.at)[0];
 if(lastContact&&now-lastContact.at<DAY)return {status:'suppress',reason:'cross_channel_daily_cap',analysis:a};
 const candidates=[];
 if(a.current.games===1&&a.activeDays===1&&!a.playedToday&&p.capabilities?.regionRoute&&a.lastPlayed&&now-a.lastPlayed>=12*3600000&&now-a.lastPlayed<=72*3600000)candidates.push({id:'first_route',priority:90,goal:'complete_second_active_day'});
 const daysAway=a.lastPlayed?(now-a.lastPlayed)/DAY:null;
 if(daysAway>=7&&daysAway<30)candidates.push({id:'welcome_back',priority:100,goal:'complete_return_game'});
 if(a.current.games>=3&&a.current.answers>=30&&p.weeklyReportDue)candidates.push({id:'weekly_passport',priority:70,goal:'open_map_then_play'});
 if(p.mistakeCountryCount>=3&&a.current.answers>=30&&p.capabilities?.reviewMistakes)candidates.push({id:'mastery_lab',priority:80,goal:'correct_repeated_mistakes'});
 if(p.completedDuels7d>=5&&p.duelSummaryDue)candidates.push({id:'duel_brief',priority:65,goal:'complete_next_opt_in_duel'});
 if(p.countryMasteryRatio>=0.75&&p.capabilities?.regionRoute)candidates.push({id:'next_continent',priority:60,goal:'complete_new_region_game'});
 if(a.dominant==='morning'&&localParts(now,p.timezone).hour<16&&a.events.some(e=>localParts(e.at,e.timezone||p.timezone).day===localParts(now,p.timezone).day&&bucket(localParts(e.at,e.timezone||p.timezone).hour)==='morning')&&p.firstDailyRewardClaimed===true&&a.current.games>=3&&!a.events.some(e=>bucket(localParts(e.at,p.timezone).hour)==='afternoon')&&p.marketingConsent&&p.capabilities?.signedRewardOffer&&p.capabilities?.rewardLedger&&p.capabilities?.bonusRoute&&p.rewardBudgetAvailable&&p.timezoneStableDays>=7)candidates.push({id:'daylight_bonus',priority:50,goal:'complete_verified_bonus_game',reward:{base:'eligible_perfect_game',multiplier:2,maxExtra:1,maxClaimsPerDay:1,maxClaimsPer7d:2,windowLocal:[12,16]}});
 if(a.current.games>=5&&a.current.accuracy>=85&&p.capabilities?.capitalsLink&&!p.capitalsAlreadyUsed)candidates.push({id:'capital_bridge',priority:20,goal:'start_capitals_first_game'});
 for(const c of candidates.sort((x,y)=>y.priority-x.priority)){
  if((p.completedGoals||[]).includes(c.goal))continue;
  if(!p.readyTemplates?.[p.locale]?.includes(c.id))continue;
  const channel=chooseChannel(p,c.id,now);if(!channel)continue;
  const holdout=crypto.createHash('sha256').update(`${p.id}:lifecycle-pilot-v1`).digest().readUInt32BE(0)%100<(p.holdoutPercent??10);
  return {status:holdout?'holdout':'eligible',journey:c.id,channel,goal:c.goal,reward:c.reward||null,analysis:a,scheduledReminderTimeUnchanged:p.reminderTime||null};
 }
 return {status:'observe',reason:'no_relevant_journey',analysis:a};
}
module.exports={analyze,decide,bucket,localParts,chooseChannel};
