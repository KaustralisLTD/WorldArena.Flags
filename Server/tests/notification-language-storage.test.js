'use strict';
const {test}=require('node:test'),assert=require('node:assert/strict'),Database=require('better-sqlite3');
const inbox=require('../notification-inbox'),i18n=require('../notification-localization');
test('recipient preference, old history, payload details and read state stay isolated by account',()=>{
 const db=new Database(':memory:');
 db.exec("CREATE TABLE users(username TEXT PRIMARY KEY,device_token TEXT); INSERT INTO users VALUES('alice','a-token'),('bob','b-token')");
 const routes={};inbox.install({get:(p,f)=>routes[p]=f,post:(p,f)=>routes[p]=f},db,req=>({username:req.username}));
 i18n.saveLocale(db,'alice','en');i18n.saveLocale(db,'bob','ru');
 assert.equal(i18n.recipientLocale(db,{token:'a-token'}),'en');assert.equal(i18n.recipientLocale(db,{token:'b-token'}),'ru');
 const notification={payload:{type:'friend_request',details:{senderName:'Alice'}}};
 inbox.record(db,'b-token',notification,{title:'World Arena',body:'Alice added you as a friend. Open the app to add them back or decline.'});
 assert.equal(JSON.parse(db.prepare('SELECT details FROM notification_inbox').get().details).senderName,'Alice');
 function get(username,language){let response;routes['/api/v1/notifications']({username,headers:language?{'accept-language':language}:{}},{set(){return this},json(x){response=x}});return response}
 assert.equal(get('alice').items.length,0);
 let page=get('bob');assert.equal(page.items[0].title,'Запросы в друзья');assert.equal(page.unread,1);
 const id=page.items[0].id;
 db.prepare('UPDATE notification_inbox SET read_at=123 WHERE id=?').run(id);
 page=get('bob','fr-FR');assert.equal(page.items[0].title,'Demandes d’amitié');assert.equal(page.items[0].readAt,123);assert.equal(page.unread,0);
 assert.equal(i18n.recipientLocale(db,{token:'b-token'}),'fr');assert.equal(i18n.recipientLocale(db,{token:'a-token'}),'en');
 // A malformed old metadata record must not prevent the rest of the inbox loading.
 db.prepare("UPDATE notification_inbox SET details='broken' WHERE id=?").run(id);
 assert.equal(get('bob','ru').items[0].title,'Запросы в друзья');
 db.close();
});
test('legacy lifecycle language is available before a new client sync',()=>{
 const db=new Database(':memory:');db.exec("CREATE TABLE users(username TEXT PRIMARY KEY,device_token TEXT); INSERT INTO users VALUES('bob','b-token'); CREATE TABLE lifecycle_prefs(username TEXT,locale TEXT); INSERT INTO lifecycle_prefs VALUES('bob','uk')");inbox.initialize(db);
 assert.equal(i18n.recipientLocale(db,{token:'b-token'}),'uk');db.close();
});
