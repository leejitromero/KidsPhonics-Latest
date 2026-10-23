# Home village redesign — 11 October 2026

Home now uses four equal category houses: Lessons and Games above Progress and Parents. Doors are closed and mascots are absent by default. The existing floating-island sky and KidsPhonics logo remain, with a softly shaded lawn, stone walkways and a small star fountain. Flutter paints the houses, sculpted roof tiles, cream walls, beveled door frames, lanterns and doors; raised wooden signs identify each category.

Official Home mascot mapping:

| Category | Supplied image | Bundled asset |
| --- | --- | --- |
| Lessons | `lesson_mascot.png`, purple with notebook/pen | `assets/images/home_village/lessons.png` |
| Games | `game_mascots.png`, blue with headset/controller | `assets/images/home_village/games.png` |
| Progress | `progress_mascot.png`, orange with trophy | `assets/images/home_village/progress.png` |
| Parents | `parent_mascot.png`, green with glasses/book | `assets/images/home_village/parents.png` |

All four PNGs were copied unchanged and checked against the supplied files. Transparency and aspect ratios are preserved. The reference `h.png` directs the layout; it is not used as a flattened screenshot underneath tappable overlays.

`lib/data/home_village.dart` centralizes category presentation and the visit timeline. `CategoryHouse` composes the house, doorway, emerging mascot and hinged door. `HomeVillageMenu` owns the two-row layout; `HomeVillageFooter` and `HomeVillageNavigation` provide the compact summary and five-item Home navigation bar. `lib/screens/home_screen.dart` retains route selection, existing intro and welcome audio, provider reads and lifecycle handling.

A tap starts one 1.05-second visit: the house lifts, the doorway glows, the door swings open, and the correct mascot emerges and rocks in greeting. The existing supplied category recording begins at the doorway. The normal route transition follows, keeping the interaction around 1.35 seconds. Other controls remain disabled during the visit and route opening. Backgrounding cancels an unfinished visit. Returning closes every door. Reduced motion skips the visit and route animation; voice and sound preferences remain effective.

The summary reads the existing recommended adventure letter, last Quick Check result, Level, Stars and XP. Continue opens the same Quick Check as before. The navigation bar opens the existing category screens and respects disabled Games and the Parents PIN. This change introduces no preference keys, resets or data migrations. Other category screens are not redesigned, and first-launch onboarding remains future work; the shared timeline can support it later.

Verification: 83 focused regression checks passed, and full Flutter analysis found no issues. Coverage includes four doorway destinations, five-item navigation, voice/mute and lifecycle behavior, progress persistence after remount, parent access, asset decoding/transparency, enlarged text, system SafeArea and layouts at 320×568, 390×844, 430×932 and tablet sizes. The two medium portrait layouts fit without scrolling; short screens and enlarged text can scroll without overlapping the fixed navigation bar.

Preview captures: `build/ui_previews/home_village_390.png` and `home_village_lessons_welcome.png`. Generate them with `flutter test test/home_mascot_menu_test.dart --dart-define=CAPTURE_UI=true`. Evidence is in `tools/home_village_verification.json`; logs are under ignored `build/`. The subsequent APK delivery is [version 1.0.13, build 14](RELEASE_1_0_13.md), with a separate release verification report. Physical-device checks are still separate from widget tests.
