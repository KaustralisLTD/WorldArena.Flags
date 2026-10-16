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
test('challenge survives sender completion; recipient accepts, resumes and submits identical questions', () => {
  const store = load('db.js', dependencies);
  const routes = new Map();
  const app = { use() {}, listen() {}, get(route, handler) { routes.set('GET '+route, handler); }, post(route, handler) { routes.set('POST '+route, handler); } };
  for (const method of ['patch', 'delete', 'put']) app[method] = (route, handler) => routes.set(method.toUpperCase()+' '+route, handler);
  const express = Object.assign(() => app, { json: () => () => {}, static: () => () => {} });
  load('server.js', name => {
    if (name === './db') return store;
    if (name === 'express') return express;
    if (name === 'cors') return () => () => {};
    if (name === 'dotenv') return { config() {} };
    if (name.includes('mailgun') || name.includes('push')) return {};
    return dependencies(name);
  });
  function request(method, route, user, body = {}) {
    const res = { statusCode: 200, status(code) { this.statusCode = code; return this; }, json(value) { this.body = value; return this; } };
    routes.get(method+' '+route)({ headers: { 'x-user-id': user }, body, query: { userId: user } }, res);
    return res;
  }
  try {
    store.registerUser({ userId: 'senderqa', username: 'senderqa' });
    store.registerUser({ userId: 'receiverqa', username: 'receiverqa' });
    const questions = [{ correctCountryId: 'ua', optionCountryIds: ['ua','fr','jp','de'] }];
    const created = request('POST', '/api/v1/duel/challenge', 'senderqa', { opponentId: 'receiverqa', seed: 42, challengerName: 'Sender', duelQuestionsPayload: questions });
    assert.equal(created.statusCode, 201);
    const challengeId = created.body.challengeId;
    const sent = request('POST', '/api/v1/duel/submit', 'senderqa', { challengeId, side: 'challenger', score: 1, elapsedMs: 1000 });
    assert.equal(sent.body.status, 'challenger_completed');
    const inbox = request('GET', '/api/v1/duel/incoming', 'receiverqa');
    assert.equal(inbox.body.challenges[0].id, challengeId);
    assert.equal(JSON.stringify(inbox.body.challenges[0].duelQuestionsPayload), JSON.stringify(questions));
    assert.equal(request('POST', '/api/v1/duel/accept', 'unrelatedqa', { challengeId }).statusCode, 403);
    const accepted = request('POST', '/api/v1/duel/accept', 'receiverqa', { challengeId });
    assert.equal(accepted.statusCode, 200);
    assert.equal(JSON.stringify(accepted.body.duelQuestionsPayload), JSON.stringify(questions));
    assert.equal(request('POST', '/api/v1/duel/accept', 'receiverqa', { challengeId }).statusCode, 200);
    const final = request('POST', '/api/v1/duel/submit', 'receiverqa', { challengeId, side: 'opponent', score: 0, elapsedMs: 1500 });
    assert.equal(final.body.status, 'completed');
    assert.equal(final.body.winner, 'challenger');
    assert.equal(request('GET', '/api/v1/duel/incoming', 'receiverqa').body.challenges.length, 0);
    assert.equal(request('POST', '/api/v1/duel/accept', 'receiverqa', { challengeId }).statusCode, 400);
  } finally { store.db.close(); }
});
