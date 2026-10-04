# Asset maintenance tools

These tools are separate from the Android app.

- `verify_game_apk.ps1` checks supplied game assets and retired asset exclusions in a built APK. It uses `game_assets_manifest.json` and `removed_legacy_assets.json`; keep both manifests.
- `mascot_frames/` retains original supplied artwork for future mascot animation and launcher edits. Runtime PNG/GIF assets remain in `assets/images/`.

Run APK verification from the project root:

```powershell
./tools/verify_game_apk.ps1 -ApkPath KidsPhonics-animated-1.0.2.apk
```

Regenerate launcher icons with `dart run flutter_launcher_icons`, using the existing configuration in `pubspec.yaml`.

Eight obsolete network audio/icon generators and the old SVG icon were removed after checking app, test, and build references. Current recordings are supplied local assets; setup does not generate or download replacements. The direct `http` development dependency used only by those generators was removed; Flutter packages may still require it transitively.

For future human recordings, keep using `../PHONICS_RECORDING_SCRIPT.md`, `../AUDIO_REPLACEMENT_AUDIT.md`, and `../PHONICS_TEACHER_VALIDATION.md` with teacher review.

The CVC and Blending lesson generators use the installed Microsoft Zira voice for offline narration. `positive_praise.ps1` shares a brighter praise style: +12% pitch and +8% rate on the congratulation, with a short pause and medium-rate spelling. This adjusts synthetic prosody; it does not clone the supplied voice examples. The 25 CVC and 40 Blending praise WAVs are bundled with the app.

Regenerate only positive praise, preserving all other recordings:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/generate_cvc_narration.ps1 -PraiseOnly
powershell -NoProfile -ExecutionPolicy Bypass -File tools/generate_blending_narration.ps1 -PraiseOnly
```
