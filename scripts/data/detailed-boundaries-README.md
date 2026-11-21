# Detailed small-country land contours

`World Arena. Flags/Resources/country-boundaries-detailed.json` is a separate
OpenStreetMap-derived database, © OpenStreetMap contributors, licensed under
[ODbL 1.0](https://opendatacommons.org/licenses/odbl/1-0/). It is distributed as
editable JSON with the app/source repository. The app displays linked attribution
on affected maps. Natural Earth fallback data keeps its public-domain license.

Ten replacements: Jersey, Andorra, San Marino, Monaco, Gibraltar, Vatican City,
Liechtenstein, Malta, Guernsey and Isle of Man. Download provenance and SHA-256
hashes are in `detailed-boundaries-sources.json`. Snapshot date: 2026-11-21.
Geofabrik extracts and the OSM API provide current administrative borders and
coastlines; no runtime download is necessary.

## Rebuild

Install Python `osmium`, `shapely`, `pyproj` in a temporary environment. Download
the listed files into one directory, preserving manifest filenames. Check hashes
when reproducing this exact snapshot; upstream `latest`/API URLs can change.

1. `python scripts/extract_osm_country_land.py INPUT/*.osm.pbf INPUT/JEY.osm INPUT/GIB.osm INPUT/VAT.osm INPUT/SMR.osm`
2. `python scripts/merge_gibraltar_coast.py INPUT`
3. `python scripts/build_detailed_country_boundaries.py INPUT OUTPUT.json`
4. Compare output with the bundled detailed JSON; run
   `python scripts/audit_detailed_boundaries.py` and
   `python scripts/audit_country_boundaries.py OUTPUT_DIRECTORY` (also needs Pillow).

Landlocked states use their administrative polygons. Islands use polygonized
coastlines clipped to their administrative territory. Monaco and Gibraltar select
the land cell bounded by the coastline and international border, using an interior
landmark. This avoids filling territorial waters. Each contour is simplified by
only 5 metres in a local azimuthal metric projection, preserving topology. Islands
and holes remain separate. The main Natural Earth database is not regenerated.

These are educational map overlays, not surveyed legal boundaries. Apple may use
a different coastline date/generalization, particularly around reclamation and
tidal rocks. Validation includes actual Apple snapshot alignment for all ten,
not merely checking that polygons close. The preview runs MapKit on macOS; it is
not a screenshot of the iOS quiz screen.
