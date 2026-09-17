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
db.pragma('foreign_keys = ON');

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
    challenger_time_ms INTEGER,
    opponent_time_ms INTEGER,
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
    expires_at TEXT NOT NULL,
    device_model TEXT,
    app_version TEXT,
    location_label TEXT
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
try { db.exec(`ALTER TABLE users ADD COLUMN avatar TEXT`); } catch (_) {}
try { db.exec(`ALTER TABLE users ADD COLUMN avatar_photo_base64 TEXT`); } catch (_) {}
try { db.exec(`ALTER TABLE users ADD COLUMN achievements_json TEXT`); } catch (_) {}
try { db.exec(`CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_unique ON users(email)`); } catch (_) {}
try { db.exec(`ALTER TABLE duel_challenges ADD COLUMN challenger_time_ms INTEGER`); } catch (_) {}
try { db.exec(`ALTER TABLE duel_challenges ADD COLUMN opponent_time_ms INTEGER`); } catch (_) {}
try { db.exec(`ALTER TABLE duel_challenges ADD COLUMN duel_regions TEXT`); } catch (_) {}
try { db.exec(`ALTER TABLE duel_challenges ADD COLUMN duel_difficulty TEXT`); } catch (_) {}
try { db.exec(`ALTER TABLE duel_challenges ADD COLUMN duel_game_mode INTEGER`); } catch (_) {}
try { db.exec(`ALTER TABLE duel_challenges ADD COLUMN duel_questions_count INTEGER`); } catch (_) {}
try { db.exec(`ALTER TABLE duel_challenges ADD COLUMN duel_options_count INTEGER`); } catch (_) {}
try { db.exec(`ALTER TABLE duel_challenges ADD COLUMN duel_questions_payload TEXT`); } catch (_) {}
try { db.exec(`ALTER TABLE auth_sessions ADD COLUMN device_model TEXT`); } catch (_) {}
try { db.exec(`ALTER TABLE auth_sessions ADD COLUMN app_version TEXT`); } catch (_) {}
try { db.exec(`ALTER TABLE auth_sessions ADD COLUMN location_label TEXT`); } catch (_) {}
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
try {
  db.exec(`
    CREATE TABLE IF NOT EXISTS time_challenge_scores (
      id TEXT PRIMARY KEY,
      username TEXT NOT NULL,
      score INTEGER NOT NULL,
      correct_answers INTEGER DEFAULT 0,
      total_answers INTEGER DEFAULT 0,
      best_combo INTEGER DEFAULT 0,
      duration_sec INTEGER DEFAULT 0,
      created_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (username) REFERENCES users(username)
    );
  `);
  db.exec(`CREATE INDEX IF NOT EXISTS idx_time_challenge_username ON time_challenge_scores(username)`);
  db.exec(`CREATE INDEX IF NOT EXISTS idx_time_challenge_created ON time_challenge_scores(created_at)`);
} catch (_) {}

function randomFriendCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 8; i++) code += chars[Math.floor(Math.random() * chars.length)];
  return code;
}

const insertUser = db.prepare(`
  INSERT INTO users (username, friend_code, device_token, level, xp, streak, total_games_played, correct_answers, best_time, display_name, birthday, achievements_json)
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
`);
const updateUserToken = db.prepare(`
  UPDATE users SET device_token = ?, updated_at = datetime('now') WHERE username = ?
`);
const updateUserStats = db.prepare(`
  UPDATE users SET level = ?, xp = ?, streak = ?, total_games_played = ?, correct_answers = ?, best_time = ?, achievements_json = ?, updated_at = datetime('now') WHERE username = ?
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

/** Единый вид user id для гостей/логина: без учёта регистра (как buildSafeUsername). */
function normalizeUsernameId(s) {
  if (!s || typeof s !== 'string') return '';
  return s.trim().toLowerCase();
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

function clipSessionText(v, maxLen) {
  if (typeof v !== 'string') return null;
  const t = v.trim();
  if (!t) return null;
  return t.length > maxLen ? t.slice(0, maxLen) : t;
}

/** meta: { deviceModel?, appVersion?, locationLabel? } — с клиента при login/register/social */
function createSession(username, meta = {}) {
  const token = randomToken();
  const dm = clipSessionText(meta.deviceModel, 120);
  const av = clipSessionText(meta.appVersion, 160);
  const loc = clipSessionText(meta.locationLabel, 200);
  db.prepare(`
    INSERT INTO auth_sessions (token, username, expires_at, device_model, app_version, location_label)
    VALUES (?, ?, datetime('now', '+30 days'), ?, ?, ?)
  `).run(token, username, dm, av, loc);
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

function getAuthSessionsForUser(username) {
  const u = getCanonicalUsername(username) || normalizeUsernameId(username);
  if (!u) return [];
  return db.prepare(`
    SELECT
      token,
      created_at AS createdAt,
      expires_at AS expiresAt,
      device_model AS deviceModel,
      app_version AS appVersion,
      location_label AS locationLabel
    FROM auth_sessions
    WHERE username = ?
      AND datetime(expires_at) > datetime('now')
    ORDER BY created_at DESC
  `).all(u);
}

function registerAuthUser({ email, password, username, sessionMeta }) {
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
  const token = createSession(uname, sessionMeta || {});
  return { username: uname, email: normalizedEmail, token, friendCode, rewardGranted: true };
}

function loginAuthUser({ email, password, sessionMeta }) {
  const normalizedEmail = normalizeEmail(email);
  const row = db.prepare(`
    SELECT username, email, friend_code, password_hash, password_salt
    FROM users WHERE email = ?
  `).get(normalizedEmail);
  if (!row) return { error: 'invalid_credentials' };
  if (!verifyPassword(password, row.password_salt, row.password_hash)) {
    return { error: 'invalid_credentials' };
  }
  const token = createSession(row.username, sessionMeta || {});
  return { username: row.username, email: row.email, friendCode: row.friend_code, token };
}

function changePassword({ username, currentPassword, newPassword }) {
  const u = getCanonicalUsername(username);
  if (!u) return { error: 'not_found' };
  const row = db.prepare('SELECT password_hash, password_salt FROM users WHERE username = ?').get(u);
  if (!row) return { error: 'not_found' };
  if (!verifyPassword(currentPassword, row.password_salt, row.password_hash)) {
    return { error: 'invalid_credentials' };
  }
  if (!newPassword || newPassword.length < 6) return { error: 'weak_password' };
  const { saltHex, hashHex } = makePasswordHash(newPassword);
  updatePasswordStmt.run(hashHex, saltHex, u);
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

function socialLogin({ provider, providerUserId, email, displayName, sessionMeta }) {
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
  const token = createSession(user.username, sessionMeta || {});
  return {
    username: user.username,
    email: user.email,
    friendCode: user.friend_code,
    token,
    rewardGranted: !!user.rewardGranted
  };
}

function registerUser({ userId, username, deviceToken = null, stats = {} }) {
  const raw = (username || userId || 'Player').trim();
  if (!raw) return { username: 'Player', friendCode: randomFriendCode() };
  const normalized = normalizeUsernameId(raw);
  // Сначала точное имя, затем lower-case, затем каноническое без учёта регистра — один аккаунт на логин.
  let row = db.prepare('SELECT username, friend_code FROM users WHERE username = ?').get(raw);
  if (!row && normalized && normalized !== raw) {
    row = db.prepare('SELECT username, friend_code FROM users WHERE username = ?').get(normalized);
  }
  if (!row) {
    const canonical = getCanonicalUsername(raw);
    if (canonical) {
      row = db.prepare('SELECT username, friend_code FROM users WHERE username = ?').get(canonical);
    }
  }
  if (row) {
    const dbUsername = row.username;
    updateUserToken.run(deviceToken, dbUsername);
    updateDisplayName.run(dbUsername, dbUsername);
    const hasStats = [stats.level, stats.xp, stats.streak, stats.totalGamesPlayed, stats.correctAnswers, stats.bestTime, stats.achievements].some(v => v != null);
    if (hasStats)
      {
      const achievementsJson = Array.isArray(stats.achievements) ? JSON.stringify(stats.achievements) : null;
      updateUserStats.run(
        stats.level ?? 1,
        stats.xp ?? 0,
        stats.streak ?? 0,
        stats.totalGamesPlayed ?? 0,
        stats.correctAnswers ?? 0,
        stats.bestTime ?? null,
        achievementsJson,
        dbUsername
      );
    }
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
        updateUserBirthday.run(stored, dbUsername);
      }
    }
    return { username: dbUsername, friendCode: row.friend_code };
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

  const newKey = normalized || normalizeUsernameId(raw);
  insertUser.run(
    newKey,
    friendCode,
    deviceToken,
    stats.level ?? 1,
    stats.xp ?? 0,
    stats.streak ?? 0,
    stats.totalGamesPlayed ?? 0,
    stats.correctAnswers ?? 0,
    stats.bestTime ?? null,
    raw,
    birthdayISO,
    Array.isArray(stats.achievements) ? JSON.stringify(stats.achievements) : null
  );
  return { username: newKey, friendCode };
}

function getUserByUsername(username) {
  const u = getCanonicalUsername(username);
  if (!u) return null;
  return db.prepare(
    'SELECT username, friend_code, display_name, device_token, level, xp, streak, total_games_played, correct_answers, best_time, birthday, avatar, avatar_photo_base64, achievements_json, created_at FROM users WHERE username = ?'
  ).get(u);
}

function getUserByFriendCode(code) {
  if (!code || typeof code !== 'string') return null;
  const normalized = code.trim().toUpperCase();
  return db.prepare(
    'SELECT username, friend_code, display_name, level, xp, streak, total_games_played, correct_answers, birthday, avatar, avatar_photo_base64, achievements_json, created_at FROM users WHERE friend_code = ?'
  ).get(normalized);
}

const addFriendship = db.prepare(`
  INSERT OR IGNORE INTO friendships (user_username, friend_username) VALUES (?, ?)
`);
const addFriendshipReverse = db.prepare(`
  INSERT OR IGNORE INTO friendships (user_username, friend_username) VALUES (?, ?)
`);

/** Однозначный username в БД: точное совпадение или без учёта регистра (при дубликатах — самый ранний created_at). */
function getCanonicalUsername(raw) {
  if (!raw || typeof raw !== 'string') return null;
  const t = raw.trim();
  if (!t) return null;
  const exact = db.prepare('SELECT username FROM users WHERE username = ?').get(t);
  if (exact) return exact.username;
  const ci = db.prepare(`
    SELECT username FROM users
    WHERE LOWER(username) = LOWER(?)
    ORDER BY datetime(created_at) ASC, username ASC
  `).all(t);
  if (ci.length === 0) return null;
  return ci[0].username;
}

function addFriend(myUsername, friendCode) {
  const raw = typeof myUsername === 'string' ? myUsername.trim() : myUsername;
  const me = getCanonicalUsername(raw);
  if (!me) return null;
  const meRow = getUserByUsername(me);
  if (!meRow) return null;
  const meKey = meRow.username;
  const friend = getUserByFriendCode(friendCode);
  if (!friend) return null;
  const friendRow = getUserByUsername(friend.username);
  if (!friendRow) return null;
  const friendKey = friendRow.username;
  if (friendKey === meKey) return null;
  try {
    addFriendship.run(meKey, friendKey);
    addFriendshipReverse.run(friendKey, meKey);
  } catch (e) {
    const msg = e && e.message ? String(e.message) : '';
    const fk = e && (e.code === 'SQLITE_CONSTRAINT_FOREIGNKEY' || msg.includes('FOREIGN KEY'));
    if (fk) {
      console.warn('[db.addFriend] FOREIGN KEY (check deploy + users row)', { meKey, friendKey, raw });
      return null;
    }
    throw e;
  }
  return friend;
}

/** Место в мире по XP: 1 = лучший; при равенстве XP — лексикографически меньший username выше. */
function getWorldRank(username) {
  const u = getCanonicalUsername(username);
  if (!u) return null;
  const row = db.prepare('SELECT xp, username FROM users WHERE username = ?').get(u);
  if (!row) return null;
  const xp = Number(row.xp) || 0;
  const name = row.username;
  const r = db
    .prepare(
      `SELECT COUNT(*) + 1 AS rank FROM users WHERE xp > ? OR (xp = ? AND username < ?)`
    )
    .get(xp, xp, name);
  return r && r.rank != null ? Number(r.rank) : null;
}

function getFriends(username) {
  const u = getCanonicalUsername(username);
  if (!u) return [];
  const rows = db.prepare(`
    SELECT u.username, u.friend_code, u.display_name, u.level, u.xp, u.streak, u.updated_at AS updated_at, u.birthday AS birthday,
           u.avatar AS avatar, u.avatar_photo_base64 AS avatar_photo_base64, u.achievements_json AS achievements_json,
           u.total_games_played AS total_games_played, u.correct_answers AS correct_answers, u.created_at AS created_at
    FROM friendships f
    JOIN users u ON u.username = f.friend_username
    WHERE f.user_username = ?
  `).all(u);
  return rows;
}

function hasSentBirthdayGiftThisYear(giverUsername, receiverUsername, year) {
  const g = getCanonicalUsername(giverUsername) || normalizeUsernameId(giverUsername);
  const r = getCanonicalUsername(receiverUsername) || normalizeUsernameId(receiverUsername);
  const row = db
    .prepare(
      'SELECT 1 FROM birthday_gifts WHERE (giver_username = ? OR LOWER(giver_username) = LOWER(?)) AND (receiver_username = ? OR LOWER(receiver_username) = LOWER(?)) AND year = ? LIMIT 1'
    )
    .get(g, g, r, r, year);
  return !!row;
}

function createBirthdayGift({ giverUsername, receiverUsername, year, type }) {
  const g = getCanonicalUsername(giverUsername) || normalizeUsernameId(giverUsername);
  const r = getCanonicalUsername(receiverUsername) || normalizeUsernameId(receiverUsername);
  db.prepare(
    'INSERT OR IGNORE INTO birthday_gifts (giver_username, receiver_username, year, type, created_at) VALUES (?, ?, ?, ?, datetime(\'now\'))'
  ).run(g, r, year, type);
}

function getBirthdayGiftsForUser(username) {
  const u = getCanonicalUsername(username) || normalizeUsernameId(username);
  const year = new Date().getUTCFullYear();
  return db
    .prepare(
      'SELECT giver_username AS giverUsername, receiver_username AS receiverUsername, year, type FROM birthday_gifts WHERE (receiver_username = ? OR LOWER(receiver_username) = LOWER(?)) AND year = ?'
    )
    .all(u, u, year);
}

function clearBirthdayGiftsForUser(username) {
  const u = getCanonicalUsername(username) || normalizeUsernameId(username);
  const year = new Date().getUTCFullYear();
  db.prepare('DELETE FROM birthday_gifts WHERE (receiver_username = ? OR LOWER(receiver_username) = LOWER(?)) AND year = ?').run(u, u, year);
}

function setDisplayName(username, displayName) {
  const u = getCanonicalUsername(username);
  if (!u || !displayName) return false;
  updateDisplayName.run((displayName || '').trim(), u);
  return true;
}

function setUserAvatar(username, avatar, avatarPhotoBase64) {
  const u = getCanonicalUsername(username);
  if (!u) return false;
  db.prepare(
    'UPDATE users SET avatar = ?, avatar_photo_base64 = ?, updated_at = datetime(\'now\') WHERE username = ?'
  ).run(avatar || null, avatarPhotoBase64 || null, u);
  return true;
}

// Duel challenges
function createChallenge(row) {
  db.prepare(`
    INSERT INTO duel_challenges (
      id, challenger_id, challenger_name, opponent_id, opponent_name, seed, challenger_score, opponent_score, status,
      duel_regions, duel_difficulty, duel_game_mode, duel_questions_count, duel_options_count, duel_questions_payload
    )
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(
    row.id, row.challengerId, row.challengerName, row.opponentId, row.opponentName, row.seed, null, null, 'pending',
    row.duelRegions || null, row.duelDifficulty || null, row.duelGameMode ?? null, row.duelQuestionsCount ?? null, row.duelOptionsCount ?? null, row.duelQuestionsPayload || null
  );
}

function getChallenge(id) {
  return db.prepare('SELECT * FROM duel_challenges WHERE id = ?').get(id);
}

function setChallengeStatus(id, status) {
  db.prepare('UPDATE duel_challenges SET status = ? WHERE id = ?').run(status, id);
}

function getIncomingChallenges(opponentId) {
  const oid = getCanonicalUsername(opponentId) || normalizeUsernameId(opponentId);
  if (!oid) return [];
  // pending — ждём принятия; challenger_completed + opponent_score NULL — challengер уже сыграл,
  // оппонент ещё не принял/не видел вызов в приложении (иначе строка пропадала из /incoming).
  return db.prepare(`
    SELECT id, challenger_id AS challengerId, challenger_name AS challengerName, seed, created_at AS createdAt, challenger_score AS challengerScore, status,
           duel_regions AS duelRegions, duel_difficulty AS duelDifficulty, duel_game_mode AS duelGameMode,
           duel_questions_count AS duelQuestionsCount, duel_options_count AS duelOptionsCount,
           duel_questions_payload AS duelQuestionsPayload
    FROM duel_challenges
    WHERE opponent_id = ?
      AND datetime(created_at) >= datetime('now', '-24 hours')
      AND (
        status = 'pending'
        OR (status = 'challenger_completed' AND opponent_score IS NULL)
      )
    ORDER BY created_at DESC
  `).all(opponentId);
}

function getIncomingChallengesForSync(opponentId) {
  return db.prepare(`
    SELECT
      id,
      challenger_id AS challengerId,
      challenger_name AS challengerName,
      seed,
      created_at AS createdAt,
      challenger_score AS challengerScore,
      opponent_score AS opponentScore,
      challenger_time_ms AS challengerTimeMs,
      opponent_time_ms AS opponentTimeMs,
      status,
      duel_regions AS duelRegions,
      duel_difficulty AS duelDifficulty,
      duel_game_mode AS duelGameMode,
      duel_questions_count AS duelQuestionsCount,
      duel_options_count AS duelOptionsCount,
      duel_questions_payload AS duelQuestionsPayload
    FROM duel_challenges
    WHERE opponent_id = ?
      AND status IN ('pending','challenger_completed','opponent_completed','completed')
      AND datetime(created_at) >= datetime('now', '-24 hours')
    ORDER BY created_at DESC
  `).all(opponentId);
}

function getOutgoingChallenges(challengerId) {
  return db.prepare(`
    SELECT id, challenger_name AS challengerName, opponent_name AS opponentName, seed,
           created_at AS createdAt, challenger_score AS challengerScore, opponent_score AS opponentScore,
           status, challenger_time_ms AS challengerTimeMs, opponent_time_ms AS opponentTimeMs,
           duel_regions AS duelRegions, duel_difficulty AS duelDifficulty, duel_game_mode AS duelGameMode,
           duel_questions_count AS duelQuestionsCount, duel_options_count AS duelOptionsCount,
           duel_questions_payload AS duelQuestionsPayload
    FROM duel_challenges
    WHERE challenger_id = ?
      AND datetime(created_at) >= datetime('now', '-24 hours')
    ORDER BY created_at DESC
  `).all(challengerId);
}

function removeFriendship(userA, friendUsername) {
  const a = getCanonicalUsername(userA);
  const b = getCanonicalUsername(friendUsername);
  if (!a || !b || a === b) return false;
  const r = db
    .prepare(
      'DELETE FROM friendships WHERE (user_username = ? AND friend_username = ?) OR (user_username = ? AND friend_username = ?)'
    )
    .run(a, b, b, a);
  return r.changes > 0;
}

function updateChallengeScore(id, side, score, elapsedMs) {
  const c = getChallenge(id);
  if (!c) return null;
  if (c.status === 'declined') return null;
  if (side === 'challenger') {
    const createdAt = c.created_at ? new Date(c.created_at).getTime() : 0;
    const expiry24h = Date.now() - 24 * 60 * 60 * 1000;
    if (c.opponent_score == null && createdAt < expiry24h) {
      db.prepare('UPDATE duel_challenges SET challenger_score = ?, challenger_time_ms = ?, opponent_score = ?, status = ? WHERE id = ?').run(
        score, elapsedMs ?? null, -1, 'completed', id
      );
      return getChallenge(id);
    }
    db.prepare('UPDATE duel_challenges SET challenger_score = ?, challenger_time_ms = ?, status = ? WHERE id = ?').run(
      score,
      elapsedMs ?? null,
      c.opponent_score != null ? 'completed' : 'challenger_completed',
      id
    );
  } else {
    db.prepare('UPDATE duel_challenges SET opponent_score = ?, opponent_time_ms = ?, status = ? WHERE id = ?').run(
      score,
      elapsedMs ?? null,
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
  const a = getCanonicalUsername(usernameA);
  const b = getCanonicalUsername(usernameB);
  if (!a || !b || a === b) return false;
  const row = db.prepare(
    'SELECT 1 FROM friendships WHERE (user_username = ? AND friend_username = ?) OR (user_username = ? AND friend_username = ?)'
  ).get(a, b, b, a);
  return !!row;
}

const insertNudge = db.prepare(`
  INSERT INTO nudges (id, from_username, to_username, phrase_id) VALUES (?, ?, ?, ?)
`);

function createNudge({ id, fromUsername, toUsername, phraseId }) {
  const from = getCanonicalUsername(fromUsername) || normalizeUsernameId(fromUsername);
  const to = getCanonicalUsername(toUsername) || normalizeUsernameId(toUsername);
  insertNudge.run(id, from, to, phraseId);
  return { id, fromUsername: from, toUsername: to, phraseId };
}

function getNudgesForUser(toUsername, unreadOnly = true) {
  const to = getCanonicalUsername(toUsername) || normalizeUsernameId(toUsername);
  const sql = unreadOnly
    ? "SELECT id, from_username AS fromUsername, phrase_id AS phraseId, created_at AS createdAt FROM nudges WHERE (to_username = ? OR LOWER(to_username) = LOWER(?)) AND read_at IS NULL ORDER BY created_at DESC"
    : "SELECT id, from_username AS fromUsername, phrase_id AS phraseId, created_at AS createdAt, read_at AS readAt FROM nudges WHERE to_username = ? OR LOWER(to_username) = LOWER(?) ORDER BY created_at DESC";
  return db.prepare(sql).all(to, to);
}

function markNudgesRead(toUsername) {
  const to = getCanonicalUsername(toUsername) || normalizeUsernameId(toUsername);
  return db.prepare("UPDATE nudges SET read_at = datetime('now') WHERE (to_username = ? OR LOWER(to_username) = LOWER(?)) AND read_at IS NULL").run(to, to);
}

function addTimeChallengeScore(row) {
  const u = getCanonicalUsername(row.username) || normalizeUsernameId(row.username);
  db.prepare(`
    INSERT INTO time_challenge_scores
      (id, username, score, correct_answers, total_answers, best_combo, duration_sec, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'))
  `).run(
    row.id,
    u,
    row.score ?? 0,
    row.correctAnswers ?? 0,
    row.totalAnswers ?? 0,
    row.bestCombo ?? 0,
    row.durationSec ?? 0
  );
}

function getTimeChallengeTop(period = 'daily', limit = 20) {
  const safeLimit = Math.max(1, Math.min(100, Number(limit) || 20));
  const periodFilter = period === 'weekly'
    ? `created_at >= datetime('now', '-6 days')`
    : `created_at >= date('now')`;
  return db.prepare(`
    SELECT
      username,
      MAX(score) AS score,
      MAX(best_combo) AS best_combo
    FROM time_challenge_scores
    WHERE ${periodFilter}
    GROUP BY username
    ORDER BY score DESC, best_combo DESC, username ASC
    LIMIT ?
  `).all(safeLimit);
}

function mergeUserInto(primary, dup) {
  if (!primary || !dup || primary === dup) return;
  console.log('[db] mergeUserInto', primary, '<-', dup);
  db.prepare('UPDATE friendships SET user_username = ? WHERE user_username = ?').run(primary, dup);
  db.prepare('UPDATE friendships SET friend_username = ? WHERE friend_username = ?').run(primary, dup);
  db.prepare('DELETE FROM friendships WHERE user_username = friend_username').run();
  db.prepare(`
    DELETE FROM friendships WHERE rowid NOT IN (
      SELECT MIN(rowid) FROM friendships GROUP BY user_username, friend_username
    )
  `).run();

  db.prepare('UPDATE duel_challenges SET challenger_id = ? WHERE challenger_id = ?').run(primary, dup);
  db.prepare('UPDATE duel_challenges SET opponent_id = ? WHERE opponent_id = ?').run(primary, dup);

  db.prepare('UPDATE nudges SET from_username = ? WHERE from_username = ?').run(primary, dup);
  db.prepare('UPDATE nudges SET to_username = ? WHERE to_username = ?').run(primary, dup);

  db.prepare('UPDATE auth_sessions SET username = ? WHERE username = ?').run(primary, dup);
  db.prepare('UPDATE password_resets SET username = ? WHERE username = ?').run(primary, dup);
  db.prepare('UPDATE birthday_gifts SET giver_username = ? WHERE giver_username = ?').run(primary, dup);
  db.prepare('UPDATE birthday_gifts SET receiver_username = ? WHERE receiver_username = ?').run(primary, dup);
  db.prepare('UPDATE time_challenge_scores SET username = ? WHERE username = ?').run(primary, dup);

  const pRow = db.prepare('SELECT * FROM users WHERE username = ?').get(primary);
  const dRow = db.prepare('SELECT * FROM users WHERE username = ?').get(dup);
  if (pRow && dRow) {
    const mergedLevel = Math.max(pRow.level || 0, dRow.level || 0);
    const mergedXp = Math.max(pRow.xp || 0, dRow.xp || 0);
    const mergedStreak = Math.max(pRow.streak || 0, dRow.streak || 0);
    const mergedTgp = Math.max(pRow.total_games_played || 0, dRow.total_games_played || 0);
    const mergedCa = Math.max(pRow.correct_answers || 0, dRow.correct_answers || 0);
    let mergedBt = pRow.best_time;
    if (dRow.best_time != null) {
      if (mergedBt == null || dRow.best_time < mergedBt) mergedBt = dRow.best_time;
    }
    const deviceToken = pRow.device_token || dRow.device_token;
    const displayName = pRow.display_name || dRow.display_name;
    const email = pRow.email || dRow.email;
    const avatar = pRow.avatar || dRow.avatar;
    const photo = pRow.avatar_photo_base64 || dRow.avatar_photo_base64;
    const achievements = pRow.achievements_json || dRow.achievements_json;

    db.prepare(`
      UPDATE users SET
        level = ?, xp = ?, streak = ?, total_games_played = ?, correct_answers = ?, best_time = ?,
        device_token = ?, display_name = ?, email = ?, avatar = ?, avatar_photo_base64 = ?, achievements_json = ?,
        updated_at = datetime('now')
      WHERE username = ?
    `).run(
      mergedLevel,
      mergedXp,
      mergedStreak,
      mergedTgp,
      mergedCa,
      mergedBt,
      deviceToken,
      displayName,
      email,
      avatar,
      photo,
      achievements,
      primary
    );
  }

  db.prepare('DELETE FROM users WHERE username = ?').run(dup);
}

function mergeDuplicateUsers() {
  const groups = db.prepare(`
    SELECT LOWER(username) AS k, COUNT(*) AS c
    FROM users
    GROUP BY LOWER(username)
    HAVING c > 1
  `).all();
  let merged = 0;
  for (const g of groups) {
    const rows = db.prepare(`
      SELECT username FROM users
      WHERE LOWER(username) = ?
      ORDER BY datetime(created_at) ASC, username ASC
    `).all(g.k);
    if (rows.length < 2) continue;
    const primary = rows[0].username;
    for (let i = 1; i < rows.length; i++) {
      mergeUserInto(primary, rows[i].username);
      merged += 1;
    }
  }
  if (merged > 0) console.log('[db] mergeDuplicateUsers: merged', merged, 'duplicate account(s)');
}

try {
  mergeDuplicateUsers();
} catch (e) {
  console.error('[db] mergeDuplicateUsers failed', e.message || e);
}

function getTimeChallengeRank(period = 'daily', username, score) {
  if (!username) return null;
  const u = getCanonicalUsername(username) || normalizeUsernameId(username);
  const periodFilter = period === 'weekly'
    ? `created_at >= datetime('now', '-6 days')`
    : `created_at >= date('now')`;
  const myBest = db.prepare(`
    SELECT MAX(score) AS value
    FROM time_challenge_scores
    WHERE username = ? AND ${periodFilter}
  `).get(u)?.value ?? 0;
  const effectiveScore = Math.max(Number(score) || 0, myBest);
  const betterCount = db.prepare(`
    SELECT COUNT(*) AS c
    FROM (
      SELECT username, MAX(score) AS max_score
      FROM time_challenge_scores
      WHERE ${periodFilter}
      GROUP BY username
    ) t
    WHERE t.max_score > ?
  `).get(effectiveScore)?.c ?? 0;
  return Number(betterCount) + 1;
}

module.exports = {
  db,
  registerUser,
  getUserByUsername,
  getWorldRank,
  getCanonicalUsername,
  normalizeUsernameId,
  getUserByFriendCode,
  addFriend,
  getFriends,
  setDisplayName,
  setUserAvatar,
  createChallenge,
  getChallenge,
  setChallengeStatus,
  getIncomingChallenges,
  getIncomingChallengesForSync,
  getOutgoingChallenges,
  removeFriendship,
  updateChallengeScore,
  getAllUsersForRandomOpponent,
  areFriends,
  createNudge,
  getNudgesForUser,
  markNudgesRead,
  getSession,
  getAuthSessionsForUser,
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
  addTimeChallengeScore,
  getTimeChallengeTop,
  getTimeChallengeRank,
};
