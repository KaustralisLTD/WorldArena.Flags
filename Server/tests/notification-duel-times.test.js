const {test}=require('node:test');
const assert=require('node:assert/strict');
const Database=require('better-sqlite3');
const inbox=require('../notification-inbox');
test('historical notifications recover each side’s time without exposing another player’s duel or changing read status',()=>{
 const db=new Database(':memory:');
 db.exec("CREATE TABLE users(username TEXT PRIMARY KEY); INSERT INTO users VALUES('alice'),('bob'),('eve')");
 db.exec('CREATE TABLE duel_challenges(id TEXT,challenger_id TEXT,opponent_id TEXT,challenger_time_ms INTEGER,opponent_time_ms INTEGER,status TEXT,opponent_score INTEGER,challenger_score INTEGER,challenger_name TEXT,opponent_name TEXT)');
 db.prepare('INSERT INTO duel_challenges VALUES(?,?,?,?,?,?,?,?,?,?)').run('match','alice','bob',41230,43780,'completed',13,15,'Alice','Bob');
 const routes={};const app={get:(p,f)=>routes[p]=f,post:()=>{}};
 inbox.install(app,db,req=>({username:req.username}));
 for(const username of ['alice','bob','eve'])inbox.recordForUser(db,username,{id:username,title:'Victory',body:'15:15',kind:'duel_result',target:'match',readAt:1234,details:{myScore:15,opponentScore:0}});
 function get(username){let result;routes['/api/v1/notifications']({username},{set(){return this},json(x){result=x}});return result}
 assert.equal(get('alice').items[0].details.myTimeMs,41230);
 assert.equal(get('alice').items[0].details.opponentScore,13);
 assert.equal(get('alice').items[0].details.opponentName,'Bob');
 assert.equal(get('alice').items[0].details.iWon,true);
 assert.equal(get('alice').items[0].details.opponentTimeMs,43780);
 assert.equal(get('bob').items[0].details.myTimeMs,43780);
 assert.equal(get('bob').items[0].details.opponentTimeMs,41230);
 assert.equal(get('eve').items[0].details.myTimeMs,undefined);
 assert.equal(get('alice').items[0].readAt,1234);
 assert.equal(get('alice').unread,0);
 db.close();
});
