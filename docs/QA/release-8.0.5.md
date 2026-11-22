# Flags 8.0.5 (112) — Google sign-in hotfix

Release source: 9c506eb, including 470ed99 fix and all previous 8.0.4 features.

Validation:
- Four OAuth configuration unit tests and one real-button UI test passed on
  iPhone 16 Pro / iOS 18.5 before release preparation.
- The UI test verified Google's system web-authentication consent and cancellation;
  it did not sign into a real Google account or verify a complete backend session.
- Release archive succeeded. The new mandatory build-phase OAuth validation passed.
- Final archived Info.plist and GoogleService-Info.plist were checked again: correct
  client ID, reverse callback scheme, and consistent settings. Version 8.0.5/build 112.
- Both boundary databases match source exactly. No private .p8 keys bundled.
- App Store Connect upload succeeded; only the existing missing vendor dSYM warnings
  for GoogleMobileAds/UserMessagingPlatform remain. Application dSYM is included.
- App Store metadata and What's New saved/read back in all 29 configured locales.
- Existing screenshot assets all COMPLETE; required primary iPhone/iPad sets present.
- Review contact details complete; review notes explain the hotfix and actual tests.
- Production API health passed; no server changes required for this client crash.

App Store version ID: a25604e4-50bd-44cf-9a21-588727ead59e.
Release verified on 2026-11-22:
- Build ID `45ed2b71-ad77-4462-938e-199f27010be3`: VALID, IN_BETA_TESTING.
- Membership in World Arena. Test Group verified; TestFlight notes saved and read
  back in all 29 languages.
- Build 112 attached to App Store 8.0.5.
- Review submission `01c59aff-2e72-446e-8f17-9a8e73eb87b0` submitted at
  2026-11-22T12:31:37.339Z; both submission and version WAITING_FOR_REVIEW.
- Release mode AFTER_APPROVAL: automatic publication after Apple approval.

Persistent archive ZIP (CRC verified):
`/Users/spilberg/.codex/visualizations/2026/10/25/01a17347-a91d-7a52-ab22-95c475d3ed4f/releases/Flags-8.0.5-112.xcarchive.zip`
