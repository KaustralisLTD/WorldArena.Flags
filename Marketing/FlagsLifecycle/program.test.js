const {test}=require('node:test'),assert=require('node:assert/strict');
const {analyze,decide,localParts}=require('./program');
const DAY=86400000,now=Date.parse('2026-10-16T10:30:00Z');
const events=Array.from({length:10},(_,i)=>({id:'game-'+i,type:'game_completed',at:Date.parse('2026-10-16T06:30:00Z')-i*DAY,answers:20,correct:18,mode:'classic',difficulty:'medium',region:'europe'}));
const profile={locale:'ru',readyTemplates:{ru:['first_route','daylight_bonus','mastery_lab','weekly_passport','duel_brief','welcome_back','next_continent','capital_bridge']},id:'qa-player',registered:true,timezone:'Europe/Madrid',timezoneStableDays:14,marketingConsent:true,progressConsent:true,emailVerified:true,emailAvailable:true,inAppAvailable:true,reminderTime:'19:15',firstDailyRewardClaimed:true,rewardBudgetAvailable:true,capabilities:{signedRewardOffer:true,rewardLedger:true,bonusRoute:true}};
test('habits require enough distinct days, not repeated games on one day',()=>{
 assert.equal(analyze(events,'Europe/Madrid',now).dominant,'morning');
 const farm=Array.from({length:100},(_,i)=>({...events[0],id:'farm'+i,at:events[0].at+i*1000}));
 assert.equal(analyze(farm,'Europe/Madrid',now).dominant,null);
});
test('reward offer requires consent, ledger, timezone stability and an already completed daily game',()=>{
 const offer=decide(profile,events,now);assert.equal(offer.journey,'daylight_bonus');assert.equal(offer.reward.maxExtra,1);assert.equal(offer.scheduledReminderTimeUnchanged,'19:15');
 for(const patch of [{marketingConsent:false},{rewardBudgetAvailable:false},{firstDailyRewardClaimed:false},{timezoneStableDays:1},{capabilities:{signedRewardOffer:true}}])assert.notEqual(decide({...profile,...patch},events,now).journey,'daylight_bonus');
 assert.notEqual(decide(profile,events.slice(1),now).journey,'daylight_bonus');
});
test('one opted-in journey at a time, quiet hours and cross-channel caps',()=>{
 const contacted={...profile,contacts:[{kind:'marketing',channel:'push',journey:'other',at:now-3600000}]};
 assert.equal(decide(contacted,events,now).status,'suppress');
 const night=Date.parse('2026-10-16T22:00:00Z');
 assert.equal(decide({...profile,inAppAvailable:false},events,night).status,'observe');
 assert.equal(decide({...profile,gameInProgress:true},events,now).status,'suppress');
});
test('daypart recommendation is withheld once the new slot is already used',()=>{
 const afternoon={...events[0],id:'afternoon',at:Date.parse('2026-10-15T12:00:00Z')};
 assert.notEqual(decide(profile,[...events,afternoon],now).journey,'daylight_bonus');
});
test('learning need outranks a currency promotion; completed goals stop it',()=>{
 const p={...profile,mistakeCountryCount:3,capabilities:{...profile.capabilities,reviewMistakes:true}};
 assert.equal(decide(p,events,now).journey,'mastery_lab');
 assert.equal(decide({...p,completedGoals:['correct_repeated_mistakes']},events,now).journey,'daylight_bonus');
});
test('timezone and data quality: DST uses IANA rules, duplicates and impossible answers ignored',()=>{
 assert.equal(localParts(Date.parse('2026-10-25T00:30Z'),'Europe/Madrid').hour,2);
 assert.equal(localParts(Date.parse('2026-10-25T01:30Z'),'Europe/Madrid').hour,2);
 assert.equal(analyze([...events,events[0],{...events[0],id:'bad',correct:21}],'Europe/Madrid',now).events.length,10);
 assert.equal(decide({...profile,timezone:'bad-zone'},events,now).reason,'timezone_invalid');
 assert.equal(decide({...profile,timezone:null},events,now).reason,'timezone_missing');
});
test('weekly progress category does not grant permission for bonuses and cross-promotion',()=>{
 const p={...profile,marketingConsent:false,weeklyReportDue:true};
 const decision=decide(p,events,now);assert.equal(decision.journey,'weekly_passport');
 assert.equal(decide({...p,progressConsent:false},events,now).status,'observe');
});
test('three ignored emails suppress further external marketing; experiment assignment is stable',()=>{
 assert.equal(decide({...profile,unresponsiveEmails:3,inAppAvailable:false},events,now).status,'observe');
 assert.equal(decide(profile,events,now).status,decide(profile,events,now).status);
});

test('new players get a small second-day step rather than an invented habit',()=>{
 const first=[{...events[0],id:'only-game',at:now-DAY}];
 const p={...profile,capabilities:{regionRoute:true},firstDailyRewardClaimed:false};
 assert.equal(decide(p,first,now).journey,'first_route');
 assert.equal(decide(p,first,now).analysis.dominant,null);
});

test('no untranslated template, expired daytime slot or misleading accuracy comparison',()=>{
 assert.equal(decide({...profile,locale:'ja'},events,now).status,'observe');
 assert.notEqual(decide(profile,events,Date.parse('2026-10-16T15:00:00Z')).journey,'daylight_bonus');
 const mixed=events.map((e,i)=>({...e,difficulty:i<7?'easy':'hard'}));
 assert.equal(analyze(mixed,'Europe/Madrid',now).comparable,null);
 assert.ok(analyze(events,'Europe/Madrid',now).comparable);
});

 test('full rollout has no holdout while opt-outs remain respected',()=>{
 for(let i=0;i<200;i++)assert.equal(decide({...profile,id:'rollout-'+i,holdoutPercent:0},events,now).status,'eligible');
 assert.equal(decide({...profile,holdoutPercent:0,marketingConsent:false,progressConsent:false},events,now).status,'observe');
});
