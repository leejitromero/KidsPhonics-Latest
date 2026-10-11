# KidsPhonics

KidsPhonics is a Flutter Android application for Grade 1 supplemental phonics practice. Lessons, recordings, games, learning progress, rewards, and parent controls use local assets and storage. No account, cloud database, or analytics service is required.

## Current features

- Animated sky backgrounds and the supplied flying Home menu, with tappable
  Lessons/Games/Progress artwork, plus the restored original loading screen.
  See [animated screen delivery](ANIMATED_SCREEN_DELIVERY.md).

- A–Z letter lessons and Short Vowel Sounds, with separate LETTER, SOUND, and WORD buttons using the user's latest 78 supplied recordings. See [LESSON_ASSETS.md](LESSON_ASSETS.md) for current mappings and cleanup.
- Five-question Quick Checks: **4/5 masters a letter**. Browsing only marks it Viewed. Statuses are Not Started, Viewed, Practiced, and Mastered; later practice does not remove previously earned mastery.
- Game Zone: Flappy Letters, Sound Match, Memory Flip, Phonics Quiz, Word Builder, Speak & Recognize, Alphabet Order, Missing Vowel, Picture Match, Rumbled Words, and Rhyming Words: **eleven menu activities**. Sound Position remains implemented but currently has no menu entry.
- Real mastery, Needs Practice, Recommended Next, seven-day activity, streaks, and separate reward statistics. Results show the XP/stars actually saved for that play.
- Parent PIN with a random salt and SHA-256 digest, session checks, protected progress reset, game-access control, daily foreground screen time, and parent-authorized extra time.
- Local `shared_preferences` persistence. Existing keys and safe legacy migration are retained; old `learned` entries become Viewed, never Mastered.
- Speak & Recognize uses the device's existing speech-recognition engine to match recognized words. It does **not** assess phonetic pronunciation. Offline recognition availability depends on the Android recognition service and installed language support; test it on the target phone in airplane mode. The app adds no online speech service.
- New/viewed letters selected from Progress or parent recommendations open a teaching screen before Quick Check. Name/sound/word listening and speech-recognition practice are tracked separately from quiz accuracy.
- Checked save retries and app/screen-time snapshots preserve consistent progress across interrupted writes; pending changes have a Retry action in the Parent Panel.
- Runtime artwork uses lossless WebP encodings with verified identical pixels, retaining PNG launcher inputs and existing GIFs. All games offer visual How to Play examples. See [implemented improvements](IMPROVEMENTS_IMPLEMENTED.md).

## Development

Verified toolchain: Flutter **3.41.5**, Dart **3.11.3**. Use the committed `pubspec.lock`. Android deployment requires the Android SDK, Java compatible with the Gradle setup (Java 17 compilation), and an Android device or emulator. The current Flutter SDK sets minimum Android API **24**. Portrait Android is the supported project scope; desktop/web are not final deployment targets.

From the project root:

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Run `dart format lib test tools` when changing Dart files. Generated directories may be present after local verification; exclude them when sharing source. `flutter pub get` recreates package metadata. `flutter run` regenerates build output and Android local SDK configuration. If your SDK is in a custom location, configure it with `flutter config --android-sdk <path>`.

Fonts are the existing Nunito and Fredoka families, now bundled locally with their licenses. Runtime font HTTP fetching is disabled. No font download is needed on first launch. See [font provenance](tools/asset_notes/fonts/README.md).

## Project layout

- `lib/data/`, `lib/models/`: phonics content, questions, and learning/activity models.
- `lib/providers/`: the existing Provider state and serialized local persistence.
- `lib/services/`: local audio, Parent PIN/session, and foreground screen time.
- `lib/screens/`, `lib/widgets/`, `lib/theme/`: screens and shared learner/dashboard components.
- `assets/`: current audio/images and bundled fonts. Letter lessons use the latest supplied letters/sounds/words ZIP; see [LESSON_ASSETS.md](LESSON_ASSETS.md).
- `test/`: progress, content, mastery, parent/time controls, dashboard, learner UI, and stabilization coverage.
- `tools/`: APK asset verification, runtime asset audit, cleanup inventory, and asset documentation; see [tools/README.md](tools/README.md).

## Android identity and signing

The launcher label is **KidsPhonics**. Application ID and namespace remain `com.example.kidsphonics` for installation/data continuity at this stage. Changing to `com.kidsphonics.app` would install a separate application and would not automatically migrate existing progress, PIN, or time state. Plan that change before distribution, with an explicit data/reset decision.

The main manifest requests microphone access and declares recognition-service discovery. The unused TTS query, legacy external-storage flag, and main-manifest internet permission were removed. Flutter's debug/profile internet permission remains for development tooling.

Release currently uses the **development debug signing configuration**. No production signing keys or passwords were generated. Configure proper signing separately before store distribution. Release **1.0.12+13** includes the simplified Parents overview, parent-session cleanup and startup/reset save recovery fixes, alongside the colorful Quick Check buttons, updated Home layout, compact Progress/Parents cards and animated Sound Match orb. Build output is `build/app/outputs/flutter-apk/app-release.apk`; the verified delivery is `releases/KidsPhonics-1.0.12-build13.apk`. See [release verification](tools/latest_apk_verification.json) and [release notes](docs/RELEASE_1_0_12.md). Earlier deliveries are historical snapshots in [ANIMATED_SCREEN_DELIVERY.md](ANIMATED_SCREEN_DELIVERY.md) and [SCREEN_REFRESH_DELIVERY.md](SCREEN_REFRESH_DELIVERY.md).

## Verification and manual testing

See [ASSET_CLEANUP_REPORT.md](ASSET_CLEANUP_REPORT.md) for the current asset cleanup, APK size reduction and validation. [SOURCE_CLEANUP.md](SOURCE_CLEANUP.md), [FINAL_VERIFICATION.md](FINAL_VERIFICATION.md) and earlier implementation reports retain historical results.

Use [MANUAL_TEST_CHECKLIST.md](MANUAL_TEST_CHECKLIST.md) for the upcoming device test. Automated tests do not replace microphone, speaker, lifecycle, and installation testing on Android.

See [APP_IMPROVEMENT_REVIEW.md](APP_IMPROVEMENT_REVIEW.md) for the 2026-10-07 review, verified fixes, prioritized improvements, and remaining device checks.

The phonics text and proposed recording workflow are documented in:

- [PHONICS_RECORDING_SCRIPT.md](PHONICS_RECORDING_SCRIPT.md)
- [AUDIO_REPLACEMENT_AUDIT.md](AUDIO_REPLACEMENT_AUDIT.md)
- [PHONICS_TEACHER_VALIDATION.md](PHONICS_TEACHER_VALIDATION.md)

Teacher approval and listening review remain validation tasks. Current supplied lesson artwork and recordings are documented in [LESSON_ASSETS.md](LESSON_ASSETS.md); the older audit records the previous asset set.

## Sharing the source

Cleanup on 2026-10-04 removed an unreferenced Home illustration widget, the retired empty voice-feedback service and its calls, four superseded APKs with checksums, temporary previews/logs/edit scripts, and generated build directories. APK artifacts are ignored by Git; older APK/preview links in historical reports describe past deliveries and may no longer exist locally. Original artwork, runtime assets, tests, platform configuration, and historical reports remain available. See [SOURCE_CLEANUP.md](SOURCE_CLEANUP.md) for the full inventory.

Include `android/`, `assets/`, `lib/`, `test/`, `tools/`, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `.metadata`, `.gitignore`, this README, and useful Markdown documentation. Keep Android Gradle wrapper/configuration files. Exclude regenerated `build/`, `.dart_tool/`, Android `.gradle`/`.cxx` caches, local SDK paths, generated plugin registration/metadata, logs, and temporary files. Never include signing secrets. `.gitignore` lists these exclusions; it does not automatically filter a manually created ZIP.
