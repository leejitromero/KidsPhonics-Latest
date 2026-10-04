# Screen refresh — October 1, 2026

The existing Home, Lessons, Game Zone, Progress, Parent Panel, letter lessons,
Quick Check, and Tricky Letters designs are retained. This pass completes the
remaining presentation work:

- Launch: a responsive welcome card, existing mascot artwork, Learn/Play/Grow
  chips, bundled Nunito typography, and support for reduced motion.
- Sound Position, Rhyming Words, and Speak & Recognize: illustrated prompt
  cards, clearer question hierarchy, and more spacing between choices.
- All activities using GameScaffold: a consistent difficulty and round header
  with a visual progress bar. Existing instruction panels remain supported.
- Word games: a soft picture backdrop and letter grids that wrap according to
  available width and text size.
- Memory Flip: less empty collection space for short rounds and card hit areas
  constrained to their visible cells.

Existing progress, rewards, parent controls, recordings, game rules, app ID,
version 1.0.0+1, and signing configuration are preserved.

## Verification

- Flutter static analysis: no issues.
- Full existing suite: 187 tests passed.
- New welcome/enlarged-text grid regressions: 2 tests passed.
- Rendered launch, Sound Position, Rhyming Words, and speech previews in
  `build/activity_previews/`; inspected launch and Sound Position.
- Corrected older test assumptions for sound-only prompts, animation settling,
  floating point card sizes, and continued practice after the memory timer.
  Reward tests mute audio to test scoring independently of platform playback.
- Build output is excluded from analysis, including temporary preview scripts.
- No Android device was connected. Installation, real sound playback, microphone
  permission, and recognition still need verification on the target phone.

## APK

The delivered APK is a universal release build for Android API 24 and later.
It uses the project's existing development signing key; it is suitable for
direct testing and is not configured for production store signing.

Delivery location and SHA-256 are appended after packaging and signature checks.

Verified delivery: `KidsPhonics-improved-2026-10-01.apk`

- Size: 290,609,350 bytes (277.1 MiB).
- APK Signature Scheme v2 verification passed; signer: Android Debug.
- Application ID: `com.example.kidsphonics`; version: `1.0.0+1`.
- Includes `arm64-v8a`, `armeabi-v7a`, and `x86_64`.
- Minimum API 24; target API 36.
- SHA-256: `AE1D0572AC9B20A93E0D03C3CE486317A7DD0CC656E13E35E370FDE29FF91A13`.
