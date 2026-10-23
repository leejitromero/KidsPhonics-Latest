# Home spacing adjustment

This change only adjusts layout geometry. Artwork, colors, activity callbacks,
profile/progress storage, background cycling, walking/cloud timing and the
introduction layout remain intact.

- Lessons and Games use equal dimensions and equal outer margins (2.5% of the
  viewport, respecting system insets). Their smaller row sits lower in the play
  area, with the existing mascots aligned above the corresponding signs.
- Practice uses a smaller centered rectangle below that row, with a responsive
  gap and clearance above the fixed navigation bar.
- The student's floor anchor maps the classroom image's rug center at
  `(512, 1008)` through the existing centered `BoxFit.cover` crop. It uses the
  full background viewport rather than the shorter content area above the dock.
  On very wide displays where that point falls behind the dock, the student
  stays within the visible floor area above Practice.
- The wooden dock uses a more compact height and balanced horizontal/vertical
  padding. Four equal button targets remain inside the supplied frame. The
  existing nine-slice frame treatment, active images and press animation remain.

`HomeSceneLayout` centralizes the Home rectangles. Character destinations still
derive from the actual mascot rectangles using the existing approach algorithm.
Short screens leave horizontal clearance beside the student's shoes; the
character, signs, Practice and dock do not overlap.

Rendered previews:

- `build/ui_previews/update_custom_navigation_390.png` — phone, safe insets.
- `build/ui_previews/update_custom_navigation_768.png` — tablet, safe insets.
- `build/ui_previews/update_home_layout_girl_390.png` — selected girl animation.

Checks: `build/home_spacing_final.log`,
`build/home_spacing_navigation_final.log`, `build/home_spacing_analysis.log`
and `build/home_spacing_test_analysis.log`.
Tests verify centered rug placement on portrait phones/tablets, symmetrical
buttons, safe navigation targets, retained screen state, walking/stop/cloud
behavior, unchanged background images/fades, onboarding and saved settings.
Test helpers scroll tall content into view before tapping it. Navigation tests
load the app's real local fonts independently of screenshot capture. The
combined run passed 92 cases; the three navigation failures caused by synthetic
test-font metrics were resolved by that font setup, and the navigation suite
then passed all 10 cases. All 95 distinct scoped cases have passed.

This layout has been checked in rendered previews and automated tests; it has
not been installed on a physical device. Release **1.0.22 (build 23)** includes
these changes: `output/apk/KidsPhonics-1.0.22-build23.apk`.
Android version/signature verification passed and the certificate matches the
previous release. All 948 captured source inputs remained unchanged during the
build and all 785 bundled project assets match source. See
`tools/release_1_0_22_verification.json` and `build/home_layout_apk_build.log`.
