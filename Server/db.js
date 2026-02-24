/**
 * SQLite хранилище: пользователи, друзья, дуэли.
 * Файл БД: ./data/duel.db (создаётся при первом запуске).
 */
const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');

const dataDir = path.join(__dirname, 'data');
if (!fs.existsSync(dataDir)) fs.mkdirSync(dataDir, { recursive: true });
const dbPath = path.join(dataDir, 'duel.db');
const db = new Database(dbPath);

db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    username TEXT PRIMARY KEY,
    friend_code TEXT UNIQUE NOT NULL,
    device_token TEXT,
    level INTEGER DEFAULT 1,
    xp INTEGER DEFAULT 0,
    streak INTEGER DEFAULT 0,
    total_games_played INTEGER DEFAULT 0,
    correct_answers INTEGER DEFAULT 0,
    best_time REAL,
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now'))
  );

  CREATE TABLE IF NOT EXISTS friendships (
    user_username TEXT NOT NULL,
    friend_username TEXT NOT NULL,
    created_at TEXT DEFAULT (datetime('now')),
    PRIMARY KEY (user_username, friend_username),
    FOREIGN KEY (user_username) REFERENCES users(username),
    FOREIGN KEY (friend_username) REFERENCES users(username),
    CHECK (user_username != friend_username)
  );

  CREATE TABLE IF NOT EXISTS duel_challenges (
    id TEXT PRIMARY KEY,
    challenger_id TEXT NOT NULL,
    challenger_name TEXT NOT NULL,
    opponent_id TEXT NOT NULL,
    opponent_name TEXT NOT NULL,
    seed INTEGER NOT NULL,
    created_at TEXT DEFAULT (datetime('now')),
    challenger_score INTEGER,
    opponent_score INTEGER,
    status TEXT NOT NULL DEFAULT 'pending'
  );

  CREATE TABLE IF NOT EXISTS nudges (
    id TEXT PRIMARY KEY,
    from_username TEXT NOT NULL,
    to_username TEXT NOT NULL,
    phrase_id INTEGER NOT NULL,
    created_at TEXT DEFAULT (datetime('now')),
    read_at TEXT
  );
  CREATE INDEX IF NOT EXISTS idx_nudges_to ON nudges(to_username);
`);
try { db.exec(`ALTER TABLE users ADD COLUMN display_name TEXT`); } catch (_) {}

function randomFriendCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 8; i++) code += chars[Math.floor(Math.random() * chars.length)];
  return code;
}

const insertUser = db.prepare(`
  INSERT INTO users (username, friend_code, device_token, level, xp, streak, total_games_played, correct_answers, best_time, display_name)
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
`);
const updateUserToken = db.prepare(`
  UPDATE users SET device_token = ?, updated_at = datetime('now') WHERE username = ?
`);
const updateUserStats = db.prepare(`
  UPDATE users SET level = ?, xp = ?, streak = ?, total_games_played = ?, correct_answers = ?, best_time = ?, updated_at = datetime('now') WHERE username = ?
`);
const updateDisplayName = db.prepare(`
  UPDATE users SET display_name = ?, updated_at = datetime('now') WHERE username = ?
`);

function registerUser({ userId, username, deviceToken = null, stats = {} }) {
  const name = (username || userId || 'Player').trim();
  if (!name) return { username: 'Player', friendCode: randomFriendCode() };
  const existing = db.prepare('SELECT friend_code FROM users WHERE username = ?').get(name);
  if (existing) {
    updateUserToken.run(deviceToken, name);
    updateDisplayName.run(name, name);
    const hasStats = [stats.level, stats.xp, stats.streak, stats.totalGamesPlayed, stats.correctAnswers, stats.bestTime].some(v => v != null);
    if (hasStats)
      updateUserStats.run(
        stats.level ?? 1,
        stats.xp ?? 0,
        stats.streak ?? 0,
        stats.totalGamesPlayed ?? 0,
        stats.correctAnswers ?? 0,
        stats.bestTime ?? null,
        name
      );
    return { username: name, friendCode: existing.friend_code };
  }
  let friendCode = randomFriendCode().toUpperCase();
  while (db.prepare('SELECT 1 FROM users WHERE friend_code = ?').get(friendCode))
    friendCode = randomFriendCode().toUpperCase();
  insertUser.run(
    name,
    friendCode,
    deviceToken,
    stats.level ?? 1,
    stats.xp ?? 0,
    stats.streak ?? 0,
    stats.totalGamesPlayed ?? 0,
    stats.correctAnswers ?? 0,
    stats.bestTime ?? null,
    name
  );
  return { username: name, friendCode };
}

function getUserByUsername(username) {
  return db.prepare(
    'SELECT username, friend_code, device_token, level, xp, streak, total_games_played, correct_answers, best_time FROM users WHERE username = ?'
  ).get(username);
}

function getUserByFriendCode(code) {
  if (!code || typeof code !== 'string') return null;
  const normalized = code.trim().toUpperCase();
  return db.prepare(
    'SELECT username, friend_code, display_name, level, xp, streak FROM users WHERE friend_code = ?'
  ).get(normalized);
}

const addFriendship = db.prepare(`
  INSERT OR IGNORE INTO friendships (user_username, friend_username) VALUES (?, ?)
`);
const addFriendshipReverse = db.prepare(`
  INSERT OR IGNORE INTO friendships (user_username, friend_username) VALUES (?, ?)
`);

function addFriend(myUsername, friendCode) {
  const friend = getUserByFriendCode(friendCode);
  if (!friend || friend.username === myUsername) return null;
  addFriendship.run(myUsername, friend.username);
  addFriendshipReverse.run(friend.username, myUsername);
  return friend;
}

function getFriends(username) {
  const rows = db.prepare(`
    SELECT u.username, u.friend_code, u.display_name, u.level, u.xp, u.streak
    FROM friendships f
    JOIN users u ON u.username = f.friend_username
    WHERE f.user_username = ?
  `).all(username);
  return rows;
}

function setDisplayName(username, displayName) {
  if (!username || !displayName) return false;
  updateDisplayName.run((displayName || '').trim(), username);
  return true;
}

// Duel challenges
function createChallenge(row) {
  db.prepare(`
    INSERT INTO duel_challenges (id, challenger_id, challenger_name, opponent_id, opponent_name, seed, challenger_score, opponent_score, status)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(row.id, row.challengerId, row.challengerName, row.opponentId, row.opponentName, row.seed, null, null, 'pending');
}

function getChallenge(id) {
  return db.prepare('SELECT * FROM duel_challenges WHERE id = ?').get(id);
}

function setChallengeStatus(id, status) {
  db.prepare('UPDATE duel_challenges SET status = ? WHERE id = ?').run(status, id);
}

function getIncomingChallenges(opponentId) {
  return db.prepare(`
    SELECT id, challenger_id AS challengerId, challenger_name AS challengerName, seed, created_at AS createdAt, challenger_score AS challengerScore, status
    FROM duel_challenges
    WHERE opponent_id = ? AND status = 'pending'
      AND datetime(created_at) >= datetime('now', '-24 hours')
    ORDER BY created_at DESC
  `).all(opponentId);
}

function updateChallengeScore(id, side, score) {
  const c = getChallenge(id);
  if (!c) return null;
  if (side === 'challenger') {
    const createdAt = c.created_at ? new Date(c.created_at).getTime() : 0;
    const expiry24h = Date.now() - 24 * 60 * 60 * 1000;
    if (c.opponent_score == null && createdAt < expiry24h) {
      db.prepare('UPDATE duel_challenges SET challenger_score = ?, opponent_score = ?, status = ? WHERE id = ?').run(
        score, -1, 'completed', id
      );
      return getChallenge(id);
    }
    db.prepare('UPDATE duel_challenges SET challenger_score = ?, status = ? WHERE id = ?').run(
      score,
      c.opponent_score != null ? 'completed' : 'challenger_completed',
      id
    );
  } else {
    db.prepare('UPDATE duel_challenges SET opponent_score = ?, status = ? WHERE id = ?').run(
      score,
      c.challenger_score != null ? 'completed' : 'opponent_completed',
      id
    );
  }
  return getChallenge(id);
}

function getAllUsersForRandomOpponent(excludeUsernames) {
  const placeholders = excludeUsernames.length ? excludeUsernames.map(() => '?').join(',') : 'NULL';
  const sql = excludeUsernames.length
    ? `SELECT username, level, xp, streak FROM users WHERE username NOT IN (${placeholders})`
    : 'SELECT username, level, xp, streak FROM users';
  const stmt = excludeUsernames.length ? db.prepare(sql) : db.prepare(sql);
  return excludeUsernames.length ? stmt.all(...excludeUsernames) : stmt.all();
}

function areFriends(usernameA, usernameB) {
  if (!usernameA || !usernameB) return false;
  const row = db.prepare(
    'SELECT 1 FROM friendships WHERE (user_username = ? AND friend_username = ?) OR (user_username = ? AND friend_username = ?)'
  ).get(usernameA, usernameB, usernameB, usernameA);
  return !!row;
}

const insertNudge = db.prepare(`
  INSERT INTO nudges (id, from_username, to_username, phrase_id) VALUES (?, ?, ?, ?)
`);

function createNudge({ id, fromUsername, toUsername, phraseId }) {
  insertNudge.run(id, fromUsername, toUsername, phraseId);
  return { id, fromUsername, toUsername, phraseId };
}

function getNudgesForUser(toUsername, unreadOnly = true) {
  const sql = unreadOnly
    ? "SELECT id, from_username AS fromUsername, phrase_id AS phraseId, created_at AS createdAt FROM nudges WHERE to_username = ? AND read_at IS NULL ORDER BY created_at DESC"
    : "SELECT id, from_username AS fromUsername, phrase_id AS phraseId, created_at AS createdAt, read_at AS readAt FROM nudges WHERE to_username = ? ORDER BY created_at DESC";
  return db.prepare(sql).all(toUsername);
}

function markNudgesRead(toUsername) {
  return db.prepare("UPDATE nudges SET read_at = datetime('now') WHERE to_username = ? AND read_at IS NULL").run(toUsername);
}

module.exports = {
  db,
  registerUser,
  getUserByUsername,
  getUserByFriendCode,
  addFriend,
  getFriends,
  setDisplayName,
  createChallenge,
  getChallenge,
  setChallengeStatus,
  getIncomingChallenges,
  updateChallengeScore,
  getAllUsersForRandomOpponent,
  areFriends,
  createNudge,
  getNudgesForUser,
  markNudgesRead,
};
