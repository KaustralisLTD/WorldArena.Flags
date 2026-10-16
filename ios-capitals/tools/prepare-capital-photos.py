"""Build the attributed offline capital-photo catalogue from public city pages."""
import concurrent.futures, json, pathlib, re, urllib.parse, urllib.request
ROOT=pathlib.Path(__file__).resolve().parents[1]
APP=ROOT/'World Arena. Capitals'
headers={'User-Agent':'WorldArenaCapitals/1.0 (https://capital.worldarena.games)'}
overrides=dict(re.findall(r'"([A-Z]{3})": "([^"\n]+)"',(APP/'Services/CapitalPhotoService.swift').read_text()))
overrides.update(json.loads((ROOT/'Design/capital-photo-page-overrides.json').read_text()))
def fetch(url):
    with urllib.request.urlopen(urllib.request.Request(url,headers=headers),timeout=12) as r:return r.read()
def prepare(country):
    code=country['cca3']; capitals=country.get('capital') or []
    if not capitals:return code,None,'no capital'
    title=overrides.get(code,capitals[0].replace(' ','_'))
    try:
        page=json.loads(fetch('https://en.wikipedia.org/api/rest_v1/page/summary/'+urllib.parse.quote(title,safe='')))
        thumb=page.get('thumbnail',{}).get('source',''); original=page.get('originalimage',{}).get('source','')
        filename=urllib.parse.unquote(urllib.parse.urlparse(original).path.rsplit('/',1)[-1])
        if page.get('type')!='standard' or urllib.parse.urlparse(thumb).hostname not in ('upload.wikimedia.org','thumb.wikimedia.org') or not original:raise ValueError('no city thumbnail')
        if any(x in filename.lower() for x in ['flag_of','coat_of','locator','location_map','.svg','seal_of']):raise ValueError('not a photograph')
        data=fetch(thumb)
        if not (data.startswith(b'\xff\xd8') or data.startswith(b'\x89PNG')):raise ValueError('unsupported image format')
        name='capital_photo_'+code
        directory=APP/'Assets.xcassets'/(name+'.imageset'); directory.mkdir(exist_ok=True)
        ext='jpg' if data.startswith(b'\xff\xd8') else 'png'
        (directory/('photo.'+ext)).write_bytes(data)
        (directory/'Contents.json').write_text(json.dumps({'images':[{'filename':'photo.'+ext,'idiom':'universal'}],'info':{'author':'xcode','version':1}},indent=2))
        source='https://commons.wikimedia.org/wiki/File:'+urllib.parse.quote(filename,safe='')
        return code,{'imageName':name,'imageURL':thumb,'sourceURL':source,'capital':capitals[0],'articleURL':page.get('content_urls',{}).get('desktop',{}).get('page','')},None
    except Exception as e:return code,None,str(e)
if __name__=='__main__':
    countries=json.loads((APP/'Resources/game_countries.json').read_text())
    photos={}; failures={}
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        for code,photo,error in pool.map(prepare,countries):
            if photo:photos[code]=photo
            else:failures[code]=error
    (APP/'Resources/capital-photos.json').write_text(json.dumps(photos,ensure_ascii=False,indent=2)+'\n')
    (ROOT/'Design/capital-photo-coverage.json').write_text(json.dumps({'bundled':len(photos),'unavailable':failures},ensure_ascii=False,indent=2)+'\n')
    print('Bundled capital photos:',len(photos),'Unavailable:',len(failures),flush=True)
