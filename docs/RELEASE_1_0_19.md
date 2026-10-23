# KidsPhonics 1.0.19 / build 20

APK: [KidsPhonics-1.0.19-build20.apk](../releases/KidsPhonics-1.0.19-build20.apk).
The release build succeeded. All 957 captured build inputs remained unchanged;
all 792 bundled source assets and 785 required runtime assets were verified.
Android package version and signature were checked, and the signing certificate
matches build 19 for an in-place update. APK: 482,283,140 bytes (459.9 MiB).
SHA-256: `BFEFA86E8173E4C1A606AB39C046C0222E8410716953214D5A57C4F93433C895`.

Includes the reference-style school Home, constant-size walking exits, startup
KidsPhonics chorus for saved learners on every fresh launch, improved framed
character selection, and dialogue tails anchored near each speaker's head.
Saved names, selected characters, lesson progress and rewards retain their
existing storage keys.

Scoped UI/audio regressions and Flutter analysis passed during these changes.
No full-suite run was performed for this packaging step. Physical-device
installation, audio and layout have not been checked.

Evidence: `build/release_1_0_19_build.log`,
`tools/release_1_0_19_source_snapshot.json`, `tools/release_1_0_19_verification.json`,
`tools/latest_apk_verification.json`, and the adjacent APK `.sha256` file.
Design and test details are in `HOME_REFERENCE_MATCH.md`,
`CHARACTER_SELECTION_REFERENCE.md`, and `DIALOGUE_HEAD_ANCHOR.md`.
