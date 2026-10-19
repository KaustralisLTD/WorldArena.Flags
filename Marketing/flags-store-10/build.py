from pathlib import Path
import json,html,shutil,re,sys
root=Path(__file__).resolve().parents[2];out=root/'artifacts/flags-oct19/store-10'
copy=json.loads((Path(__file__).parent/'copy.json').read_text())
scenes=['quiz','duel','map','country','regions','quests','achievements','league','statistics','avatars']
themes=['','duel','light','','light','','gold','gold','light','']
(out/'assets').mkdir(parents=True,exist_ok=True)
shutil.copy(Path(__file__).parent/'assets/arena.png',out/'assets/arena.png')
css=(Path(__file__).parent/'base.css').read_text()
css+='''\nh1{font-size:124px}.copy p{font-size:36px}.ipad .copy{right:auto;width:550px}.ipad .device{left:60px;width:680px}.ipad .scene{left:640px}.ipad .duel .scene{left:500px}.ipad .duel .device{left:0;width:430px}.ipad .duel .second{left:410px}.ipad .duel .copy{width:650px}.award{font-size:22px}.floating{max-width:1050px;font-size:30px}.ipad .floating{max-width:760px}.brand{letter-spacing:3px;font-size:24px}.ipad .pills{max-width:540px}.ipad .brand{font-size:23px}\n'''
css=css.replace('\\n','\n')
css+='\n.duel .arena{mask-image:radial-gradient(ellipse at center,#000 20%,transparent 70%)}\n.ipad .duel .arena{top:550px;left:-80px;width:1100px;opacity:.65}\n'
(out/'poster.css').write_text(css)
for lang,t in copy.items():
 assert len(t['slides'])==10
 dest=out/lang;dest.mkdir(exist_ok=True)
 logo=root/'World Arena. Flags/Assets.xcassets'/f'IconPreview-{lang}.imageset/icon.png'
 if lang=='en':logo=Path(__file__).parent/'assets/brand-en.png'
 assert logo.exists(),logo
 shutil.copy(logo,out/f'assets/brand-{lang}.png')
 for index,(one,two,body,tag) in enumerate(t['slides']):
  number=f'{index+1:02d}';theme=themes[index];scene=scenes[index]
  def device(name,second=False):
   return '<div class="device phone'+(' second' if second else '')+'"><img data-phone="../assets/iphone/'+lang+'/'+name+'.png" data-pad="../assets/ipad/'+lang+'/'+name+'.png" alt="'+html.escape(t['brand'])+'"></div>'
  picture='<div class="orb"></div>'
  if scene=='duel':picture+='<img class="arena" src="../assets/arena.png">'
  picture+=device(scene)
  if scene=='duel':picture+=device('quiz',True)+'<div class="versus">VS</div>'
  award='<div class="award"><strong>❧</strong><div>'+html.escape(t['award'][0])+'<br><b>'+html.escape(t['award'][1])+'</b></div><strong>❧</strong></div>' if index==0 else ''
  doc='<!doctype html><html lang="'+lang+'"><meta charset="utf-8"><title>'+html.escape(one+' '+two)+'</title><link rel="stylesheet" href="../poster.css"><body><main class="canvas '+theme+'"><div class="brand"><img src="../assets/brand-'+lang+'.png">WORLD ARENA / '+t['brand']+'</div><div class="sequence">'+number+' / 10</div><header class="copy"><h1>'+html.escape(one)+'<br><span>'+html.escape(two)+'</span></h1><p>'+html.escape(body)+'</p><div class="pills"><b>'+html.escape(tag)+'</b></div>'+award+'</header><div class="scene">'+picture+'</div><div class="floating">'+html.escape(tag)+'</div><footer><b>'+html.escape(t['footer'])+'</b><span>WORLD ARENA</span></footer></main></body></html>'
  (dest/(number+'.html')).write_text(doc)
shutil.copy(Path(__file__).parent/'copy.json',out/'copy.json')
print(out)
