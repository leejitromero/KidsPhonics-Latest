# KidsPhonics Settings

Settings is an everyday preferences screen, accessible without a Parent PIN.
It reuses the classroom background, character picker, audio controls and wooden
navigation. Sound and display sections expand on tap; all options remain
scrollable above the navigation, including with large accessibility text.

- **Sound & Music:** voice assistance, sound effects, background music, and the
  existing soft music volume range (0–40%). Learning audio still ducks music.
- **My Character:** edit the saved name and boy/girl selection without resetting
  mastery, XP, stars or completed onboarding.
- **Display & Animations:** Standard, Large (115%) and Extra Large (130%) text,
  plus reduced animations. App text sizing composes with the system text scaler;
  reduced animations also respects the system accessibility setting. These
  preferences apply above the Navigator to include dialogs and pushed screens.
- **Replay Introduction:** replay the mascot introduction, with Skip and Done
  returning to the same Settings page. Replay omits first-time character setup
  instructions and never changes onboarding completion or learning progress.
- **Help & Tutorials:** existing Lessons/Games guides and microphone help. Device
  settings only opens when the user presses its button.
- **About KidsPhonics:** installed Android version/build, local-save explanation,
  credits and open-source licenses. Unavailable native version information has a
  readable fallback rather than a hardcoded version.

Game access, daily limits, PIN changes and progress reset remain in Parents.
Leaving Parents for Settings ends the authenticated parent session. The Parents
settings tab links to App Settings instead of duplicating audio controls.

Display preferences use the existing `AppProvider` snapshot and checked write
queue. No progress records or extra storage system were introduced. Save failures
remain retryable, with the existing unsaved-changes notice displayed in Settings.

## Validation

91 scoped tests passed across Settings, shared navigation, parental controls,
audio, save recovery, first-time introduction, narration and the complete startup
flow. Settings tests include 320×568, 390×844, 768×1024 and landscape 844×390,
system text scaling up to 250%, nonlinear system scaling, app reduced motion,
preference restoration, and profile/progress preservation. Analysis of the 11
changed Dart sources/tests found no issues.

Evidence: `build/settings_regression.log`, `build/settings_analysis.log`,
`build/ui_previews/update_settings_390.png` and
`build/ui_previews/update_settings_768.png`.

Android release **1.0.21 (build 22)** compiled successfully:
`build/app/outputs/flutter-apk/app-release.apk`. Its version and signature were
verified, and its signing certificate matches the previous release. All 785
bundled project assets match their source files; the native version-info channel
is present in the APK. See `tools/settings_apk_verification.json` and
`build/settings_apk_build.log`. Flutter still reports the existing missing legacy
asset-directory registrations during bundling; the release build succeeds.

These are automated checks and rendered previews; physical-device interaction,
speaker playback and opening Android device settings have not been verified.
