# KidsPhonics 1.0.18 / build 19

Verified APK: [KidsPhonics-1.0.18-build19.apk](../releases/KidsPhonics-1.0.18-build19.apk).
All 552 regression tests passed and static analysis reported no issues. The
Android release build succeeded. All 788 bundled source assets match their
captured hashes, including 781 required runtime assets. All 952 captured build
inputs remained unchanged after compilation. The signing certificate matches
the previous release. APK size: 474,410,889 bytes (452.4 MiB). SHA-256:
`F903B9151CF6495E83214A09909C1F47DC6D55CF50E88086CC263ECAA7FACB32`.

This release includes the classroom Home artwork and the supplied Lessons,
Practice This Letter and Games buttons. Home artwork fills the display behind
transparent Android system bars. Lessons, Games, Progress and Parents show
their complete background artwork across the display. A small floating menu
replaces the fixed category footer; the learner profile appears inside Progress
content and the navigation menu.

First-time flow: loading, Home without a student, four synchronized KidsPhonics
title voices, a 1.5-second pause, Lala's five dialogues, Lulu's five dialogues,
Get Started, required character/name setup, and the cloud reveal of Home with
the chosen student. Next waits for each recording to finish. Dialogue text fits
inside the supplied speech bubbles.

Idle students wave, and Lala/Lulu gently move behind their buttons. After five
seconds without interaction, the selected boy/girl gives one invitation per
Home visit. Tapping Lessons or Games cancels the idle invitation, plays the
selected student's learn/play recording, then walks the student into the
corresponding room before opening it. Voice muting, parent restrictions,
route visibility, lifecycle interruption and reduced motion remain respected.

Category backgrounds continue their morning, sunset and night cycle with
3.5-second intervals and 650-millisecond fades. Navigation remains available
through the floating menu, including Home, profile setup and replaying guides.
Existing saved profiles and learning progress retain their storage keys.

Release evidence:

- `build/release_1_0_18_tests.log`: full regression suite.
- `build/release_1_0_18_analysis.log`: static analysis.
- `build/release_1_0_18_build.log`: Android release build.
- `tools/release_1_0_18_source_snapshot.json`: captured build inputs.
- `tools/release_1_0_18_verification.json`: APK asset hashes, source consistency,
  Android version metadata and signing certificate.
- `tools/latest_apk_verification.json`: delivered APK path and checksum.

No Android device or emulator was attached for this release. Automated tests
and rendered previews cover the flow and layout; physical-device audio, frame
pacing and installation still require a phone check.
