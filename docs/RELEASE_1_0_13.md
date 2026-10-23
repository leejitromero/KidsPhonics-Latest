# KidsPhonics 1.0.13, build 14

This release adds the Magical Village Home: four category houses with closed doors, raised wooden signs and the supplied purple, blue, orange and green mascots. A house tap opens the door, welcomes the learner with its mascot and existing audio, then opens the corresponding screen. Home also has a compact learning summary and a five-item navigation bar.

The other category screens retain their existing designs. Saved progress, rewards, local audio settings, parent controls and Quick Check entry points remain intact. The release includes the earlier Parents simplification and startup/reset recovery fixes.

Delivery: [KidsPhonics-1.0.13-build14.apk](../releases/KidsPhonics-1.0.13-build14.apk).

Verification: [release report](../tools/release_1_0_13_verification.json) and [Home checks](../tools/home_village_verification.json). Full static analysis found no issues, and 83 focused regression checks passed. Source files and mascot assets match the verified Home implementation; the release version was then incremented. All source inputs were captured before compilation and checked afterward. All 681 source assets were compared with bundled bytes.

The signing certificate matches the prior APK. Physical-device installation, speaker and microphone checks remain separate from automated verification. See [Home design notes](HOME_VILLAGE_REDESIGN.md) and the [manual checklist](../MANUAL_TEST_CHECKLIST.md).
