#!/usr/bin/env python3
"""Compile notification text from the same 30 iOS catalogs used by the app."""
import json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
PAIR=re.compile(r'^\s*"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;',re.M)
def catalog(path):
    return {json.loads('"'+k+'"'):json.loads('"'+v+'"') for k,v in PAIR.findall(path.read_text())}
def compile_catalogs():
    required=['Duel','Victory','Defeat','You','Duel challenge from %@','friends.requests.title','friends.requests.body','notification.nudge.title','Уровень','Лиги','Достижения','Well done! Keep practicing!','league.weekly_result.title.week_finished','Бронзовая лига','Серебряная лига','Золотая лига','Лига Мастеров','Лига Чемпионов Мира','Платина','Алмаз']+[f'nudge_phrase_{i}' for i in range(1,17)]
    result={}
    for path in sorted((ROOT/'World Arena. Flags/Resources').glob('*.lproj/Localizable.strings')):
        data=catalog(path);lang=path.parent.name[:-6]
        missing=[key for key in required if not data.get(key)]
        if missing:raise ValueError(f'{lang}: {missing}')
        result[lang]={key:data[key] for key in required}
    return result
if __name__=='__main__':
    out=ROOT/'Server/notification-locales.json';out.write_text(json.dumps(compile_catalogs(),ensure_ascii=False,indent=2)+'\n')
    print('Compiled notification catalogs for 30 languages')
