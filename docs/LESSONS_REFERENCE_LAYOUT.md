# Lessons reference layout

The Lessons menu uses the existing classroom images with centered `BoxFit.cover`
and the existing transparent letter, vowel, cat, and blending artwork. No original
image was edited or regenerated. Two previously retired transparent illustrations
are copied unchanged into `assets/images/lessons_menu/` to replace leafy card
backgrounds. The header spells Lessons with the existing 3D letter assets over
the wooden base; Back and the editable selected profile occupy opposite corners.

Five equal cards stay in two columns, with Blending Sounds centered below the
first four. Heights adapt to the available viewport; small screens, landscape,
and large text scroll to preserve readable labels. The existing wooden navigation
component stays outside the scroll area and respects the bottom SafeArea.
Its Home button represents the Home/Lessons branch. Other buttons return to the
retained main tabs through the existing navigation scope.

Letter cards use the current saved Quick Check/Letter Adventure mastery, including
the existing assessment policy. Viewing or listening does not award mastery.
CVC and Blending previously had no per-word persistence. They now save unique
completed words through the existing AppProvider snapshot/write queue under
`wordLessonProgressV1`, cleared by the existing parent-authorized reset.
CVC shows **Practiced** after finishing the guided sequence; Blending shows
**Completed** after solving and finishing the blend. These are not presented as
assessed mastery. Totals come from the actual catalogs (17 CVC and 22 Blending),
not the sample numbers in the reference. Replaying does not duplicate progress
or award new XP/stars. Start changes to Continue after an activity is entered.

The existing lesson destinations, audio sequences, and reward rules are retained.
Cards and header controls use a subtle 0.97 press animation; lesson entry uses
the existing 300 ms fade, respecting reduced-motion preferences.

Tests cover phone/tablet portrait and landscape layouts, large text, equal card
geometry, complete card reachability, profile editing, assessed mastery refresh,
word completion and persistence, replay deduplication, corrupt saves, reset,
all five destinations, press feedback, rapid taps, and retained main navigation.
Run `flutter test test/lessons_reference_test.dart --dart-define=CAPTURE_UI=true`
to also create previews under `build/ui_previews/update_lessons_reference_*.png`.
