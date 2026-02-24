/**
 * API дуэлей World Arena Flags.
 * Хранилище: SQLite (users, friendships, duel_challenges).
 * Продакшен: flags.worldarena.games (nginx проксирует /api/ на этот процесс).
 */
const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');
const db = require('./db');

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

const PORT = process.env.PORT || 3001;

app.get('/api/v1/health', (_, res) => {
  res.json({ ok: true, service: 'duel-api' });
});

// ——— Users ———
// POST /api/v1/users/register
app.post('/api/v1/users/register', (req, res) => {
  const { userId, username, deviceToken } = req.body;
  const id = (userId || username || '').trim();
  if (!id) return res.status(400).json({ error: 'userId or username required' });
  try {
    const result = db.registerUser({
      userId: id,
      username: username || id,
      deviceToken: deviceToken || null,
      stats: req.body.stats || {},
    });
    res.json({ ok: true, username: result.username, friendCode: result.friendCode });
  } catch (e) {
    console.error('register', e);
    res.status(500).json({ error: 'Registration failed' });
  }
});

// GET /api/v1/users/by-code/:code — по коду друга вернуть пользователя (для добавления в друзья)
app.get('/api/v1/users/by-code/:code', (req, res) => {
  const user = db.getUserByFriendCode(req.params.code);
  if (!user) return res.status(404).json({ error: 'User not found' });
  res.json({
    username: user.username,
    displayName: user.display_name || user.username,
    friendCode: user.friend_code,
    level: user.level || 1,
    xp: user.xp || 0,
    streak: user.streak || 0,
  });
});

// GET /api/v1/users/me/friends — список друзей текущего пользователя (displayName — имя для отображения у друзей)
app.get('/api/v1/users/me/friends', (req, res) => {
  const userId = req.headers['x-user-id'] || req.query.userId;
  if (!userId) return res.status(400).json({ error: 'userId required' });
  const friends = db.getFriends(userId);
  res.json({
    friends: friends.map((f) => ({
      username: f.username,
      displayName: f.display_name || f.username,
      friendCode: f.friend_code,
      level: f.level || 1,
      xp: f.xp || 0,
      streak: f.streak || 0,
    })),
  });
});

// PATCH /api/v1/users/me — обновить отображаемое имя (у друзей будет видно новое имя)
app.patch('/api/v1/users/me', (req, res) => {
  const userId = req.headers['x-user-id'] || req.body.userId;
  const { displayName } = req.body;
  if (!userId) return res.status(400).json({ error: 'userId required' });
  if (!displayName || typeof displayName !== 'string') return res.status(400).json({ error: 'displayName required' });
  db.setDisplayName(userId, displayName.trim());
  res.json({ ok: true });
});

// POST /api/v1/friends/add — добавить друга по коду
app.post('/api/v1/friends/add', (req, res) => {
  const myUsername = req.headers['x-user-id'] || req.body.userId;
  const { friendCode } = req.body;
  if (!myUsername || !friendCode) return res.status(400).json({ error: 'userId and friendCode required' });
  const friend = db.addFriend(myUsername, friendCode);
  if (!friend) return res.status(400).json({ error: 'Invalid code or cannot add yourself' });
  res.json({
    ok: true,
    friend: {
      username: friend.username,
      displayName: friend.display_name || friend.username,
      friendCode: friend.friend_code,
      level: friend.level || 1,
      xp: friend.xp || 0,
      streak: friend.streak || 0,
    },
  });
});

// ——— Duel ———
// POST /api/v1/duel/challenge
app.post('/api/v1/duel/challenge', (req, res) => {
  const { opponentId, seed, challengerName } = req.body;
  const challengerId = req.headers['x-user-id'] || req.body.challengerId || 'local-user';
  if (!opponentId || seed == null) return res.status(400).json({ error: 'opponentId and seed required' });
  const opponent = db.getUserByUsername(opponentId);
  const opponentName = (opponent && opponent.username) || 'Opponent';
  const id = uuidv4();
  db.createChallenge({
    id,
    challengerId,
    challengerName: challengerName || 'Challenger',
    opponentId,
    opponentName,
    seed,
  });
  console.log('Duel challenge created:', id, '-> push to', opponentId);
  res.status(201).json({ challengeId: id, seed, opponentName });
});

// GET /api/v1/duel/incoming
app.get('/api/v1/duel/incoming', (req, res) => {
  const userId = req.headers['x-user-id'] || req.query.userId;
  if (!userId) return res.status(400).json({ error: 'userId required' });
  const list = db.getIncomingChallenges(userId);
  res.json({
    challenges: list.map((c) => ({
      id: c.id,
      challengerId: c.challengerId,
      challengerName: c.challengerName,
      seed: c.seed,
      createdAt: c.createdAt,
      challengerScore: c.challengerScore,
      status: c.status,
    })),
  });
});

// POST /api/v1/duel/accept
app.post('/api/v1/duel/accept', (req, res) => {
  const { challengeId } = req.body;
  const c = db.getChallenge(challengeId);
  if (!c) return res.status(404).json({ error: 'Challenge not found' });
  if (c.status !== 'pending') return res.status(400).json({ error: 'Challenge already accepted or completed' });
  db.setChallengeStatus(challengeId, 'accepted');
  res.json({
    seed: c.seed,
    challengerName: c.challenger_name,
    challengerScore: c.challenger_score,
  });
});

// POST /api/v1/duel/submit
app.post('/api/v1/duel/submit', (req, res) => {
  const { challengeId, score, side } = req.body;
  const updated = db.updateChallengeScore(challengeId, side, score);
  if (!updated) return res.status(404).json({ error: 'Challenge not found' });
  let winner = null;
  if (updated.status === 'completed') {
    winner =
      (updated.challenger_score || 0) >= (updated.opponent_score || 0) ? 'challenger' : 'opponent';
    const winnerId = winner === 'challenger' ? updated.challenger_id : updated.opponent_id;
    console.log('Duel completed, winner:', winnerId);
  }
  res.json({
    status: updated.status,
    winner,
    challengerScore: updated.challenger_score,
    opponentScore: updated.opponent_score,
  });
});

// POST /api/v1/duel/random-opponent
app.post('/api/v1/duel/random-opponent', (req, res) => {
  const { excludeFriendIds = [], myStats = {} } = req.body;
  const userId = req.headers['x-user-id'] || req.body.userId;
  const exclude = [userId, ...(excludeFriendIds || [])].filter(Boolean);
  const pool = db.getAllUsersForRandomOpponent(exclude);
  if (pool.length === 0) return res.status(404).json({ error: 'No opponent available' });
  const opponent = pool[Math.floor(Math.random() * pool.length)];
  res.json({
    opponentId: opponent.username,
    opponentName: opponent.username,
    level: opponent.level || 1,
    xp: opponent.xp || 0,
  });
});

// ——— Nudge (напоминание другу) ———
// Фразы для push-уведомления (английский); в приложении получателя показываются по phraseId в его языке.
const NUDGE_PHRASES_EN = [
  "Don't give up! You've got this!",
  "Your streak is waiting for you. Play today!",
  "One game a day keeps the streak alive!",
  "Come back and show those flags who's boss!",
  "We miss you! Time for a quick game?",
  "Your friends are playing. Join them!",
  "Small step today, big streak tomorrow!",
  "You're so close! Don't break the streak!",
  "Flags are calling. Answer the call!",
  "Rise and shine — it's flag time!",
  "A little practice goes a long way!",
  "Today's the day to keep your streak!",
  "Get back in the game! We believe in you!",
  "One more game and you'll feel great!",
  "Your streak misses you. Come back!",
];

let sendNudgePush;
try {
  const push = require('./push.js');
  sendNudgePush = push.sendNudgePush;
} catch (e) {
  sendNudgePush = () => {};
}

// POST /api/v1/nudge — отправить напоминание другу
app.post('/api/v1/nudge', (req, res) => {
  const fromUsername = (req.headers['x-user-id'] || '').trim();
  const { toUsername, phraseId } = req.body || {};
  if (!fromUsername || !toUsername) return res.status(400).json({ error: 'X-User-Id and toUsername required' });
  const phrase = Math.max(0, Math.min(14, parseInt(phraseId, 10) || 0));
  if (!db.areFriends(fromUsername, toUsername)) return res.status(400).json({ error: 'Can only nudge friends' });
  const toUser = db.getUserByUsername(toUsername);
  if (!toUser) return res.status(404).json({ error: 'Recipient not found' });
  const id = uuidv4();
  db.createNudge({ id, fromUsername, toUsername, phraseId: phrase });
  const bodyText = NUDGE_PHRASES_EN[phrase] || NUDGE_PHRASES_EN[0];
  if (toUser.device_token) {
    sendNudgePush(toUser.device_token, fromUsername, bodyText, (err) => {
      if (err) console.error('Nudge push failed:', err);
    });
  }
  console.log('Nudge created:', id, fromUsername, '->', toUsername);
  res.status(200).json({ ok: true, nudgeId: id });
});

// GET /api/v1/nudge/inbox — непрочитанные напоминания для текущего пользователя
app.get('/api/v1/nudge/inbox', (req, res) => {
  const userId = (req.headers['x-user-id'] || req.query.userId || '').trim();
  if (!userId) return res.status(400).json({ error: 'userId required' });
  const nudges = db.getNudgesForUser(userId, true);
  res.json({ nudges });
});

// POST /api/v1/nudge/read — отметить все напоминания как прочитанные
app.post('/api/v1/nudge/read', (req, res) => {
  const userId = (req.headers['x-user-id'] || req.body?.userId || '').trim();
  if (!userId) return res.status(400).json({ error: 'userId required' });
  db.markNudgesRead(userId);
  res.json({ ok: true });
});

app.listen(PORT, '127.0.0.1', () => {
  console.log(`Duel API listening on 127.0.0.1:${PORT}`);
});
