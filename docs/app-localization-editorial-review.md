# AI editorial review — in progress

The user selected AI editorial review, rather than professional native-speaker
review, on 25 October 2026. **The requested complete review is not finished.**
Key coverage and successful tests must not be represented as linguistic approval.

This checkpoint directly changes 2,602 distinct locale/key entries. The review
ledger records 4,998 reviewed entries out of 48,677, including locale-specific
extras. It records each reviewed value's SHA-256, the remaining count per language,
and before/after values for changes. Every language remains `in_progress`.
A reviewed value means checked or directly rewritten by the AI against its source
and context; it is not a guarantee of flawless native usage.

## Completed editorial scope in this checkpoint

- All 70 F-Bucks keys in all 30 languages: claim/close actions, daily rewards,
  streak terminology, league rewards, prices, transaction history and shop items.
- Shared time-challenge results, correct/total counts, survival-mode labels,
  friend progress/achievements and weekly survival reward explanations.
- Duel announcement: corrected the misleading English source and translations.
  `Server/server.js:duelWinnerFromRow` compares scores first and elapsed time
  second; the previous copy said the first player to score wins.
- Accuracy result: replaced the contradictory promise of answering without any
  errors at an arbitrary accuracy, and removed Cyrillic fragments in other locales.
- Aligned equivalent shop item/streak labels in the older profile catalog keys.
- Removed the word “cash” from the duplicated F-Bucks tournament description by
  using the existing description without it: this is game currency, not cash.
- Repaired identified English leftovers in achievements, league names and controls.
- Removed translation artifacts: a Spanish `{0}`, Filipino XML and Arabic
  translator instructions. Regression tests reject these artifacts.

The ledger deliberately does not count all 1,613 base keys per language as
reviewed merely because they load successfully or pass format validation.

## Subsequent learning and Premium pass

- Read all 49 learning keys in all 30 languages and corrected shared-anthem meaning,
  playlist actions, gallery terminology and country information labels.
- Reviewed Premium copy and corrected identified map, country-area, mistakes,
  lives and expand/collapse wording across all 30 languages.
- Premium is still pending final revision: remaining register, mode-name, weekly
  reward and other findings are not marked complete. Only corrected Premium
  values are credited in the ledger at this checkpoint.

## Validation

- All 30 catalogs: zero missing/empty keys, format mismatches or translator markers.
- Apple's parser loads all 30 catalogs; Foundation resolves all base keys in them.
- Real formatted examples verify correct/total argument order for nine languages
  that place total before correct, as well as lives timers and accuracy.
- Six Python regression tests pass; 26 notification/server integration tests pass.
- Compiled server notification texts are regenerated from the updated catalogs.

## Remaining work

Continue using `app-localization-editorial-progress.json`: pending keys are the
current catalog keys absent from its reviewed set; a changed value hash invalidates
the prior review.
The remaining work includes most help, country facts, Premium, onboarding,
profile, achievements, home-screen and other gameplay copy. Also check terminology
across those screens, singular/plural rendering and text fit in the interface.
The preliminary English/Russian read exposed additional wording issues in older
help and Premium copy; those reads are not marked complete in the ledger.

There is also a separate factual-content issue in the source: the old square-flag
fact claims Switzerland has the world's only square flag, while another catalog
fact describes Vatican City's square flag. This needs source verification and a
coordinated content correction, not blind translation of the contradiction.

No merge, production deployment or App Store/TestFlight release is included.

## Resume notes after learning/Premium correction

The learning prefix (49 keys × 30 languages) has been read and revised. Country
facts outside that prefix are still pending. This pass changed another 436
locale/key values. The cumulative ledger now records 4,998 reviewed entries and
2,602 changed entries; these totals deliberately exclude read-but-unresolved copy.

The 44 Premium keys were read across all 30 languages. Finish these identified
issues before marking that prefix complete:

- Align informal/formal address in es, ca, fr, de, nl, hu and ro, especially
  family sharing, avatar, anthem and story copy. Preserve the six-person total
  including the subscriber; review Bengali wording for the maximum.
- Clarify seven full days from bonus activation in the remaining awkward weekly
  reward sentences (including ar, bn, id, ta, te and tr). Keep reward synchronization
  on opening the app. Do not infer a different subscription entitlement.
- Finish map title and practice headline wording where literal world development,
  physical gaps or anatomical hearts remain. Check hi, bn, th, ta and te especially.
- Review headwear copy: pt-BR says helmet, ro says winter cap. Avoid claiming a
  specific accessory unless the actual item establishes that detail.
- Finish country story text: Hungarian country slides became students; Filipino
  text retains unnecessary English; Turkish wording suggests physically attaching
  a flag. Dutch anthem recordings also retain an English fragment.
- Continue reviewing all other unmarked keys using the ledger, including profile,
  achievements, onboarding, help, country facts and gameplay. The earlier reading
  of help/source facts was preliminary and is not counted as completed review.

Validation for this pass: all 30 catalogs pass coverage/format and Apple parsing;
6 catalog regression tests pass; Foundation loads all base keys and existing
notification/time/accuracy formatting scenarios pass. No app code changed.
