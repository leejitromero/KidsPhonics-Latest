# KidsPhonics — Improvement #5: Lessons & Games UI/UX

Implemented September 23, 2026. The existing Flutter app, validated learning content, local progress storage, and parent protections remain in place.

## Verification

- `flutter test`: **97 passed**, including all **77 original tests**, unchanged, and 20 new targeted tests.
- `flutter analyze`: **0 errors, 2 warnings, 100 info/lints**. Its exit status remains nonzero because diagnostics remain; this is not a clean analyzer run. Both warnings are existing unused items in `tools/generate_icon_png.dart`. Remaining info includes existing legacy-widget deprecations, generator lints, and speech API deprecations. Analysis rules were not weakened. Pre-task baseline: 0 errors, 2 warnings, 131 infos.
- Android debug APK: **successfully generated** at `build/app/outputs/flutter-apk/app-debug.apk` (163,728,505 bytes). Gradle returned 0 and Flutter reported Built; the PowerShell log-capture wrapper returned 1 after Java 8 source/target warnings on stderr. The APK was separately opened and checked for AndroidManifest.xml, classes.dex, and Flutter assets.
- Responsive widget checks cover Home, Lessons, A–Z, vowels, Game Zone, and all ten activities at **320×568**, **390×844**, and **800×1024**, including scrolling to remaining content. Hard difficulty is used for the nine applicable non-speech activity layouts. Memory also has a small-phone test that reveals cards and completes the game.
- Existing mastery tests complete fail/pass/retry checks and retain prior mastery. Existing tests cover parent PIN, blocked game access, screen-time blocking, parent unlock, extra time, and dashboards.
- New tests complete nine games and compare result XP/stars against actual provider totals. They cover per-answer rounding, bonuses, multi-blank words, wrong answers, retries in memory, Play Again, Back to Games, rapid taps, and quit confirmation. Speech tests verify truthful wording, permission explanation before the request, and denied-permission feedback; real microphone recognition is a device check.
- Original test files and protected data/model/service/dashboard files were compared with the pre-task snapshot. The only provider change is an optional `announce` parameter for XP milestone audio; UI games pass false. Mastery, daily activity, streak, PIN/session, screen-time, persistence, and reward formulas remain unchanged.

## Created source/test/report files

1. `lib/theme/kids_ui.dart` — learner colors, spacing, typography, corner radius, button sizes, and theme.
2. `lib/widgets/learner_widgets.dart` — shared learner components, navigation guard, and per-play reward display ledger.
3. `lib/services/local_audio_focus.dart` — generation guard for competing local playback requests.
4. `test/learner_ui_test.dart` — 20 targeted behavior and layout tests.
5. `LESSONS_GAMES_UI_REPORT.md` — this report.

## Modified source files

| File | Purpose |
|---|---|
| `lib/models/difficulty.dart` | Remove inaccurate universal A–F/A–N/time claims; actual game mechanics appear in each picker. Multipliers unchanged. |
| `lib/providers/app_provider.dart` | Optional XP milestone announcement suppression; default behavior preserved. |
| `lib/screens/home_screen.dart` | Same four destinations, mascot, level, XP, stars, and streak; shared readable cards, light brand colors, guarded navigation, no ambient animation. |
| `lib/screens/lessons_screen.dart` | Uniform descriptions, genuine mastery counts, progress bars, and status. |
| `lib/screens/letter_sounds_screen.dart` | Letter hierarchy, exact validated text, named audio controls, practice link, large navigation and adaptive status grid. Vowels use the same component. |
| `lib/screens/letter_mastery_check_screen.dart` | Shared header/progress/answers/feedback; original audio gate and 5-question assessment preserved. |
| `lib/screens/games_screen.dart` | Consistent game cards and data-derived difficulty descriptions; parent access and launch guards. |
| `lib/screens/sound_match_screen.dart` | Shared activity UI and truthful results; retry guard. |
| `lib/screens/phonics_quiz_screen.dart` | Shared activity UI and truthful results; answer/next guards. |
| `lib/screens/rhyming_words_screen.dart` | Shared activity UI and truthful results; returns to Lessons. |
| `lib/screens/memory_game_screen.dart` | Responsive image/letter cards, matching feedback, actual pair attempts/rewards. |
| `lib/screens/word_builder_screen.dart` | Responsive blanks and answer tiles; multi-blank tap guard and actual word rewards. |
| `lib/screens/alphabet_order_screen.dart` | Readable letter grid and progress; prevent overlapping delayed completion handlers. |
| `lib/screens/missing_vowel_screen.dart` | Shared question/answer/feedback/result UI. |
| `lib/screens/picture_word_match_screen.dart` | Shared image choices and result UI. |
| `lib/screens/sound_position_screen.dart` | Shared question/answer/feedback/result UI. |
| `lib/screens/voice_recognition_screen.dart` | Speak & Recognize wording, permission explanation, listening/result state, duplicate/stale callback guards. Existing speech engine and matching rules retained. |
| `lib/services/audio_service.dart` | One local SFX channel; stop competing instruction playback and obsolete requests. |
| `lib/services/phonics_audio_service.dart` | Cancellable instructional playback with completion state, asset check, timeout, and latest-request guard. Phrase mappings unchanged. |

Local verification artifacts: `learner-analyze.log`, `learner-tests.log`, `learner-new-tests.log`, `learner-build.log`, and `learner-format.log`. Ignored `.dart_tool/ui_baseline/` and `.dart_tool/ui_*.ps1` contain the local audit snapshot and editing helpers; they are not app assets. Build output is under the existing ignored `build/` directory.

## Reusable UI

`LearnerPage`, `LearnerActivityCard`, `GameScaffold`, `GameProgressHeader`, `GameAnswerButton`, `GameFeedback`, `GameImageCard`, `AudioButton`, `LearningStatusBadge`, and `GameResultDialog` share layout and interaction rules. `chooseGameDifficulty`, `LearnerNavigation`, and `GameSessionUi` handle repeated picker, navigation, and result behavior without changing persisted learning calculations.

The learner palette retains the purple/teal brand with a light background. Primary text is 18px or larger, answers 22px, headings 24–28px, and the main letter 72px. Primary controls have 56px minimum height; answer buttons use 64px. Feedback includes icons and words. Layouts are portrait-first, scroll where needed, and cap content width on tablets.

## Lessons and Quick Check

- A–Z and short-vowel cards derive mastered/total counts and progress from stored letter progress. Browsing does not award mastery, stars, or XP.
- Letter pages show position, uppercase/lowercase, existing example and validated sound wording, then real Viewed/Practiced/Mastered status.
- Hear Letter and Hear Word are explicit; Hear Sound appears only when the content supplies a safe recording key. Current retired isolated-sound clips remain unavailable.
- Previous, Grid, and Next wrap on smaller phones. The grid adapts from three to six columns, with 88px tiles, status icons, and semantic labels.
- Quick Check keeps five questions, 4/5 mastery, required audio completion, one scored answer per question, explicit Next, and prior mastery on a lower retry. It does not introduce pronunciation scoring or automatic voice feedback.

## Games, rewards, and mismatch fixes

Every game has the same header, progress placement, concise How to Play, difficulty label, feedback style, and result component. Rhyming remains accessible through Lessons; no new games were added. Game Zone descriptions reflect the actual activity. Difficulty details use existing content counts/choices; Alphabet Order explicitly uses A–F, A–M, A–Z.

Let `m` be the existing difficulty multiplier. Rounding occurs on each existing reward write, not after summing.

| Activity | Existing reward formula, now displayed in full | Old display problem addressed |
|---|---|---|
| Sound Match | Each correct answer `round(5m)` + completion `round(10m)` | Dialog showed bonus only. Removed the misleading generated letter + “uh” display. |
| Phonics Quiz | Each correct answer `round(5m)` + completion `round(20m)` | Result hard-coded `round(25m)` regardless of answers. |
| Memory Flip | Each matched pair `round(5m)` + completion `round(10m)` | Result hard-coded `round(20m)`. |
| Word Builder | Each completed word `round(10m)` + completion `round(15m)` | Per-word UI claimed `round(30m)`; result showed only the bonus. |
| Alphabet Order | Each correct letter `round(3m)` + completion `round(15m)` | Result showed only the bonus; overlapping handlers could repeat completion. |
| Missing Vowel | Each correct word `round(8m)` + completion `round(15m)` | Result presented bonus as XP Earned. |
| Picture Match | Each correct word `round(8m)` + completion `round(15m)` | Result omitted correct-answer XP. |
| Sound Position | Each correct round `round(8m)` + completion `round(15m)` | Result omitted correct-answer XP. |
| Rhyming Words | Each correct answer `round(8m)` + completion `round(20m)` | Result presented bonus as total XP Earned. |
| Speak & Recognize | Each accepted recognition `round(10m)` + fixed completion 15 | Result showed only the fixed bonus. |

Game Zone's fixed XP promises were removed. Each original star-awarding event still adds exactly one star, and the same per-play count is displayed. Zero-star rewards are omitted. Decorative achievements are not presented as earned stars.

`GameSessionUi` mirrors the exact XP/star writes, waits for those writes before presenting results, and resets only the local display ledger on Play Again. Existing per-answer daily-activity calls are preserved. Result scores count real scored attempts, including scored retries, and explicitly say so; instructions, audio taps, and animation events are excluded. Word Builder scores blank attempts while rewards remain per completed word. Memory scores pair attempts. Speech recognition keeps its original scope and does not add new daily-activity writes.

## Navigation and audio

- Repeated taps cannot stack the same source's destination, difficulty dialogs, mastery routes, or completion actions.
- Started games offer Cancel/Leave; untouched games return immediately. Results pop back to the actual source instead of pushing duplicate Home/Game Zone routes.
- Audio controls visibly show Playing and disable repeated playback. Missing/disabled recordings show a safe message.
- New instructional playback replaces the previous instruction. SFX replace competing instruction playback, and starting an instruction stops SFX/voice feedback. Games stop playback on disposal; lessons stop on selection/exit, and mastery stops when leaving.
- Existing recordings and phrase mappings are retained. No MP3s, TTS, voice packs, images, cloud services, or packages were added.
- The microphone explanation appears before the user requests listening. Wording is “I heard”, “Recognized”, or “Try Again”. No phonetic pronunciation-analysis claim is made.

## Future assets and device checks

Final custom images remain a later stage. `GameImageCard` provides an aspect-ratio slot, rounded padding, `BoxFit.contain`, and an emoji/error fallback. A–Z/vowels, pictured Quick Check questions, Sound Match, Phonics Quiz, Rhyming, Memory, Word Builder, Missing Vowel, Picture Match, Sound Position, and Speak & Recognize retain current visuals. Alphabet Order is text-based; Home retains its existing mascot emoji.

Final human recordings remain a later stage for Hear Letter/Hear Word, word hints across games, and audio-dependent Quick Check questions. Isolated Hear Sound recordings must be validated before enabling their keys. No new voice feedback is required by this UI.

Automated flow equivalents passed for lessons/mastery, games/results/replay/back, progress data, parent PIN, and screen-time unlock/extra time. **These are not physical-device manual checks.** Remaining device QA: listen to actual recordings and check rapid switching, microphone recognition and permissions on Android, airplane-mode behavior of the existing platform recognition engine, system Back during play, background/resume, and the full parent/time-limit flow on the target phone. The configured SDK is `C:\Android\Sdk`; `adb devices` returned no connected devices. No physical-device result is claimed.


APK SHA-256: `3BDAB4EE925E126B91CB66E58E7B6E451D4900B4E350DF439D37418ADD7CA548`.

