# Home classroom design update

The supplied `update bg.png` is imported unchanged as
`assets/images/update_scene/home_classrooms.png`. Home and first-time onboarding
draw it across the entire screen with `BoxFit.cover`, including system insets.
Only the interactive artwork uses SafeArea. The previous 600-pixel scene width
cap and scrolling background are gone. Android system bars use transparent
edge-to-edge rendering.

The lower row contains Lessons, Practice This Letter and Games buttons. Lala
and Lulu are smaller and peek out behind their corresponding buttons. Their
idle movement is a gentle bob; talking still uses the supplied separate poses.
The buttons now use the three supplied transparent PNGs, retaining their aspect
ratios. Practice has more width for its longer design. Touch targets are at
least 48 pixels tall; pressing gives a brief scale response. Saved letter
recommendations replace the baked A labels, and completed learners see Review.
Loading preloads the artwork. The imports are verified in
`tools/home_button_import_verification.json`.
The selected boy/girl uses the existing five-pose wave atlas while idle. Motion
pauses when backgrounded, covered by another route or disabled in system settings.

The first-time flow is loading, empty Home, the four new title voices together,
a 1.5-second pause, Lala's five steps, Lulu's five steps and required
character/name setup. Each recording must
finish before Next. Saving the profile now uses the existing preloaded
800-millisecond cloud curtain to reveal Home with the selected character.
Reduced-motion settings bypass the curtain.

The automatic boy/girl prompt starts after five seconds without interaction on
fully visible Home. It runs once per Home visit, not repeatedly every five
seconds. Touching the screen resets a pending countdown. Opening a category or
profile picker cancels it, including any playing prompt. Returning to Home or
resuming starts a fresh countdown. Muted voice and screen-time restrictions are
honored; unrelated speech is never interrupted. Both supplied MP3s are unchanged,
decode successfully, and last approximately 3.9 seconds.

Lessons/Games still play the selected character's learn/play recording first,
then walk toward the corresponding doorway for 1.8 seconds. The student becomes
smaller and fades inside before the destination opens. Speech bubbles fit all
text inside the white center and exclude the decorative border and tail.

Verification files:

All 115 checks in the final scoped regression run passed. The Flutter analyzer
found no issues. The imported background and both new MP3s match the original
supplied SHA-256 hashes.

- `build/classrooms-analysis.log`: analyzer result.
- `build/classrooms-final-tests.log`: Home, onboarding, voice, transitions,
  progress/navigation and device-layout regression results.
- `build/ui_previews/update_home_390.png`: rendered Home.
- `build/ui_previews/update_welcome_lessons.png` and
  `update_welcome_games.png`: dialogue layouts.
- `tools/home_classrooms_import_verification.json`: imported-file SHA-256 checks.
- `tools/intro_audio_verification.json`: all 19 runtime recordings decode and their timing.
- [Title voice update](HOME_TITLE_VOICE_UPDATE.md): synchronized startup chorus.

These changes are included in [release 1.0.18 / build 19](RELEASE_1_0_18.md),
along with the supplied buttons and full-screen category changes.
No phone or emulator was connected for physical-device sound/frame-pacing checks.

The subsequent supplied-button update passed all 50 scoped Home regressions
(`build/home-button-tests.log`) and static analysis (`build/home-button-analysis.log`).
Rendered previews are `build/ui_previews/school_home_390.png` and
`build/ui_previews/school_home_girl.png`; the latter shows the saved B recommendation.
