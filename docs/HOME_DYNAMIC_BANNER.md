# Dynamic Home banner

The original `banner_tittle.png` is retained at
`output/banner_tittle_source.png`. Its logo, blank wooden panel and reward icons
are separate transparent PNGs in `assets/images/home_banner/`. The extraction
script uses silhouette alpha masks and keeps the original RGB pixels; it does
not regenerate, resize, recolor or paint text onto the artwork. Source rectangles
and hashes are recorded in `tools/home_banner_extraction.json`.

`HomeProgressBanner` displays independent Flutter text and the existing selected
character portrait. `HomeScreen` supplies the saved name, character, recommended
Adventure letter, XP, Stars, level and learning streak from `AppProvider`.
The profile section opens the existing character picker. Decorations retain
their aspect ratios, and long names use an ellipsis before the decorative star.

The recommendation remains selected across retries and unrelated activities.
When `AdventurePolicy.passes` grants mastery, the existing recommendation ranking
selects another unmastered letter. Completing all letters displays Review
letters. A single nullable `recommendedAdventureLetterV1` preference stores the
current target in the existing authoritative save snapshot. Older saves migrate
using their existing ranking; progress reset clears that selection.

Rewards, XP-derived levels, local-calendar streaks, completion counts and result
deduplication continue through the existing activity completion methods and
serialized SharedPreferences save queue. The banner only reads these values.
No database or duplicate activity records were added.

Run `flutter test test/home_progress_banner_test.dart` for asset transparency,
original pixel checks, immediate reward/profile changes, failed versus successful
mastery, duplicate submission, reopen persistence, completed alphabet, large
totals/names/text and phone/tablet layout checks. Add
`--dart-define=CAPTURE_UI=true` to save previews in `build/ui_previews/`.

Re-extract the supplied artwork with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/extract_home_banner.ps1
```
