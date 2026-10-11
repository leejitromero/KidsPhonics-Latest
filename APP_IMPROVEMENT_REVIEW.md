# KidsPhonics improvement review

Reviewed 2026-10-07. This review covers the Flutter source, lesson/question data, game flows, local audio/assets, progress/rewards, parent controls, persistence, and Android build configuration. Findings below distinguish reproduced bugs, code-level risks, and product suggestions. Device listening, speech recognition, visual appearance, and performance still need the [manual checks](MANUAL_TEST_CHECKLIST.md).

**Follow-up implementation:** the user authorized the seven prioritized improvements. See [IMPROVEMENTS_IMPLEMENTED.md](IMPROVEMENTS_IMPLEMENTED.md) for the completed speech/storage fixes, lesson-first routing, separate practice metrics, visual tutorials, performance work, lossless image optimization, and new release validation. The findings below preserve the original review; they are not a current list of unimplemented fixes.

## Fixed during this review

Sound Match could change the task behind its Leave dialog. Sound Match, Phonics Quiz, and Word Builder could advance after answer feedback while the app was backgrounded. Five widget regressions reproduced these behaviors before the relevant fixes.

- [Shared game feedback guard](lib/widgets/learner_widgets.dart): advancement requires the current route, a resumed app, game access, and an unblocked daily limit.
- [Sound Match](lib/screens/sound_match_screen.dart), [Phonics Quiz](lib/screens/phonics_quiz_screen.dart), and [Word Builder](lib/screens/word_builder_screen.dart): delayed advancement waits until the game is accessible. Timers are canceled on disposal. Word Builder keeps input locked while awaiting its next puzzle and resets that lock for a new puzzle.
- [Regression tests](test/game_feedback_visibility_test.dart) cover leave-dialog/background cases, alongside the existing Word Builder phoneme sequencing test.
- [README](README.md) now describes the actual eleven-game menu, current APK, font documentation, and historical artifact links accurately.

The existing APK predates these source fixes. This review does not produce a new APK.

## Highest-impact remaining improvements

| Priority | Finding and evidence | Recommended change / acceptance check |
|---|---|---|
| High | **APK size:** the latest built universal APK is 407.59 MiB; images account for about 80%. The asset audit identifies 641 required files and zero unused candidates. | Optimize a small representative set of backgrounds, mascots, and word images first: appropriate resolution and an Android-compatible compressed image format. Compare transparency, edges, text, and animation quality on a phone before converting the rest. Update asset inventories and verify the rebuilt APK. More deletion alone will not solve the size problem. |
| High | **Save failure recovery:** [AppProvider.save](lib/providers/app_provider.dart) and [ScreenTimeService.save](lib/services/screen_time_service.dart) append writes using `.then` to a shared future. A rejected save prevents later queued writes from executing. Preference write return values are ignored, and screen-time save bookkeeping is updated before successful completion. | Recover the queue after failures while reporting the failed operation; check write results and retain retryable snapshots. Add a regression that forces one failed write, then verifies the next save and restart. Reduce redundant full-history writes. Preserve existing data migration behavior. This is a code-level failure-path risk; no actual storage failure was observed. |
| High | **Speech matching accepts different words:** [Speak & Recognize](lib/screens/voice_recognition_screen.dart) accepts edit distance <= 1 even on Hard. For example, target `cat` and recognized `bat` pass that rule. Easy also accepts a recognized substring of the target. | Use word/token-aware matching and avoid counting a different valid word as correct. Test short words, extra words, and one-letter changes separately. Keep the existing explanation that recognition is not a pronunciation score. Actual microphone results were not tested here. |
| High | **New-letter practice skips teaching:** the letter-tap handler in [Progress](lib/widgets/progress_journey_view.dart) opens Quick Check for every status, including Not Started. | Let new/viewed letters open their lesson first, with the existing letter/sound/word buttons; keep assessment available for practiced letters. Verify navigation and saved status for each state. This is a learning-flow recommendation, not a crash. |
| High | **Mastery scope is broader than the evidence:** the current [Quick Check question factory](lib/models/mastery_question.dart) assesses initial spelling, vocabulary, and heard-word identification. [Quick Check](lib/screens/letter_mastery_check_screen.dart) uses these questions to award general letter mastery at 4/5. A `soundLetter` enum name does not make its spelling prompt an isolated phoneme assessment. | Clarify the mastery label or add separate evidence for letter recognition, sound recognition, and word application. Review short-vowel mastery separately. Keep the supplied vocabulary and recordings; validate assessment content before changing scoring. |
| Medium | **Speech permission/service recovery:** denial sets initialization complete; later Listen attempts do not initialize again. The locale is fixed to `en_US`. Recognition errors mostly clear the listening indicator. | Add an explicit retry/reinitialize action, a settings route when permission is permanently denied, and selection from supported English locales. Show an actionable unavailable-service message. Test denial, settings grant, missing/offline language support, and retry. |
| Medium | **Speech lifecycle:** recognition callbacks check mounted state and request generation, but not foreground/current-route state; the screen does not observe lifecycle changes to invalidate a listening request. | Stop/invalidate listening when backgrounded or covered, and ignore late callbacks. Check backgrounding, Leave confirmation, and time-limit interruption with a mocked service and on Android. Engine-specific behavior needs device validation. |
| Medium | **Speech activity is missing from parent totals:** local attempts and rewards update in Speak & Recognize, but its answer/completion handlers do not call the provider's daily-answer/activity-completed methods. | Track speech practice and completion explicitly, with a separate metric if needed. Avoid mixing approximate recognized-word matching into phonics accuracy without clear labels. Check that parent totals, streaks, and rewards describe the same saved practice. |
| Medium | **Broad rebuilds every second:** [screen-time tick](lib/services/screen_time_service.dart) notifies listeners every second; multiple screens watch the whole AppProvider, including [Games](lib/screens/games_screen.dart) and Progress. | Use selectors or separate screen-time state so the clock/limit can update without rebuilding every card/chart. Profile first and compare frame timings on the same device; this review did not measure device lag. |
| Medium | **Unreachable implemented screens:** runtime searches find definitions but no construction of [Sound Position](lib/screens/sound_position_screen.dart), [Tricky Letters](lib/screens/tricky_letters_screen.dart), and [Journey Lesson](lib/screens/journey_lesson_screen.dart). | Decide which activities belong in the learning path and connect those entry points. Retire the others only after checking their data, tests, and asset references. No additional source/assets were deleted in this review. |

## Measured APK contents

Measurements use compressed ZIP entry sizes from the existing `build/app/outputs/flutter-apk/app-release.apk`, version 1.0.6+7. ZIP structure/metadata account for the small difference between summed entries and file size.

| Content | Entries | Compressed size |
|---|---:|---:|
| Images | 324 | 327.86 MiB |
| Audio | 308 | 26.42 MiB |
| Native libraries | 12 | 51.12 MiB |
| Other | 410 | 1.90 MiB |
| APK file | | **407.59 MiB** |

An app bundle or architecture-specific APK can reduce native-library delivery, but the image assets dominate this build. Do not promise a target size until a conversion/build benchmark establishes it. If compressing lesson narration, listen for intelligibility; short educational phoneme recordings need particular care. [Existing APK verification](tools/latest_apk_verification.json) records the asset/hash validation for this build.

## Further improvements worth testing

- **Pictorial instructions:** generated game narration remains removed, as requested. Add small visual demonstrations for games that currently depend on reading instructions. Preserve the existing Flappy/Memory/Builder tutorials and recorded letter/word sounds.
- **Consistent feedback:** retain automatic Quiz progression. Review other games' retry/advance behavior; Sound Match currently advances after a wrong response, which may leave children unsure of the correct choice. A brief visual correction before advancing could help.
- **Calmer motion:** most shared artwork already respects system reduced motion. An optional parent motion setting could reuse that behavior while preserving the requested mascots and completion celebrations.
- **Animation memory:** [AnimatedScreenArt](lib/widgets/animated_screen_art.dart) preloads several backgrounds, with bounded decode width. Measure memory with the other animated word/mascot images on a low-memory phone before increasing frame counts or preload scope.
- **Accessible parent controls:** the Parent header Back button has a 42-by-42 fixed size; increase its target to match the app's common 48-by-48 controls. Review small activity labels, contrast, TalkBack announcements, and large-text layout on Android. Existing widget layout checks are useful but do not establish device accessibility.
- **Audio balance:** compare recording loudness, button clicks, and letter feedback on the same phone speaker. Current controls separate voice, effects, and music, but only music has a volume slider. Consider an effects slider if individual users still find clicks loud. No listening-quality claim is made from source inspection.
- **Persistence/export:** optional parent-controlled local progress export/restore would help with phone changes and reinstalls. Include versioned validation and explicit import/reset behavior before adding it.
- **Content progression:** use saved needs-practice information to guide existing lesson/game entry points. Keep rewards separate from mastery, and avoid adding duplicate Home controls to the current requested layout.
- **Session variation:** shuffle bags already reduce repetition within a running app. If repetition across restarts is a problem, persist a small recent-item history; retain deterministic content tests.
- **Maintainability:** split the large shared learner widget file and content factories into focused components when modifying them. Prefer incremental extraction with regression coverage over a broad rewrite.
- **Distribution readiness:** release currently uses the development debug signing configuration and placeholder application ID. Before public distribution, plan production signing and installation/data continuity. This does not block local testing of the existing APK.

## Suggested implementation order

1. Reliability: save-queue recovery, speech matching/recovery/lifecycle, and remaining completion-dialog interruption paths.
2. Size and smoothness: benchmark representative image optimization, rebuild/verify assets, then profile and limit unnecessary Provider rebuilds.
3. Learning experience: lesson-first routing, clearer mastery evidence, pictorial instructions, and consistent retry feedback.
4. Device validation: complete the manual checklist on the lowest-spec target Android phone; then finalize release signing and delivery.

## Verification

- Five new lifecycle regressions failed against the relevant prior behavior and passed after the fixes.
- Focused lifecycle and existing Word Builder audio checks: **6 passed**.
- Final analyzer: **No issues found**.
- Final full suite, including the required-asset audit: **349 tests passed**.
- Required-asset audit is included with `flutter test --dart-define=AUDIT_ASSETS=true --reporter expanded`.
- Device/emulator execution, microphone recognition, listening review, and performance profiling were not performed in this review. Remaining recommendations are not reported as implemented.

Local validation logs are under ignored `build/`: `app_review_final_tests.log`, `app_review_final_analysis.log`, `app_review_focused_tests.log`, and the before-fix lifecycle logs.
