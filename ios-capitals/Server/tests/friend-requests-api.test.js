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
test('request endpoints require the recipient session and reject spoofed identity headers', () => {
  const store = load('db.js', dependencies);
  const routes = new Map();
  const pushes = [];
  const app = { use() {}, listen() {}, patch() {}, get(route, handler) { routes.set('GET '+route, handler); }, post(route, handler) { routes.set('POST '+route, handler); } };
  const express = () => app; express.json = () => () => {}; express.static = () => () => {};
  load('server.js', name => {
    if (name === './db') return store;
    if (name === './streak-freezes') return { installStreakFreezes() {} };
    if (name === 'express') return express;
    if (name === 'cors') return () => () => {};
    if (name === 'dotenv') return { config() {} };
    if (name.includes('push')) return { sendFriendRequestPush: (...args) => pushes.push(args) };
    if (name.includes('mailgun')) return {};
    return dependencies(name);
  });
  const call = (method, path, token, body = {}) => {
    const res = { code: 200, status(code) { this.code = code; return this; }, json(value) { this.body = value; return this; } };
    routes.get(method + ' ' + path)({ headers: { authorization: token ? 'Bearer ' + token : '', 'x-user-id': 'bobqa' }, body }, res);
    return res;
  };
  try {
    for (const username of ['aliceqa','bobqa','carolqa']) {
      store.registerUser({userId: username, username});
      store.db.prepare("INSERT INTO auth_sessions(token,username,expires_at) VALUES(?,?,datetime('now','+1 day'))").run(username,username);
    }
    store.db.prepare('UPDATE users SET device_token = ? WHERE username = ?').run('test-token','aliceqa');
    const add = () => call('POST','/api/v1/friends/add','bobqa',{friendCode:store.getUserByUsername('aliceqa').friend_code});
    assert.equal(add().code,200); assert.equal(add().code,200);
    assert.equal(pushes.length,1);
    // A separate pending request is required for the recipient authorization checks.
    store.db.prepare('DELETE FROM friendships').run();
    store.db.prepare('DELETE FROM friend_requests').run();
    store.addFriend('aliceqa',store.getUserByUsername('bobqa').friend_code);
    assert.equal(call('GET','/api/v1/friends/requests',null).code,401);
    assert.equal(call('GET','/api/v1/friends/requests','carolqa').body.requests.length,0);
    assert.equal(call('POST','/api/v1/friends/requests/respond','carolqa',{sender:'aliceqa',accept:true}).code,404);
    assert.equal(call('POST','/api/v1/friends/requests/respond','bobqa',{sender:'aliceqa',accept:'false'}).code,400);
    assert.equal(call('POST','/api/v1/friends/requests/respond','bobqa',{sender:'aliceqa',accept:true}).code,200);
    assert.equal(store.getFriends('bobqa').length,1);
  } finally { store.db.close(); }
});
