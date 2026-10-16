const {test}=require('node:test'),assert=require('node:assert/strict'),{EventEmitter}=require('node:events');
const {requestDiagnostics}=require('../request-diagnostics');
test('failed duel requests get a correlation ID without logging tokens, identity or query',()=>{
 const messages=[];const middleware=requestDiagnostics({error:(...x)=>messages.push(x.join(' '))});
 const res=new EventEmitter();res.statusCode=502;res.setHeader=(k,v)=>{res[k]=v;};let calls=0;
 middleware({method:'GET',url:'/api/v1/duel/incoming-sync?userId=PRIVATE',headers:{authorization:'Bearer SECRET'}},res,()=>calls++);
 res.emit('finish');assert.equal(calls,1);assert.ok(res['X-Request-ID']);assert.equal(messages.length,1);assert.ok(!messages[0].includes('PRIVATE'));assert.ok(!messages[0].includes('SECRET'));assert.ok(messages[0].includes('502'));
});
