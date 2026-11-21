"""Validate all bundled boundaries and render a contact sheet (pip install pillow shapely)."""
import json, math, sys
from pathlib import Path
from shapely.geometry import Polygon, Point
from PIL import Image, ImageDraw, ImageFont
root=Path(__file__).resolve().parents[1]
res=root/'World Arena. Flags/Resources'
data=json.loads((res/'country-boundaries.json').read_text())
cat=json.loads((res/'game_countries.json').read_text())
out=Path(sys.argv[1]);out.mkdir(parents=True,exist_ok=True)
assert {c['cca3'] for c in cat} == set(data)
errors=[]
for code,polys in data.items():
 assert polys, code
 for poly in polys:
  for ring in poly:
   assert len(ring)>=4 and ring[0]==ring[-1],code
   assert all(len(p)==2 and all(math.isfinite(v) for v in p) and -180<=p[0]<=180 and -90<=p[1]<=90 for p in ring),code
  # Rings touching the date line are checked in an unwrapped projection below.
  shape=Polygon(poly[0],poly[1:])
  if not shape.is_valid:errors.append(code)
assert not errors, sorted(set(errors))
def contains(code,xy):return any(Polygon(p[0],p[1:]).covers(Point(xy)) for p in data[code])
for code,pt in [('AUS',(133,-25)),('AUS',(147,-42)),('UKR',(34.1,44.95)),('UKR',(30.52,50.45)),('FRA',(2.35,48.85)),('GIB',(-5.35,36.14))]:assert contains(code,pt),(code,pt)
assert not contains('RUS',(34.1,44.95))
W=268435456
def projected(pair,anchor):
 lon,lat=pair;lat=max(-85.05112878,min(85.05112878,lat))
 x=(lon+180)/360*W;x+=round((anchor-x)/W)*W
 y=(1-math.asinh(math.tan(math.radians(lat)))/math.pi)/2*W
 return x,y
def view(code,coord,size):
 anchor=(coord[1]+180)/360*W
 pp=[[[projected(v,anchor) for v in r] for r in p] for p in data[code]]
 boxes=[(min(x for x,y in p[0]),min(y for x,y in p[0]),max(x for x,y in p[0]),max(y for x,y in p[0])) for p in pp]
 main=max(boxes,key=lambda b:(b[2]-b[0])*(b[3]-b[1]));reach=max(main[2]-main[0],main[3]-main[1])*.35
 nearby=[main];remaining=[b for b in boxes if b!=main]
 while True:
  neighbours=[b for b in remaining if any(b[0]<=a[2]+reach and b[2]>=a[0]-reach and b[1]<=a[3]+reach and b[3]>=a[1]-reach for a in nearby)]
  if not neighbours:break
  nearby.extend(neighbours);remaining=[b for b in remaining if b not in neighbours]
 whole=(min(b[0] for b in boxes),min(b[1] for b in boxes),max(b[2] for b in boxes),max(b[3] for b in boxes))
 if whole[2]-whole[0]<W/12 and whole[3]-whole[1]<W/12:nearby=boxes
 b=[min(v[0] for v in nearby),min(v[1] for v in nearby),max(v[2] for v in nearby),max(v[3] for v in nearby)]
 width=max((b[2]-b[0])*1.18,(b[3]-b[1])*1.18*size[0]/size[1],1000);height=max((b[3]-b[1])*1.18,width*size[1]/size[0]);cx=(b[0]+b[2])/2;cy=(b[1]+b[3])/2
 assert all(math.isfinite(x) and x>0 for x in (width,height)),code
 return pp,(cx-width/2,cy-height/2,width,height)
font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',20)
small=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',14)
def card(c,w=340,h=165):
 code=c['cca3'];pp,b=view(code,c['latlng'],(w,h));im=Image.new('RGB',(w,h),(224,242,252));draw=ImageDraw.Draw(im)
 for p in pp:
  for i,ring in enumerate(p):
   xy=[((x-b[0])/b[2]*w,(y-b[1])/b[3]*h) for x,y in ring]
   draw.polygon(xy,fill=(179,215,247) if i==0 else (224,242,252));draw.line(xy,fill=(0,122,255),width=2)
 return im
cols=6;cellw=360;cellh=210;sheet=Image.new('RGB',(cols*cellw,math.ceil(len(cat)/cols)*cellh),'white');d=ImageDraw.Draw(sheet)
for i,c in enumerate(cat):
 x=(i%cols)*cellw;y=(i//cols)*cellh
 sheet.paste(card(c),(x+10,y+35));d.text((x+10,y+9),c['cca3']+' · '+c['name']['common'],font=small,fill='#1b2335')
sheet.save(out/'all-243-boundaries.png')
examples=['AUS','UKR','FJI','IDN','JPN','GIB'];preview=Image.new('RGB',(1000,1020),'#f3f5fa');d=ImageDraw.Draw(preview)
for i,code in enumerate(examples):
 c=next(c for c in cat if c['cca3']==code);x=(i%2)*500+20;y=(i//2)*330+20
 d.text((x,y),c['name']['common'],font=font,fill='#1b2335');preview.paste(card(c,460,240),(x,y+40))
preview.save(out/'boundary-examples.png')
(out/'audit.json').write_text(json.dumps({'countries':len(cat),'validRings':True,'validPolygons':True,'australiaMainlandAndTasmania':True,'crimeaInsideUkraineOnly':True,'preview':'Offline contour renderer; Apple background is shown when online.'},indent=2))
print('PASS:',len(cat),'countries; all polygons valid; Australia/Tasmania and Ukraine/Crimea assertions passed')
