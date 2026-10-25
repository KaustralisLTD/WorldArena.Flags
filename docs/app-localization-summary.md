# App localization coverage — 25 October 2026

All 1,613 English-base keys now have nonempty values in all 30 app catalogs.
The full audit reports zero missing keys, empty values, format mismatches or
unresolved translation markers. Locale-specific extra keys are retained.

## Changes

- Added 2,632 dictionary entries for Premium, country information, the app guide,
  streak recovery, avatar controls, help, connectivity errors and other screens.
- Reused 203 translations already present under equivalent keys; preserved 20
  language autonyms. Of the new entries, 202 received direct editorial changes,
  particularly streak terminology and recovery messages. The other 2,207 were
  machine-translated from the English source, with protected brands/arguments.
- Filled seven empty accuracy messages, including the English source.
- Fixed the results screen to look up a stable key before formatting accuracy.
- Repaired corrupted Arabic/Japanese/Traditional Chinese format markers and
  explicitly indexed reordered lives/minutes/seconds arguments.
- Removed a stray semicolon in the Dutch dictionary that caused Apple's parser
  to ignore 797 entries despite those entries appearing in text-based checks.
- Separated adjacent dictionary entries and fixed doubled percent signs in a
  plain-text explanation.

## Validation

- Full catalog audit: 30 languages, 1,613 base keys, no errors.
- Swift/Foundation loads every base key directly from each of the 30 language
  bundles, without relying on an English fallback. Timer, streak recovery and
  accuracy format examples are checked with distinct argument values.
- Existing notification/history checks and format-audit regression tests pass.
- All 30 dictionaries pass Apple's property-list validation.
- Full Debug arm64 iOS Simulator build is checked before publishing the commit.

## Scope and limits

This closes catalog gaps and the concrete runtime/formatting defects found in
this pass. It does not certify every sentence as native-reviewed, nor establish
that every hardcoded or dynamically generated string elsewhere in the app is
localized. Machine-translated copy still benefits from native-speaker review.
No production server deployment or App Store/TestFlight release is included.

Machine-readable coverage: `app-localization-audit.json`.

## Subsequent AI editorial review

The user requested full proofreading and selected AI editorial review. Work is
in progress: 2,602 further entries corrected and 4,998 of 48,677 entries recorded
as reviewed. The complete review is **not** finished. See
`app-localization-editorial-review.md` and the per-language/key progress ledger.
