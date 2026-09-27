# Improvement #3: Parent protection and daily screen time

Implemented within the existing Flutter application. Phonics content, mastery rules, recordings, game images, and analysis rules were not changed. All new parent-control operations use local storage without accounts or network requests.

## Files created

- `lib/services/parent_auth_service.dart` — PIN validation, salted hashing, verification, cooldown, in-memory session, PIN changes.
- `lib/services/screen_time_service.dart` — the single daily usage clock, persistence, warnings, calendar rollover, protected limits and temporary allowances.
- `lib/widgets/parent_pin_form.dart` — masked numeric setup, login, and change-PIN forms.
- `test/parent_controls_test.dart` — 17 service/provider tests.
- `test/parent_controls_widget_test.dart` — 4 UI/navigation/lifecycle tests.
- `PARENT_CONTROLS_REPORT.md` — this report and device verification checklist.

## Files modified

- `lib/main.dart` — installs the limit guard above the application's Navigator.
- `lib/providers/app_provider.dart` — owns the authentication and screen-time services; enforces authentication for game settings and progress reset; removes the old session timer.
- `lib/screens/home_screen.dart` — removes the obsolete Home-only timer startup.
- `lib/screens/parent_screen.dart` — gates the entire panel with the PIN, displays actual daily usage, adds limit selection and Change Parent PIN, and retains confirmation before progress reset. Leaving the panel ends authentication. The panel no longer pushes learner screens over an authenticated parent visit.
- `lib/screens/games_screen.dart` — checks game access at the screen and launch callbacks, including entry from other navigation tabs.
- `lib/widgets/time_limit_overlay.dart` — full-app blocking screen, PIN unlock, temporary allowance UI, visual warnings, lifecycle observation, and parent-session expiry.
- `pubspec.yaml` and `pubspec.lock` — makes `crypto` a direct offline hashing dependency.
- `test/learning_progress_test.dart` — existing reset tests now authenticate first; mastery assertions remain intact.

Verification artifacts: `parent-analyze.log`, `parent-tests.log`, and `parent-widget-tests.log`. Flutter also regenerated its normal ignored build/package metadata. The old test asset output was preserved as `build/unit_test_assets_before_parent_controls` because its existing Windows permissions prevented Flutter from replacing it; tests ran successfully with a fresh `build/unit_test_assets`.

## PIN storage and parent authentication

`parentPinHashV1` stores a randomly generated 24-byte salt and a SHA-256 digest of the salt and PIN, in one local SharedPreferences value. The PIN itself is neither stored nor logged. There is no master PIN, recovery question, or online recovery.

First access requires two matching four-digit entries. `0000`, `1111`, `1234`, `4321`, nonnumeric values, and incorrect lengths are rejected. Subsequent visits require the saved PIN. Five consecutive wrong entries impose a 30-second cooldown, including current-PIN checks when changing it. Successful verification clears the failure count. Failed attempts remain in memory across panel visits; restarting the process clears the cooldown.

Authentication exists only in memory. It ends when leaving Parent Panel, completing/cancelling the extra-time flow, closing the process, or remaining outside the resumed lifecycle for one minute. Service/provider methods independently check authentication, so a different UI route cannot directly mutate protected limits, allowances, games, PIN, or learning progress.

Change Parent PIN requires the current PIN plus a valid matching replacement. Existing sessions do not allow a parent to skip current-PIN verification.

## Daily screen-time calculation

One service measures foreground elapsed time using a monotonic Stopwatch; a one-second timer refreshes the UI and evaluates the cap. Usage is tracked even when the daily limit is disabled. Authenticated parent time and time spent on the blocked screen are excluded.

Local keys include `screenTimeDateV2`, `screenTimeUsedSecondsV2`, `screenTimeLimitEnabledV2`, `screenTimeLimitMinutesV2`, `extraTimeSecondsTodayV1`, `limitBypassDateV1`, and `screenTimeWarningsV2`.

Changed usage is saved every ten seconds, at lifecycle pauses, at the cap, at parent-session changes, and when settings or allowances change. Saves are serialized to prevent an older snapshot overwriting a newer one. Ordinary closing/reopening preserves the day's usage. A sudden process kill or power loss can lose the most recent checkpoint interval and a fractional second; this is not an OS-level tamper-proof timer.

Only `resumed` starts tracking. `inactive`, `hidden`, `paused`, and `detached` pause and save; background elapsed time is not added on resume. The service cancels its timer when paused or disposed and does not create duplicate timers on rebuilds.

The local `YYYY-MM-DD` date is checked at construction, resume, and foreground ticks. A different calendar date clears daily usage, extra allowance, bypass, and warning flags. A tick crossing midnight counts only its new-day portion. The configured limit and PIN remain unchanged. Values are clamped and missing/wrong-type screen-time preferences fall back to defaults.

The configured default is 30 minutes. The existing disabled/enabled preference is migrated from `timeLimit`; a fresh installation retains the previous app's default of limit disabled until a parent enables it. Available limits are 15, 30, 45, 60, and 90 minutes.

Parent Panel shows real used/allowed minutes, remaining minutes, a clamped progress bar, and whether the limit is off globally or for today. Warnings appear briefly at five minutes and one minute remaining, once per local day per threshold, with flags surviving restarts.

## Blocking and temporary extra time

The full-screen guard sits above every normal route and dialog, excludes underlying pointer/focus/semantic access, and uses a non-poppable blocking route. Back navigation cannot expose usable learner content while the cap is reached. Parent Unlock verifies the PIN before displaying Add 10/15/30 Minutes, Disable Limit for Today, and Cancel. Exit requests the platform to close the app.

Extra minutes are added to today's allowance and persisted. For example, 30 configured minutes plus 15 extra allows 45 today; tomorrow returns to 30. Disable Limit for Today stores today's date and leaves the configured enabled setting untouched. Both expire automatically at the next local calendar date. Cancelling does not grant time.

Games disabled by a parent show “Games are turned off by a parent.” Core lessons and five-question mastery checks remain available within the screen-time allowance.

## Progress reset stays separate

Reset calls the existing learning-only `resetProgress()` after authenticated access and explicit confirmation. It clears learning/mastery, activity, XP, stars, streak, and the learning completion flag. It preserves the PIN, daily usage, daily limit configuration, temporary allowances, game access, and sound/voice preferences. Reset cannot be used to get a fresh daily timer.

## Verification results

- `flutter test`: **51 tests passed**, including the 21 new parent-control tests and all existing content/mastery/progress tests.
- `flutter analyze`: **0 errors, 2 warnings, 131 info notices**; exit code 1 because existing analyzer findings remain. The warnings are the unused `dart:math` import and unused `endpoints` variable in `tools/generate_icon_png.dart`. Existing notices include deprecated `withOpacity`, const suggestions, and developer-tool print calls. New parent-authentication, screen-time, PIN-form, and parent-control test files have no analyzer findings. `analysis_options.yaml` was not weakened.
- The earlier `correction-verified-analysis.log` already records these unrelated warnings/notices; source locations may shift after formatting.
- Service tests cover fresh setup/invalid PINs, login, current-PIN replacement, cooldown, protected mutations, 8/20/30-minute persistence, background exclusion, regular checkpoints, cap clamping, midnight rollover, extra-time/bypass persistence and expiry, parent-time exclusion, warning persistence, corrupt time preferences, and reset preserving settings.
- Widget tests cover first-time setup, a deeply pushed route and system back at the cap, wrong/correct PIN unlock, granting 15 minutes, background session expiry, panel-exit expiry, and direct Games-screen access when disabled.
- Tests use local SharedPreferences mocks and do not require a server. Real-device airplane-mode, phone-lock, and force-close checks were not performed in this environment.

## Remaining limitations and device checklist

1. A parent must complete the initial PIN setup before handing the app to a learner. As requested, the first person opening Parent Panel on a fresh installation can create the PIN.
2. There is no in-app forgotten-PIN recovery. Keep the PIN somewhere safe. Clearing Android app storage or reinstalling may remove local learning/settings data and is not a selective PIN reset; Android backup/restore behavior can also affect what is restored.
3. A manually changed device date/time can affect daily rollover. Clearing app data, modifying app storage, rooted-device access, and repeated forced termination are outside this practical offline protection model. A salted four-digit PIN is not a substitute for device security.
4. SharedPreferences persistence is best effort; a hard kill can lose roughly ten seconds since the previous completed checkpoint. Cooldown is intentionally not persisted between process restarts.
5. On an Android device, finish acceptance checks in airplane mode: set a PIN, enable 15 minutes, verify the five-/one-minute warnings, reach the block inside a game and lesson, press Android back, reopen the app, verify wrong/correct unlock, add time, and restart again. Check Home/screen-lock background exclusion and one-minute parent-session expiry. Verify next-day reset and learning reset preserving settings. These manual hardware checks remain outstanding.
