#!/usr/bin/env node
'use strict';
// Local administration only: no public message-sending endpoint.
require('dotenv').config({quiet:true});
const fs=require('node:fs'),{db}=require('./db'),{recordForUser}=require('./notification-inbox');
const file=process.argv[2];if(!file)throw Error('Usage: node send-inbox-message.js message.json [--send]');
const m=JSON.parse(fs.readFileSync(file,'utf8'));
if(typeof m.id!=='string'||!/^[a-zA-Z0-9_-]{1,100}$/.test(m.id))throw Error('A stable campaign ID is required');
if(!Array.isArray(m.users)||!m.users.length||m.users.some(x=>typeof x!=='string'))throw Error('Explicit recipient usernames are required');
if(!m.copy?.en?.title||!m.copy?.en?.body)throw Error('English fallback copy is required');
const recipients=[];
for(const username of new Set(m.users)){
 const u=db.prepare('SELECT username,device_token FROM users WHERE username=?').get(username);if(!u)throw Error('Recipient not found');
 const prefs=db.prepare("SELECT name FROM sqlite_master WHERE name='lifecycle_prefs'").get();
 const locale=prefs?db.prepare('SELECT locale FROM lifecycle_prefs WHERE username=?').get(username)?.locale:'en';
 const copy=m.copy[locale]||m.copy.en;
 if(typeof copy.title!=='string'||typeof copy.body!=='string'||!copy.title.trim()||!copy.body.trim()||copy.title.length>150||copy.body.length>5000)throw Error('Invalid localized copy');
 const id='message:'+m.id+':'+username;require('./notification-inbox').initialize(db);
 recipients.push({user:u,copy,id,existing:!!db.prepare('SELECT id FROM notification_inbox WHERE id=?').get(id)});
}
(async()=>{
 const send=process.argv.includes('--send'),push=process.argv.includes('--push');
 if(send)db.transaction(()=>{for(const r of recipients)recordForUser(db,r.user.username,{id:r.id,title:r.copy.title,body:r.copy.body,kind:'message'})})();
 let pushed=0,failed=0;
 if(send&&push)for(const r of recipients){if(!r.user.device_token||r.existing)continue;const ok=await new Promise(resolve=>require('./push').sendMessagePush(r.user.device_token,r.id,r.copy.title,r.copy.body,e=>resolve(!e)));if(ok)pushed++;else failed++;}
 console.log(JSON.stringify({mode:send?'sent':'preview',recipients:recipients.length,campaign:m.id,pushed,pushFailed:failed}));db.close();
})().catch(e=>{console.error(e.message);db.close();process.exitCode=1});
