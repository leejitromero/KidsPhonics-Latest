# Full-screen category scenes

Lessons, Games, Progress and Parents now give their content the full safe display
height. The fixed profile/navigation footer and separate help-button row are
removed. Their 52-pixel floating menu opens navigation, profile editing and the
Lessons/Games guide when needed. Home still has no category navigation.

All three time-of-day backgrounds reach the entire display, outside SafeArea.
They use `BoxFit.fill` to display every part of the supplied image without
cropping; this adjusts the artwork proportions to the display's aspect ratio.
Interactive content and the floating control stay clear of system insets.
The transparent Android system bars retain the existing edge-to-edge setup.

Progress shows the chosen character and name in its scrollable content. Category
lists have a bottom scroll inset so their final action can move above the menu.
Navigation still respects parent game restrictions, and the parent PIN remains
required. The existing day-cycle timing, classroom entry and cloud transitions
are preserved.

Verification covers screen bounds, navigation, profile persistence, card access,
Quick Check progress and parent PIN/settings. Rendered category previews are in
`build/ui_previews/update_*Screen_390.png`. This update is included in
[release 1.0.18 / build 19](RELEASE_1_0_18.md).

All 91 distinct scoped regression checks passed: 52 category/navigation,
parent/progress checks and 39 screen-layout checks. The nine scene-bound checks
were also rerun with explicit full-background and no-cropping assertions.
Flutter analysis found no issues. Logs: `build/category-fullscreen-tests.log`,
`build/category-fullscreen-bounds-tests.log`,
`build/category-fullscreen-layout-tests.log` and
`build/category-fullscreen-analysis.log`.
