# Flags 8.0.4: post-game reminders and country boundaries

Base: build 109, commit 183e3ad4, branch codex/fix-card-map-scroll. The original user's checkout remains on build 100 with unrelated changes, and was not overwritten.

Changes:
- Header/footer stay outside the friend-list ScrollView; Continue is fixed at bottom.
- Exclude played-today and reminded-today friends, refresh from server on entry, persist sender-scoped local receipts, remove successful recipients immediately. Failed requests no longer show success.
- Server derives played-today from actual last-game date/completed-game events, never profile updated_at. Deduplicates same-day reminders in sender timezone; game day uses recipient timezone. Requires deploying Server/server.js + Server/friend-reminders.js together. No production deployment performed.
- Rebuilt bundled boundaries for all 243 catalog entries. Australia no longer overwritten by Ashmore/Cartier ISO-code collision. Ukraine includes Crimea; matching Russia contour avoids overlap. Added missing territories and upgraded crude small-country outlines.
- Main landmass/archipelago viewport; immediate offline outline; bounded 24 MB Apple snapshot memory cache. Apple background/labels remain system-controlled.

Verification completed:
- Three SQLite-backed reminder tests passed (timezone/day rollover, sender isolation, completed game vs profile sync).
- Audit passed for all 243 countries: coordinate bounds, closed rings, valid polygons, finite projected viewports; mainland Australia/Tasmania, Kyiv/Crimea coverage and no Crimea overlap in RUS.
- App and test targets compiled during simulator test preparation. Subsequent compact-archipelago/identity-guard edits parsed successfully but require a final incremental build.
- Contact sheet and representative offline contour previews generated. These are data previews, not simulator screenshots.

Still required:
- Finish unit/UI tests and actual screenshots. Test execution stalled at simulator installation as free disk space dropped to ~150 MB; stopped test process and removed only generated intermediates. No claim that UI tests passed.
- User was asked to free 8–10 GB. Existing source edits are preserved.
- No TestFlight upload, App Store publication, or production server mutation performed.

Tests to run after freeing space: CountryBoundaryTests; testReminderListExcludesPlayedAndSentAndPinsContinue; testAustraliaAndUkraineMaps. Disable Xcode parallel test execution to avoid creating multiple simulator copies.
