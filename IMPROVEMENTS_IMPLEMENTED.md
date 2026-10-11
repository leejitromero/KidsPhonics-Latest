# Improvements implemented — 2026-10-07

The seven prioritized improvements were implemented in the existing Flutter app. Generated game narration and spoken praise remain absent; the supplied letter/word audio, Flappy letter feedback, Memory preview, automatic Quiz advancement, artwork, and celebrations are retained.

## Speech practice

- Recognition compares complete normalized words. Easy/Medium allow the exact target within a phrase; Hard requires that word alone. Different words such as `cat`/`bat`, partial words, and substrings do not pass.
- Denied/unavailable microphone sessions can reinitialize without reopening the game. Permanent denial offers device settings; unsupported English recognition gives an actionable retry message.
- The locale is chosen from the recognition service's available English locales.
- Listening stops when backgrounded, covered, or access is blocked; generation checks discard late recognition results. Permission prompts are allowed to finish, but microphone capture still requires foreground/current-route access.
- An injectable [speech service](lib/services/speech_practice_service.dart) supports regression tests without requiring a microphone. It adds no online speech provider. Recognition availability and offline support depend on the Android service/language installation.

## Reliable local saving

- [PreferenceWriteQueue](lib/services/preference_write_queue.dart) serializes writes, checks returned success values, retries up to three attempts, and allows subsequent saves after errors.
- Unchanged successfully written keys are skipped. App state and screen time each have an authoritative JSON snapshot, with the existing keys mirrored for compatibility. Old installations still load the previous keys. A partially updated legacy mirror cannot replace a valid authoritative snapshot.
- Failed writes leave state in memory and expose pending-save status. The Parent Panel's Retry action saves the latest progress/settings and screen time. Repeated failures are reported as pending, not claimed as persisted.
- Successful usage checkpoints are recorded only after saving; failed screen-time usage remains eligible for another save.
- Existing PIN authentication, learning reset, old-progress migration, and screen-time rules remain in place. Storage snapshots improve consistency but do not guarantee survival of unavailable/corrupt device storage.

## Lesson-first learning and clearer progress

- New/viewed letters selected from Progress or the parent recommendation open a [letter introduction](lib/screens/letter_introduction_screen.dart) with the picture and Hear Letter, Hear Sound, and Hear Word controls. Practiced/mastered letters keep direct Quick Check access.
- The supplied G/O/X sound notes remain visible so a picture's initial sound is not confused with a different introductory sound recording.
- Completed name/sound/word playback is tracked independently. Listening does not award mastery or increase answer accuracy.
- Speech attempts, recognized words, and speech completions have separate persisted daily/weekly counters. They do not inflate phonics answer accuracy; speech attempts can maintain the learning streak.
- Parent/Progress labels clarify that the existing 4/5 Quick Check covers letter and word practice. Listening counts are exposure, not independent sound-recognition mastery. No historical mastery was removed or reinterpreted as a new skill score.

## Game guidance and smoothness

- The shared How to Play system includes visual examples for all Game Zone activities, plus Sound Position's existing standalone screen. The original three first-visit tutorials are retained; additional guides are available through Help without interrupting an existing session automatically.
- Sound Match highlights and names the correct letter briefly after a wrong choice, then advances automatically. Correct-answer rewards/formulas remain unchanged.
- Picture animation is shared between lesson/game word artwork. It updates the widget tree only at discrete frame changes, reuses image widgets, keeps decode widths bounded, and pauses off-route/background or with reduced motion.
- Screen-time updates reach the global learning provider at displayed minute, day, setting, access, or save-status changes rather than on every second. Limit activation still updates immediately. Games watches game access specifically.
- The Parent header Back target now matches the app's 48-by-48 controls.

## Lossless image optimization

317 runtime PNG images were converted to lossless WebP. Dimensions and every decoded RGBA pixel were compared before replacements. Transparency is retained. Launcher input artwork stays PNG; GIF animations and all audio recordings retain their formats.

| Converted image assets | Before | After | Saved |
|---|---:|---:|---:|
| Source bytes | 323.92 MiB | 219.54 MiB | **104.38 MiB (32.2%)** |

Runtime references, dynamic paths, the game asset manifest, format/dimension tests, and asset audit were updated. Originals are retained in ignored `build/image_optimization/originals`; generated tooling/backups are excluded when sharing source. They are not packaged in the APK.

- [Per-image pixel verification and sizes](tools/image_optimization_report.json)
- [Reproducible encoding tool](tools/optimize_image_assets.py)
- [Runtime asset audit](tools/asset_usage_audit.json)

## Verification and release

- Full regression suite with required-asset audit: **375 tests passed**. After the final initial-migration write was moved onto the checked save queue, **36 targeted storage/progress/parent-control tests passed**, including the new startup-failure regression. These are overlapping runs, not 411 distinct tests.
- Final `flutter analyze`: **No issues found**.
- Flutter successfully decoded all **317** optimized images; Home transparency and background dimensions are verified by decoded-image tests.
- Asset audit: **641 required files, zero unused candidates**. APK hash verification confirmed all 641 source assets, 365 retired assets absent, and 73 cleanup entries absent.
- Final universal release APK: **1.0.7+8**, `com.example.kidsphonics`, minimum Android API 24. Android v2 signature verifies using the existing development signing configuration.

| APK | Before (1.0.6) | After (1.0.7) | Reduction |
|---|---:|---:|---:|
| Universal release | 407.59 MiB | **303.51 MiB** | **104.08 MiB / 25.54%** |

Delivery: [KidsPhonics-latest-1.0.7.apk](KidsPhonics-latest-1.0.7.apk), with [SHA-256 checksum](KidsPhonics-latest-1.0.7.apk.sha256). Build and delivery copies match.

SHA-256: `3BDE34105E271BC36DB33085FD2D4D60071EA83721EBD2ED1D16EE05AFC14F47`.

Local verification logs are under ignored `build/`: `improvements_final_tests.log`, `improvements_storage_final_tests.log`, `improvements_delivery_analysis.log`, and `improvements_final_apk_build.log`. [APK asset/hash report](tools/latest_apk_verification.json) records the built bytes and package content verification.

No Android phone or emulator was connected (`flutter devices --machine` found only desktop/browser targets). Actual microphone/speaker behavior, low-memory phone performance, TalkBack, and install/upgrade validation therefore remain unchecked in [MANUAL_TEST_CHECKLIST.md](MANUAL_TEST_CHECKLIST.md). Automated checks do not substitute for those device results.
