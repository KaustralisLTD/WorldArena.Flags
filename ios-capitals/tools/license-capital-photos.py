"""Resolve each photograph's authoritative file page and free licence."""
import concurrent.futures,html,json,pathlib,re,urllib.parse,urllib.request
ROOT=pathlib.Path(__file__).resolve().parents[1]; APP=ROOT/'World Arena. Capitals'
p=APP/'Resources/capital-photos.json'; photos=json.loads(p.read_text())
def file_name(url):
    parts=urllib.parse.urlparse(url).path.split('/')
    return urllib.parse.unquote(parts[-2] if '/thumb/' in url else parts[-1]).replace('_',' ')
def batch(entries):
    params={'action':'query','format':'json','prop':'imageinfo','iiprop':'extmetadata|url','titles':'|'.join('File:'+file_name(v['imageURL']) for k,v in entries)}
    req=urllib.request.Request('https://en.wikipedia.org/w/api.php?'+urllib.parse.urlencode(params),headers={'User-Agent':'WorldArenaCapitals/1.0 (https://capital.worldarena.games)'})
    with urllib.request.urlopen(req,timeout=25) as r:data=json.load(r)
    result={}
    for page in data.get('query',{}).get('pages',{}).values():
        infos=page.get('imageinfo',[])
        if not infos:continue
        info=infos[0]; meta=info.get('extmetadata',{})
        def val(key):return html.unescape(re.sub('<[^>]+>','',meta.get(key,{}).get('value',''))).strip()
        license=val('LicenseShortName'); allowed=license.lower().startswith(('cc by','cc-by','cc0','public domain','gfdl','pd')) and 'nc' not in license.lower() and 'nd' not in license.lower()
        if not allowed:continue
        result[page['title'].removeprefix('File:').replace('_',' ')]={'sourceURL':info.get('descriptionurl',''),'creator':val('Artist') or 'Unknown author','license':license}
    return result
entries=list(photos.items()); verified={}
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
    for found in pool.map(batch,[entries[i:i+30] for i in range(0,len(entries),30)]):verified.update(found)
removed=[]
for code,v in list(photos.items()):
    credit=verified.get(file_name(v['imageURL']))
    if credit:v.update(credit)
    else:removed.append(code); del photos[code]
credit_overrides=json.loads((ROOT/'Design/capital-photo-credit-overrides.json').read_text())
for code,creator in credit_overrides.items():
    if code in photos:photos[code]['creator']=creator
p.write_text(json.dumps(photos,ensure_ascii=False,indent=2)+'\n')
(ROOT/'Design/capital-photo-license-report.json').write_text(json.dumps({'verified':len(photos),'unverified':removed},indent=2)+'\n')
print('Verified free photos:',len(photos),'Unverified:',removed,flush=True)
