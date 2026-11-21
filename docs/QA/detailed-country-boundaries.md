# Small-country boundary alignment — 2026-11-21

Based on the complete TestFlight 8.0.4 (110) source, without removing prior fixes.
Released as build 8.0.4 (111) on 2026-11-21. No additional server changes were needed; production health passed before submission.

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

## Release confirmation

- Source release commit: 9745d5f (includes ceaef27 detailed contours and every build 110 change).
- Release archive and upload succeeded. Bundled boundary/license SHA-256 matched source.
- App Store Connect build: `1163a392-e6dd-497a-9a98-556e578fa446`, processing VALID,
  internal state IN_BETA_TESTING; membership in World Arena. Test Group verified.
- Public What's New and TestFlight notes saved and read back in all 29 configured locales.
- Existing screenshot assets checked: all uploaded assets COMPLETE; primary locale
  contains iPhone and iPad sets. Existing screenshot inheritance remains in place.
- App Store version: `99317e88-b640-433b-b94b-24a2b7b00782`, attached build 111.
- Review submission: `d4fb7c32-20f9-4e5c-a7eb-f78925570bb4`, submitted
  2026-11-21T12:16:21.94Z. Both submission and version are WAITING_FOR_REVIEW.
- Release mode AFTER_APPROVAL: automatic publication after Apple approves.
- Upload only warned about missing third-party GoogleMobileAds/UserMessagingPlatform
  dSYMs; application dSYM included. No blocking upload errors.
- Archive ZIP verified at `/Volumes/spilberg/3.Work/9.iOS/Flags-Builds/8.0.4-111/Flags-8.0.4-111.xcarchive.zip`.
