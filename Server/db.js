/**
 * SQLite хранилище: пользователи, друзья, дуэли.
 * Файл БД: ./data/duel.db (создаётся при первом запуске).
 */
const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');

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

  CREATE TABLE IF NOT EXISTS auth_sessions (
    token TEXT PRIMARY KEY,
    username TEXT NOT NULL,
    created_at TEXT DEFAULT (datetime('now')),
    expires_at TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS password_resets (
    id TEXT PRIMARY KEY,
    username TEXT NOT NULL,
    email TEXT NOT NULL,
    code TEXT NOT NULL,
    created_at TEXT DEFAULT (datetime('now')),
    used_at TEXT
  );
`);
try { db.exec(`ALTER TABLE users ADD COLUMN display_name TEXT`); } catch (_) {}
try { db.exec(`ALTER TABLE users ADD COLUMN email TEXT`); } catch (_) {}
try { db.exec(`ALTER TABLE users ADD COLUMN password_hash TEXT`); } catch (_) {}
try { db.exec(`ALTER TABLE users ADD COLUMN password_salt TEXT`); } catch (_) {}
try { db.exec(`ALTER TABLE users ADD COLUMN auth_provider TEXT DEFAULT 'guest'`); } catch (_) {}
try { db.exec(`ALTER TABLE users ADD COLUMN is_registered INTEGER DEFAULT 0`); } catch (_) {}
try { db.exec(`ALTER TABLE users ADD COLUMN registration_reward_granted INTEGER DEFAULT 0`); } catch (_) {}
try { db.exec(`ALTER TABLE users ADD COLUMN birthday TEXT`); } catch (_) {}
try { db.exec(`CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_unique ON users(email)`); } catch (_) {}
try {
  db.exec(`
    CREATE TABLE IF NOT EXISTS birthday_gifts (
      giver_username TEXT NOT NULL,
      receiver_username TEXT NOT NULL,
      year INTEGER NOT NULL,
      type TEXT NOT NULL,
      created_at TEXT DEFAULT (datetime('now')),
      PRIMARY KEY (giver_username, receiver_username, year),
      FOREIGN KEY (giver_username) REFERENCES users(username),
      FOREIGN KEY (receiver_username) REFERENCES users(username)
    );
  `);
} catch (_) {}

function randomFriendCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 8; i++) code += chars[Math.floor(Math.random() * chars.length)];
  return code;
}

const insertUser = db.prepare(`
  INSERT INTO users (username, friend_code, device_token, level, xp, streak, total_games_played, correct_answers, best_time, display_name, birthday)
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
`);
const updateUserToken = db.prepare(`
  UPDATE users SET device_token = ?, updated_at = datetime('now') WHERE username = ?
`);
const updateUserStats = db.prepare(`
  UPDATE users SET level = ?, xp = ?, streak = ?, total_games_played = ?, correct_answers = ?, best_time = ?, updated_at = datetime('now') WHERE username = ?
`);
const updateUserBirthday = db.prepare(`
  UPDATE users SET birthday = ?, updated_at = datetime('now') WHERE username = ?
`);
const updateDisplayName = db.prepare(`
  UPDATE users SET display_name = ?, updated_at = datetime('now') WHERE username = ?
`);
const updatePasswordStmt = db.prepare(`
  UPDATE users SET password_hash = ?, password_salt = ?, auth_provider = 'email', is_registered = 1, updated_at = datetime('now') WHERE username = ?
`);

function normalizeEmail(email) {
  return (email || '').trim().toLowerCase();
}

function makePasswordHash(password, saltHex) {
  const salt = saltHex ? Buffer.from(saltHex, 'hex') : crypto.randomBytes(16);
  const hash = crypto.pbkdf2Sync(password, salt, 120000, 32, 'sha256');
  return {
    saltHex: salt.toString('hex'),
    hashHex: hash.toString('hex'),
  };
}

function verifyPassword(password, saltHex, hashHex) {
  if (!password || !saltHex || !hashHex) return false;
  const { hashHex: calc } = makePasswordHash(password, saltHex);
  const a = Buffer.from(calc, 'hex');
  const b = Buffer.from(hashHex, 'hex');
  if (a.length !== b.length) return false;
  return crypto.timingSafeEqual(a, b);
}

function randomToken() {
  return crypto.randomBytes(32).toString('hex');
}

function randomResetCode() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

function buildSafeUsername(base) {
  let clean = (base || 'player').trim().toLowerCase().replace(/[^a-z0-9_]/g, '');
  if (!clean) clean = `player_${Math.floor(Math.random() * 100000)}`;
  let candidate = clean;
  let i = 1;
  while (db.prepare('SELECT 1 FROM users WHERE username = ?').get(candidate)) {
    i += 1;
    candidate = `${clean}_${i}`;
  }
  return candidate;
}

function createSession(username) {
  const token = randomToken();
  db.prepare('INSERT INTO auth_sessions (token, username, expires_at) VALUES (?, ?, datetime(\'now\', \'+30 days\'))')
    .run(token, username);
  return token;
}

function getSession(token) {
  if (!token) return null;
  return db.prepare(`
    SELECT s.token, s.username, s.expires_at, u.email, u.is_registered
    FROM auth_sessions s
    JOIN users u ON u.username = s.username
    WHERE s.token = ? AND datetime(s.expires_at) > datetime('now')
  `).get(token);
}

function registerAuthUser({ email, password, username }) {
  const normalizedEmail = normalizeEmail(email);
  if (!normalizedEmail || !password || password.length < 6) {
    return { error: 'invalid_input' };
  }
  const existingByEmail = db.prepare('SELECT username FROM users WHERE email = ?').get(normalizedEmail);
  if (existingByEmail) return { error: 'email_exists' };

  const uname = buildSafeUsername(username || normalizedEmail.split('@')[0]);
  let friendCode = randomFriendCode().toUpperCase();
  while (db.prepare('SELECT 1 FROM users WHERE friend_code = ?').get(friendCode)) {
    friendCode = randomFriendCode().toUpperCase();
  }

  const { saltHex, hashHex } = makePasswordHash(password);
  db.prepare(`
    INSERT INTO users (
      username, friend_code, email, password_hash, password_salt,
      auth_provider, is_registered, registration_reward_granted, display_name
    ) VALUES (?, ?, ?, ?, ?, 'email', 1, 0, ?)
  `).run(uname, friendCode, normalizedEmail, hashHex, saltHex, uname);

  db.prepare('UPDATE users SET registration_reward_granted = 1 WHERE username = ?').run(uname);
  const token = createSession(uname);
  return { username: uname, email: normalizedEmail, token, friendCode, rewardGranted: true };
}

function loginAuthUser({ email, password }) {
  const normalizedEmail = normalizeEmail(email);
  const row = db.prepare(`
    SELECT username, email, friend_code, password_hash, password_salt
    FROM users WHERE email = ?
  `).get(normalizedEmail);
  if (!row) return { error: 'invalid_credentials' };
  if (!verifyPassword(password, row.password_salt, row.password_hash)) {
    return { error: 'invalid_credentials' };
  }
  const token = createSession(row.username);
  return { username: row.username, email: row.email, friendCode: row.friend_code, token };
}

function changePassword({ username, currentPassword, newPassword }) {
  const row = db.prepare('SELECT password_hash, password_salt FROM users WHERE username = ?').get(username);
  if (!row) return { error: 'not_found' };
  if (!verifyPassword(currentPassword, row.password_salt, row.password_hash)) {
    return { error: 'invalid_credentials' };
  }
  if (!newPassword || newPassword.length < 6) return { error: 'weak_password' };
  const { saltHex, hashHex } = makePasswordHash(newPassword);
  updatePasswordStmt.run(hashHex, saltHex, username);
  return { ok: true };
}

function requestPasswordReset(email) {
  const normalizedEmail = normalizeEmail(email);
  const row = db.prepare('SELECT username, email FROM users WHERE email = ?').get(normalizedEmail);
  if (!row) return { ok: true };
  const code = randomResetCode();
  const id = crypto.randomUUID();
  db.prepare('INSERT INTO password_resets (id, username, email, code) VALUES (?, ?, ?, ?)')
    .run(id, row.username, normalizedEmail, code);
  return { ok: true, username: row.username, code };
}

function confirmPasswordReset({ email, code, newPassword }) {
  const normalizedEmail = normalizeEmail(email);
  if (!newPassword || newPassword.length < 6) return { error: 'weak_password' };
  const row = db.prepare(`
    SELECT id, username, code
    FROM password_resets
    WHERE email = ? AND used_at IS NULL AND datetime(created_at) > datetime('now', '-30 minutes')
    ORDER BY created_at DESC
    LIMIT 1
  `).get(normalizedEmail);
  if (!row || row.code !== String(code || '').trim()) return { error: 'invalid_code' };
  const { saltHex, hashHex } = makePasswordHash(newPassword);
  updatePasswordStmt.run(hashHex, saltHex, row.username);
  db.prepare('UPDATE password_resets SET used_at = datetime(\'now\') WHERE id = ?').run(row.id);
  return { ok: true, username: row.username };
}

function socialLogin({ provider, providerUserId, email, displayName }) {
  const safeProvider = ['apple', 'google'].includes(provider) ? provider : 'social';
  const normalizedEmail = normalizeEmail(email);
  let user = null;
  if (normalizedEmail) {
    user = db.prepare('SELECT username, email, friend_code FROM users WHERE email = ?').get(normalizedEmail);
  }
  if (!user) {
    const base = displayName || `${safeProvider}_${providerUserId || randomToken().slice(0, 6)}`;
    const username = buildSafeUsername(base);
    let friendCode = randomFriendCode().toUpperCase();
    while (db.prepare('SELECT 1 FROM users WHERE friend_code = ?').get(friendCode)) {
      friendCode = randomFriendCode().toUpperCase();
    }
    db.prepare(`
      INSERT INTO users (
        username, friend_code, email, auth_provider, is_registered, registration_reward_granted, display_name
      ) VALUES (?, ?, ?, ?, 1, 0, ?)
    `).run(username, friendCode, normalizedEmail || null, safeProvider, displayName || username);
    db.prepare('UPDATE users SET registration_reward_granted = 1 WHERE username = ?').run(username);
    user = { username, email: normalizedEmail || null, friend_code: friendCode };
    user.rewardGranted = true;
  } else {
    db.prepare('UPDATE users SET auth_provider = ?, is_registered = 1, updated_at = datetime(\'now\') WHERE username = ?')
      .run(safeProvider, user.username);
    user.rewardGranted = false;
  }
  const token = createSession(user.username);
  return {
    username: user.username,
    email: user.email,
    friendCode: user.friend_code,
    token,
    rewardGranted: !!user.rewardGranted
  };
}

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
    if (stats.birthday != null) {
      // birthday приходит как миллисекунды Unix или ISO‑строка — приводим к ISO‑датe
      let stored = null;
      if (typeof stats.birthday === 'number') {
        stored = new Date(stats.birthday).toISOString();
      } else if (typeof stats.birthday === 'string') {
        const d = new Date(stats.birthday);
        if (!Number.isNaN(d.getTime())) stored = d.toISOString();
      }
      if (stored) {
        updateUserBirthday.run(stored, name);
      }
    }
    return { username: name, friendCode: existing.friend_code };
  }
  let friendCode = randomFriendCode().toUpperCase();
  while (db.prepare('SELECT 1 FROM users WHERE friend_code = ?').get(friendCode))
    friendCode = randomFriendCode().toUpperCase();
  let birthdayISO = null;
  if (stats.birthday != null) {
    if (typeof stats.birthday === 'number') {
      birthdayISO = new Date(stats.birthday).toISOString();
    } else if (typeof stats.birthday === 'string') {
      const d = new Date(stats.birthday);
      if (!Number.isNaN(d.getTime())) birthdayISO = d.toISOString();
    }
  }

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
    name,
    birthdayISO
  );
  return { username: name, friendCode };
}

function getUserByUsername(username) {
  return db.prepare(
    'SELECT username, friend_code, device_token, level, xp, streak, total_games_played, correct_answers, best_time, birthday FROM users WHERE username = ?'
  ).get(username);
}

function getUserByFriendCode(code) {
  if (!code || typeof code !== 'string') return null;
  const normalized = code.trim().toUpperCase();
  return db.prepare(
    'SELECT username, friend_code, display_name, level, xp, streak, birthday FROM users WHERE friend_code = ?'
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
    SELECT u.username, u.friend_code, u.display_name, u.level, u.xp, u.streak, u.updated_at AS updated_at, u.birthday AS birthday
    FROM friendships f
    JOIN users u ON u.username = f.friend_username
    WHERE f.user_username = ?
  `).all(username);
  return rows;
}

function hasSentBirthdayGiftThisYear(giverUsername, receiverUsername, year) {
  const row = db
    .prepare(
      'SELECT 1 FROM birthday_gifts WHERE giver_username = ? AND receiver_username = ? AND year = ? LIMIT 1'
    )
    .get(giverUsername, receiverUsername, year);
  return !!row;
}

function createBirthdayGift({ giverUsername, receiverUsername, year, type }) {
  db.prepare(
    'INSERT OR IGNORE INTO birthday_gifts (giver_username, receiver_username, year, type, created_at) VALUES (?, ?, ?, ?, datetime(\'now\'))'
  ).run(giverUsername, receiverUsername, year, type);
}

function getBirthdayGiftsForUser(username) {
  const year = new Date().getUTCFullYear();
  return db
    .prepare(
      'SELECT giver_username AS giverUsername, receiver_username AS receiverUsername, year, type FROM birthday_gifts WHERE receiver_username = ? AND year = ?'
    )
    .all(username, year);
}

function clearBirthdayGiftsForUser(username) {
  const year = new Date().getUTCFullYear();
  db.prepare('DELETE FROM birthday_gifts WHERE receiver_username = ? AND year = ?').run(username, year);
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
  getSession,
  registerAuthUser,
  loginAuthUser,
  changePassword,
  requestPasswordReset,
  confirmPasswordReset,
  socialLogin,
  hasSentBirthdayGiftThisYear,
  createBirthdayGift,
  getBirthdayGiftsForUser,
  clearBirthdayGiftsForUser,
};
