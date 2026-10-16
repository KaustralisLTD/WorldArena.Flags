// Run actual route handlers against SQLite in memory. No sockets, push or player data.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { createRequire } = require('node:module');
const serverDir = path.resolve(__dirname, '..');
const sourceDir = process.env.DUEL_TEST_SOURCE ? path.resolve(process.env.DUEL_TEST_SOURCE) : serverDir;
const dependencies = createRequire(path.join(serverDir, 'server.js'));
function load(file, customRequire) {
  const module = { exports: {} };
  let code = fs.readFileSync(path.join(sourceDir, file), 'utf8');
  if (file === 'db.js') code = code.replace('new Database(dbPath)', "new Database(':memory:')");
  vm.runInNewContext(code, { module, exports: module.exports, require: customRequire, __dirname: serverDir,
    process: { env: {} }, console: { log() {}, warn() {}, error() {} }, Buffer, URL, setTimeout, clearTimeout }, { filename: file });
  return module.exports;
}
test('duel pushes carry match IDs; result delivery is opt-out and idempotent', () => {
  const store = load('db.js', dependencies), routes = new Map(), invites = [], results = [];
  const middleware = [];
  let pushError = null;
  const app = { use(fn) { if (typeof fn === "function" && fn.length === 3) middleware.push(fn); }, listen() {} };
  for (const method of ['get','post','patch','delete','put']) app[method] = (route, handler) => routes.set(method.toUpperCase()+' '+route,handler);
  const express = Object.assign(() => app,{json:()=>()=>{},static:()=>()=>{}});
  load('server.js', name => {
    if(name==='./db') return store;
    if(name==='express') return express;
    if(name==='cors') return ()=>()=>{};
    if(name==='dotenv') return {config(){}};
    if(name.includes('mailgun')) return {};
    if(name.includes('push')) return {sendDuelChallengePush:(token,name,cb,id)=>{invites.push({token,id});cb(pushError);},sendDuelResultPush:(token,match,cb)=>{results.push({token,...match});cb();}};
    return dependencies(name);
  });
  function call(route,user,body={}) {
    const res={code:200,status(c){this.code=c;return this},json(v){this.body=v;return this}};
    const req = {headers:{'x-user-id':user},body};
    for (const fn of middleware) fn(req,res,()=>{});
    routes.get('POST '+route)(req,res);return res;
  }
  const page = { code: 200, status(c) { this.code=c; return this; }, type(t) { this.mime=t; return this; }, send(body) { this.body=body; return this; } };
  const shared = store.registerUser({userId:'profileqa',username:'profileqa'});
  routes.get('GET /profile/:code')({params:{code:shared.friendCode}},page);
  assert.equal(page.code,200);
  assert.ok(page.body.includes('worldarenaflags://profile/'+shared.friendCode));
  assert.ok(page.body.includes('apps.apple.com/app/id6744296834'));
  routes.get('GET /profile/:code')({params:{code:'<script>'}},page);
  assert.equal(page.code,400);
  const association = {json(value){this.body=value;}};
  routes.get('GET /.well-known/apple-app-site-association')({},association);
  assert.equal(association.body.applinks.details[0].appID,'8QK64BF264.World-Arena.-Flags');
  try {
    for(const name of ['aliceqa','bobqa']) store.registerUser({userId:name,username:name,deviceToken:name+'-token'});
    const create=()=>call('/api/v1/duel/challenge','aliceqa',{opponentId:'bobqa',seed:42,challengerName:'Alice'}).body.challengeId;
    store.registerUser({userId:'ірина',username:'ірина',deviceToken:'unicode-token'});
    const unicodeID = call('/api/v1/duel/challenge','aliceqa',{opponentId:'ірина',seed:42,challengerName:'Alice'}).body.challengeId;
    assert.ok(unicodeID);
    assert.equal(call('/api/v1/duel/accept',encodeURIComponent('ірина'),{challengeId:unicodeID}).code,200);
    assert.equal(call('/api/v1/duel/accept',Buffer.from('ірина','utf8').toString('latin1'),{challengeId:unicodeID}).code,200);
    assert.equal(call('/api/v1/duel/accept',encodeURIComponent('інша'),{challengeId:unicodeID}).code,403);
    invites.length = 0;
    const id=create(); assert.ok(id); assert.equal(invites[0].id,id);
    assert.equal(call('/api/v1/duel/submit','bobqa',{challengeId:id,side:'challenger',score:9}).code,403);
    call('/api/v1/duel/submit','aliceqa',{challengeId:id,side:'challenger',score:10,elapsedMs:10000});assert.equal(results.length,0);
    call('/api/v1/duel/submit','bobqa',{challengeId:id,side:'opponent',score:8,elapsedMs:9000});assert.equal(results.length,2);
    assert.equal(results[0].challengeId,id);assert.equal(results[0].iWon,true);assert.equal(results[1].iWon,false);
    call('/api/v1/duel/submit','bobqa',{challengeId:id,side:'opponent',score:99});assert.equal(results.length,2);assert.equal(store.getChallenge(id).opponent_score,8);
    const legacyID = create();
    assert.equal(call('/api/v1/duel/submit',undefined,{challengeId:legacyID,side:'invalid',score:10}).code,403);
    assert.equal(call('/api/v1/duel/submit',undefined,{challengeId:legacyID,side:'challenger',score:10}).code,200);
    assert.equal(call('/api/v1/duel/submit',undefined,{challengeId:legacyID,side:'opponent',score:9}).code,200);
    assert.equal(store.getChallenge(legacyID).status,'completed');
    results.splice(2); invites.splice(1);
    store.setDuelNotificationPreferences('bobqa',false,false);
    const id2=create();assert.equal(invites.length,1);
    call('/api/v1/duel/submit','aliceqa',{challengeId:id2,side:'challenger',score:10});
    call('/api/v1/duel/submit','bobqa',{challengeId:id2,side:'opponent',score:11});
    assert.equal(results.length,3);assert.equal(results[2].token,'aliceqa-token');assert.equal(results[2].iWon,false);
    store.setDuelNotificationPreferences('bobqa',true,true);
    const reminderID=create();
    assert.equal(call('/api/v1/duel/remind','aliceqa',{challengeId:reminderID}).body.pushSent,true);
    assert.equal(call('/api/v1/duel/remind','aliceqa',{challengeId:reminderID}).body.throttled,true);
    const failingID=create();pushError=new Error('APNs unavailable');
    const failed=call('/api/v1/duel/remind','aliceqa',{challengeId:failingID});
    assert.equal(failed.code,502);assert.equal(failed.body.errorCode,'Server error. Try again.');
    pushError=null;
    assert.equal(call('/api/v1/duel/remind','aliceqa',{challengeId:failingID}).body.pushSent,true,'failed delivery does not lock the button');
    const disabledID=create();store.setDuelNotificationPreferences('bobqa',true,false);
    assert.equal(call('/api/v1/duel/remind','aliceqa',{challengeId:disabledID}).body.reason,'notifications_disabled');
    store.setDuelNotificationPreferences('bobqa',true,true);
    store.db.prepare('UPDATE users SET device_token=NULL WHERE username=?').run('bobqa');
    assert.equal(call('/api/v1/duel/remind','aliceqa',{challengeId:disabledID}).body.reason,'no_device_token');
  } finally {store.db.close();}
});
