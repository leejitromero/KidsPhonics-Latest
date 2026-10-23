# Verified Home startup flow

The first setup follows this sequence with the current classroom Home artwork:

1. Loading screen reaches 100% and opens the welcome scene after its fade.
2. The KidsPhonics welcome/title chorus plays on the Home scene without a learner.
3. After actual playback completion and a 1.5-second pause, Lala explains Lessons.
4. Lulu explains Games. The speaking guide uses the supplied talking frames;
   Next is enabled after each recording finishes.
5. Character setup opens after the guidelines. The child selects boy/girl and
   enters a name; saving waits for the setup instructions to finish.
6. Saving plays the cloud transition, with input blocked under the curtain.
7. Home reveals the selected character, with Lala behind Lessons and Lulu behind
   Games. The startup chorus does not repeat during this reveal.
8. After five seconds without a touch, the selected child's automatic prompt
   plays once for that Home visit. Touch resets the pending timer. Covered
   routes, backgrounding, voice settings and time limits suppress the prompt.
9. Tapping Lessons or Games stops an idle prompt and plays the child's matching
   "Let's learn" or "Let's play" cue. The chosen character then walks at constant
   size toward that side, exits completely beyond the screen edge, and the
   destination opens with a fade. Backgrounding cancels an unfinished visit.

On subsequent launches, loading opens Home with the saved character and plays
the welcome/title chorus once. Guidelines and required character setup are
skipped after their saved completion flag. Returning from another screen does
not repeat startup audio or character setup. Names, character choices, progress
and rewards keep their existing storage keys.

Voice-off settings skip recordings while leaving the flow usable. Reduced
motion settings suppress animation without blocking setup or navigation.

## Verification

`test/home_full_flow_test.dart` exercises the complete chain from the actual
`SplashScreen`, including all ten guideline clips, setup, clouds, selected
character, the 4,999 ms / 5,000 ms idle boundary, voice before walking, and full
exit before the destination opens. Cases cover boy -> Lessons and girl -> Games.
Existing voice regressions cover all four boy/girl and Lessons/Games pairings,
interruption, muting, touches, saved startup and returning to Home.

The release check passed 78 tests across the complete flow, Home audio, startup,
layout, saved recommendations, clouds and asset audit. Flutter analysis found
no issues. Logs are `build/release_1_0_20_tests.log` and
`build/release_1_0_20_analysis.log`. Audio plugin completion is simulated by the
test harness; physical-device playback and installation are still separate
manual checks.

The release is version **1.0.20+21**. APK and packaging evidence are documented
in `RELEASE_1_0_20.md`.
