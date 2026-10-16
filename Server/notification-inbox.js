'use strict';
const crypto=require('node:crypto');
function initialize(db) {
 db.exec(`CREATE TABLE IF NOT EXISTS notification_inbox(id TEXT PRIMARY KEY,username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,title TEXT NOT NULL,body TEXT NOT NULL,kind TEXT NOT NULL,created_at INTEGER NOT NULL,read_at INTEGER); CREATE INDEX IF NOT EXISTS notification_inbox_user_unread ON notification_inbox(username,read_at)`);
}
function record(db,token,notification,explicitAlert) {
 const alert=explicitAlert||notification.alert||notification.aps?.alert;
 if(!alert)return;
 const title=typeof alert==='string'?'World Arena':alert.title;
 const body=typeof alert==='string'?alert:alert.body;
 if(typeof title!=='string'||typeof body!=='string')return;
 initialize(db);
 const user=db.prepare('SELECT username FROM users WHERE device_token=?').get(token);
 if(!user)return;
 const payload=notification.payload||{};
 const id=payload.challengeId?`${payload.type}:${payload.challengeId}:${user.username}`:crypto.randomUUID();
 db.prepare('INSERT OR IGNORE INTO notification_inbox(id,username,title,body,kind,created_at) VALUES(?,?,?,?,?,?)').run(id,user.username,title,body,payload.type||'message',Date.now());
 notification.payload={...payload,notificationId:id};
 notification.badge=db.prepare('SELECT COUNT(*) AS n FROM notification_inbox WHERE username=? AND read_at IS NULL').get(user.username).n;
}
function install(app,db,authenticate) {
 initialize(db);
 app.get('/api/v1/notifications', (req,res)=>{
  const user=authenticate(req);if(!user)return res.status(401).json({error:'Sign in required'});
  const rows=db.prepare('SELECT id,title,body,kind,created_at AS createdAt,read_at AS readAt FROM notification_inbox WHERE username=? ORDER BY created_at DESC LIMIT 200').all(user.username);
  const unread=db.prepare('SELECT COUNT(*) AS count FROM notification_inbox WHERE username=? AND read_at IS NULL').get(user.username).count;
  res.set('Cache-Control','no-store').json({items:rows,unread});
 });
 app.post('/api/v1/notifications/read', (req,res)=>{
  const user=authenticate(req);if(!user)return res.status(401).json({error:'Sign in required'});
  db.prepare('UPDATE notification_inbox SET read_at=? WHERE username=? AND read_at IS NULL').run(Date.now(),user.username);
  res.json({ok:true});
 });
}
module.exports={record,install};
