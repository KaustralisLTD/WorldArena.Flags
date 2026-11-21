'use strict';
// A profile sync is not a game. Store the actual last-game date separately.
function initialize(db) {
  db.exec(`CREATE TABLE IF NOT EXISTS friend_reminder_activity (
    username TEXT PRIMARY KEY REFERENCES users(username) ON DELETE CASCADE,
    last_played_at INTEGER, timezone TEXT NOT NULL DEFAULT 'UTC')`);
}
function validZone(zone) {
  try { new Intl.DateTimeFormat('en', {timeZone: zone}).format(); return typeof zone === 'string' ? zone : 'UTC'; }
  catch { return 'UTC'; }
}
function day(at, zone) {
  return new Intl.DateTimeFormat('en-CA', {timeZone: validZone(zone), year:'numeric', month:'2-digit', day:'2-digit'}).format(new Date(at));
}
function recordActivity(db, username, at, zone, now = Date.now()) {
  const date = Number.isSafeInteger(at) && at > 0 && at <= now ? at : null;
  db.prepare(`INSERT INTO friend_reminder_activity(username,last_played_at,timezone) VALUES(?,?,?)
    ON CONFLICT(username) DO UPDATE SET last_played_at=MAX(COALESCE(friend_reminder_activity.last_played_at,0),COALESCE(excluded.last_played_at,0)),timezone=excluded.timezone`).run(username,date,validZone(zone));
}
function status(db, sender, recipient, now = Date.now()) {
  const activity = db.prepare('SELECT * FROM friend_reminder_activity WHERE username=?').get(recipient);
  const owner = db.prepare('SELECT timezone FROM friend_reminder_activity WHERE username=?').get(sender);
  let lastPlayed = activity?.last_played_at || 0;
  // Older clients may already have uploaded a completed-game event.
  if (db.prepare("SELECT 1 FROM sqlite_master WHERE type='table' AND name='lifecycle_events'").get()) {
    lastPlayed = Math.max(lastPlayed, db.prepare('SELECT MAX(at) AS at FROM lifecycle_events WHERE username=? AND at<=?').get(recipient,now)?.at || 0);
  }
  const recent = db.prepare("SELECT created_at FROM nudges WHERE from_username=? AND to_username=? AND datetime(created_at)>=datetime(? / 1000,'unixepoch','-2 days')").all(sender,recipient,now);
  return {
    playedToday: lastPlayed > 0 && day(lastPlayed,activity?.timezone) === day(now,activity?.timezone),
    remindedToday: recent.some(row => day(Date.parse(row.created_at.replace(' ','T') + (/Z$|[+-]\d\d:\d\d$/.test(row.created_at) ? '' : 'Z')),owner?.timezone) === day(now,owner?.timezone))
  };
}
module.exports = {initialize, recordActivity, status, day};
