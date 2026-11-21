"""Build 10 detailed ODbL land contours from extracted OpenStreetMap snapshots.
Usage: python build_detailed_country_boundaries.py INPUT_DIRECTORY OUTPUT_JSON
Requires shapely, pyproj. See scripts/data/detailed-boundaries-README.md.
"""
import json,sys
from pathlib import Path
from shapely.geometry import shape,MultiPolygon,mapping
from shapely.ops import unary_union,polygonize
from pyproj import Geod
p=Path(sys.argv[1]);geod=Geod(ellps='WGS84')
def area(g):return abs(geod.geometry_area_perimeter(g)[0])/1e6
def read(n):return json.loads((p/n).read_text())
def admin(n,code):return unary_union([shape(a['geometry']) for a in read(n)['admin'] if a['tags'].get('ISO3166-1:alpha3')==code])
files={'AND':('andorra.osm.extracted.json',None),'LIE':('liechtenstein.osm.extracted.json',None),'SMR':('SMR.extracted.json',None),'VAT':('VAT.extracted.json',None),'JEY':('JEY.extracted.json','channel-islands.osm.extracted.json'),'GGY':('channel-islands.osm.extracted.json','channel-islands.osm.extracted.json'),'MCO':('monaco.osm.extracted.json','monaco.osm.extracted.json'),'MLT':('malta.osm.extracted.json','malta.osm.extracted.json'),'IMN':('isle-of-man.osm.extracted.json','isle-of-man.osm.extracted.json'),'GIB':('GIB.extracted.json','GIB-map.extracted.json')}
result={}
for code,(af,cf) in files.items():
 assert (p/af).exists() and (cf is None or (p/cf).exists()), (code, 'Missing source input')
 a=admin(af,code);assert not a.is_empty,code
 if cf:
  coast=[shape(g) for g in read(cf)['coast']]
  if code in ['MCO','GIB']:
   cells=list(polygonize(unary_union([a.boundary]+coast)))
   from shapely.geometry import Point
   seed=Point({'MCO':(7.424,43.738),'GIB':(-5.347,36.135)}[code])
   # The country land cell includes its land border and modern coastline,
   # unlike its administrative polygon, which includes territorial waters.
   candidates=[c for c in cells if a.covers(c.representative_point()) and c.covers(seed)]
   assert candidates,code
   s=unary_union(candidates)
  else:
   cells=list(polygonize(unary_union(coast)))
   s=unary_union([c for c in cells if a.covers(c.representative_point())]).intersection(a)
 else:s=a
 assert s.is_valid and not s.is_empty,code
 # Keep 5 metre detail in a local metric projection, much finer than card pixels.
 from pyproj import CRS,Transformer
 from shapely.ops import transform
 c=s.representative_point();crs=CRS.from_proj4(f'+proj=aeqd +lat_0={c.y} +lon_0={c.x} +datum=WGS84 +units=m')
 forward=Transformer.from_crs(4326,crs,always_xy=True).transform;back=Transformer.from_crs(crs,4326,always_xy=True).transform
 s=transform(back,transform(forward,s).simplify(5,preserve_topology=True))
 g=mapping(s);polys=g['coordinates'] if g['type']=='MultiPolygon' else [g['coordinates']]
 result[code]=polys
 print(code,round(area(s),3),sum(len(r) for poly in polys for r in poly),'vertices',len(polys),'polygons')
Path(sys.argv[2]).write_text(json.dumps(result,separators=(',',':'))+'\n')
