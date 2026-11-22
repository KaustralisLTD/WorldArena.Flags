# Google sign-in immediate crash — 2026-11-22

Report: Salex exits to the Home Screen immediately after tapping Continue with Google,
before selecting a Google account, in App Store 8.0.3 and 8.0.4.

Confirmed release-source defect: tracked GoogleService-Info.plist lacked CLIENT_ID
and REVERSED_CLIENT_ID, and app Info.plist lacked GIDClientID. The user's original
local checkout contained the two OAuth IDs, but the release branch did not.
The Google SDK raises NSInvalidArgumentException for a missing configuration before
starting interactive sign-in; Swift do/catch does not intercept Objective-C exceptions.
A reverse callback scheme alone was already present and was not sufficient.
No device crash report was available; the reported trigger matches this deterministic
SDK failure. This is not a claim of reading Salex's device crash log.

Changes:
- Restore existing public OAuth client IDs from the original local configuration.
- Use GIDClientID in app Info.plist as the authoritative runtime configuration.
- Check client ID and matching return scheme before calling the SDK; fail safely.
- Reject missing/dismissing presenters without falling back to email-only login.
- Forward SwiftUI onOpenURL callbacks to Google before handling application links.
- Add a mandatory build phase validating processed/bundled OAuth configuration.
  It rejects missing identifiers or mismatched schemes before a release can complete.

Verification:
- Old release configuration rejected by the new checker; current configuration passes.
- Missing callback regression correctly rejected.
- Build and all five targeted tests passed on iPhone 16 Pro / iOS 18.5:
  four GoogleSignInSetupTests and one Google sign-in UI regression test.
- UI test tapped the actual Google button, observed system consent for google.com,
  confirmed the process remained alive, canceled, and returned to the login screen.
- No account credentials entered; a full user sign-in/backend session was not tested.
- No new App Store/TestFlight build uploaded in this fix pass.

Screenshot:
`/Users/spilberg/.codex/visualizations/2026/10/25/01a17347-a91d-7a52-ab22-95c475d3ed4f/google-signin-fix/google-auth-consent.png`
Test log: `/private/tmp/flags-google-test.log`.
