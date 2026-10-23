# KidsPhonics 1.0.14, build 15

Built and verified on 2026-10-11. Delivery:
`releases/KidsPhonics-1.0.14-build15.apk`.

This release includes the supplied four Home garden background frames,
Games house on the upper left and Lessons house on the upper right, and their
playful matching mascots on the lower pads. Progress and Parents remain in the
Home navigation bar. It also includes the eleven Games and five Lessons card
designs, corrected Blending Sounds title, transparent Word Builder/Alphabet
Order card backgrounds, responsive captions and existing lesson progress.

See [Home garden refresh](HOME_GARDEN_ART_REFRESH.md) and
[Lessons/Games cards](LESSONS_GAMES_CARD_REFRESH.md) for the implementation.

Verification:

- Release compilation succeeded.
- All 847 source inputs captured before compilation remained unchanged.
- All 700 source assets inside the APK match their SHA-256 hashes.
- Retired assets and six superseded menu files are absent from the APK.
- Android package version is 1.0.14, version code 15.
- APK signature verified; signing certificate matches build 14.
- Final Lessons/Games regression suite passed 70 tests with clean analysis.
  The preceding Home garden suite passed 78 tests.
- APK size: 366,445,014 bytes (349.5 MiB).

Detailed evidence is in `tools/release_1_0_14_verification.json`,
`tools/release_1_0_14_source_snapshot.json` and
`releases/KidsPhonics-1.0.14-build15.apk.sha256`.

The existing development signing configuration is retained. Physical Android
installation, microphone and speaker behavior have not been tested for this
release.
