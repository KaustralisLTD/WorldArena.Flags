# Completed AI editorial review — 25 October 2026

All **48,677 entries in 30 language catalogs** have been read and
reviewed against source meaning and app context. **12,690 distinct
entries were corrected** relative to the editorial baseline
`391bf1aab94976d26cd9c3e1475aef99a4e318bc`. Every language has zero pending entries.

This is the AI editorial review selected by the user. It is not professional
native-speaker certification. Coverage means every value in the 30
`Resources/*.lproj/Localizable.strings` catalogs, including 287 locale-specific
extras, has been reviewed. It does not assert an exhaustive audit of external
country databases, user-generated messages, or every hardcoded string elsewhere.

## Review evidence

`app-localization-editorial-progress.json` records the exact SHA-256 of every
reviewed value and the before/after text of corrections. Changed text invalidates
its earlier review. Run `python3 scripts/audit_editorial_progress.py` to check
current values, completeness, totals and final correction values. Hashes document
which text was read; they do not prove linguistic quality on their own.

The continuation covered all remaining game modes, results, home screen, profile,
friends, league standings, quests, achievements, country fact cards, settings,
help, errors, subscriptions, avatar editor, shop, reminders and notification
history. Earlier reviewed sections were retained, with further corrections where
context required them. Three additional AI editors were used after the user's
explicit authorization, with non-overlapping language assignments and recorded
handoffs. All pending values were read individually rather than bulk-approved
from an automated key check.

## Corrections

- Fixed literal mistranslations: lives as a verb, capitals as uppercase letters,
  Close as nearby, Premium as insurance/reward, avatars' clothing and hair names,
  and daily streaks as stripes or winning streaks.
- Preserved World Arena Flags, Premium, F-Bucks, XP and language autonyms where
  appropriate. Localized ordinary interface labels and aligned terms and address.
- Corrected result/count argument order with indexed format arguments. Kept
  player names, scores, time fields and percentage placeholders intact.
- Restored full meaning to the five notification-detail paragraphs in every
  language; earlier shortened versions omitted information about retained history,
  profile experience, rewards and next goals.
- Updated help to actual avatar/photo controls, notification preferences, iCloud
  progress mirroring, streak protection and variable league promotion zones.
- Clarified that perfect-game currency rewards require eligible games. Removed
  the fixed 10/10 or 15/15 condition and obsolete 238-country promise.
- Replaced unsupported two-month and +750% learning promises with factual feature
  descriptions. Corrected inaccurate and overgeneralized flag facts.

The 37 coordinated source revisions are recorded in
`localization-editorial-source-decisions.json`; the ledger also includes all
other individual editorial changes.

## Context verification

- `GameState.swift` defines question counts by difficulty and limits perfect-game
  eligibility; Time Challenge, duels and My Mistakes are excluded from that reward.
- `LeaguesService.swift` defines changing promotion/demotion thresholds;
  `LeaguesView.swift` uses these ranges and grants F-Bucks on promotion.
- `UserProfile.swift` supplies streak protection and recovery. `ProfileView.swift`,
  `ProfileEditView.swift` and `AvatarEditorView.swift` supply the current editing
  path. The old Create skin tab and app cache-clear instruction were removed.
- `LocalProgressICloudMirror.swift` mirrors local progress through iCloud;
  `PrivacySettingsView.swift` exposes data export.
- `WorldProgressMapView.swift` passes mastered/answered count before total count;
  translations that place total first now use explicit argument indices.

## Fact sources

- [Swiss foreign affairs: Swiss and Vatican square flags](https://www.aboutswitzerland.eda.admin.ch/en/swiss-flag)
- [Danish embassy: the 1219 legend and later historical evidence](https://um.dk/estland/en/denmark-and-estonia/national-symbols/danish-national-flag)
- [IOC: Olympic symbol and colours](https://brand-centre.olympic.org/olympic_symbol)
- [Australian Government: five Southern Cross stars](https://www.pmc.gov.au/resources/australian-symbols-booklet/national-symbols/australian-national-flag)
- [Canada: eleven-point maple leaf](https://www.canada.ca/en/canadian-heritage/services/flag-canada-description.html)
- [Royal Household: the three crosses of the Union Flag](https://www.royal.uk/union-jack?page=1)
- [UK Parliament: the 1959 Welsh flag decision](https://hansard.parliament.uk/Commons/1959-02-23/debates/506ca02e-41c8-4267-ba99-d5999fcdaab2/WelshFlag)
- [South Sudan Presidency: national symbols](https://op.gov.ss/south-sudan/)
- [Japan: flag and anthem](https://www.japan.go.jp/japan/flagandanthem/)
- [Belize National Library: national symbols](https://www.bnlsis.org/nationalsymbolsofbelize)
- [Dominican Presidency: flag and coat of arms](https://www.presidencia.gob.do/acerca-de-rd/simbolos-patrios)
- [Mozambique foreign ministry: national symbols](https://minec.gov.mz/simbolos-nacionais/)

## Validation

- All 1,613 base keys in all 30 catalogs: no missing/empty values, argument
  mismatches or unresolved translation markers.
- Notification audit: all 149 keys complete in all 30 languages.
- Apple's property-list parser accepts all 30 files.
- Swift/Foundation loads every base key from every language bundle, and verifies
  timers, recovery, accuracy, correct/total order and saved event localization.
- All six Python catalog regression tests and all 26 server integration tests pass.
- Generated server notification catalogs match the edited app dictionaries.
- No app behavior code changed in this continuation. The earlier full arm64
  Simulator build and the current resource/runtime checks are distinct; a new
  full simulator build was not needed for these resource-only app changes.

## Per-language completion

| Locale | Entries | Reviewed | Corrected |
| --- | ---: | ---: | ---: |
| ar | 1613 | 1613 | 528 |
| bn | 1613 | 1613 | 386 |
| ca | 1665 | 1665 | 278 |
| cs | 1613 | 1613 | 519 |
| de | 1614 | 1614 | 360 |
| el | 1613 | 1613 | 660 |
| en | 1613 | 1613 | 98 |
| es | 1665 | 1665 | 227 |
| fil | 1613 | 1613 | 447 |
| fr | 1614 | 1614 | 423 |
| hi | 1613 | 1613 | 442 |
| hu | 1613 | 1613 | 529 |
| id | 1613 | 1613 | 422 |
| it | 1614 | 1614 | 329 |
| ja | 1613 | 1613 | 481 |
| ko | 1613 | 1613 | 493 |
| nl | 1614 | 1614 | 296 |
| pl | 1614 | 1614 | 373 |
| pt-BR | 1614 | 1614 | 306 |
| ro | 1613 | 1613 | 566 |
| ru | 1666 | 1666 | 418 |
| sv | 1613 | 1613 | 394 |
| ta | 1613 | 1613 | 392 |
| te | 1613 | 1613 | 612 |
| th | 1613 | 1613 | 424 |
| tr | 1613 | 1613 | 604 |
| uk | 1689 | 1689 | 442 |
| vi | 1613 | 1613 | 438 |
| zh | 1661 | 1661 | 307 |
| zh-Hant | 1613 | 1613 | 496 |

No merge, production deployment or App Store/TestFlight release is included.
