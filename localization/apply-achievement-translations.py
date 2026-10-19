from pathlib import Path
import json,re
root=Path(__file__).resolve().parents[1]
rows=[('streak_60','streak',60),('streak_100','streak',100),('streak_365','streak',365),('games_250','games',250),('games_500','games',500),('games_1000','games',1000),('xp_50000','xp',50000),('xp_100000','xp',100000),('level_25','level',25),('level_50','level',50),('level_100','level',100),('friends_10','friends',10)]
copy=json.loads((root/'localization/achievement-collection-2026.json').read_text())
for lang,t in copy.items():
 assert len(t['titles'])==12
 p=root/'World Arena. Flags/Resources'/f'{lang}.lproj/Localizable.strings';s=p.read_text()
 for idx,(name,kind,n) in enumerate(rows):
  for suffix,value in [('title',t['titles'][idx]),('body',t[kind]%n)]:
   key=f'achievement.{name}.{suffix}';line=json.dumps(key,ensure_ascii=False)+' = '+json.dumps(value,ensure_ascii=False)+';'
   pat=r'^"'+re.escape(key)+r'"\s*=.*?;\s*$'
   s=re.sub(pat,lambda m:line,s,flags=re.M) if re.search(pat,s,re.M) else s+'\n'+line+'\n'
 p.write_text(s)
# Contract: every achievement title and requirement has a real entry in every app language.
keys=re.findall(r'(?:titleKey|descriptionKey): "([^"]+)"',(root/'World Arena. Flags/Models/AchievementDefinitions.swift').read_text())
for lang in json.loads((root/'shared/languages.json').read_text()):
 s=(root/'World Arena. Flags/Resources'/f'{lang["code"]}.lproj/Localizable.strings').read_text()
 assert all(re.search(r'^"'+re.escape(k)+r'"\s*=',s,re.M) for k in keys),lang
print('All 32 achievements have titles and requirements in all 30 app languages.')
