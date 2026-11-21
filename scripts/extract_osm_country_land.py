"""Extract administrative polygons and coastlines. Requires osmium, shapely, pyproj.
Inputs: local .osm/.osm.pbf snapshots listed in detailed-boundaries-sources.json.
Outputs: .extracted.json files beside each input.
"""
import osmium,json,sys
from pathlib import Path
from shapely.geometry import shape,LineString,mapping
from shapely.ops import polygonize,unary_union
from pyproj import Geod
factory=osmium.geom.GeoJSONFactory();geod=Geod(ellps='WGS84')
class Reader(osmium.SimpleHandler):
 def __init__(self):super().__init__();self.coast=[];self.areas=[]
 def way(self,w):
  if w.tags.get('natural')=='coastline':
   self.coast.append(LineString([(n.lon,n.lat) for n in w.nodes]))
 def area(self,a):
  if a.tags.get('boundary')=='administrative' and a.tags.get('admin_level') in ('2','3','4'):
   s=shape(json.loads(factory.create_multipolygon(a)));self.areas.append((dict(a.tags),s))
for filename in sys.argv[1:]:
 p=Path(filename);r=Reader();r.apply_file(str(p),locations=True)
 print('\n',p.stem,'coast ways',len(r.coast))
 for tags,s in r.areas:
  print(tags.get('name'),tags.get('ISO3166-1:alpha3'),tags.get('admin_level'),round(abs(geod.geometry_area_perimeter(s)[0])/1e6,3),s.is_valid)
 (p.with_suffix('.extracted.json')).write_text(json.dumps({'coast':[mapping(g) for g in r.coast],'admin':[{'tags':t,'geometry':mapping(s)} for t,s in r.areas]}))
