"""Regression checks for small-country land overlays; excludes maritime admin polygons."""
import json
from pathlib import Path
from shapely.geometry import MultiPolygon, Polygon, Point
from pyproj import Geod
root=Path(__file__).resolve().parents[1]
data=json.loads((root/'World Arena. Flags/Resources/country-boundaries-detailed.json').read_text())
# Wide geodesic land-area bounds catch marine polygons, missing islands and scale errors.
limits={'AND':(460,475),'SMR':(60,63),'VAT':(.4,.6),'LIE':(158,163),
        'MCO':(2,2.3),'GIB':(6,7.2),'JEY':(115,125),'GGY':(75,85),
        'MLT':(310,325),'IMN':(565,580)}
inside={'AND':(1.5218,42.5078),'SMR':(12.4578,43.9367),'VAT':(12.4534,41.9029),
        'LIE':(9.5215,47.1394),'MCO':(7.424,43.738),'GIB':(-5.349,36.151),
        'JEY':(-2.106,49.187),'GGY':(-2.58,49.46),'MLT':(14.25,36.04),'IMN':(-4.55,54.2)}
sea={'JEY':(-2.3,49.2),'MCO':(7.45,43.73),'GIB':(-5.38,36.13),'MLT':(14.1,35.95)}
geod=Geod(ellps='WGS84')
assert data.keys()==limits.keys()
report={}
for code,polys in data.items():
    geom=MultiPolygon([Polygon(p[0],p[1:]) for p in polys])
    assert geom.is_valid and not geom.is_empty,code
    area=sum(abs(geod.geometry_area_perimeter(p)[0]) for p in geom.geoms)/1e6
    assert limits[code][0]<area<limits[code][1],(code,area)
    assert geom.covers(Point(inside[code])),(code,'missing land landmark')
    if code in sea:assert not geom.covers(Point(sea[code])),(code,'includes open sea')
    report[code]={'landAreaKm2':round(area,3),'vertices':sum(len(r) for p in polys for r in p)}
print(json.dumps(report,indent=2))
print('PASS: 10 detailed land contours; area, validity, landmarks and sea exclusions')
