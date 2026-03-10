/**
 * Отправка писем через Mailgun API (сброс пароля).
 * Если MAILGUN_API_KEY не задан — отправка не выполняется (для разработки).
 */
const https = require('https');
const FormData = require('form-data');

const apiKey = process.env.MAILGUN_API_KEY;
const domain = (process.env.MAILGUN_DOMAIN || '').trim();
const eu = process.env.MAILGUN_EU === 'true' || process.env.MAILGUN_EU === '1';
const host = eu ? 'api.eu.mailgun.net' : 'api.mailgun.net';

if (!apiKey || !domain) {
  console.log('[mailgun] Disabled: set MAILGUN_API_KEY and MAILGUN_DOMAIN in .env to enable');
}

function sendResetEmail(toEmail, code, username) {
  if (!apiKey || !domain) {
    return Promise.resolve();
  }
  return new Promise((resolve, reject) => {
    const from = process.env.MAILGUN_FROM || `World Arena <noreply@${domain}>`;
    const subject = 'Сброс пароля — World Arena Flags';
    const text = [
      `Привет${username ? ', ' + username : ''}!`,
      '',
      'Код для сброса пароля: ' + code,
      '',
      'Код действителен 30 минут. Если вы не запрашивали сброс — просто проигнорируйте это письмо.',
      '',
      '— World Arena Flags'
    ].join('\n');

    const form = new FormData();
    form.append('from', from);
    form.append('to', toEmail);
    form.append('subject', subject);
    form.append('text', text);

    const opts = {
      host,
      path: '/v3/' + encodeURIComponent(domain) + '/messages',
      method: 'POST',
      headers: {
        ...form.getHeaders(),
        'Authorization': 'Basic ' + Buffer.from('api:' + apiKey).toString('base64')
      }
    };

    const req = https.request(opts, (res) => {
      const chunks = [];
      res.on('data', (c) => chunks.push(c));
      res.on('end', () => {
        const body = Buffer.concat(chunks).toString();
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve();
        } else {
          reject(new Error('Mailgun ' + res.statusCode + ': ' + body));
        }
      });
    });
    req.on('error', reject);
    form.pipe(req);
  });
}

module.exports = { sendResetEmail };
