const publicPaths = new Set(['/health', '/campaigns', '/auth/register', '/auth/login', '/auth/social-login', '/auth/reset-password/request', '/auth/reset-password/confirm']);
function sessionBoundary(authenticate) {
  return (req,res,next) => {
    if (publicPaths.has(req.path)) return next();
    const publicLifecycle = /^\/lifecycle\/(?:assets\/[A-Za-z0-9-]+|(?:open|preferences)\/[a-f0-9]{64})$/.test(req.path);
    if (publicLifecycle && (req.method === 'GET' || (req.method === 'POST' && req.path.startsWith('/lifecycle/preferences/')))) return next();
    const session=authenticate(req);
    if (!session?.username) return res.status(401).json({error:'Sign in required'});
    // Existing handlers consume X-User-Id. Derive it only from the verified session.
    req.headers['x-user-id']=session.username;
    next();
  };
}
module.exports={sessionBoundary};
