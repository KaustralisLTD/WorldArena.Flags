/**
 * API дуэлей World Arena Flags.
 * Хранилище: SQLite (users, friendships, duel_challenges).
 * Продакшен: flags.worldarena.games (nginx проксирует /api/ на этот процесс).
 */
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env'), override: true });
const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');
const db = require('./db');
if (process.env.MAILGUN_API_KEY && process.env.MAILGUN_DOMAIN) {
  console.log('[server] .env loaded, Mailgun enabled');
}
const mailgun = require('./mailgun');
// Парсим локаль из заголовка сами, чтобы не зависеть от экспорта mailgun
const SUPPORTED_LOCALES = ['en', 'ru', 'de', 'es', 'fr', 'it', 'nl', 'pl', 'pt', 'zh', 'ca', 'uk'];
function getMailgunLocale(acceptLanguage) {
  if (!acceptLanguage) return 'en';
  const raw = (acceptLanguage.split(',')[0] || '').trim().toLowerCase();
  const first = raw.substring(0, 2);
  if (first === 'pt' && (raw.startsWith('pt-br') || raw.startsWith('pt_br'))) return 'pt';
  return SUPPORTED_LOCALES.includes(first) ? first : 'en';
}

const app = express();
app.use(cors({ origin: true }));
app.use(express.json({ limit: '3mb' }));
// Статические файлы: `public/flags/AF.png` → GET /flags/AF.png (тот же хост, что и /api у nginx)
app.use(express.static(path.join(__dirname, 'public')));

/** Победитель при status=completed (счёт или ничья по времени). Поддержка snake_case и camelCase из SQLite alias. */
function duelWinnerFromRow(c) {
  if (!c || c.status !== 'completed') return null;
  const cs = (c.challenger_score ?? c.challengerScore ?? 0) || 0;
  const os = (c.opponent_score ?? c.opponentScore ?? 0) || 0;
  if (cs > os) return 'challenger';
  if (os > cs) return 'opponent';
  const ctRaw = c.challenger_time_ms ?? c.challengerTimeMs;
  const otRaw = c.opponent_time_ms ?? c.opponentTimeMs;
  const ct = Number.isFinite(ctRaw) ? ctRaw : Number.MAX_SAFE_INTEGER;
  const ot = Number.isFinite(otRaw) ? otRaw : Number.MAX_SAFE_INTEGER;
  return ot < ct ? 'opponent' : 'challenger';
}

function parseJSONSafe(raw, fallback = null) {
  if (typeof raw !== 'string' || !raw.length) return fallback;
  try { return JSON.parse(raw); } catch (_) { return fallback; }
}

/**
 * Краткая сводка по duelQuestionsPayload для логов (без вывода всего JSON).
 * mode: payload — на клиентах должны совпасть вопросы по id; seed_only — только seed+регионы (риск расхождений).
 */
function duelPayloadLogSummary(rawPayload) {
  const arr = Array.isArray(rawPayload)
    ? rawPayload
    : parseJSONSafe(rawPayload, null);
  if (!Array.isArray(arr) || arr.length === 0) {
    return {
      payloadMode: 'seed_only',
      payloadQuestionCount: 0,
      payloadFirstCorrectId: null,
      payloadLastCorrectId: null,
      payloadFirstOptionsLen: null,
    };
  }
  const first = arr[0];
  const last = arr[arr.length - 1];
  const firstCorrect = first && typeof first.correctCountryId === 'string' ? first.correctCountryId : null;
  const lastCorrect = last && typeof last.correctCountryId === 'string' ? last.correctCountryId : null;
  const firstOptLen = first && Array.isArray(first.optionCountryIds) ? first.optionCountryIds.length : null;
  return {
    payloadMode: 'payload',
    payloadQuestionCount: arr.length,
    payloadFirstCorrectId: firstCorrect,
    payloadLastCorrectId: lastCorrect,
    payloadFirstOptionsLen: firstOptLen,
  };
}

/** SQLite `datetime` как UTC → миллисекунды для клиента (joinDate / стабильный seed ранга). */
function millisFromSqliteDateTime(v) {
  if (v == null || v === '') return null;
  const d = new Date(String(v).replace(' ', 'T') + 'Z');
  return Number.isNaN(d.getTime()) ? null : d.getTime();
}

/** Заголовок X-User-Id / поля body — к одному username в БД (регистр не важен). */
function resolveUserId(raw) {
  const t = String(raw || '').trim();
  if (!t) return '';
  const c = db.getCanonicalUsername(t);
  if (c) return c;
  return db.normalizeUsernameId(t);
}

const PORT = process.env.PORT || 3001;

app.get('/api/v1/health', (_, res) => {
  res.json({ ok: true, service: 'duel-api' });
});

/** Быстрая диагностика APNs: env, провайдер, topic (без секретов). */
let getApnsDiagnostics = () => ({
  env: {
    APNS_KEY_ID: false,
    APNS_TEAM_ID: false,
    APNS_BUNDLE_ID: false,
    APNS_KEY_P8_PATH: false,
  },
  hasProvider: false,
  nodeEnv: process.env.NODE_ENV || null,
  apnsProduction: process.env.NODE_ENV === 'production',
  topic: process.env.APNS_BUNDLE_ID || 'com.worldarena.flags',
});
try {
  const pushMod = require('./push.js');
  if (typeof pushMod.getApnsDiagnostics === 'function') {
    getApnsDiagnostics = pushMod.getApnsDiagnostics;
  }
} catch (e) {
  console.warn('[server] push.js diagnostics unavailable:', e.message);
}
app.get('/api/v1/health/push', (_, res) => {
  const diag = getApnsDiagnostics();
  res.json({ ok: true, service: 'duel-api', apns: diag });
});

function sessionMetaFromRequest(req) {
  const b = req.body || {};
  const nest = b.clientInfo || b.sessionInfo || {};
  const src = { ...nest, ...b };
  const clip = (v, n) => {
    if (typeof v !== 'string') return null;
    const t = v.trim();
    if (!t) return null;
    return t.length > n ? t.slice(0, n) : t;
  };
  return {
    deviceModel: clip(src.deviceModel || src.device_model, 120),
    appVersion: clip(src.appVersion || src.app_version, 160),
    locationLabel: clip(src.locationLabel || src.location_label, 200),
  };
}

function authFromRequest(req) {
  const bearer = (req.headers.authorization || '').trim();
  const token = bearer.startsWith('Bearer ') ? bearer.slice(7) : null;
  if (!token) return null;
  return db.getSession(token);
}

// ——— Auth ———
// POST /api/v1/auth/register
app.post('/api/v1/auth/register', (req, res) => {
  try {
    const result = db.registerAuthUser({
      email: req.body?.email,
      password: req.body?.password,
      username: req.body?.username,
      sessionMeta: sessionMetaFromRequest(req),
    });
    if (result.error === 'email_exists') return res.status(409).json({ error: 'Email already exists', errorCode: 'email_already_exists' });
    if (result.error) return res.status(400).json({ error: 'Invalid registration payload', errorCode: 'invalid_registration' });
    const locale = getMailgunLocale(req.headers['accept-language']);
    if (process.env.MAILGUN_API_KEY && process.env.MAILGUN_DOMAIN) {
      mailgun.sendWelcomeEmail(result.email, result.username, locale).catch((err) => console.error('[auth/register] welcome email', err.message));
    }
    return res.status(201).json({
      ok: true,
      token: result.token,
      user: {
        username: result.username,
        email: result.email,
        friendCode: result.friendCode
      },
      awardedRegistrationBonus: result.rewardGranted === true
    });
  } catch (e) {
    console.error('auth/register', e);
    return res.status(500).json({ error: 'Registration failed', errorCode: 'registration_failed' });
  }
});

// POST /api/v1/auth/login
app.post('/api/v1/auth/login', (req, res) => {
  try {
    const result = db.loginAuthUser({
      email: req.body?.email,
      password: req.body?.password,
      sessionMeta: sessionMetaFromRequest(req),
    });
    if (result.error) return res.status(401).json({ error: 'Invalid credentials' });
    return res.json({
      ok: true,
      token: result.token,
      user: {
        username: result.username,
        email: result.email,
        friendCode: result.friendCode
      }
    });
  } catch (e) {
    console.error('auth/login', e);
    return res.status(500).json({ error: 'Login failed' });
  }
});

// POST /api/v1/auth/social-login
app.post('/api/v1/auth/social-login', (req, res) => {
  try {
    const result = db.socialLogin({
      provider: req.body?.provider,
      providerUserId: req.body?.providerUserId,
      email: req.body?.email,
      displayName: req.body?.displayName,
      sessionMeta: sessionMetaFromRequest(req),
    });
    return res.json({
      ok: true,
      token: result.token,
      user: {
        username: result.username,
        email: result.email,
        friendCode: result.friendCode
      },
      awardedRegistrationBonus: result.rewardGranted === true
    });
  } catch (e) {
    console.error('auth/social-login', e);
    return res.status(500).json({ error: 'Social login failed' });
  }
});

// Список активных сессий (по токену нельзя, показываем по username для UI в настройках).
function handleAuthSessions(req, res) {
  const userId = resolveUserId(req.headers['x-user-id'] || req.query.userId);
  if (!userId) return res.status(400).json({ error: 'userId required' });

  try {
    const rows = db.getAuthSessionsForUser(userId);
    res.json({
      sessions: rows.map((s) => ({
        token: s.token,
        createdAt: s.createdAt,
        expiresAt: s.expiresAt,
        deviceModel: s.deviceModel || null,
        appVersion: s.appVersion || null,
        locationLabel: s.locationLabel || null,
      }))
    });
  } catch (e) {
    console.error('auth/sessions', e);
    res.status(500).json({ error: 'Failed to fetch sessions' });
  }
}
// Основной путь
app.get('/api/v1/auth/sessions', handleAuthSessions);
// Legacy/проксированный путь (когда /api/v1 срезается reverse-proxy)
app.get('/auth/sessions', handleAuthSessions);

// POST /api/v1/auth/change-password
app.post('/api/v1/auth/change-password', (req, res) => {
  const auth = authFromRequest(req);
  if (!auth) return res.status(401).json({ error: 'Unauthorized' });
  try {
    const result = db.changePassword({
      username: auth.username,
      currentPassword: req.body?.currentPassword,
      newPassword: req.body?.newPassword
    });
    if (result.error === 'invalid_credentials') return res.status(400).json({ error: 'Current password is invalid' });
    if (result.error === 'weak_password') return res.status(400).json({ error: 'New password is too weak' });
    if (result.error) return res.status(400).json({ error: 'Password update failed' });
    if (auth.email) {
      const locale = getMailgunLocale(req.headers['accept-language']);
      mailgun.sendPasswordChangedEmail(auth.email, auth.username, locale).catch((err) => console.error('[auth/change-password] mailgun', err.message));
    }
    return res.json({ ok: true });
  } catch (e) {
    console.error('auth/change-password', e);
    return res.status(500).json({ error: 'Password update failed' });
  }
});

// POST /api/v1/auth/reset-password/request
app.post('/api/v1/auth/reset-password/request', (req, res) => {
  try {
    const { email } = req.body || {};
    const result = db.requestPasswordReset(email);
    const userFound = !!(result && result.code && result.username);
    if (userFound) {
      if (!process.env.MAILGUN_API_KEY || !process.env.MAILGUN_DOMAIN) {
        console.log(`[auth/reset-password] Mailgun not configured; code for ${result.username} (${email}): ${result.code}`);
      } else {
        console.log('[auth/reset-password] sending email to user');
        const locale = getMailgunLocale(req.headers['accept-language']);
        mailgun.sendResetEmail(email, result.code, result.username, locale).catch((err) => {
          console.error('[auth/reset-password] mailgun', err.message);
          if (String(err.message).includes('401')) {
            console.error('[auth/reset-password] 401 = wrong API key or wrong region. Check MAILGUN_API_KEY (Private key) and MAILGUN_EU (true for EU domain) in .env');
          }
        });
      }
    } else {
      console.log('[auth/reset-password] request received, no user with this email in DB');
    }
    return res.json({ ok: true, emailSent: userFound });
  } catch (e) {
    console.error('auth/reset-password/request', e);
    return res.status(500).json({ error: 'Reset request failed', errorCode: 'reset_request_failed' });
  }
});

// POST /api/v1/auth/reset-password/confirm
app.post('/api/v1/auth/reset-password/confirm', (req, res) => {
  try {
    const result = db.confirmPasswordReset({
      email: req.body?.email,
      code: req.body?.code,
      newPassword: req.body?.newPassword
    });
    if (result.error === 'invalid_code') return res.status(400).json({ error: 'Invalid reset code' });
    if (result.error === 'weak_password') return res.status(400).json({ error: 'New password is too weak' });
    if (result.error) return res.status(400).json({ error: 'Password reset failed' });
    if (result.username && req.body?.email && process.env.MAILGUN_API_KEY && process.env.MAILGUN_DOMAIN) {
      const locale = getMailgunLocale(req.headers['accept-language']);
      mailgun.sendPasswordChangedEmail(req.body.email, result.username, locale).catch((err) => {
        console.error('[auth/reset-password/confirm] password-changed email', err.message);
      });
    }
    return res.json({ ok: true });
  } catch (e) {
    console.error('auth/reset-password/confirm', e);
    return res.status(500).json({ error: 'Password reset failed' });
  }
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
    const worldRank = db.getWorldRank(result.username);
    res.json({ ok: true, username: result.username, friendCode: result.friendCode, worldRank });
  } catch (e) {
    console.error('register', e);
    res.status(500).json({ error: 'Registration failed' });
  }
});

// GET /api/v1/users/by-code/:code — по коду друга вернуть пользователя (для добавления в друзья)
app.get('/api/v1/users/by-code/:code', (req, res) => {
  const user = db.getUserByFriendCode(req.params.code);
  if (!user) return res.status(404).json({ error: 'User not found' });
  const achievements = parseJSONSafe(user.achievements_json, []);
  res.json({
    username: user.username,
    displayName: user.display_name || user.username,
    friendCode: user.friend_code,
    level: user.level || 1,
    xp: user.xp || 0,
    streak: user.streak || 0,
    totalGamesPlayed: user.total_games_played ?? 0,
    correctAnswers: user.correct_answers ?? 0,
    createdAt: millisFromSqliteDateTime(user.created_at),
    avatar: user.avatar || null,
    avatarPhotoBase64: user.avatar_photo_base64 || null,
    achievements: Array.isArray(achievements) ? achievements : [],
    worldRank: db.getWorldRank(user.username),
  });
});

// GET /api/v1/users/by-username/:username — логин без учёта регистра (для добавления в друзья и профиля)
app.get('/api/v1/users/by-username/:username', (req, res) => {
  const raw = (req.params.username || '').trim();
  if (!raw) return res.status(400).json({ error: 'username required' });
  const canonical = db.getCanonicalUsername(raw);
  if (!canonical) return res.status(404).json({ error: 'User not found' });
  const row = db.getUserByUsername(canonical);
  if (!row) return res.status(404).json({ error: 'User not found' });
  const achievements = parseJSONSafe(row.achievements_json, []);
  res.json({
    username: row.username,
    displayName: row.display_name || row.username,
    friendCode: row.friend_code,
    level: row.level || 1,
    xp: row.xp || 0,
    streak: row.streak || 0,
    totalGamesPlayed: row.total_games_played ?? 0,
    correctAnswers: row.correct_answers ?? 0,
    createdAt: millisFromSqliteDateTime(row.created_at),
    avatar: row.avatar || null,
    avatarPhotoBase64: row.avatar_photo_base64 || null,
    achievements: Array.isArray(achievements) ? achievements : [],
    worldRank: db.getWorldRank(row.username),
  });
});

function isPlayedToday(updatedAt) {
  if (!updatedAt) return false;
  const d = new Date(updatedAt);
  const now = new Date();
  return d.getUTCFullYear() === now.getUTCFullYear() &&
    d.getUTCMonth() === now.getUTCMonth() &&
    d.getUTCDate() === now.getUTCDate();
}

// GET /api/v1/users/me/friends — список друзей текущего пользователя (displayName, playedToday, birthday)
app.get('/api/v1/users/me/friends', (req, res) => {
  const userId = resolveUserId(req.headers['x-user-id'] || req.query.userId);
  if (!userId) return res.status(400).json({ error: 'userId required' });
  const friends = db.getFriends(userId);
  res.json({
    friends: friends.map((f) => {
      const achievements = parseJSONSafe(f.achievements_json, []);
      return {
        username: f.username,
        displayName: f.display_name || f.username,
        friendCode: f.friend_code,
        level: f.level || 1,
        xp: f.xp || 0,
        streak: f.streak || 0,
        totalGamesPlayed: f.total_games_played ?? 0,
        correctAnswers: f.correct_answers ?? 0,
        createdAt: millisFromSqliteDateTime(f.created_at),
        playedToday: isPlayedToday(f.updated_at),
        birthday: f.birthday || null,
        avatar: f.avatar || null,
        avatarPhotoBase64: f.avatar_photo_base64 || null,
        achievements: Array.isArray(achievements) ? achievements : [],
        worldRank: db.getWorldRank(f.username),
      };
    }),
  });
});

// PATCH /api/v1/users/me — обновить отображаемое имя (у друзей будет видно новое имя)
app.patch('/api/v1/users/me', (req, res) => {
  const userId = resolveUserId(req.headers['x-user-id'] || req.body.userId);
  const { displayName, avatar, customAvatarBase64 } = req.body || {};
  if (!userId) return res.status(400).json({ error: 'userId required' });
  const hasDisplayName = typeof displayName === 'string' && displayName.trim().length > 0;
  const hasAvatar = typeof avatar === 'string' || typeof customAvatarBase64 === 'string';
  if (!hasDisplayName && !hasAvatar) {
    return res.status(400).json({ error: 'nothing to update' });
  }
  if (hasDisplayName) {
    db.setDisplayName(userId, displayName.trim());
  }
  if (hasAvatar) {
    const safeAvatar = typeof avatar === 'string' ? avatar : null;
    const safePhoto = typeof customAvatarBase64 === 'string' ? customAvatarBase64 : null;
    db.setUserAvatar(userId, safeAvatar, safePhoto);
  }
  res.json({ ok: true });
});

// POST /api/v1/friends/add — добавить друга по коду
app.post('/api/v1/friends/add', (req, res) => {
  const myUsername = resolveUserId(req.headers['x-user-id'] || req.body.userId);
  const { friendCode } = req.body;
  if (!myUsername || !friendCode) return res.status(400).json({ error: 'userId and friendCode required' });
  let friend;
  try {
    friend = db.addFriend(myUsername, friendCode);
  } catch (e) {
    const msg = e && e.message ? String(e.message) : String(e);
    console.warn('[friends/add] addFriend threw:', msg, 'user=', myUsername);
    return res.status(400).json({ error: 'Invalid code or cannot add yourself' });
  }
  if (!friend) return res.status(400).json({ error: 'Invalid code or cannot add yourself' });
  const achievements = parseJSONSafe(friend.achievements_json, []);
  res.json({
    ok: true,
    friend: {
      username: friend.username,
      displayName: friend.display_name || friend.username,
      friendCode: friend.friend_code,
      level: friend.level || 1,
      xp: friend.xp || 0,
      streak: friend.streak || 0,
      totalGamesPlayed: friend.total_games_played ?? 0,
      correctAnswers: friend.correct_answers ?? 0,
      createdAt: millisFromSqliteDateTime(friend.created_at),
      birthday: friend.birthday || null,
      avatar: friend.avatar || null,
      avatarPhotoBase64: friend.avatar_photo_base64 || null,
      achievements: Array.isArray(achievements) ? achievements : [],
      worldRank: db.getWorldRank(friend.username),
    },
  });
});

// POST /api/v1/friends/remove — удалить дружбу с обеих сторон
app.post('/api/v1/friends/remove', (req, res) => {
  const myUsername = resolveUserId(req.headers['x-user-id'] || req.body.userId);
  const { friendUsername } = req.body;
  if (!myUsername || !friendUsername) return res.status(400).json({ error: 'userId and friendUsername required' });
  const ok = db.removeFriendship(myUsername, String(friendUsername).trim());
  if (!ok) return res.status(404).json({ error: 'Friendship not found' });
  res.json({ ok: true });
});

// ——— Duel ———
// POST /api/v1/duel/challenge
app.post('/api/v1/duel/challenge', (req, res) => {
  const {
    opponentId,
    seed,
    challengerName,
    duelRegions,
    duelDifficulty,
    duelGameMode,
    duelQuestionsCount,
    duelOptionsCount,
    duelQuestionsPayload
  } = req.body || {};
  const challengerId = resolveUserId(req.headers['x-user-id'] || req.body.challengerId || 'local-user');
  if (!opponentId || seed == null) return res.status(400).json({ error: 'opponentId and seed required' });
  const opponentKey = resolveUserId(opponentId);
  const opponent = db.getUserByUsername(opponentKey);
  const opponentName = (opponent && opponent.username) || 'Opponent';
  const id = uuidv4();
  db.createChallenge({
    id,
    challengerId,
    challengerName: challengerName || 'Challenger',
    opponentId: opponentKey,
    opponentName,
    seed,
    duelRegions: Array.isArray(duelRegions) ? JSON.stringify(duelRegions) : null,
    duelDifficulty: typeof duelDifficulty === 'string' ? duelDifficulty : null,
    duelGameMode: Number.isFinite(duelGameMode) ? duelGameMode : null,
    duelQuestionsCount: Number.isFinite(duelQuestionsCount) ? duelQuestionsCount : null,
    duelOptionsCount: Number.isFinite(duelOptionsCount) ? duelOptionsCount : null,
    duelQuestionsPayload: Array.isArray(duelQuestionsPayload) ? JSON.stringify(duelQuestionsPayload) : null,
  });
  const regionsSorted = Array.isArray(duelRegions) ? [...duelRegions].map(String).sort() : null;
  console.log('[duel/challenge]', {
    challengeId: id,
    challengerId,
    opponentId: opponentKey,
    seed,
    regions: regionsSorted,
    duelDifficulty: typeof duelDifficulty === 'string' ? duelDifficulty : null,
    duelGameMode: Number.isFinite(duelGameMode) ? duelGameMode : null,
    duelQuestionsCount: Number.isFinite(duelQuestionsCount) ? duelQuestionsCount : null,
    duelOptionsCount: Number.isFinite(duelOptionsCount) ? duelOptionsCount : null,
    ...duelPayloadLogSummary(duelQuestionsPayload),
  });
  if (opponent && opponent.device_token) {
    sendDuelChallengePush(opponent.device_token, challengerName || 'Friend', (err) => {
      if (err) console.error('[duel/challenge] push failed', { challengeId: id, opponentId: opponentKey, message: err.message });
    });
    console.log('[duel/challenge] push enqueued', { challengeId: id, opponentId: opponentKey });
  } else {
    console.log(
      'Duel challenge created:',
      id,
      '-> no push (',
      opponentKey,
      opponent ? 'missing device_token' : 'user not found',
      ')'
    );
  }
  res.status(201).json({ challengeId: id, seed, opponentName });
});

// GET /api/v1/duel/incoming
app.get('/api/v1/duel/incoming', (req, res) => {
  const userId = resolveUserId(req.headers['x-user-id'] || req.query.userId);
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
      duelRegions: parseJSONSafe(c.duelRegions, null),
      duelDifficulty: c.duelDifficulty || null,
      duelGameMode: c.duelGameMode ?? null,
      duelQuestionsCount: c.duelQuestionsCount ?? null,
      duelOptionsCount: c.duelOptionsCount ?? null,
      duelQuestionsPayload: parseJSONSafe(c.duelQuestionsPayload, null),
    })),
  });
});

// GET /api/v1/duel/incoming-sync — для синхронизации (включает pending/opponent_completed/completed)
app.get('/api/v1/duel/incoming-sync', (req, res) => {
  const userId = resolveUserId(req.headers['x-user-id'] || req.query.userId);
  if (!userId) return res.status(400).json({ error: 'userId required' });
  const list = db.getIncomingChallengesForSync(userId);
  res.json({
    challenges: list.map((c) => ({
      id: c.id,
      challengerId: c.challengerId,
      challengerName: c.challengerName,
      seed: c.seed,
      createdAt: c.createdAt,
      challengerScore: c.challengerScore,
      opponentScore: c.opponentScore,
      challengerTimeMs: c.challengerTimeMs ?? null,
      opponentTimeMs: c.opponentTimeMs ?? null,
      status: c.status,
      winner: duelWinnerFromRow(c),
      duelRegions: parseJSONSafe(c.duelRegions, null),
      duelDifficulty: c.duelDifficulty || null,
      duelGameMode: c.duelGameMode ?? null,
      duelQuestionsCount: c.duelQuestionsCount ?? null,
      duelOptionsCount: c.duelOptionsCount ?? null,
      duelQuestionsPayload: parseJSONSafe(c.duelQuestionsPayload, null),
    })),
  });
});

// GET /api/v1/duel/outgoing — мои вызовы как challenger (актуальные счёт и статус)
app.get('/api/v1/duel/outgoing', (req, res) => {
  const userId = resolveUserId(req.headers['x-user-id'] || req.query.userId);
  if (!userId) return res.status(400).json({ error: 'userId required' });
  const list = db.getOutgoingChallenges(userId);
  res.json({
    challenges: list.map((c) => ({
      id: c.id,
      challengerName: c.challengerName,
      opponentName: c.opponentName,
      seed: c.seed,
      createdAt: c.createdAt,
      challengerScore: c.challengerScore,
      opponentScore: c.opponentScore,
      challengerTimeMs: c.challengerTimeMs ?? null,
      opponentTimeMs: c.opponentTimeMs ?? null,
      status: c.status,
      winner: duelWinnerFromRow(c),
      duelRegions: parseJSONSafe(c.duelRegions, null),
      duelDifficulty: c.duelDifficulty || null,
      duelGameMode: c.duelGameMode ?? null,
      duelQuestionsCount: c.duelQuestionsCount ?? null,
      duelOptionsCount: c.duelOptionsCount ?? null,
      duelQuestionsPayload: parseJSONSafe(c.duelQuestionsPayload, null),
    })),
  });
});

// POST /api/v1/duel/accept
app.post('/api/v1/duel/accept', (req, res) => {
  const { challengeId } = req.body;
  const userId = (req.headers['x-user-id'] || req.body?.userId || '').trim();
  console.log('[duel/accept] request', { challengeId, userId: userId || '(empty)' });
  const c = db.getChallenge(challengeId);
  if (!c) return res.status(404).json({ error: 'Challenge not found' });
  const createdMs = c.created_at ? new Date(c.created_at).getTime() : 0;
  if (createdMs && Date.now() - createdMs > 24 * 60 * 60 * 1000) {
    return res.status(400).json({ error: 'Challenge expired' });
  }
  if (c.status === 'declined') return res.status(400).json({ error: 'Challenge declined' });
  if (c.status === 'completed') return res.status(400).json({ error: 'Challenge already completed' });
  if (c.status === 'opponent_completed') {
    return res.status(400).json({ error: 'Challenge already in progress' });
  }
  if (c.status === 'pending') {
    db.setChallengeStatus(challengeId, 'accepted');
  } else if (c.status === 'accepted') {
    // повторный accept — idempotent
  } else if (c.status === 'challenger_completed') {
    const os = c.opponent_score;
    if (os != null && Number(os) >= 0) {
      return res.status(400).json({ error: 'Opponent already submitted' });
    }
    // оппонент принимает после того, как challengер уже сдал счёт — статус не меняем
  } else {
    return res.status(400).json({ error: 'Challenge cannot be accepted' });
  }
  const fresh = db.getChallenge(challengeId);
  const statusAfter = fresh?.status ?? c.status;
  const acceptRegions = parseJSONSafe(c.duel_regions, null);
  console.log('[duel/accept] accepted', {
    challengeId,
    userId: userId || '(empty)',
    statusAfter,
    challengerId: c.challenger_id,
    opponentId: c.opponent_id,
    seed: c.seed,
    regions: acceptRegions,
    duelDifficulty: c.duel_difficulty || null,
    duelGameMode: c.duel_game_mode ?? null,
    duelQuestionsCount: c.duel_questions_count ?? null,
    duelOptionsCount: c.duel_options_count ?? null,
    ...duelPayloadLogSummary(c.duel_questions_payload),
  });
  res.json({
    seed: c.seed,
    challengerName: c.challenger_name,
    challengerScore: c.challenger_score,
    duelRegions: parseJSONSafe(c.duel_regions, null),
    duelDifficulty: c.duel_difficulty || null,
    duelGameMode: c.duel_game_mode ?? null,
    duelQuestionsCount: c.duel_questions_count ?? null,
    duelOptionsCount: c.duel_options_count ?? null,
    duelQuestionsPayload: parseJSONSafe(c.duel_questions_payload, null),
  });
});

// POST /api/v1/duel/decline
app.post('/api/v1/duel/decline', (req, res) => {
  const userId = resolveUserId(req.headers['x-user-id'] || '');
  const { challengeId } = req.body || {};
  if (!userId || !challengeId) return res.status(400).json({ error: 'userId and challengeId required' });

  const c = db.getChallenge(challengeId);
  if (!c) return res.status(404).json({ error: 'Challenge not found' });

  // Отклонить должен именно тот, кому бросили вызов (opponent).
  const oppStored = db.getCanonicalUsername(c.opponent_id) || db.normalizeUsernameId(c.opponent_id);
  if (oppStored !== userId) return res.status(403).json({ error: 'Not your challenge' });
  if (c.status !== 'pending' && c.status !== 'challenger_completed') {
    return res.status(400).json({ error: 'Challenge already accepted or completed' });
  }

  db.setChallengeStatus(challengeId, 'declined');
  res.json({ ok: true, status: 'declined' });
});

/** Один push при многократном нажатии «Напомнить» (мс). */
const duelRemindThrottleMs = 90 * 1000;
const duelRemindLastSent = new Map();

// POST /api/v1/duel/remind
app.post('/api/v1/duel/remind', (req, res) => {
  const userIdRaw = (req.headers['x-user-id'] || '').trim();
  const { challengeId } = req.body || {};
  if (!userIdRaw || !challengeId) return res.status(400).json({ error: 'userId and challengeId required' });

  const c = db.getChallenge(challengeId);
  if (!c) return res.status(404).json({ error: 'Challenge not found' });

  const me = resolveUserId(userIdRaw);
  const challenger = db.getCanonicalUsername(c.challenger_id) || db.normalizeUsernameId(c.challenger_id);
  const opponent = db.getCanonicalUsername(c.opponent_id) || db.normalizeUsernameId(c.opponent_id);
  if (!me || !challenger || !opponent) {
    console.warn('[duel/remind] canonical username failed', { userIdRaw, challenger_id: c.challenger_id, opponent_id: c.opponent_id });
    return res.status(400).json({ error: 'Invalid participant ids' });
  }
  if (me !== challenger && me !== opponent) return res.status(403).json({ error: 'Not your challenge' });

  // Если уже есть результат — не шлём.
  if (c.status !== 'pending' && c.status !== 'challenger_completed') {
    return res.status(409).json({ error: 'Result already available', status: c.status });
  }

  const throttleKey = `${challengeId}:${me}`;
  const now = Date.now();
  const last = duelRemindLastSent.get(throttleKey) || 0;
  if (now - last < duelRemindThrottleMs) {
    console.log('[duel/remind] throttled', { challengeId, me, waitMs: duelRemindThrottleMs - (now - last) });
    return res.json({ ok: true, status: c.status, pushSent: false, throttled: true, retryAfterMs: duelRemindThrottleMs - (now - last) });
  }

  // Получатель push — второй участник (кто должен отреагировать на вызов).
  const recipientUsername = me === challenger ? opponent : challenger;
  const recipient = db.getUserByUsername(recipientUsername);
  if (!recipient) {
    console.warn('[duel/remind] recipient row missing', { recipientUsername, challengeId });
    return res.status(404).json({ error: 'Recipient not found' });
  }

  if (!recipient.device_token) {
    console.warn('[duel/remind] no device_token for recipient', { recipientUsername, challengeId });
    duelRemindLastSent.set(throttleKey, now);
    return res.json({ ok: true, status: c.status, pushSent: false, reason: 'no_device_token' });
  }

  sendDuelChallengePush(recipient.device_token, c.challenger_name, (err) => {
    if (err) console.error('[duel/remind] push failed:', err.message || err);
    else console.log('[duel/remind] push ok', { challengeId, to: recipientUsername });
  });
  duelRemindLastSent.set(throttleKey, now);

  res.json({ ok: true, status: c.status, pushSent: true });
});

// POST /api/v1/duel/submit
app.post('/api/v1/duel/submit', (req, res) => {
  const { challengeId, score, side, elapsedMs } = req.body;
  const updated = db.updateChallengeScore(challengeId, side, score, elapsedMs);
  if (!updated) return res.status(404).json({ error: 'Challenge not found' });

  const submitRegions = parseJSONSafe(updated.duel_regions, null);
  const submitPayloadSummary = duelPayloadLogSummary(updated.duel_questions_payload);
  console.log('[duel/submit]', {
    challengeId,
    side,
    score,
    elapsedMs,
    status: updated.status,
    challengerId: updated.challenger_id,
    opponentId: updated.opponent_id,
    seed: updated.seed,
    regions: submitRegions,
    duelDifficulty: updated.duel_difficulty || null,
    duelGameMode: updated.duel_game_mode ?? null,
    duelQuestionsCount: updated.duel_questions_count ?? null,
    duelOptionsCount: updated.duel_options_count ?? null,
    challengerScore: updated.challenger_score,
    opponentScore: updated.opponent_score,
    challengerTimeMs: updated.challenger_time_ms,
    opponentTimeMs: updated.opponent_time_ms,
    ...submitPayloadSummary,
  });

  let winner = null;
  if (updated.status === 'completed') {
    winner = duelWinnerFromRow(updated);
    const cs = updated.challenger_score || 0;
    const os = updated.opponent_score || 0;
    const winnerId = winner === 'challenger' ? updated.challenger_id : updated.opponent_id;
    console.log('[duel/submit] finished', {
      challengeId,
      winnerUsername: winnerId,
      winnerSide: winner,
      scoresChallengerOpponent: `${cs} ${os}`,
      timesMsChallengerOpponent: `${updated.challenger_time_ms} ${updated.opponent_time_ms}`,
      payloadMode: submitPayloadSummary.payloadMode,
      seed: updated.seed,
    });
  }
  res.json({
    status: updated.status,
    winner,
    challengerScore: updated.challenger_score,
    opponentScore: updated.opponent_score,
    challengerTimeMs: updated.challenger_time_ms,
    opponentTimeMs: updated.opponent_time_ms,
  });
});

// POST /api/v1/duel/random-opponent
app.post('/api/v1/duel/random-opponent', (req, res) => {
  const { excludeFriendIds = [], myStats = {} } = req.body;
  const userId = resolveUserId(req.headers['x-user-id'] || req.body.userId);
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
  "You haven't completed your daily lesson on the path to learning Flags!",
];

let sendNudgePush;
let sendDuelChallengePush;
try {
  const push = require('./push.js');
  sendNudgePush = push.sendNudgePush;
  sendDuelChallengePush = push.sendDuelChallengePush;
} catch (e) {
  sendNudgePush = () => {};
  sendDuelChallengePush = () => {};
}

// POST /api/v1/nudge — отправить напоминание другу
app.post('/api/v1/nudge', (req, res) => {
  const fromUsername = resolveUserId(req.headers['x-user-id'] || '');
  const { toUsername, phraseId } = req.body || {};
  if (!fromUsername || !toUsername) return res.status(400).json({ error: 'X-User-Id and toUsername required' });
  const phrase = Math.max(0, Math.min(15, parseInt(phraseId, 10) || 0));
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
  if (toUser.email && process.env.MAILGUN_API_KEY && process.env.MAILGUN_DOMAIN) {
    const localeRaw = String(toUser.preferred_language || toUser.preferredLanguage || 'en').toLowerCase();
    const locale = SUPPORTED_LOCALES.includes(localeRaw.substring(0, 2)) ? localeRaw.substring(0, 2) : 'en';
    mailgun.sendNudgeReminderEmail(
      toUser.email,
      toUser.username || toUsername,
      fromUsername,
      bodyText,
      locale
    ).then(() => {
      console.log('[nudge] email sent to', toUser.email);
    }).catch((err) => {
      console.error('[nudge] reminder email failed:', err.message);
    });
  } else if (!toUser.email) {
    console.warn('[nudge] recipient has no email on file; Mailgun skipped');
  } else {
    console.warn('[nudge] MAILGUN_API_KEY / MAILGUN_DOMAIN not set; email skipped');
  }
  console.log('Nudge created:', id, fromUsername, '->', toUser.username);
  res.status(200).json({ ok: true, nudgeId: id });
});

// GET /api/v1/nudge/inbox — непрочитанные напоминания для текущего пользователя
app.get('/api/v1/nudge/inbox', (req, res) => {
  const userId = resolveUserId(req.headers['x-user-id'] || req.query.userId);
  if (!userId) return res.status(400).json({ error: 'userId required' });
  const nudges = db.getNudgesForUser(userId, true);
  res.json({ nudges });
});

// POST /api/v1/nudge/read — отметить все напоминания как прочитанные
app.post('/api/v1/nudge/read', (req, res) => {
  const userId = resolveUserId(req.headers['x-user-id'] || req.body?.userId);
  if (!userId) return res.status(400).json({ error: 'userId required' });
  db.markNudgesRead(userId);
  res.json({ ok: true });
});

// POST /api/v1/friends/:username/birthday-gift — подарок другу на день рождения
// type: 'xpBoost' | 'fBucks'
app.post('/api/v1/friends/:username/birthday-gift', (req, res) => {
  const fromUsername = resolveUserId(req.headers['x-user-id'] || '');
  const toUsername = (req.params.username || '').trim();
  const { type } = req.body || {};
  if (!fromUsername || !toUsername) return res.status(400).json({ error: 'X-User-Id and username required' });
  if (db.normalizeUsernameId(fromUsername) === db.normalizeUsernameId(toUsername)) {
    return res.status(400).json({ error: 'Cannot send gift to yourself' });
  }
  if (type !== 'xpBoost' && type !== 'fBucks') {
    return res.status(400).json({ error: 'Invalid gift type' });
  }
  if (!db.areFriends(fromUsername, toUsername)) {
    return res.status(400).json({ error: 'Can only send birthday gifts to friends' });
  }
  const now = new Date();
  const year = now.getUTCFullYear();
  if (db.hasSentBirthdayGiftThisYear(fromUsername, toUsername, year)) {
    return res.status(400).json({ error: 'Gift already sent this year' });
  }
  db.createBirthdayGift({ giverUsername: fromUsername, receiverUsername: toUsername, year, type });
  console.log('Birthday gift created:', fromUsername, '->', toUsername, 'type:', type, 'year:', year);
  res.json({ ok: true });
});

// GET /api/v1/birthday-gifts/inbox — входящие подарки ко дню рождения (для получателя)
app.get('/api/v1/birthday-gifts/inbox', (req, res) => {
  const userId = resolveUserId(req.headers['x-user-id'] || req.query.userId);
  if (!userId) return res.status(400).json({ error: 'userId required' });
  const gifts = db.getBirthdayGiftsForUser(userId);
  res.json({ gifts });
});

// POST /api/v1/birthday-gifts/consume — пометить все входящие подарки как обработанные
app.post('/api/v1/birthday-gifts/consume', (req, res) => {
  const userId = resolveUserId(req.headers['x-user-id'] || req.body?.userId);
  if (!userId) return res.status(400).json({ error: 'userId required' });
  db.clearBirthdayGiftsForUser(userId);
  res.json({ ok: true });
});

// Time Challenge leaderboard
app.post('/api/v1/time-challenge/submit', (req, res) => {
  const userId = resolveUserId(req.headers['x-user-id'] || req.body.userId);
  if (!userId) return res.status(400).json({ error: 'userId required' });
  const score = Number(req.body?.score ?? 0);
  const correctAnswers = Number(req.body?.correctAnswers ?? 0);
  const totalAnswers = Number(req.body?.totalAnswers ?? 0);
  const bestCombo = Number(req.body?.bestCombo ?? 0);
  const durationSec = Number(req.body?.durationSec ?? 0);
  db.addTimeChallengeScore({
    id: uuidv4(),
    username: userId,
    score: Number.isFinite(score) ? Math.max(0, Math.floor(score)) : 0,
    correctAnswers: Number.isFinite(correctAnswers) ? Math.max(0, Math.floor(correctAnswers)) : 0,
    totalAnswers: Number.isFinite(totalAnswers) ? Math.max(0, Math.floor(totalAnswers)) : 0,
    bestCombo: Number.isFinite(bestCombo) ? Math.max(0, Math.floor(bestCombo)) : 0,
    durationSec: Number.isFinite(durationSec) ? Math.max(0, Math.floor(durationSec)) : 0,
  });
  const dailyRank = db.getTimeChallengeRank('daily', userId, score);
  const weeklyRank = db.getTimeChallengeRank('weekly', userId, score);
  res.json({ ok: true, dailyRank, weeklyRank });
});

app.get('/api/v1/time-challenge/leaderboard', (req, res) => {
  const period = req.query.period === 'weekly' ? 'weekly' : 'daily';
  const limit = Number(req.query.limit ?? 20);
  const top = db.getTimeChallengeTop(period, limit);
  res.json({
    period,
    top: top.map((x, idx) => ({
      rank: idx + 1,
      username: x.username,
      score: x.score ?? 0,
      bestCombo: x.best_combo ?? 0,
    })),
  });
});

app.listen(PORT, '127.0.0.1', () => {
  console.log(`Duel API listening on 127.0.0.1:${PORT}`);
});
