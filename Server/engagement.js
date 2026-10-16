'use strict';
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const copies = require('./progress-mail-locales.json');
const esc = x => String(x ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
function locale(value) {
  const raw = String(value || 'en').replace(/_/g, '-').toLowerCase();
  if (/^zh-(hant|tw|hk|mo)/.test(raw)) return 'zh-Hant';
  if (raw.startsWith('pt')) return 'pt-BR';
  return Object.keys(copies).find(x => x.toLowerCase() === raw) || (copies[raw.split('-')[0]] ? raw.split('-')[0] : 'en');
}
function milestone(n) { return n < 10 ? 0 : n < 25 ? 10 : n < 50 ? 25 : Math.floor(n / 50) * 50; }
function accuracy(s) { return s.answers > 0 ? Math.round(100 * s.correct / s.answers) : null; }
function render(report) {
  const lang = locale(report.locale), t = copies[lang];
  const progress = accuracy(report), previous = accuracy(report.previous || {});
  const cards = [[t.games, report.games], [t.accuracy, progress === null ? '—' : (previous !== null && previous !== progress ? `${previous}% → ${progress}%` : `${progress}%`)], [t.wins, `${report.wins} / ${report.duels}`]];
  const html = `<!doctype html><html lang="${lang}" dir="${lang === 'ar' ? 'rtl' : 'ltr'}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${esc(t.title)}</title></head><body style="margin:0;background:#eef3f5;font-family:Arial,sans-serif;color:#fff"><table role="presentation" width="100%"><tr><td align="center" style="padding:32px 12px"><table role="presentation" width="100%" style="width:100%;max-width:560px;table-layout:fixed;background:#09172c;border-radius:24px"><tr><td style="padding:28px"><p style="color:#36ddca;letter-spacing:3px;font-weight:bold">FLAGS · WORLD ARENA</p><h1 style="font-size:32px;line-height:1.15;overflow-wrap:break-word">${esc(t.title)}</h1><p style="color:#c8d5dd">${esc(report.username)}, ${esc(t.milestone)}</p>${cards.map(([label,value]) => `<table role="presentation" width="100%" style="table-layout:fixed;margin:12px 0;background:#142c40;border-radius:12px"><tr><td width="48%" style="padding:16px;overflow-wrap:break-word;color:#c8d5dd">${esc(label)}</td><td align="right" style="padding:16px;font-size:24px;font-weight:bold;color:#fff4df">${esc(value)}</td></tr></table>`).join('')}<p style="color:#c8d5dd">${esc(t.saved)}</p><p style="padding:20px 0"><a href="${esc(report.profileURL)}" style="display:inline-block;background:#36ddca;color:#09172c;border-radius:14px;padding:16px 26px;text-decoration:none;font-weight:bold">${esc(t.cta)}</a></p><a href="${esc(report.unsubscribeURL)}" style="color:#a8bdc9;font-size:12px">${esc(t.preferences)}</a></td></tr></table></td></tr></table></body></html>`;
  return {subject: `${t.title} · World Arena Flags`, html, text: `${report.username}\n${t.milestone}\n${cards.map(x=>x.join(': ')).join('\n')}\n${t.saved}\n${report.profileURL}\n${t.preferences}: ${report.unsubscribeURL}`};
}
function install(app, store, authenticate, sendMail) {
  const db = store.db;
  db.exec(`CREATE TABLE IF NOT EXISTS progress_mail (username TEXT PRIMARY KEY REFERENCES users(username) ON DELETE CASCADE, enabled INTEGER NOT NULL DEFAULT 0, locale TEXT NOT NULL DEFAULT 'en', games INTEGER NOT NULL DEFAULT 0, answers INTEGER NOT NULL DEFAULT 0, correct INTEGER NOT NULL DEFAULT 0, baseline TEXT NOT NULL DEFAULT '{}', last_sent INTEGER NOT NULL DEFAULT 0, retry_after INTEGER NOT NULL DEFAULT 0, unsubscribe_token TEXT UNIQUE NOT NULL)`);
  app.get('/api/v1/campaigns', (_req,res) => {
    try {
      const data=JSON.parse(fs.readFileSync(path.join(__dirname,'campaigns.json'),'utf8'));
      const now=Date.now();
      res.set('Cache-Control','no-store').json(data.filter(c=>c.enabled === true && (!c.startsAt || Date.parse(c.startsAt)<=now) && (!c.endsAt || Date.parse(c.endsAt)>now)).slice(0,10));
    } catch { res.json([]); }
  });
  app.post('/api/v1/progress-mail', (req,res) => {
    const session=authenticate(req); if(!session)return res.status(401).json({error:'Sign in required'});
    const b=req.body;
    if(typeof b.enabled!=='boolean')return res.status(400).json({error:'enabled must be boolean'});
    for(const k of ['games','answers','correct'])if(!Number.isSafeInteger(b[k])||b[k]<0||b[k]>1e9)return res.status(400).json({error:'Invalid progress'});
    if(b.correct>b.answers)return res.status(400).json({error:'Invalid accuracy'});
    const existing=db.prepare('SELECT * FROM progress_mail WHERE username=?').get(session.username);
    const currentDuels=db.prepare("SELECT COUNT(*) AS n FROM duel_challenges WHERE status='completed' AND (challenger_id=? OR opponent_id=?)").get(session.username,session.username).n;
    // Only a transition from off to on creates a new baseline; background sync never re-subscribes an unsubscribed user.
    const enabled=b.enabled && (!existing || existing.enabled !== -1 || b.explicitConsent === true);
    db.prepare(`INSERT INTO progress_mail(username,enabled,locale,games,answers,correct,baseline,unsubscribe_token) VALUES(?,?,?,?,?,?,?,?) ON CONFLICT(username) DO UPDATE SET enabled=CASE WHEN progress_mail.enabled=-1 AND ?=0 THEN -1 ELSE excluded.enabled END,baseline=CASE WHEN progress_mail.enabled<>1 AND excluded.enabled=1 AND ?=1 THEN excluded.baseline ELSE progress_mail.baseline END,locale=excluded.locale,games=excluded.games,answers=excluded.answers,correct=excluded.correct`).run(session.username,enabled?1:0,locale(b.locale),b.games,b.answers,b.correct,JSON.stringify({games:b.games,answers:b.answers,correct:b.correct,duels:currentDuels}),crypto.randomBytes(32).toString('hex'),b.explicitConsent===true?1:0,b.explicitConsent===true?1:0);
    res.json({ok:true,enabled:db.prepare('SELECT enabled FROM progress_mail WHERE username=?').get(session.username).enabled===1});
  });
  app.get('/api/v1/progress-mail/preferences/:token', (req,res) => {
    const row=db.prepare('SELECT locale FROM progress_mail WHERE unsubscribe_token=?').get(req.params.token);
    if(!row)return res.sendStatus(404);
    const t=copies[locale(row.locale)];
    // GET is intentionally read-only: mail scanners must not unsubscribe the recipient.
    res.type('html').send(`<html lang="${locale(row.locale)}"><meta name="viewport" content="width=device-width"><body style="font:18px system-ui;padding:40px"><h1>${esc(t.preferences)}</h1><form method="post"><button name="unsubscribe" value="1" style="font:inherit;padding:16px">${esc(t.preferences)}: OFF</button></form></body></html>`);
  });
  app.post('/api/v1/progress-mail/preferences/:token', (req,res) => {
    const result=db.prepare('UPDATE progress_mail SET enabled=-1 WHERE unsubscribe_token=?').run(req.params.token);
    res.status(result.changes?200:404).type('html').send('<meta name="viewport" content="width=device-width"><p>World Arena Flags · Email: OFF</p>');
  });
  let busy=false;
  async function tick() {
    if(busy || process.env.PROGRESS_EMAILS_ENABLED!=='true' || !process.env.MAILGUN_API_KEY || !process.env.MAILGUN_DOMAIN)return;
    busy=true;
    try {
      const now=Date.now();
      const rows=db.prepare(`SELECT p.*,u.email,u.display_name,u.friend_code FROM progress_mail p JOIN users u ON u.username=p.username WHERE p.enabled=1 AND u.is_registered=1 AND u.email IS NOT NULL AND p.last_sent<? AND p.retry_after<?`).all(now-7*86400000,now);
      const hasLifecycle = !!db.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name='lifecycle_prefs'").get();
      for(const row of rows) {
        if(hasLifecycle && db.prepare('SELECT 1 FROM lifecycle_prefs WHERE username=?').get(row.username))continue;
        const previous=JSON.parse(row.baseline);
        const duels=db.prepare(`SELECT * FROM duel_challenges WHERE status='completed' AND (challenger_id=? OR opponent_id=?)`).all(row.username,row.username);
        if(milestone(row.games)<=milestone(previous.games||0) && milestone(duels.length)<=milestone(previous.duels||0))continue;
        const wins=duels.filter(d=>{const own=d.challenger_id===row.username;const a=own?d.challenger_score:d.opponent_score,b=own?d.opponent_score:d.challenger_score;return a>b || (a===b && Number.isFinite(own?d.challenger_time_ms:d.opponent_time_ms) && Number.isFinite(own?d.opponent_time_ms:d.challenger_time_ms) && (own?d.challenger_time_ms:d.opponent_time_ms)<(own?d.opponent_time_ms:d.challenger_time_ms));}).length;
        // Reserve a retry window before the network request; a restart cannot immediately duplicate a delivery.
        const claimed=db.prepare('UPDATE progress_mail SET retry_after=? WHERE username=? AND retry_after<?').run(now+86400000,row.username,now);
        if(!claimed.changes)continue;
        const report=render({...row,previous,wins,duels:duels.length,username:row.display_name||row.username,profileURL:`https://flags.worldarena.games/profile/${encodeURIComponent(row.friend_code)}`,unsubscribeURL:`https://flags.worldarena.games/api/v1/progress-mail/preferences/${row.unsubscribe_token}`});
        try {
          await sendMail(row.email,report.subject,report.text,report.html);
          db.prepare('UPDATE progress_mail SET last_sent=?,baseline=? WHERE username=?').run(Date.now(),JSON.stringify({games:row.games,answers:row.answers,correct:row.correct,duels:duels.length}),row.username);
        } catch(e) { console.error('[progress-mail]',e.message); }
      }
    } finally {busy=false;}
  }
  const timer=setInterval(()=>tick().catch(e=>console.error('[progress-mail]',e.message)),3600000);timer.unref();
  return {tick};
}
module.exports={install,locale,milestone,accuracy,render};
