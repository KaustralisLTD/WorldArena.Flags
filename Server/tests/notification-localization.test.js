'use strict';
const {test}=require('node:test');
const assert=require('node:assert/strict');
const i18n=require('../notification-localization');
const copies=require('../notification-locales.json');

test('every supported locale renders system events with its own catalog, preserving names and scores',()=>{
 assert.equal(Object.keys(copies).length,30);
 for(const [code,t] of Object.entries(copies)){
  const name='Ірина %@ 李';
  assert.deepEqual(i18n.render('duel_challenge',{opponentName:name},code),{title:t.Duel,body:t['Duel challenge from %@'].replace('%@',name)});
  const result=i18n.render('duel_result',{iWon:true,myScore:15,opponentScore:14,opponentName:name},code);
  assert.equal(result.title,t.Victory);assert.equal(result.body,`${t.You}: 15 · ${name}: 14`);
  assert.equal(i18n.render('friend_request',{senderName:name},code).body,`${name}: ${t['friends.requests.body']}`);
  for(let phraseID=0;phraseID<16;phraseID++)assert.equal(i18n.render('nudge',{senderName:name,phraseID},code).body,t['nudge_phrase_'+(phraseID+1)]);
  assert.equal(i18n.render('progress',{level:100,xp:99000},code).title,t['Уровень']+' 100');
  assert.equal(i18n.render('progress',{league:'Gold League',rank:2},code).body,t['Золотая лига']+' · #2');
 }
});
test('Russian recipients never use sender language; old known English events are reconstructed',()=>{
 const ru=copies.ru;
 assert.equal(i18n.render('friend_request',null,'ru',{title:'World Arena',body:'Alice added you as a friend. Open the app to add them back or decline.'}).title,ru['friends.requests.title']);
 assert.equal(i18n.render('nudge',{},'ru',{title:'Alice reminds you',body:copies.en.nudge_phrase_1}).body,ru.nudge_phrase_1);
 assert.equal(i18n.render('duel_challenge',{},'ru',{title:'Duel',body:'Alice challenged you to a duel'}).body,ru['Duel challenge from %@'].replace('%@','Alice'));
});
test('locale aliases preserve traditional Chinese and Brazilian Portuguese',()=>{
 for(const x of ['zh-Hant','zh_Hant_TW','zh-TW','zh-HK','zh-MO'])assert.equal(i18n.locale(x),'zh-Hant');
 assert.equal(i18n.locale('zh-CN'),'zh');assert.equal(i18n.locale('pt_BR'),'pt-BR');assert.equal(i18n.locale('pt-PT'),'pt-BR');
 assert.equal(i18n.locale('tl-PH'),'fil');assert.equal(i18n.locale('ru-RU, en;q=0.9'),'ru');assert.equal(i18n.locale('invalid'),'en');
});
test('free-form messages and player-authored nudge text are never translated or discarded',()=>{
 const original={title:'Private message',body:'Alice wrote this: %d %@'};
 assert.deepEqual(i18n.render('message',{},'ru',original),original);
 assert.deepEqual(i18n.render('nudge',{},'ru',original),original);
});
test('localized campaign snapshots switch language without changing historical facts',()=>{
 const d={localizedTitles:{ru:'Неделя',en:'Week'},localizedBodies:{ru:'Победы: 3',en:'Wins: 3'}};
 assert.deepEqual(i18n.render('lifecycle',d,'ru'),{title:'Неделя',body:'Победы: 3'});
 assert.equal(d.localizedBodies.en,'Wins: 3');
});
test('old lifecycle cards translate known labels and preserve the original numbers',()=>{
 const message=require('../lifecycle-copy').message('duel_brief','en',{wins:3,duels:5,scoreWins:2,speedWins:1});
 const row={title:message.title,body:[message.body,...message.facts.map(f=>f.label+': '+f.value)].join('\n')};
 const details=i18n.legacyLifecycleDetails('duel_brief',row);
 assert.ok(details.localizedBodies.ru.includes('3 / 5'));
 assert.ok(details.localizedBodies.ru.includes('Победы в дуэлях: 3 / 5'));
 assert.equal(details.localizedBodies.en,row.body);
 assert.equal(i18n.legacyLifecycleDetails('duel_brief',{title:'Custom title',body:'Custom body'}),null);
});

test('legacy duel scores survive empty metadata without a matching database row',()=>{
 const fallback={title:'Duel victory!',body:'You won against Alice. Your score: 15; opponent: 14.'};
 assert.deepEqual(i18n.render('duel_result',{},'ru',fallback),{title:copies.ru.Victory,body:copies.ru.You+': 15 · Alice: 14'});
});
