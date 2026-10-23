# Home navigation and game card polish

Updated 2026-10-11.

Games now show only the supplied artwork, whose frames already contain titles
and descriptions. Every game card uses the same width-to-height ratio (0.8).
The complete image fills that box without cropping; source images with different
proportions are scaled to match. The whole card opens the existing activity.
Accessible names and descriptions remain available to screen readers.

The Home navigation bar uses the five original supplied PNG buttons, copied
unchanged into `assets/images/navigation_buttons/`. The mapping lives in
`lib/data/home_village.dart`. Buttons fit five equal slots, with safe-area
padding, a selected Home indicator, and the existing parent game-access lock.

Home mascots are smaller and positioned using the background's original garden
coordinates. Each lower play area is an ellipse centered at x=235 (Games) or
x=706 (Lessons), y=1060 in the 941x1672 source image. The play area is projected
with the same cover geometry as the background. Reduced sprite dimensions and
animation allowance keep the characters inside those circles while they hop
and lean. Each category still occupies the same side as its house.

Verification: 46 focused tests passed; Flutter analysis reported no issues.
Checks cover card sizes, titles, activity routes, filters, difficulty selection,
Home navigation, saved progress, game restrictions, system insets, large text,
mascot animation containment, lifecycle pauses, and reduced motion. The asset
audit found 705 required assets and no unused candidates. Original navigation
copies and current source hashes are recorded in
`tools/home_navigation_polish_verification.json`.

Reviewed previews:

- `build/ui_previews/home_garden_390.png`
- `build/ui_previews/games_cards_390_844_1x.png`

The source update was subsequently packaged in [release 1.0.15+16](RELEASE_1_0_15.md).
The earlier 1.0.14+15 APK does not include these changes. Physical Android
testing remains pending.
