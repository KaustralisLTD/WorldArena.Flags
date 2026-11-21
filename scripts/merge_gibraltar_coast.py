"""Merge six bounded OSM API map responses; retain complete coastline ways only."""
import json, sys
import xml.etree.ElementTree as ET
from pathlib import Path
folder=Path(sys.argv[1]);nodes={};ways={}
for index in range(6):
    root=ET.parse(folder/f'GIB-map-{index}.osm').getroot()
    for node in root.findall('node'):
        nodes[node.attrib['id']]=[float(node.attrib['lon']),float(node.attrib['lat'])]
    for way in root.findall('way'):
        if any(t.attrib['k']=='natural' and t.attrib['v']=='coastline' for t in way.findall('tag')):
            ways[way.attrib['id']]=[n.attrib['ref'] for n in way.findall('nd')]
coast=[{'type':'LineString','coordinates':[nodes[n] for n in refs]} for refs in ways.values()]
assert coast
(folder/'GIB-map.extracted.json').write_text(json.dumps({'coast':coast,'admin':[]}))
