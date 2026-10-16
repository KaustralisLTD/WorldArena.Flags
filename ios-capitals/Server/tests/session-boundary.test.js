const test=require('node:test');
const assert=require('node:assert/strict');
const {sessionBoundary}=require('../session-boundary');
test('private duel and session routes cannot be entered with an identity header alone',()=>{
  for(const path of ['/duel/challenge','/duel/incoming','/auth/sessions','/users/register','/health/push']) {
    let next=false;const res={status(code){this.code=code;return this;},json(body){this.body=body;}};
    sessionBoundary(()=>null)({path,headers:{'x-user-id':'victim'}},res,()=>{next=true;});
    assert.equal(res.code,401);assert.equal(next,false);
  }
});
test('private identity comes from bearer session and cannot be spoofed',()=>{
  const req={path:'/auth/sessions',headers:{'x-user-id':'victim'}};let next=false;
  sessionBoundary(()=>({username:'real-player'}))(req,{},()=>{next=true;});
  assert.equal(next,true);assert.equal(req.headers['x-user-id'],'real-player');
});
test('account sign-in and health remain available without a session',()=>{
  for(const path of ['/health','/auth/login','/auth/register','/auth/social-login']) {
    let next=false;sessionBoundary(()=>null)({path,headers:{}},{},()=>{next=true;});assert.equal(next,true);
  }
});

test('only public lifecycle assets and opaque-token pages bypass sessions',()=>{
 const token='a'.repeat(64);
 for(const [path,method] of [['/lifecycle/assets/map-ru-v1','GET'],['/lifecycle/preferences/'+token,'GET'],['/lifecycle/preferences/'+token,'POST'],['/lifecycle/open/'+token,'GET']]){
  let allowed=false;sessionBoundary(()=>null)({path,method,headers:{}},{},()=>allowed=true);assert.equal(allowed,true);
 }
 for(const path of ['/lifecycle/sync','/lifecycle/bonus/start','/lifecycle/message','/lifecycle/contacts/private','/lifecycle/preferences/short']){
  const res={status(n){this.code=n;return this},json(){}};let allowed=false;
  sessionBoundary(()=>null)({path,method:'POST',headers:{}},res,()=>allowed=true);assert.equal(allowed,false);assert.equal(res.code,401);
 }
});
