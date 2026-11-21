"""Rebuild bundled country polygons; inputs are unmodified Natural Earth GeoJSON.
Usage: python3 scripts/build_country_boundaries.py countries50.json units10.json ukr10.json
Never use ISO_A3_EH as a unique key: several Australian territories share AUS.
"""
import hashlib, json, sys
from pathlib import Path
root = Path(__file__).resolve().parents[1]
resources = root / 'World Arena. Flags/Resources'
files = [Path(x) for x in sys.argv[1:]]
assert len(files) == 3
features = [json.loads(p.read_text())['features'] for p in files]
codes = {c['cca3'] for c in json.loads((resources/'game_countries.json').read_text())}
alias = {'SDS':'SSD','SAH':'ESH','PSX':'PSE','ALD':'ALA','KOS':'XKX'}
def polygons(f):
    g=f['geometry']
    return g['coordinates'] if g['type']=='MultiPolygon' else [g['coordinates']]
data={}
for f in features[0]:
    code=alias.get(f['properties']['ADM0_A3'],f['properties']['ADM0_A3'])
    if code in codes: data.setdefault(code,[]).extend(polygons(f))
missing=codes-data.keys()
for f in features[1]:
    code=f['properties']['ISO_A3_EH']
    if code in missing: data.setdefault(code,[]).extend(polygons(f))
# Low-resolution data reduces tiny islands to triangles or drops whole atolls.
# Replace small/simple outlines using the 1:10m country layer (without changing large-country data).
for f in features[2]:
    code=alias.get(f['properties']['ADM0_A3'],f['properties']['ADM0_A3'])
    if code in data and sum(len(r) for p in data[code] for r in p) < 100:
        data[code]=polygons(f)
# Use the same source resolution for both sides so Crimea is neither omitted nor duplicated.
for f in features[2]:
    code=f['properties']['ADM0_A3']
    if code in ('UKR','RUS'): data[code]=polygons(f)
assert not codes-data.keys(), codes-data.keys()
(resources/'country-boundaries.json').write_text(json.dumps(data,separators=(',',':'))+'\n')
manifest={'license':'Natural Earth public domain','sources':[{'file':p.name,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in files], 'countryCount':len(data),'ukraine':'Includes Crimea; RUS uses the matching non-overlapping boundary from ne_10m_admin_0_countries_ukr.'}
(root/'scripts/data/country-boundaries-sources.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('Bundled',len(data),'countries and territories')
