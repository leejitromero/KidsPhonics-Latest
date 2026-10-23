# KidsPhonics 1.0.17 / build 18

Verified APK: [KidsPhonics-1.0.17-build18.apk](../releases/KidsPhonics-1.0.17-build18.apk).
The Android build succeeded. All 781 bundled source assets match their captured
hashes, including 774 required runtime assets. The 944 captured source inputs
remain unchanged after compilation, and the signing certificate matches the
previous release. APK SHA-256:
`4E59EC45936A640DFD6ED9A63AD706B0FC53CC2B6AD2EB675BBBEE4E18AA9248`.

First-time learners see the Home courtyard after loading, with Lala and Lulu
behind their signs and no student character. After the Home transition finishes,
a 1.5-second pause precedes Lala's introduction. Her five dialogues come first,
followed by Lulu's five dialogues. Each uses its own supplied recording and
speech bubble. Next stays disabled during playback; completion does not advance
the dialogue. Lulu's final button is Get Started.

Get Started opens the framed boy/girl picker and the name field. Setup recordings
play in order. A character selection and a nonblank name are required; saving
finishes before the selected student appears at the center of Home. Returning
users retain their saved profile and learning data and skip first-time onboarding.

Tapping Lessons or Games plays the selected boy/girl recording (Let's learn or
Let's play), then walks the student toward the selected side for 1.8 seconds.
After the student exits, the destination fades in over 300 milliseconds. Rapid
taps cannot duplicate playback or routes. Backgrounding cancels a Home visit;
resuming an interrupted introduction replays that same dialogue. Muted voice,
disabled games, screen-time controls and reduced-motion settings remain honored.

Home has no navigation bar or app header. Category screens have themed navigation
and the learner's selected profile frame. Their morning, sunset and night skies
cycle every 3.5 seconds with 650-millisecond fades after the images have loaded.
The cycle pauses while inactive or off-route. Phone game artwork remains in
compact rows, and profile statistics cannot expand the footer indefinitely with
large system text. Help dialogs reuse the supplied guideline clips.

All 16 supplied MP3s decode successfully; measured initial silence is 0.05–0.13
seconds. The recordings and four dialogue PNGs retain their supplied bytes.
The ZIP's lesson_intro names are imported as lessons_intro to match the script.
Speech does not wait for an idle music channel's queued setup work. Images and
local audio files warm in the cache during loading.

Verification artifacts:

- `build/final-tests.log`: all 534 regression tests passed.
- `build/final-scene-and-audio.log`: 17 focused layout, native completion,
  cancellation and replay tests passed.
- `build/final-analysis.log`: no analyzer issues.
- `build/ui_previews/update_*.png`: final rendered layouts.
- `tools/intro_audio_verification.json`: decoded timing and recording hashes.
- `tools/release_1_0_17_source_snapshot.json`: inputs captured before compilation.
- `tools/release_1_0_17_verification.json`: APK version, signing certificate, source
  consistency and asset hash verification.

No Android device or emulator was attached during this update. Automated tests
and rendered previews do not replace checking sound and frame pacing on a phone.
