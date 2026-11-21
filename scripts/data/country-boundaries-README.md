# Bundled country boundaries

243 catalog countries/territories. Natural Earth public-domain data downloaded 2026-11-21:

- https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_50m_admin_0_countries.geojson
- https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_10m_admin_0_map_units.geojson
- https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_10m_admin_0_countries_ukr.geojson

Source hashes: `country-boundaries-sources.json`. Rebuild using `scripts/build_country_boundaries.py` with these three downloaded files as arguments. Validate with `scripts/audit_country_boundaries.py OUTPUT_DIRECTORY` (Pillow and Shapely).

Country records are keyed by ADM0_A3 with explicit application aliases, not ISO_A3_EH: the latter gave several Australian territories the same AUS key, overwriting the mainland. Map-unit data fills eleven missing territories. Countries with fewer than 100 vertices in the coarse source are upgraded to 1:10m geometry. UKR and RUS use the matching Ukraine-view geometries so Crimea belongs to the Ukraine overlay and is not drawn twice.

The 1:50m/1:10m shapes are generalized educational outlines, not cadastral or navigation data. Viewports show all islands in compact archipelagos and the connected main cluster for countries with remote dependencies. Apple provides its own background map and labels. The app draws its corrected boundary overlay independently. Offline, the app immediately renders its bundled outline, without network or stored Apple tile images; a bounded memory cache reuses Apple snapshots during a session.

License: https://www.naturalearthdata.com/about/terms-of-use/

Detailed small-country overlays are loaded from a separate ODbL resource; see `detailed-boundaries-README.md`. These take precedence over Natural Earth for the ten audited small countries/territories.
