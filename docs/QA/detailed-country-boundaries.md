# Small-country boundary alignment — 2026-11-21

Based on the complete TestFlight 8.0.4 (110) source, without removing prior fixes.
These changes have not yet been uploaded to TestFlight. Server changes are unnecessary.

The previous audit proved valid geometry, not agreement with a street-scale map.
Natural Earth outlines were too generalized for microstates: Monaco had 12 vertices,
San Marino 19, Andorra 51. Detailed OpenStreetMap-derived land contours now override
only AND, GGY, GIB, IMN, JEY, LIE, MCO, MLT, SMR, VAT. The fallback database for all
243 entries is byte-for-byte unchanged. Data is bundled; visible linked attribution
and an ODbL notice accompany the editable detailed JSON (approximately 746 KiB).

Verification:
- Detailed regeneration produces byte-identical JSON.
- All 243 combined country records passed coordinate/ring/polygon/viewport checks;
  Australia/Tasmania and Ukraine/Crimea regression checks still pass.
- Ten detailed records passed geodesic land-area bounds, landmark containment,
  open-sea exclusion and valid MultiPolygon checks.
- Real macOS MapKit snapshots were generated and visually inspected for all ten
  countries in light and dark appearances. Contours follow the background's land
  borders and coasts at card scale. This is not an iOS simulator screenshot or a
  cadastral accuracy claim; tidal rocks and reclaimed coastlines can differ between
  Apple and OSM. The other 233 countries were not individually compared to Apple.
- Generic iOS Simulator Debug build succeeded, including PlayerEducation.swift.
- SHA-256 of the two boundary databases and license in the compiled app match source.
- No iOS runtime/UI test execution in this pass.

Preview: `/Users/spilberg/.codex/visualizations/2026/10/25/01a17347-a91d-7a52-ab22-95c475d3ed4f/maps-precise-111/light/apple-map-overlays.png`
Build log: `/private/tmp/flags-precise-build.log`
Source provenance/rebuild: `scripts/data/detailed-boundaries-README.md`.
