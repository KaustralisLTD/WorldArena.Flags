const { createPublicKey, verify } = require('node:crypto');
const cache = new Map();
async function providerKeys(provider) {
  const cached = cache.get(provider);
  if (cached && cached.until > Date.now()) return cached.keys;
  const url = provider === 'apple' ? 'https://appleid.apple.com/auth/keys' : 'https://www.googleapis.com/oauth2/v3/certs';
  const response = await fetch(url, {signal: AbortSignal.timeout(8000)});
  if (!response.ok) throw new Error('Identity provider unavailable');
  const {keys} = await response.json();
  if (!Array.isArray(keys)) throw new Error('Invalid identity keys');
  cache.set(provider, {keys, until: Date.now() + 3600000});
  return keys;
}
async function verifySocialIdentity(provider, token, options = {}) {
  if (!['apple', 'google'].includes(provider) || typeof token !== 'string' || token.length > 16000) throw new Error('Verified identity token required');
  const parts = token.split('.');
  if (parts.length !== 3) throw new Error('Invalid identity token');
  const header = JSON.parse(Buffer.from(parts[0], 'base64url'));
  const claims = JSON.parse(Buffer.from(parts[1], 'base64url'));
  if (header.alg !== 'RS256' || typeof header.kid !== 'string') throw new Error('Unsupported identity signature');
  const keys = await (options.keys || providerKeys)(provider);
  const jwk = keys.find(k => k.kid === header.kid && k.kty === 'RSA');
  if (!jwk || !verify('RSA-SHA256', Buffer.from(parts[0] + '.' + parts[1]), createPublicKey({key:jwk, format:'jwk'}), Buffer.from(parts[2], 'base64url'))) throw new Error('Invalid identity signature');
  const audience = options.audience || (provider === 'apple' ? 'games.worldarena.capitals' : process.env.GOOGLE_CLIENT_ID);
  const now = Math.floor(Date.now()/1000);
  const issuerOK = provider === 'apple' ? claims.iss === 'https://appleid.apple.com' : ['https://accounts.google.com','accounts.google.com'].includes(claims.iss);
  if (!audience || claims.aud !== audience || !issuerOK || !Number.isFinite(claims.exp) || claims.exp <= now || !Number.isFinite(claims.iat) || claims.iat > now + 60 || typeof claims.sub !== 'string' || !claims.sub) throw new Error('Invalid identity claims');
  const emailVerified = claims.email_verified === true || claims.email_verified === 'true';
  return {provider, providerUserId:claims.sub, email:emailVerified ? claims.email : undefined};
}
module.exports = {verifySocialIdentity};
