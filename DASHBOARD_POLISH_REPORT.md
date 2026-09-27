# Improvement #4 — Progress and Parent Dashboard

Implemented in the existing offline Flutter app. No new package, network service, preference key, or migration was needed. Parent authentication, PIN hashing, screen-time tracking, phonics content, mastery passing rules, audio, speech recognition, and game images were preserved.

## Created files

- `lib/models/weekly_learning_summary.dart`: immutable seven-day window with dated daily entries, totals, accuracy, and achievement presentation model.
- `lib/widgets/dashboard_widgets.dart`: shared dashboard cards, rewards, streak, recent daily history, and the display-only parent screen-time summary.
- `test/dashboard_statistics_test.dart`: 15 calculation/provider tests.
- `test/dashboard_widgets_test.dart`: 11 UI tests, including six responsive-layout combinations.
- `DASHBOARD_POLISH_REPORT.md`: this audit and implementation report.

## Modified files

- `lib/providers/app_provider.dart`: canonical A–Z statistics, percentage, vowel count, Needs Practice, recommendation, weekly summary, and evidence-based achievement getters.
- `lib/screens/progress_screen.dart`: learning-first child dashboard with separate recommendation, letter grid, rewards, and activity sections.
- `lib/screens/parent_screen.dart`: reordered protected dashboard, detailed summary, activity/history, rewards, screen time, controls, and separate destructive-data section. Existing PIN gates, session exit, current-PIN change flow, and reset confirmation remain.
- `lib/widgets/learning_progress_widgets.dart`: consistent status legend/grid, letter detail dates and labels, weighted accuracy displays, shared weekly window, bounded Needs Practice list, and deterministic recommendation.
- `test/widget_test.dart`: updates the empty-week wording and verifies both explicitly labeled no-attempt accuracy fields.
- `test/parent_controls_widget_test.dart`: expects the new learning-summary section after successful setup instead of the formerly higher screen-time section; security assertions remain.

Verification output: `dashboard-analyze.log`, `dashboard-tests.log`, and `dashboard-widget-tests.log`. The full-suite log contains the final passing results; the focused widget log records an earlier iteration. Ignored `.dart_tool/dashboard_baseline/` contains the source/analyzer snapshots used for comparisons. Flutter regenerated its normal ignored test outputs.

## Statistics audit

| Display | Single source | Meaning / correction |
| --- | --- | --- |
| Mastered / Practiced / Viewed / Not Started | Existing `LetterProgress.status`, through `AppProvider.allLetterProgress` | Mutually exclusive current states for exactly A–Z; sum is 26. |
| Phonics Mastery | `AppProvider.masteryPercentage` | Mastered count only, independent of XP. |
| Vowel Progress | `AppProvider.masteredVowelCount` | Existing mastery of A, E, I, O, U; no separate storage. |
| Letter Practice Accuracy | `AppProvider.letterPracticeAccuracy` | Weighted ratio of correct letter answers to letter attempts, including quick-check attempts. |
| Overall Activity Accuracy in parent learning summary | `AppProvider.overallActivityAccuracy` | All recorded scored answers in `DailyActivity`, including games and letter checks; lifetime scope stated beside the summary. |
| Weekly bars and weekly totals | `AppProvider.getWeeklySummary()` | Same seven dates for questions, correct answers, completions, and accuracy. Replaces the old lifetime accuracy beside a weekly graph. |
| Needs Practice | `AppProvider.lettersNeedingPractice` | Attempted, unmastered letters, sorted by lowest accuracy. |
| Recommended Next | `AppProvider.recommendedNextPractice` | Deterministic priority from existing letter progress. |
| Current learning streak | Existing `AppProvider.streak` | Existing consecutive-learning-day logic; no independent UI calculation. |
| XP / Stars / Level | Existing provider getters | Rewards only; level remains `floor(XP / 200) + 1`. |
| Learning achievements | `AppProvider.learningAchievements` | Existing genuine mastery milestones plus a provable three-day learning streak. XP-only badge removed. |
| Recent Activity | Same weekly summary's dated daily entries | Actual daily totals only; no invented game names or event history. |
| Today's Screen Time and allowance | Existing `ScreenTimeService` getters | Actual active app use, separate from learning performance. |
| Games / limit / audio preferences | Existing protected provider/service settings | Only editable inside authenticated Parent Panel. |

## Child Progress screen

The first section is Learning Progress: mastered letters out of 26, a progress bar, Phonics Mastery percentage, and vowel mastery. A short recommendation follows. The A–Z grid retains exactly Not Started, Viewed, Practiced, and Mastered, with different Material icons, colors, a legend, semantic labels, and tooltips.

Tapping a letter shows its current status, attempts, correct answers, Letter Practice Accuracy, Best Quick Check, and a full local mastery date including year when a valid timestamp exists. No attempts show “No attempts yet”; an untaken check shows “Not taken yet.” Invalid/missing mastery timestamps are omitted.

Rewards has XP, stars, level, and achievement descriptions, while Activity displays the real current streak. Detailed accuracy totals and parent controls stay out of the child's main overview. Empty/all-mastered states use encouraging wording.

## Parent Panel

The authenticated panel now uses this order:

1. Child Learning Summary, including current status counts, percentage, vowels, distinct lifetime accuracies, and expandable A–Z details.
2. Needs Practice and Recommended Next.
3. Weekly Activity, current streak, matching weekly totals, and expandable recent daily history.
4. Rewards.
5. Today's Screen Time.
6. Parent Controls, including Games Enabled/Disabled, daily limit, sound preferences, and Change Parent PIN.
7. Data / Reset, separated from routine statistics and still requiring confirmation.

The screen-time presentation uses configured limit, extra minutes, allowed seconds, remaining seconds, and usage directly from `ScreenTimeService`. With a normal active limit it shows used/allowed minutes and the bar. With today's bypass or the global limit disabled, it shows actual used minutes and the disabled status without implying that a finite allowance is still enforced. Configured and extra time remain explicitly labeled.

Cards stay within 720 logical pixels on wider devices. Wrapping rewards/status counts, adaptive grid columns, scrollable dialogs, and expandable details keep phone layouts readable.

## Exact formulas and selection rules

- **Mastery percentage:** `clamp(masteredLetterCount / 26 * 100, 0, 100)`. Display rounds to the nearest whole percent; the bar uses the unrounded ratio.
- **Letter Practice Accuracy:** `sum(A–Z correctAnswers) / sum(A–Z attempts)`. Returns null when total attempts is zero.
- **Overall Activity Accuracy:** `sum(all stored DailyActivity.correctAnswers) / sum(all stored DailyActivity.questionsAnswered)`. Returns null with zero questions.
- **Weekly Activity Accuracy:** `sum(correctAnswers in the displayed seven days) / sum(questionsAnswered in those same days)`. Returns null with zero questions, displayed as “No activity yet.”
- **Accuracy formatting:** a non-null ratio is displayed as a rounded whole percentage, clamped to 0–100%. It is not an average of individual percentages. A genuine zero after scored attempts is 0%; absence of attempts is never presented as 0%.
- **Needs Practice:** `attempts > 0 && !mastered`, ascending letter accuracy, then alphabetical order for ties. Shows at most five initially, with View All when more exist. Viewed-only and Not Started letters are excluded.
- **Recommended Next:** first Needs Practice letter; otherwise first alphabetically Viewed letter; otherwise first alphabetically Not Started letter. No recommendation is invented if all letters are mastered.
- **Seven-day window:** construct local calendar dates with `DateTime(today.year, today.month, today.day - 6 + i)` for `i = 0..6`; look up each existing local `YYYY-MM-DD` key, filling genuinely missing dates with zero activity. This handles month/year/leap boundaries without subtracting fixed 24-hour intervals. “This Week” explicitly says “Last 7 days”; it is a rolling window, not a Monday-based week.

## Achievement consistency and preservation

Mastery achievements retain the app's existing 1, 5, 13, and 26 thresholds and its existing once-per-crossing milestone events. They come from persisted genuine mastery, never screen visits, XP, or legacy viewed-letter migration. Keeping 13 preserves the existing Halfway There milestone.

The three-day achievement is derived from stored days with at least one scored question. Three consecutive local calendar ordinals prove it was earned. Unlike the former current-streak-only badge, it stays earned after a missed day while that historical evidence remains. Rebuilding or reopening does not award anything again, and no duplicated achievement flag is stored. Learning reset clears the underlying evidence and therefore the badge. The XP Hunter dashboard badge was removed; existing audio implementations/assets were untouched.

All new statistics are derived from existing progress. No SharedPreferences keys were added, renamed, or migrated. Checksums confirmed that `parent_auth_service.dart`, `screen_time_service.dart`, and `models/learning_progress.dart` are unchanged. Existing protected reset still preserves PIN, parent preferences, and daily usage; derived dashboard values immediately return to their empty states.

## Verification

- **`flutter test`: 77 tests passed, exit code 0.** Includes all 51 prior tests and 26 new dashboard tests.
- **`flutter analyze`: 0 errors, 2 warnings, 131 info notices; exit code 1.** Findings match the pre-change analyzer snapshot after normalizing shifted line numbers. The two existing warnings are an unused import and unused local variable in `tools/generate_icon_png.dart`. No new dashboard warning/error/lint was introduced, and `analysis_options.yaml` was not changed.
- Calculation tests cover fresh/reset state, status exclusivity, 13/26 mastery, weighted accuracy, no attempts, Needs Practice selection/ties, recommendation priorities, full mastery, exact weekly boundaries, empty/completion-only activity, leap/year transitions, rewards independence, and historical streak evidence.
- UI tests cover letter details and date display, weekly-versus-lifetime accuracy, real daily history, service-backed usage/extra-time/bypass display, top-five/View All, and immediate reset updates.
- Both screens were scrolled and checked for Flutter layout errors at **320×568, 390×844, and 800×1024**, each at **1.3× text scale**. All six combinations passed.
- Existing PIN, unlock/back blocking, time persistence, background exclusion, temporary allowance, mastery, phonics-content, and progress tests remain passing.

## Known limits

- Layout verification used Flutter widget tests, not a physical Android device or Android accessibility reader. A final visual/touch check on the target phone remains useful.
- Existing storage contains daily aggregates, not individual game/event history. Recent Activity intentionally reports only those aggregates.
- Values reflect the local stored record. This change does not reconstruct missing historical activity or add clock-tampering protection. Existing offline PIN and screen-time limitations remain as documented in `PARENT_CONTROLS_REPORT.md`.
