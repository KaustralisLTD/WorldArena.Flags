#!/usr/bin/env python3
"""Fail notification localization gaps; inventory wider app gaps without hiding them."""
import argparse,json,re,sys
from pathlib import Path
from notification_catalog import ROOT,catalog,compile_catalogs
SOURCES=['Views/NotificationInboxView.swift','Views/DuelInboxResultContent.swift','Views/Settings/NotificationSettingsView.swift','Views/FriendRequestsView.swift','Services/NotificationService.swift','Services/NotificationTextLocalization.swift']
FORMAT=re.compile(r'%(?!%)(?:(\d+)\$)?[-+0 #]*(?:\d+)?(?:\.\d+)?(ll|l)?([@difugs])')
def formats(value):return sorted((length or '',kind) for _,length,kind in FORMAT.findall(re.sub(r'\d\s*%', '', value)))
def audit():
    catalogs={p.parent.name[:-6]:catalog(p) for p in sorted((ROOT/'World Arena. Flags/Resources').glob('*.lproj/Localizable.strings'))}
    base=catalogs['en'];keys=set()
    for source in SOURCES:
        keys.update(re.findall(r'(?:localizedString|tr|text)\("([^"\n]+)"\)',(ROOT/'World Arena. Flags'/source).read_text()))
    keys.update(k for k in base if k.startswith(('inbox.','friends.requests.','nudge_phrase_')))
    keys.update(['Victory','Defeat','Duel','You won the duel!','Well done! Keep practicing!','Duel motivation win','Duel motivation lose','notification.nudge.title'])
    definitions=(ROOT/'World Arena. Flags/Models/AchievementDefinitions.swift').read_text()
    keys.update(re.findall(r'(?:titleKey|descriptionKey): "([^"\n]+)"',definitions))
    keys.update(next(iter(compile_catalogs().values())).keys())
    rows=[];errors=[]
    for lang,data in catalogs.items():
        missing=sorted(k for k in keys if not data.get(k))
        malformed=sorted(k for k in keys&data.keys()&base.keys() if formats(data[k])!=formats(base[k]))
        if missing or malformed:errors.append({'locale':lang,'missing':missing,'format_mismatch':malformed})
        rows.append({'locale':lang,'notification_missing':missing,'format_mismatch':malformed,'app_missing':sorted(base.keys()-data.keys())})
    compiled=json.loads((ROOT/'Server/notification-locales.json').read_text())
    if compiled!=compile_catalogs():errors.append({'server_catalog':'out of date; run scripts/notification_catalog.py'})
    return {'locales':len(catalogs),'notification_keys':len(keys),'notification_errors':errors,'languages':rows}
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--report',type=Path);args=parser.parse_args();result=audit()
    if args.report:
        args.report.parent.mkdir(parents=True,exist_ok=True)
        lines=['# Notification localization audit','', 'Scope: all notification inbox screens, detail views, notification settings, friend requests, local reminders, achievement names/descriptions, league events and server push templates.','',f'Checked {result["notification_keys"]} keys in {result["locales"]} catalogs. Notification errors: {len(result["notification_errors"])}.','', '## Wider catalog inventory','', 'These are missing keys elsewhere in the app compared with the English catalog. They are not silently filled with English or claimed as fixed by the notification patch.','', '| Language | Notification gaps | Other missing base keys |','| --- | ---: | ---: |']
        for row in result['languages']:lines.append(f'| {row["locale"]} | {len(row["notification_missing"])} | {len(row["app_missing"])} |')
        for row in result['languages']:
            if row['app_missing']:lines+=['',f'### {row["locale"]}', '']+[f'- `{key}`' for key in row['app_missing']]
        args.report.write_text('\n'.join(lines)+'\n')
    print(json.dumps({k:v for k,v in result.items() if k!='languages'},ensure_ascii=False))
    sys.exit(bool(result['notification_errors']))
