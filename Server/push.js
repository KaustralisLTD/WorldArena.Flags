/**
 * Отправка APNs push для nudge.
 * Чтобы включить: задайте в env APNS_KEY_ID, APNS_TEAM_ID, APNS_BUNDLE_ID, APNS_KEY_P8_PATH
 * и установите пакет: npm install apn
 * Без конфигурации push не отправляется (inbox в приложении покажет напоминания при открытии).
 *
 * Sandbox (Xcode): APNS_USE_SANDBOX=1 или NODE_ENV!=production.
 * На сервере проверьте путь к .p8 и что PM2 подхватывает те же переменные, что в локальном .env.
 */
const fs = require('fs');

/** undefined = ещё не пытались инициализировать; null = попытка не удалась; иначе экземпляр Provider */
let apnProvider;
let apnModule = null;

/** Sandbox (Xcode debug) vs Production (TestFlight/App Store). Переопределение: APNS_USE_SANDBOX=1 или APNS_PRODUCTION=0|1 */
function apnsUseProductionGateway() {
  const s = (process.env.APNS_USE_SANDBOX || '').toLowerCase();
  if (s === '1' || s === 'true' || s === 'yes') return false;
  const p = (process.env.APNS_PRODUCTION || '').toLowerCase();
  if (p === '0' || p === 'false') return false;
  if (p === '1' || p === 'true') return true;
  return process.env.NODE_ENV !== 'development' && process.env.NODE_ENV !== 'test';
}

function getProvider() {
  if (apnProvider !== undefined) {
    return apnProvider;
  }
  const keyId = process.env.APNS_KEY_ID;
  const teamId = process.env.APNS_TEAM_ID;
  const bundleId = process.env.APNS_BUNDLE_ID;
  const keyPath = process.env.APNS_KEY_P8_PATH;
  if (!keyId || !teamId || !bundleId || !keyPath) {
    apnProvider = null;
    return null;
  }
  if (!fs.existsSync(keyPath)) {
    console.warn('[push] APNS_KEY_P8_PATH not found on disk:', keyPath);
    apnProvider = null;
    return null;
  }
  try {
    apnModule = require('apn');
    apnProvider = new apnModule.Provider({
      token: { key: keyPath, keyId, teamId },
      production: apnsUseProductionGateway(),
    });
  } catch (e) {
    console.warn('APNs provider init failed (npm install apn?):', e.message);
    apnProvider = null;
  }
  return apnProvider;
}

/**
 * @param {string} deviceToken - APNs device token
 * @param {string} fromUsername - кто отправил напоминание
 * @param {string} bodyText - текст фразы (для push)
 * @param {function(Error?)} callback
 */
function recordInbox(deviceToken, notification, alert) {
  try {
    const db=require('./db').db,inbox=require('./notification-inbox'),i18n=require('./notification-localization');
    inbox.initialize(db);
    const details=i18n.detailsFor(notification.payload?.type,notification.payload?.details||{},alert);
    notification.payload={...notification.payload,details};
    Object.assign(alert,i18n.render(notification.payload.type,details,i18n.recipientLocale(db,{token:deviceToken}),alert));
    notification.alert=alert;
    inbox.record(db,deviceToken,notification,alert);
  } catch (error) {
    // A secondary inbox failure must never turn a saved duel into HTTP 500.
    console.error('[push] inbox persistence failed', { code: error.code || error.name });
  }
}

function sendNudgePush(deviceToken, fromUsername, bodyText, callback, phraseID) {
  if (!deviceToken || typeof callback !== 'function') {
    if (callback) callback();
    return;
  }
  const provider = getProvider();
  if (!provider || !apnModule) {
    console.warn('[push] sendNudgePush: APNs not configured (set APNS_KEY_ID, APNS_TEAM_ID, APNS_BUNDLE_ID, APNS_KEY_P8_PATH; npm install apn)');
    callback(new Error('APNs provider is not configured'));
    return;
  }
  const notification = new apnModule.Notification();
  const alert = { title: `${fromUsername} reminds you`, body: bodyText };
  notification.alert = alert;
  notification.sound = 'default';
  notification.pushType = 'alert';
  notification.priority = 10;
  notification.topic = process.env.APNS_BUNDLE_ID || 'com.worldarena.flags';
  notification.payload = { type: 'nudge', fromUsername, details: {senderName:fromUsername,phraseID} };
  // Persist the actual message and use its unread count, never a fixed badge.
  recordInbox(deviceToken, notification, alert);
  provider.send(notification, deviceToken).then((result) => {
    if (result.failed.length) {
      const err = result.failed[0].response?.reason || result.failed[0].status;
      return callback(new Error(String(err)));
    }
    callback();
  }).catch((err) => callback(err));
}

/**
 * Push: входящий вызов на дуэль.
 */
function sendDuelChallengePush(deviceToken, challengerName, callback, challengeId) {
  if (!deviceToken || typeof callback !== 'function') {
    if (callback) callback();
    return;
  }
  const provider = getProvider();
  if (!provider || !apnModule) {
    console.warn('[push] sendDuelChallengePush: APNs provider not configured (check APNS_* env and npm install apn)');
    callback(new Error('APNs provider is not configured'));
    return;
  }
  const notification = new apnModule.Notification();
  const alert = {
    title: 'Duel',
    body: `${challengerName} challenged you to a duel`
  };
  notification.alert = alert;
  notification.sound = 'default';
  notification.pushType = 'alert';
  notification.priority = 10;
  notification.topic = process.env.APNS_BUNDLE_ID || 'com.worldarena.flags';
  notification.payload = { type: 'duel_challenge', challengerName, challengeId, details: {opponentName:challengerName} };
  if (challengeId) notification.collapseId = `invite-${challengeId}`;
  const tokenHint = deviceToken.length > 14 ? `${deviceToken.slice(0, 14)}…` : deviceToken;
  // Persist the actual message and use its unread count, never a fixed badge.
  recordInbox(deviceToken, notification, alert);
  provider.send(notification, deviceToken).then((result) => {
    if (result.failed.length) {
      const f = result.failed[0];
      const reason = f.response?.reason || f.status || f.error?.message || String(f.error || 'unknown');
      console.error('[push] duel_challenge failed', {
        reason,
        status: f.status,
        deviceTokenPrefix: tokenHint,
        apnsProduction: apnsUseProductionGateway(),
      });
      return callback(new Error(String(reason)));
    }
    console.log('[push] duel_challenge delivered to APNs', { deviceTokenPrefix: tokenHint });
    callback();
  }).catch((err) => {
    console.error('[push] duel_challenge exception', err.message || err);
    callback(err);
  });
}

function sendDuelResultPush(deviceToken, match, callback) {
  const provider = getProvider();
  if (!provider || !apnModule) return callback(new Error('APNs provider is not configured'));
  const notification = new apnModule.Notification();
  const alert = {
    title: match.iWon ? 'Duel victory!' : 'Duel result',
    body: `${match.iWon ? 'You won' : 'You lost'} against ${match.opponentName}. Your score: ${match.myScore}; opponent: ${match.opponentScore}.`
  };
  notification.alert = alert;
  notification.sound = 'default';
  notification.pushType = 'alert';
  notification.priority = 10;
  notification.topic = process.env.APNS_BUNDLE_ID || 'com.worldarena.flags';
  notification.collapseId = `result-${match.challengeId}`;
  notification.payload = { type: 'duel_result', challengeId: match.challengeId, details: {...match} };
  // Persist the actual message and use its unread count, never a fixed badge.
  recordInbox(deviceToken, notification, alert);
  provider.send(notification, deviceToken).then(result => {
    const failed = result.failed[0];
    callback(failed ? new Error(String(failed.response?.reason || failed.status || 'Push failed')) : null);
  }).catch(callback);
}

function sendFriendRequestPush(deviceToken, senderName, callback) {
  const provider = getProvider();
  if (!provider || !apnModule) return callback(new Error('APNs provider is not configured'));
  const notification = new apnModule.Notification();
  const alert = { title: 'World Arena', body: `${senderName} added you as a friend. Open the app to add them back or decline.` };
  notification.alert = alert;
  notification.sound = 'default';
  notification.pushType = 'alert';
  notification.priority = 10;
  notification.topic = process.env.APNS_BUNDLE_ID || 'com.worldarena.flags';
  notification.payload = { type: 'friend_request', details: {senderName} };
  // Persist the actual message and use its unread count, never a fixed badge.
  recordInbox(deviceToken, notification, alert);
  provider.send(notification, deviceToken).then(result => {
    const failed = result.failed[0];
    callback(failed ? new Error(String(failed.response?.reason || failed.status || 'Push failed')) : null);
  }).catch(callback);
}

function getApnsDiagnostics() {
  const keyId = process.env.APNS_KEY_ID;
  const teamId = process.env.APNS_TEAM_ID;
  const bundleId = process.env.APNS_BUNDLE_ID;
  const keyPath = process.env.APNS_KEY_P8_PATH;
  const provider = getProvider();
  return {
    env: {
      APNS_KEY_ID: !!keyId,
      APNS_TEAM_ID: !!teamId,
      APNS_BUNDLE_ID: !!bundleId,
      APNS_KEY_P8_PATH: !!keyPath,
    },
    hasProvider: !!provider,
    nodeEnv: process.env.NODE_ENV || null,
    apnsProduction: apnsUseProductionGateway(),
    topic: bundleId || 'com.worldarena.flags',
  };
}

module.exports = { sendDuelResultPush, sendFriendRequestPush, sendNudgePush, sendDuelChallengePush, getApnsDiagnostics };

function sendMessagePush(deviceToken,id,title,body,callback) {
 const provider=getProvider();
 if(!deviceToken||!provider||!apnModule)return callback(new Error('APNs unavailable'));
 const notification=new apnModule.Notification(),alert={title,body};
 notification.alert=alert;notification.sound='default';notification.pushType='alert';notification.priority=10;
 notification.topic=process.env.APNS_BUNDLE_ID||'com.worldarena.flags';
 notification.payload={type:'message',notificationId:id};notification.collapseId=id.slice(0,64);
 recordInbox(deviceToken,notification,alert);
 provider.send(notification,deviceToken).then(r=>callback(r.failed.length?new Error(String(r.failed[0].response?.reason||'Push failed')):null)).catch(callback);
}
module.exports.sendMessagePush=sendMessagePush;
