# Home garden artwork refresh — 11 October 2026

Home now uses the supplied `bg_1.png` through `bg_4.png` as a gently blended background sequence. The two illustrated houses occupy the upper garden pads: Games on the left and Lessons on the right. Their matching blue and purple mascots remain visible and play on the corresponding lower pads. Progress and Parents are available through the existing five-item Home navigation bar.

The four background frames and two house PNGs are under `assets/images/home_village/`. All eight supplied files, including the two existing mascot PNGs, were copied and compared byte-for-byte with the user attachments. Their transparency and proportions are preserved. The supplied house illustrations include their own signs, closed doors and rooftop characters, and are displayed as complete artwork without another painted frame.

`HomeVillageScene` and `HomeVillageMenu` share the background cover geometry, so the foreground stays aligned with the supplied garden pads across screen sizes. Houses use `BoxFit.contain`. The mascot on each side stays horizontally aligned with its house. The compact saved learning summary occupies the lower path; short screens and enlarged text scroll without overlapping navigation.

`HomePlaygroundMascot` is reusable. Games hops and sways with a small star ball; Lessons has its own hop rhythm and two floating letter blocks. A shared 4.2-second controller keeps motion smooth. Animation pauses in the background and off-route, and reduced motion produces a still scene. House selection adds a short bounce and welcoming audio before opening the existing screen. Progress and Parents navigation does not wait for a house animation.

No category screen, storage key, saved progress, reward calculation, audio preference or parental control was rewritten. The existing Quick Check recommendation and Parent PIN remain in use.

Validation: 78 focused regression checks passed; full Flutter analysis found no issues. Checks cover the exact supplied assets, matching house/mascot columns, screen sizes, large text, SafeArea, animation pause/resume and reduced motion, category destinations, disabled Games, welcome voices and restored saved progress. Asset usage audit resolves 687 assets with no unused candidates.

Preview: `build/ui_previews/home_garden_390.png`. Generate captures with `flutter test test/home_mascot_menu_test.dart --dart-define=CAPTURE_UI=true`. Evidence is in `tools/home_garden_verification.json`; logs are under ignored `build/`.

This refresh is a source/UI delivery. APK version 1.0.13, build 14 records the earlier four-house design; it does not contain this subsequent refresh. Physical-device checks are separate from automated tests.
