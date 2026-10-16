const { test } = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const { installStreakFreezes } = require('../streak-freezes');
test('gift is authenticated, idempotent, reserved once and acknowledged only by recipient', async () => {
  const app = express(); app.use(express.json());
  const users = { areFriends: (a,b) => ['alice','bob','carol'].includes(a) && b === 'bob', getFriends: () => [{ username:'bob' }] };
  const db = installStreakFreezes(app, users, req => req.headers.authorization ? { username: req.headers.authorization } : null, ':memory:');
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening',resolve));
  const call = async (route, user, body) => {
    const r = await fetch(`http://127.0.0.1:${server.address().port}/api/v1/streak-freezes/${route}`, { method:'POST', headers:{'Content-Type':'application/json', ...(user ? {Authorization:user} : {})},body:JSON.stringify(body) });
    return {code:r.status, data:await r.json()};
  };
  try {
    assert.equal((await call('sync', null, {count:0})).code,401);
    assert.equal((await call('sync','alice',{count:4})).code,400);
    await call('sync','alice',{count:2}); await call('sync','bob',{count:0}); await call('sync','carol',{count:1});
    const gift={id:'11111111-1111-1111-1111-111111111111', recipient:'bob'};
    assert.equal((await call('gift','alice',gift)).data.status,'accepted');
    assert.equal((await call('gift','alice',gift)).data.status,'accepted');
    assert.equal(db.prepare('SELECT count FROM freeze_inventory WHERE username=?').get('alice').count,1);
    assert.equal((await call('gift','carol',{...gift,id:'22222222-2222-2222-2222-222222222222'})).data.status,'unavailable');
    assert.equal((await call('sync','bob',{count:0})).data.gifts.length,1);
    await call('sync','alice',{count:1,received:[gift.id]});
    assert.equal((await call('sync','bob',{count:0})).data.gifts.length,1);
    await call('sync','bob',{count:1,received:[gift.id]});
    assert.equal((await call('sync','bob',{count:1})).data.gifts.length,0);
    assert.equal((await call('gift','alice',gift)).data.status,'accepted');
    assert.equal((await call('sync','bob',{count:1})).data.gifts.length,0);
  } finally { server.close(); db.close(); }
});
