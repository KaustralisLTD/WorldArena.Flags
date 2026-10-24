
'use strict';
const crypto=require('node:crypto');
function initialize(db) {
 db.exec(`CREATE TABLE IF NOT EXISTS notification_inbox(id TEXT PRIMARY KEY,username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,title TEXT NOT NULL,body TEXT NOT NULL,kind TEXT NOT NULL,created_at INTEGER NOT NULL,read_at INTEGER); CREATE INDEX IF NOT EXISTS notification_inbox_user_unread ON notification_inbox(username,read_at)`);
 for(const name of ['target','details'])if(!db.prepare('PRAGMA table_info(notification_inbox)').all().some(c=>c.name===name))db.exec('ALTER TABLE notification_inbox ADD COLUMN '+name+' TEXT');
}
function recordForUser(db,username,{id=crypto.randomUUID(),title,body,kind='message',target=null,createdAt=Date.now(),readAt=null,details=null}) {
 if(typeof title!=='string'||typeof body!=='string'||!title.trim()||!body.trim())throw Error('Notification title and body required');
 initialize(db);
 db.prepare('INSERT OR IGNORE INTO notification_inbox(id,username,title,body,kind,created_at,read_at,target,details) VALUES(?,?,?,?,?,?,?,?,?)').run(id,username,title,body,kind,createdAt,readAt,target,details?JSON.stringify(details):null);
 return id;
}
function record(db,token,notification,explicitAlert) {
 const alert=explicitAlert||notification.alert||notification.aps?.alert;if(!alert)return;
 const title=typeof alert==='string'?'World Arena':alert.title,body=typeof alert==='string'?alert:alert.body;
 if(typeof title!=='string'||typeof body!=='string')return;
 const user=db.prepare('SELECT username FROM users WHERE device_token=?').get(token);if(!user)return;
 const payload=notification.payload||{};
 const id=payload.notificationId || (payload.challengeId?`${payload.type}:${payload.challengeId}:${user.username}`:crypto.randomUUID());
 recordForUser(db,user.username,{id,title,body,kind:payload.type||'message',target:payload.challengeId||null});
 notification.payload={...payload,notificationId:id};
 notification.badge=db.prepare('SELECT COUNT(*) AS n FROM (SELECT read_at FROM notification_inbox WHERE username=? ORDER BY created_at DESC LIMIT 200) WHERE read_at IS NULL').get(user.username).n;
}
function install(app,db,authenticate) {
 initialize(db);
 app.get('/api/v1/notifications', (req,res)=>{
  const user=authenticate(req);if(!user)return res.status(401).json({error:'Sign in required'});
  if(db.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name='duel_challenges'").get() && db.prepare('PRAGMA table_info(duel_challenges)').all().some(c=>c.name==='id')) {
   db.prepare("UPDATE notification_inbox SET read_at=? WHERE username=? AND kind='duel_challenge' AND read_at IS NULL AND EXISTS(SELECT 1 FROM duel_challenges d WHERE (notification_inbox.target=d.id OR notification_inbox.id='duel_challenge:'||d.id||':'||notification_inbox.username) AND (d.status NOT IN ('pending','challenger_completed') OR d.opponent_score IS NOT NULL))").run(Date.now(),user.username);
  }
  const rows=db.prepare('SELECT id,title,body,kind,target,details,created_at AS createdAt,read_at AS readAt FROM notification_inbox WHERE username=? ORDER BY created_at DESC LIMIT 200').all(user.username);
  // Hydrate historical result notifications without changing their read state.
  const duelColumns=db.prepare('PRAGMA table_info(duel_challenges)').all().map(c=>c.name);
  const canHydrate=['id','challenger_id','opponent_id','challenger_time_ms','opponent_time_ms'].every(c=>duelColumns.includes(c));
  const findDuel=canHydrate?db.prepare('SELECT * FROM duel_challenges WHERE id=? AND (challenger_id=? OR opponent_id=?)'):null;
  const items=rows.map(r=>{
   let details=r.details?JSON.parse(r.details):null;
   if(canHydrate && (r.kind==='duel_result' || r.kind==='duel_challenge') && r.target){
    const duel=findDuel.get(r.target,user.username,user.username);
    if(duel){const own=duel.challenger_id===user.username;
     if(r.kind==='duel_challenge') details={...details,opponentName:duel.challenger_name};
     else {
      const cs=duel.challenger_score,os=duel.opponent_score,ct=duel.challenger_time_ms,ot=duel.opponent_time_ms;
      const challengerWon=cs>os || (cs===os && (ot??Number.MAX_SAFE_INTEGER)>=(ct??Number.MAX_SAFE_INTEGER));
      details={...details,opponentName:(own?duel.opponent_name:duel.challenger_name)??details?.opponentName,myScore:(own?cs:os)??details?.myScore,opponentScore:(own?os:cs)??details?.opponentScore,iWon:cs!=null&&os!=null?(own?challengerWon:!challengerWon):details?.iWon,myTimeMs:own?ct:ot,opponentTimeMs:own?ot:ct};
     }
    }
   }
   return {...r,details};
  });
  res.set('Cache-Control','no-store').json({selectiveRead:true,items,unread:rows.filter(x=>x.readAt===null).length});
 });
 app.post('/api/v1/notifications/read', (req,res)=>{
  const user=authenticate(req);if(!user)return res.status(401).json({error:'Sign in required'});
  const ids=req.body?.ids;
  if(ids!==undefined&&(!Array.isArray(ids)||ids.length>200||ids.some(id=>typeof id!=='string'||id.length>300)))return res.status(400).json({error:'Invalid notification IDs'});
  if(ids){const update=db.prepare('UPDATE notification_inbox SET read_at=? WHERE username=? AND id=? AND read_at IS NULL');db.transaction(()=>{for(const id of ids)update.run(Date.now(),user.username,id)})();}
  else db.prepare('UPDATE notification_inbox SET read_at=? WHERE username=? AND read_at IS NULL').run(Date.now(),user.username);
  res.json({ok:true});
 });
}
module.exports={initialize,record,recordForUser,install};
