# KidsPhonics 1.0.15, build 16

Built and verified on 2026-10-11. Delivery:
`releases/KidsPhonics-1.0.15-build16.apk`.

This release includes the five supplied Home navigation buttons, smaller
animated Games and Lessons mascots inside the lower garden circles, and equally
sized game cards using the titles already printed in their frames. See
[navigation and card polish](HOME_NAVIGATION_AND_CARD_POLISH.md).

Verification:

- Release compilation succeeded.
- All 852 source inputs captured before compilation remained unchanged.
- All 705 bundled source assets match their SHA-256 hashes.
- Retired assets and six superseded menu files are absent from the APK.
- Android package version is 1.0.15, version code 16.
- APK signature verified; signing certificate matches build 15.
- The final focused UI and asset suite passed 46 tests with clean analysis;
  reviewed runtime source matches this build, with only the version changed.
- APK size: 376,235,852 bytes (358.8 MiB).

Detailed evidence is in `tools/release_1_0_15_verification.json`,
`tools/release_1_0_15_source_snapshot.json` and
`releases/KidsPhonics-1.0.15-build16.apk.sha256`.

The existing development signing configuration is retained. Physical Android
installation, microphone and speaker behavior have not been tested for this
release.
