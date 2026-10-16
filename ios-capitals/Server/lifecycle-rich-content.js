'use strict';
const crypto=require('node:crypto'),library=require('./lifecycle-facts.json').facts;
function countryName(code,locale){return new Intl.DisplayNames([locale],{type:'region'}).of(code)}
function flag(code){return String.fromCodePoint(...[...code].map(x=>127397+x.charCodeAt(0)))}
function stories(locale,journey,data){
 const preferred=new Set([...(data.focusCountries||[]),...(data.seenCountries||[])]);
 const seed=crypto.createHash('sha256').update(journey+':'+(data.storyPeriod||'preview')).digest().readUInt32BE(0);
 const rotated=[...library.slice(seed%library.length),...library.slice(0,seed%library.length)];
 const selected=[...rotated.filter(x=>preferred.has(x.country)),...rotated.filter(x=>!preferred.has(x.country))].slice(0,2);
 return selected.map(x=>({id:x.id,code:x.country,name:countryName(x.country,locale),flag:flag(x.country),text:x.text[locale],source:x.source,sourceName:x.sourceName}));
}
module.exports={stories,countryName,flag};
