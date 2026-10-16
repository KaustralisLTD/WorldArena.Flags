"""Use larger Wikimedia thumbnail renditions for Retina screens; preserve originals on failure."""
import concurrent.futures,json,pathlib,re,urllib.request
ROOT=pathlib.Path(__file__).resolve().parents[1];APP=ROOT/'World Arena. Capitals';p=APP/'Resources/capital-photos.json';photos=json.loads(p.read_text())
def upgrade(entry):
 code,photo=entry;url=photo['imageURL'];large=re.sub(r'/\d+px-', '/960px-',url)
 if large==url:return code,None
 try:
  r=urllib.request.Request(large,headers={'User-Agent':'WorldArenaCapitals/1.0 (https://capital.worldarena.games)'})
  with urllib.request.urlopen(r,timeout=12) as response:data=response.read()
  if not(data.startswith(b'\xff\xd8') or data.startswith(b'\x89PNG')):return code,None
  directory=APP/'Assets.xcassets'/(photo['imageName']+'.imageset');target=next(directory.glob('photo.*'));target.write_bytes(data)
  return code,large
 except Exception:return code,None
count=0
with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
 for code,url in pool.map(upgrade,list(photos.items())):
  if url:photos[code]['imageURL']=url;count+=1
p.write_text(json.dumps(photos,ensure_ascii=False,indent=2)+'\n')
print('Retina photographs upgraded:',count,flush=True)
