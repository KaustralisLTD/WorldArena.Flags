const {chromium}=require('/Users/spilberg/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const path=require('node:path'),fs=require('node:fs');
const root=path.resolve(__dirname,'../../artifacts/flags-oct19/store-10');
const copy=require('./copy.json');
(async()=>{const browser=await chromium.launch({headless:true,executablePath:'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'});
try{
for(const lang of Object.keys(copy)){
 for(const [format,width,height] of [['iphone',1320,2868],['ipad',2064,2752]]){
  fs.mkdirSync(path.join(root,lang,format),{recursive:true});const page=await browser.newPage({viewport:{width,height},deviceScaleFactor:1});
  for(let n=1;n<=10;n++){
   if(process.env.ONLY_SLIDE && n!==Number(process.env.ONLY_SLIDE))continue;
   const id=String(n).padStart(2,'0');await page.goto('file://'+path.join(root,lang,id+'.html'));
   const missing=await page.evaluate(async({format,width})=>{
    document.body.className=format==='ipad'?'ipad':'';const canvas=document.querySelector('.canvas');canvas.style.transform='scale('+(width/1320)+')';canvas.style.transformOrigin='0 0';
    for(const image of document.querySelectorAll('img[data-phone]'))image.src=format==='ipad'?image.dataset.pad:image.dataset.phone;
    document.querySelectorAll('.device').forEach(d=>d.classList.toggle('phone',format==='iphone'));
    await document.fonts.ready;await Promise.all([...document.images].map(i=>i.decode().catch(()=>{})));
    for(const [selector,limit] of [['h1',format==='ipad'?430:360],['.copy p',format==='ipad'?200:145]]){
     const el=document.querySelector(selector);let font=parseFloat(getComputedStyle(el).fontSize);
     while(el.getBoundingClientRect().height/(width/1320)>limit&&font>24){font-=2;el.style.fontSize=font+'px'}
    }
    return [...document.images].filter(i=>!i.naturalWidth).map(i=>i.src);
   },{format,width});
   if(missing.length)throw Error('Missing source screenshot: '+missing.join(', '));
   await page.screenshot({path:path.join(root,lang,format,id+'.png')});
  }
  await page.close();console.log(lang,format,'10 slides rendered');
 }
}
}finally{await browser.close()}
})().catch(e=>{console.error(e);process.exit(1)});
