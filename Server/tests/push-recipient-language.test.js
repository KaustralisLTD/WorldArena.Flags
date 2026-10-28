'use strict';
const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs'),path=require('node:path');
const Database=require('better-sqlite3');
const Module=require('node:module');
const inbox=require('../notification-inbox'),localization=require('../notification-localization');
const copies=require('../notification-locales.json');

test('actual APNs send path uses recipient language for all 30 locales, including language changes',async()=>{
 const db=new Database(':memory:');
 const saved={...process.env};
 try {
  db.exec("CREATE TABLE users(username TEXT PRIMARY KEY,device_token TEXT);INSERT INTO users VALUES('recipient','recipient-token')");inbox.initialize(db);
  const sent=[];
  class Notification {constructor(){this.aps={};}set alert(v){this.aps.alert=v;}}
  class Provider {async send(notification,token){sent.push({notification,token});return {failed:[]};}}
  const filename=path.join(__dirname,'../push.js');
  const isolated=new Module(filename,module);
  const mockRequire=name=>{
   if(name==='fs')return {existsSync:()=>true};
   if(name==='apn')return {Provider,Notification};
   if(name==='./db')return {db};
   return require(path.resolve(__dirname,'..',name));
  };
  // Execute as a Node module so native SQLite callbacks retain their environment.
  isolated.require=mockRequire;
  Object.assign(process.env,{APNS_KEY_ID:'test',APNS_TEAM_ID:'test',APNS_BUNDLE_ID:'test',APNS_KEY_P8_PATH:'fake'});
  isolated._compile(fs.readFileSync(filename,'utf8'),filename);
  const push=isolated.exports;
  const invoke=fn=>new Promise((resolve,reject)=>fn(error=>error?reject(error):resolve()));
  for(const language of Object.keys(copies)) {
   localization.saveLocale(db,'recipient',language);
   await invoke(done=>push.sendDuelChallengePush('recipient-token','Nadiia',done,'challenge-'+language));
   assert.equal(sent.at(-1).notification.aps.alert.title,copies[language].Duel);
   assert.equal(sent.at(-1).notification.aps.alert.body,localization.text(language,'Duel challenge from %@',['Nadiia']));
   const match={challengeId:'result-'+language,opponentName:'Nadiia',myScore:15,opponentScore:15,iWon:true};
   await invoke(done=>push.sendDuelResultPush('recipient-token',match,done));
   assert.deepEqual(JSON.parse(JSON.stringify(sent.at(-1).notification.aps.alert)),localization.render('duel_result',match,language));
   assert.equal(sent.at(-1).notification.payload.details.myScore,15);
   await invoke(done=>push.sendFriendRequestPush('recipient-token','Nadiia',done));
   assert.equal(sent.at(-1).notification.aps.alert.title,copies[language]['friends.requests.title']);
   await invoke(done=>push.sendNudgePush('recipient-token','Nadiia','sender-language-text',done,0));
   assert.equal(sent.at(-1).notification.aps.alert.body,copies[language].nudge_phrase_1);
  }
  assert.equal(sent.length,120);
  assert.ok(sent.every(x=>x.token==='recipient-token'));
 } finally {
  for(const key of ['APNS_KEY_ID','APNS_TEAM_ID','APNS_BUNDLE_ID','APNS_KEY_P8_PATH']) {
   if(saved[key]===undefined)delete process.env[key];else process.env[key]=saved[key];
  }
  db.close();
 }
});
