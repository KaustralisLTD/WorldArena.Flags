const test = require('node:test');
const assert = require('node:assert/strict');
const {generateKeyPairSync, sign} = require('node:crypto');
const {verifySocialIdentity} = require('../social-identity');
const {publicKey,privateKey} = generateKeyPairSync('rsa',{modulusLength:2048});
const jwk = {...publicKey.export({format:'jwk'}),kid:'test'};
const options = {audience:'capitals-client',keys:async()=>[jwk]};
function token(overrides={}) {
  const now=Math.floor(Date.now()/1000);
  const a=Buffer.from(JSON.stringify({alg:'RS256',kid:'test'})).toString('base64url');
  const b=Buffer.from(JSON.stringify({iss:'https://accounts.google.com',aud:'capitals-client',sub:'verified-player',iat:now,exp:now+60,email:'player@example.com',email_verified:true,...overrides})).toString('base64url');
  return a+'.'+b+'.'+sign('RSA-SHA256',Buffer.from(a+'.'+b),privateKey).toString('base64url');
}
test('social identity requires a signed provider token, not a claimed user ID',async()=>{
  await assert.rejects(verifySocialIdentity('google','player@example.com',options));
  const verified=await verifySocialIdentity('google',token(),options);
  assert.equal(verified.providerUserId,'verified-player');
  assert.equal(verified.email,'player@example.com');
});
test('tokens for another app, expired tokens and changed signatures are rejected',async()=>{
  await assert.rejects(verifySocialIdentity('google',token({aud:'flags-client'}),options));
  await assert.rejects(verifySocialIdentity('google',token({exp:1}),options));
  const t=token();await assert.rejects(verifySocialIdentity('google',t.slice(0,-12)+'AAAAAAAAAAAA',options));
});
test('unverified provider email cannot be used to link accounts',async()=>{
  const verified=await verifySocialIdentity('google',token({email_verified:false}),options);
  assert.equal(verified.email,undefined);
});
