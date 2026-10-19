'use strict';
const {test}=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs'),os=require('node:os'),path=require('node:path');
function scenario(conflictingConsent){
 const dir=fs.mkdtempSync(path.join(os.tmpdir(),'flags-merge-'));process.env.DUEL_DB_PATH=path.join(dir,'test.db');
 const file=require.resolve('../db');delete require.cache[file];let store=require('../db');let db=store.db;
 for(const [username,code,date] of [['sspilberg','CODEONE','2020-01-01'],['Sspilberg','CODETWO','2021-01-01'],['friendqa','CODETHREE','2022-01-01']])db.prepare('INSERT INTO users(username,friend_code,created_at) VALUES(?,?,?)').run(username,code,date);
 for(const name of ['sspilberg','Sspilberg'])db.prepare('INSERT INTO friendships(user_username,friend_username) VALUES(?,?)').run(name,'friendqa');
 require('../notification-inbox').initialize(db);
 require('../notification-inbox').recordForUser(db,'Sspilberg',{id:'history',title:'Saved',body:'Keep this',readAt:123});
 db.exec('CREATE TABLE qa_consent(username TEXT PRIMARY KEY REFERENCES users(username) ON DELETE CASCADE,progress INTEGER NOT NULL)');
 db.prepare('INSERT INTO qa_consent VALUES(?,?)').run('Sspilberg',0);
 if(conflictingConsent)db.prepare('INSERT INTO qa_consent VALUES(?,?)').run('sspilberg',1);
 db.close();delete require.cache[file];store=require('../db');db=store.db;
 try{
  if(conflictingConsent){assert.equal(db.prepare('SELECT count(*) n FROM users').get().n,3);assert.equal(db.prepare('SELECT username FROM notification_inbox WHERE id=?').get('history').username,'Sspilberg');assert.equal(db.prepare('SELECT progress FROM qa_consent WHERE username=?').get('Sspilberg').progress,0)}
  else {assert.equal(db.prepare('SELECT count(*) n FROM users').get().n,2);assert.deepEqual(db.prepare('SELECT username,read_at FROM notification_inbox WHERE id=?').get('history'),{username:'sspilberg',read_at:123});assert.equal(db.prepare('SELECT count(*) n FROM friendships').get().n,1);assert.equal(db.prepare('SELECT progress FROM qa_consent WHERE username=?').get('sspilberg').progress,0)}
 }finally{db.close();delete require.cache[file];fs.rmSync(dir,{recursive:true,force:true})}
}
test('legacy merge unions duplicate friends and keeps notification history',()=>scenario(false));
test('legacy merge rolls back atomically when consent ownership conflicts',()=>scenario(true));
