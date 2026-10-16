// Isolated in-memory database: never touches player data or sends notifications.
process.env.DUEL_DB_PATH = ':memory:';
const assert = require('node:assert/strict');
const { test, after } = require('node:test');
const store = require('../db');
after(() => store.db.close());

test('recipient finds a challenge before and after the sender finishes, without push', () => {
  store.registerUser({ username: 'SenderQA', userId: 'SenderQA' });
  store.registerUser({ username: 'ReceiverQA', userId: 'ReceiverQA' });
  const sender = store.getCanonicalUsername('SenderQA');
  const recipient = store.getCanonicalUsername('ReceiverQA');
  store.createChallenge({ id: 'inbox-regression', challengerId: sender, challengerName: 'Sender', opponentId: recipient, opponentName: 'Receiver', seed: 42 });
  assert.equal(store.getIncomingChallenges('  RECEIVERQA  ')[0].id, 'inbox-regression');
  assert.equal(store.getIncomingChallenges('SenderQA').length, 0);
  store.setChallengeStatus('inbox-regression', 'accepted');
  assert.equal(store.getIncomingChallenges('receiverqa')[0].status, 'accepted');
  assert.equal(store.getIncomingChallengesForSync('RECEIVERQA')[0].status, 'accepted');
  store.setChallengeStatus('inbox-regression', 'challenger_completed');
  assert.equal(store.getIncomingChallenges('receiverqa')[0].id, 'inbox-regression');
  assert.equal(store.getIncomingChallengesForSync('RECEIVERQA')[0].status, 'challenger_completed');
  store.setChallengeStatus('inbox-regression', 'completed');
  assert.equal(store.getIncomingChallenges('ReceiverQA').length, 0);
  assert.equal(store.getIncomingChallengesForSync('ReceiverQA')[0].status, 'completed');
});


test('legacy differently cased challenge recipient is visible to the current account', () => {
  store.registerUser({ username: 'CaseReceiver', userId: 'CaseReceiver' });
  store.createChallenge({ id: 'legacy-case', challengerId: 'CaseSender', challengerName: 'Sender', opponentId: 'CASERECEIVER', opponentName: 'Receiver', seed: 43 });
  assert.equal(store.getIncomingChallenges('casereceiver')[0].id, 'legacy-case');
  assert.equal(store.getIncomingChallengesForSync('CaseReceiver')[0].id, 'legacy-case');
  assert.equal(store.getIncomingChallenges('unrelated-user').length, 0);
});
