# Source cleanup — 2026-10-04

Completed the requested conservative source cleanup. No runtime image or audio assets, dependencies, saved-progress keys, tests, or Android configuration were removed.

## Checks before removal

- Scanned Dart import/export/part references in lib and test. HomeAdventureScene had no consumers.
- Read VoiceFeedbackService: every method was empty. Removed its import, provider field, empty stop/milestone calls, obsolete announce argument, and unused milestone variables. Current AudioService and PhonicsAudioService remain responsible for sounds and speech.
- Kept legacy screens/data that still have test or progress references; lack of a menu link alone was not used as a deletion criterion.
- Confirmed build/ and .dart_tool/flutter_build/ have no Git-tracked files, resolved their absolute paths inside this workspace, and rejected linked deletion targets before recursive removal.
- Kept .dart_tool reference documents, original ZIPs, artwork-generation scripts, package metadata, and baseline source snapshots. Selected preview PNGs/logs and completed one-off edit/audit scripts were removed by explicit file paths.
- Existing deletions from earlier work (the old SVG and eight old generators) were not part of this cleanup.

## Result

- Removed 57 individual files (1,337,749,211 bytes, approximately 1.25 GiB), plus generated build/ and .dart_tool/flutter_build/ contents. Build-directory space is additional and was not included in this measured total.
- Retained KidsPhonics-1.0.5.apk and its .sha256 file; verified the APK still matches its checksum. This is the previously delivered build; no new APK was required for this behavior-preserving cleanup.
- Added APK/checksum patterns to .gitignore and updated README's latest-delivery and cleanup references.
- Flutter analysis: no issues.
- 51 tests passed across learning_progress_test.dart, game_lives_test.dart, button_sound_test.dart, cvc_lesson_test.dart, and blending_lesson_test.dart.
- Generated build caches were removed after validation; the next Flutter build/test will recreate them and may take longer.

## Removed paths

- `lib/widgets/home_adventure_scene.dart`
- `lib/services/voice_feedback_service.dart`
- `KidsPhonics-1.0.3.apk`
- `KidsPhonics-1.0.3.apk.sha256`
- `KidsPhonics-1.0.4.apk`
- `KidsPhonics-1.0.4.apk.sha256`
- `KidsPhonics-animated-1.0.2.apk`
- `KidsPhonics-animated-1.0.2.apk.sha256`
- `KidsPhonics-latest-2026-10-02.apk`
- `KidsPhonics-latest-2026-10-02.apk.sha256`
- `.dart_tool/alphabet-refresh.png`
- `.dart_tool/answer-choices-preview.png`
- `.dart_tool/blending-320-complete.png`
- `.dart_tool/blending-320-puzzle.png`
- `.dart_tool/blending-390-complete.png`
- `.dart_tool/blending-390-puzzle.png`
- `.dart_tool/blending-800-complete.png`
- `.dart_tool/blending-800-puzzle.png`
- `.dart_tool/blending-preview.log`
- `.dart_tool/blending-regression.log`
- `.dart_tool/blending-tests.log`
- `.dart_tool/button-preview-home.log`
- `.dart_tool/button-preview.log`
- `.dart_tool/button-refresh-tests.log`
- `.dart_tool/buttons-blending.png`
- `.dart_tool/buttons-home.png`
- `.dart_tool/buttons-small.png`
- `.dart_tool/cvc-320-complete.png`
- `.dart_tool/cvc-320-sounds.png`
- `.dart_tool/cvc-390-complete.png`
- `.dart_tool/cvc-390-sounds.png`
- `.dart_tool/cvc-800-complete.png`
- `.dart_tool/cvc-800-sounds.png`
- `.dart_tool/cvc-final-tests.log`
- `.dart_tool/cvc-tests.log`
- `.dart_tool/game-difficulty-tests.log`
- `.dart_tool/game-theme-layouts.log`
- `.dart_tool/games-cards-preview.png`
- `.dart_tool/games-difficulty.png`
- `.dart_tool/games-final-tests.log`
- `.dart_tool/games-menu.png`
- `.dart_tool/games-theme-tests.log`
- `.dart_tool/home-final-check.log`
- `.dart_tool/lessons-cards-preview.png`
- `.dart_tool/lessons-theme-phone.png`
- `.dart_tool/lessons-theme-tablet.png`
- `.dart_tool/letter-recognition-phone.png`
- `.dart_tool/letter-recognition-tablet.png`
- `.dart_tool/small-vowels-refresh.png`
- `.dart_tool/vowel-preview.log`
- `.dart_tool/vowel-refresh-tests.log`
- `.dart_tool/vowels-refresh.png`
- `.dart_tool/ui_choice_edits.ps1`
- `.dart_tool/ui_helpers.ps1`
- `.dart_tool/ui_other_edits.ps1`
- `.dart_tool/positive-audio-before.json`
- `.dart_tool/positive-audio-validation.json`
- `build/`
- `.dart_tool/flutter_build/`
