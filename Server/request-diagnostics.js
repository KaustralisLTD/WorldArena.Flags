'use strict';
const crypto=require('node:crypto');
function requestDiagnostics(logger=console) {
 return function(req,res,next) {
  if(typeof res.on!=='function'||typeof res.setHeader!=='function')return next();
  const id=crypto.randomUUID(),started=Date.now();
  res.setHeader('X-Request-ID',id);
  res.on('finish',()=>{
   const route=String(req.path||req.url||'').split('?')[0];
   if(res.statusCode>=500||(route.startsWith('/api/v1/duel/')&&res.statusCode>=400)) {
    logger.error('[http-failure]',JSON.stringify({requestId:id,method:req.method,path:route,status:res.statusCode,elapsedMs:Date.now()-started}));
   }
  });
  next();
 };
}
module.exports={requestDiagnostics};
