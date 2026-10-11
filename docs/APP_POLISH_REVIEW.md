# App polish review — 10 October 2026

Parents Overview now keeps the weekly summary, next Quick Check and a link to detailed Progress. The decorative welcome card, Overall Letter Mastery panel, duplicate learning summary and A–Z status cards were removed. The 390×844 preview fits the entire overview without scrolling; small screens and enlarged text can still scroll.

Fixed issues:

- Quick Check launched from Parents retained parent authentication, which excluded learner practice from screen time and left parent access unlocked. Leaving Parents for Quick Check or detailed Progress now ends parent access immediately before opening the route. Returning requires the PIN, and learner activities reached through Progress also count toward the daily limit.
- Reset confirmation reported success even when storage writes failed. Reset now reports whether its snapshot saved and displays a pending-save message when Retry is needed.
- A failed initial preference read left startup waiting with no recovery path. Startup now shows Retry, leaves saved data untouched and starts learner tracking after a successful retry.
- Sound Match's difficulty preview counted the old choice pool. It now correctly describes three visible letter choices at every difficulty.

Review covered startup and offline resources; Home, lesson and game navigation; dialog and rapid-tap guards; audio cancellation and playback completion; microphone denial and late recognition results; timers and backgrounding; scoring, rewards and saved progress; PIN access, screen-time limits and storage failure recovery; layouts on 320×568, 390×844 and tablet sizes, enlarged text and reduced motion; and asset existence/decoding.

Full analysis found no issues and the final full suite passed 504 tests. The final parent-session adjustment was verified with 8 further passing tests. Results are recorded in `../tools/app_polish_verification.json`. The corresponding logs are under ignored `build/`. Layout captures are under `build/ui_previews/`; `parent_compact_overview.png` shows the simplified Parents screen.

Device checks remain separate from automated verification: microphone permission and recognition availability, real speaker playback, foreground/background transitions, installation over the prior APK, and animation performance on a low-memory Android phone. Use `../MANUAL_TEST_CHECKLIST.md` and record the device/build actually tested. No new APK was produced as part of this source review. The subsequent APK delivery is recorded in [release 1.0.12 notes](RELEASE_1_0_12.md) and its separate release verification report.
