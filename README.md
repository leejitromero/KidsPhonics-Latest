# KidsPhonics

KidsPhonics is a Flutter Android application for Grade 1 supplemental phonics practice. Lessons, recordings, games, learning progress, rewards, and parent controls use local assets and storage. No account, cloud database, or analytics service is required.

## Current features

- A–Z letter lessons and Short Vowel Sounds, with separate LETTER, SOUND, and WORD buttons using the user's latest 78 supplied recordings. See [LESSON_ASSETS.md](LESSON_ASSETS.md) for current mappings and cleanup.
- Five-question Quick Checks: **4/5 masters a letter**. Browsing only marks it Viewed. Statuses are Not Started, Viewed, Practiced, and Mastered; later practice does not remove previously earned mastery.
- Game Zone: Sound Match, Memory Flip, Phonics Quiz, Word Builder, Speak & Recognize, Alphabet Order, Missing Vowel, Picture Match, and Sound Position. Rhyming Words is a playable activity under Lessons: **ten activities in total**.
- Real mastery, Needs Practice, Recommended Next, seven-day activity, streaks, and separate reward statistics. Results show the XP/stars actually saved for that play.
- Parent PIN with a random salt and SHA-256 digest, session checks, protected progress reset, game-access control, daily foreground screen time, and parent-authorized extra time.
- Local `shared_preferences` persistence. Existing keys and safe legacy migration are retained; old `learned` entries become Viewed, never Mastered.
- Speak & Recognize uses the device's existing speech-recognition engine to match recognized words. It does **not** assess phonetic pronunciation. Offline recognition availability depends on the Android recognition service and installed language support; test it on the target phone in airplane mode. The app adds no online speech service.

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

Fonts are the existing Nunito and Fredoka families, now bundled locally with their licenses. Runtime font HTTP fetching is disabled. No font download is needed on first launch. See [font provenance](assets/fonts/README.md).

## Project layout

- `lib/data/`, `lib/models/`: phonics content, questions, and learning/activity models.
- `lib/providers/`: the existing Provider state and serialized local persistence.
- `lib/services/`: local audio, Parent PIN/session, and foreground screen time.
- `lib/screens/`, `lib/widgets/`, `lib/theme/`: screens and shared learner/dashboard components.
- `assets/`: current audio/images and bundled fonts. Letter lessons use the latest supplied letters/sounds/words ZIP; see [LESSON_ASSETS.md](LESSON_ASSETS.md).
- `test/`: progress, content, mastery, parent/time controls, dashboard, learner UI, and stabilization coverage.
- `tools/`: intentionally retained historical asset utilities; see [tools/README.md](tools/README.md). Do not run the old AI audio generators as part of setup or verification.

## Android identity and signing

The launcher label is **KidsPhonics**. Application ID and namespace remain `com.example.kidsphonics` for installation/data continuity at this stage. Changing to `com.kidsphonics.app` would install a separate application and would not automatically migrate existing progress, PIN, or time state. Plan that change before distribution, with an explicit data/reset decision.

The main manifest requests microphone access and declares recognition-service discovery. The unused TTS query, legacy external-storage flag, and main-manifest internet permission were removed. Flutter's debug/profile internet permission remains for development tooling.

Release currently uses the **development debug signing configuration**. No production signing keys or passwords were generated. Configure proper signing separately before deployment. APK delivery is pending the user's separate command.

## Verification and manual testing

Use [FINAL_VERIFICATION.md](FINAL_VERIFICATION.md) for the current verified results and cleanup record. Earlier implementation reports are historical snapshots, not the final verification authority.

Use [MANUAL_TEST_CHECKLIST.md](MANUAL_TEST_CHECKLIST.md) for the upcoming device test. Automated tests do not replace microphone, speaker, lifecycle, and installation testing on Android.

The phonics text and proposed recording workflow are documented in:

- [PHONICS_RECORDING_SCRIPT.md](PHONICS_RECORDING_SCRIPT.md)
- [AUDIO_REPLACEMENT_AUDIT.md](AUDIO_REPLACEMENT_AUDIT.md)
- [PHONICS_TEACHER_VALIDATION.md](PHONICS_TEACHER_VALIDATION.md)

Teacher approval and listening review remain validation tasks. Current supplied lesson artwork and recordings are documented in [LESSON_ASSETS.md](LESSON_ASSETS.md); the older audit records the previous asset set.

## Sharing the source

Include `android/`, `assets/`, `lib/`, `test/`, `tools/`, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `.metadata`, `.gitignore`, this README, and useful Markdown documentation. Keep Android Gradle wrapper/configuration files. Exclude regenerated `build/`, `.dart_tool/`, Android `.gradle`/`.cxx` caches, local SDK paths, generated plugin registration/metadata, logs, and temporary files. Never include signing secrets. `.gitignore` lists these exclusions; it does not automatically filter a manually created ZIP.
