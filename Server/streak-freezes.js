const Database = require('better-sqlite3');
const path = require('path');

function installStreakFreezes(app, users, authenticate, databasePath) {
  const sql = new Database(databasePath || process.env.DUEL_DB_PATH || path.join(__dirname, 'data', 'duel.db'));
  sql.pragma('busy_timeout = 5000');
  sql.exec(`CREATE TABLE IF NOT EXISTS freeze_inventory (username TEXT PRIMARY KEY, count INTEGER NOT NULL, updated_at INTEGER NOT NULL);
    CREATE TABLE IF NOT EXISTS freeze_gifts (id TEXT PRIMARY KEY, sender TEXT NOT NULL, recipient TEXT NOT NULL, status TEXT NOT NULL, consumed INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL);`);
  const pending = sql.prepare("SELECT id, sender FROM freeze_gifts WHERE recipient=? AND status='accepted' AND consumed=0");
  const sync = sql.transaction((username, count, received) => {
    for (const id of received) sql.prepare('UPDATE freeze_gifts SET consumed=1 WHERE id=? AND recipient=?').run(id, username);
    sql.prepare('INSERT INTO freeze_inventory VALUES(?,?,?) ON CONFLICT(username) DO UPDATE SET count=excluded.count,updated_at=excluded.updated_at').run(username, count, Date.now());
    return pending.all(username);
  });
  const gift = sql.transaction((id, sender, recipient) => {
    const old = sql.prepare('SELECT * FROM freeze_gifts WHERE id=?').get(id);
    if (old) {
      if (old.sender !== sender || old.recipient !== recipient) return { status: 'conflict' };
      return { status: old.status };
    }
    const senderStock = sql.prepare('SELECT * FROM freeze_inventory WHERE username=?').get(sender);
    const stock = sql.prepare('SELECT * FROM freeze_inventory WHERE username=?').get(recipient);
    const eligible = senderStock && senderStock.count > 0 && sender !== recipient && users.areFriends(sender, recipient) && stock && stock.count === 0 && Date.now() - stock.updated_at < 86400000 && pending.all(recipient).length === 0;
    const status = eligible ? 'accepted' : 'unavailable';
    if (eligible) sql.prepare('UPDATE freeze_inventory SET count=count-1 WHERE username=?').run(sender);
    sql.prepare('INSERT INTO freeze_gifts(id,sender,recipient,status,created_at) VALUES(?,?,?,?,?)').run(id, sender, recipient, status, Date.now());
    return { status };
  });
  app.post('/api/v1/streak-freezes/sync', (req, res) => {
    const auth = authenticate(req);
    if (!auth) return res.status(401).json({ error: 'Unauthorized' });
    const { count, received = [] } = req.body || {};
    if (!Number.isInteger(count) || count < 0 || count > 3 || !Array.isArray(received) || received.length > 500 || received.some(x => typeof x !== 'string')) return res.status(400).json({ error: 'Invalid inventory' });
    const gifts = sync(auth.username, count, received);
    const friends = users.getFriends(auth.username).filter(f => {
      const stock = sql.prepare('SELECT * FROM freeze_inventory WHERE username=?').get(f.username);
      return stock && stock.count === 0 && Date.now() - stock.updated_at < 86400000 && pending.all(f.username).length === 0;
    }).map(f => ({ username: f.username, displayName: f.display_name || f.username }));
    res.json({ gifts, friends });
  });
  app.post('/api/v1/streak-freezes/gift', (req, res) => {
    const auth = authenticate(req);
    if (!auth) return res.status(401).json({ error: 'Unauthorized' });
    const { id, recipient } = req.body || {};
    if (typeof id !== 'string' || !/^[a-zA-Z0-9-]{16,64}$/.test(id) || typeof recipient !== 'string' || recipient.length > 100) return res.status(400).json({ error: 'Invalid gift' });
    res.json(gift(id, auth.username, recipient));
  });
  return sql;
}
module.exports = { installStreakFreezes };
