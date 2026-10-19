'use strict';
const {test}=require('node:test');const assert=require('node:assert/strict');
process.env.DUEL_DB_PATH=':memory:';
const store=require('../db');const awards=require('../award-mail');
test('award emails preserve consent, isolate owners and deduplicate level/weekly events',async()=>{
 const db=store.db,routes=new Map(),sent=[];let now=1e12;
 db.exec(`CREATE TABLE lifecycle_prefs(username TEXT PRIMARY KEY,locale TEXT,unsubscribe_token TEXT,progress INTEGER,progress_blocked INTEGER)`);
 for(const name of ['іринатест','ssptest']){store.registerUser({userId:name,username:name});db.prepare('UPDATE users SET email=?,is_registered=1 WHERE username=?').run(name+'@example.test',name);db.prepare('INSERT INTO lifecycle_prefs VALUES(?,?,?,?,?)').run(name,'uk','a'.repeat(64),0,0)}
 const api=awards.install({post:(path,fn)=>routes.set(path,fn)},store,r=>r.owner?{username:r.owner}:null,async(...args)=>sent.push(args),{now:()=>now,enabled:()=>true,configured:()=>true});
 function request(owner,body){const res={code:200,status(n){this.code=n;return this},json(v){this.body=v;return this}};routes.get('/api/v1/award-mail')({owner,body},res);return res}
 const level={type:'level',xp:99000},week={type:'league',week:'2026-W42',rank:2,participants:20,league:'Золота ліга'};
 assert.equal(request(null,level).code,401);assert.equal(request('іринатест',{type:'level',xp:2}).code,400);
 for(let i=0;i<2;i++){assert.equal(request('іринатест',level).code,200);request('іринатест',week)}
 assert.equal(db.prepare('SELECT count(*) n FROM award_mail').get().n,2);
 await api.tick();assert.equal(sent.length,0);
 db.prepare('UPDATE lifecycle_prefs SET progress=1 WHERE username=?').run('іринатест');
 await api.tick();assert.equal(sent.length,2);assert.ok(sent[0][1].includes('Рівень 100'));assert.ok(sent[1][3].includes('Золота ліга'));
 await api.tick();assert.equal(sent.length,2);assert.equal(db.prepare('SELECT count(*) n FROM notification_inbox WHERE username=?').get('ssptest').n,0);
 assert.equal(db.prepare('SELECT count(*) n FROM notification_inbox WHERE username=?').get('іринатест').n,2);
 db.close();
});
