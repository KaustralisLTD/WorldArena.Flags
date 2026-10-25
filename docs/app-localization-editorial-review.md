# AI editorial review — in progress

The user selected AI editorial review on 25 October 2026. **The requested complete
review is not finished.** Coverage checks are not linguistic approval.

The ledger records **10,209 reviewed entries out of 48,677**, and **3,850 distinct
changed entries** against the editorial baseline. This continuation changed 1,248
entries relative to a98dd9f8. Each reviewed value has a SHA-256; a changed value
invalidates its prior review. A reviewed value was read or directly rewritten by
the AI against source and context, not certified by native speakers.

## Completed editorial scope

Across all 30 languages:

- 70 F-Bucks keys: rewards, streaks, currencies, prices and shop items.
- 49 learning keys: country panels, galleries, playback and shared national anthems.
- 44 Premium keys: subscription wording, benefits, family sharing, weekly rewards,
  learning progress, mistakes and expanded/collapsed accessibility labels.
- 15 guide keys: onboarding actions, daily streaks, friends and invitations.
- 24 `achievement.*` keys: achievement titles and thresholds. Older achievement
  strings outside this prefix are not all reviewed yet.
- 7 app-icon keys and 4 first-earned-currency education keys.
- 40 common profile/account/quest keys, ending with `World Flags` in base order:
  counters, labels, ranks, registration year and quest formats.
- 40 common game/navigation/result keys: region selection, scores, accuracy,
  sharing, clear/close/home actions and result feedback. Repaired damaged emojis.
- Two factual corrections in both legacy tiles and numbered fact cards (8 keys
  per language). The rest of the country facts are still pending.
- Additional gameplay, notification, league and streak entries recorded individually
  in the ledger, including the earlier score/time/accuracy repairs.

## Context findings and corrections

- `ProfileView.swift` passes `userProfile.friends.count` to the misleading
  `Following` key. The text now means friends in every language, including English.
- Registration dates receive a year, not a location. Fixed translations that meant
  “joined [organisation/place]” and used year-compatible wording.
- Personal records had become personal documents/files in several languages.
- `GameHomeVariant2View.swift` uses `home.streak_nudge.play` for both guide targets.
  `ContentView.performStartGameFromHome` starts a game or a mode introduction.
  Removed the unsupported guide promise that a Continue label appears, and matched
  the actual Play label in all 30 languages. Fixed media-play translations.
- Premium progress maps describe knowledge of flags, not conquered/weak countries.
  Corrected land-area wording, anatomical hearts, collapse-as-destruction,
  accessory specificity, weekly reward grammar and inconsistent address.
- The family sharing copy retains a maximum of six people including the subscriber.
  The weekly bonus retains full seven-day intervals from bonus activation and sync
  on opening the app; this pass does not change entitlement logic.
- Preserved product name World Arena Premium instead of literal translations such
  as “World Arena prize”. Corrected answer-count word order in quest descriptions.

## Verified fact corrections

Switzerland is not the only country with a square national flag: Vatican City also
has one. Source: [Swiss Federal Department of Foreign Affairs](https://www.aboutswitzerland.eda.admin.ch/en/swiss-flag).
The prior numbered fact wrongly excluded Vatican City on the basis that it is a
city-state. Both versions now simply identify both square national flags.

The year 1219 belongs to the legend about Denmark's flag, not a proven continuous-use
start date. The Danish embassy dates the first factual evidence to the 14th century:
[Danish national flag](https://um.dk/estland/en/denmark-and-estonia/national-symbols/danish-national-flag).
The tile and numbered fact now explicitly describe the legend. The former “oldest”
headlines have been replaced so they do not preserve the unsupported implication.

## Validation

- All 30 catalogs: zero missing or empty keys, placeholder mismatches or translator
  artifacts. All reviewed hashes match the saved values.
- Apple's parser accepts every catalog. Foundation loads every base key in all
  bundles and checks notification history, timers, recovery and accuracy formatting.
- Six Python catalog regression tests and 26 server integration tests pass.
- Compiled notification catalogs regenerated, including edited achievement text.
- No app behavior code changed in this continuation. No full simulator build was
  repeated; the previous full build and current resource/runtime tests are distinct.

## Remaining work

Use `app-localization-editorial-progress.json` for the actual pending keys. All
languages remain `in_progress`. Do not mark the whole app complete from prefix
completion or passing tests.

Remaining areas include most home-screen/gameplay/result copy, older profile and
achievement text, help and rules, country facts, errors, settings outside the icon
section, and locale-specific extras. The first 80 pending base keys from the prior
checkpoint are now reviewed; the next unreviewed base key is expected to be
`TOTAL XP`. Verify against the ledger rather than relying on order.
Cross-screen terminology, grammatical number at runtime and text fit also need
further checking. Native-language certification is not claimed.

No merge, production deployment or App Store/TestFlight release is included.
