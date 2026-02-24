/**
 * Отправка APNs push для nudge.
 * Чтобы включить: задайте в env APNS_KEY_ID, APNS_TEAM_ID, APNS_BUNDLE_ID, APNS_KEY_P8_PATH
 * и установите пакет: npm install apn
 * Без конфигурации push не отправляется (inbox в приложении покажет напоминания при открытии).
 */
let apnProvider = null;
let apnModule = null;

function getProvider() {
  if (apnProvider !== undefined) return apnProvider;
  const keyId = process.env.APNS_KEY_ID;
  const teamId = process.env.APNS_TEAM_ID;
  const bundleId = process.env.APNS_BUNDLE_ID;
  const keyPath = process.env.APNS_KEY_P8_PATH;
  if (!keyId || !teamId || !bundleId || !keyPath) {
    apnProvider = null;
    return null;
  }
  try {
    apnModule = require('apn');
    apnProvider = new apnModule.Provider({
      token: { key: keyPath, keyId, teamId },
      production: process.env.NODE_ENV === 'production',
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
function sendNudgePush(deviceToken, fromUsername, bodyText, callback) {
  if (!deviceToken || typeof callback !== 'function') {
    if (callback) callback();
    return;
  }
  const provider = getProvider();
  if (!provider || !apnModule) {
    callback();
    return;
  }
  const notification = new apnModule.Notification();
  notification.alert = { title: `${fromUsername} reminds you`, body: bodyText };
  notification.topic = process.env.APNS_BUNDLE_ID || 'com.worldarena.flags';
  notification.payload = { type: 'nudge', fromUsername };
  provider.send(notification, deviceToken).then((result) => {
    if (result.failed.length) {
      const err = result.failed[0].response?.reason || result.failed[0].status;
      return callback(new Error(String(err)));
    }
    callback();
  }).catch((err) => callback(err));
}

module.exports = { sendNudgePush };
