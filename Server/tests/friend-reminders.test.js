const {test}=require('node:test');
const assert=require('node:assert/strict');
let Database;
try { ({DatabaseSync: Database}=require('node:sqlite')); } catch { Database=require('better-sqlite3'); }
const reminders=require('../friend-reminders');
function fixture() {
 const db=new Database(':memory:');
 db.exec(`CREATE TABLE users(username TEXT PRIMARY KEY); INSERT INTO users VALUES('alice'),('bob'),('carol');
 CREATE TABLE nudges(id TEXT,from_username TEXT,to_username TEXT,created_at TEXT);
 CREATE TABLE lifecycle_events(username TEXT,at INTEGER);`);
 reminders.initialize(db);return db;
}
const now=Date.parse('2026-11-21T00:30:00Z');
test('profile sync never counts as playing; actual game uses recipient day',()=>{
 const db=fixture();reminders.recordActivity(db,'bob',null,'America/New_York',now);
 assert.equal(reminders.status(db,'alice','bob',now).playedToday,false);
 reminders.recordActivity(db,'bob',Date.parse('2026-11-20T15:00:00Z'),'America/New_York',now);
 assert.equal(reminders.status(db,'alice','bob',now).playedToday,true);
 assert.equal(reminders.status(db,'alice','bob',now+6*3600000).playedToday,false);
 reminders.recordActivity(db,'bob',now+86400000,'America/New_York',now);
 assert.equal(reminders.status(db,'alice','bob',now+6*3600000).playedToday,false);db.close();
});
test('receipts survive reads and suppress only the same sender on their local day',()=>{
 const db=fixture();reminders.recordActivity(db,'alice',null,'Europe/Madrid',now);
 db.prepare('INSERT INTO nudges VALUES(?,?,?,?)').run('one','alice','bob','2026-11-20 23:30:00');
 assert.equal(reminders.status(db,'alice','bob',now).remindedToday,true);
 assert.equal(reminders.status(db,'carol','bob',now).remindedToday,false);
 assert.equal(reminders.status(db,'alice','bob',now+86400000).remindedToday,false);db.close();
});
test('older completed-game events are accepted without treating profile changes as games',()=>{
 const db=fixture();db.prepare('INSERT INTO lifecycle_events VALUES(?,?)').run('bob',now-1000);
 assert.equal(reminders.status(db,'alice','bob',now).playedToday,true);db.close();
});
