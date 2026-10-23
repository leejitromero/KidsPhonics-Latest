# Asset maintenance tools

These tools are separate from the Android app.

The Easy/Medium/Hard word-audio refresh is recorded in `game_audio_refresh_manifest.json` and `../docs/GAME_AUDIO_REFRESH.md`: 70 recordings (including the separately supplied Violin) replace their shared word files directly, with two supplied Yarn frames updated. Umbrella is excluded from every game pool; its assets remain for letter lessons.

- `verify_game_apk.ps1` checks supplied game assets and retired asset exclusions in a built APK. It uses `game_assets_manifest.json` and `removed_legacy_assets.json`; keep both manifests.
- Current runtime mascots use lossless WebP/GIF files in `assets/images/`. Launcher inputs remain PNG. Unused source frame copies and design screenshots were removed after checking the app and build tools.
- `optimize_image_assets.py` encodes lossless WebP images with Pillow and verifies every RGBA pixel before applying replacements. `image_optimization_report.json` records 317 verified encodings and size savings. Original backups/tooling in `build/` are excluded from source delivery and APKs.
- `asset_notes/` holds font and artwork documentation outside the APK asset bundle.
- `asset_usage_audit.json` records the evaluated runtime asset list before cleanup; `removed_unused_assets.json` records removed paths, byte counts, SHA-256 checksums and reasons. Run `flutter test test/asset_usage_audit_test.dart --dart-define=AUDIT_ASSETS=true` to generate a fresh audit after catalog changes.

Run APK verification from the project root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/verify_game_apk.ps1
```

Regenerate launcher icons with `dart run flutter_launcher_icons`, using the existing configuration in `pubspec.yaml`.

Eight obsolete network audio/icon generators and the old SVG icon were removed after checking app, test, and build references. Current recordings are supplied local assets; setup does not generate or download replacements. The direct `http` development dependency used only by those generators was removed; Flutter packages may still require it transitively.

For future human recordings, keep using `../PHONICS_RECORDING_SCRIPT.md`, `../AUDIO_REPLACEMENT_AUDIT.md`, and `../PHONICS_TEACHER_VALIDATION.md` with teacher review.

CVC and Blending now use the complete user-supplied MP3 set: 35 CVC files and 46 Blending files for 17 and 22 words respectively. See `../docs/CVC_BLENDING_REFRESH.md`, the current `../BLENDING_CVC_RECORDING_SCRIPT.md`, and `cvc_blending_refresh_manifest.json`. All 119 old lesson WAV files were removed. The 39 supplied pictures reuse their verified lossless WebP assets.

The retired CVC/Blending voice generators and their shared SSML helper were removed. Maintain the supplied MP3 recordings directly; do not regenerate the old WAV lists or voices.

Game narration and spoken praise were removed at user request. Games keep their supplied word/letter recordings and ordinary sound effects.

Latest verified delivery: `../releases/KidsPhonics-1.0.20-build21.apk` (release 1.0.20, build 21). Its 795 bundled source assets, 788 required runtime assets, signature, version and 960 unchanged source inputs are recorded in `release_1_0_20_source_snapshot.json`, `release_1_0_20_verification.json` and `latest_apk_verification.json`. All 78 scoped flow/UI/audio/cloud/asset checks and Flutter analysis passed before packaging. The complete loading-to-walking flow is documented in `../docs/HOME_STARTUP_FLOW.md`. Earlier release reports remain historical records.

`verify_intro_audio.py` checks all 19 runtime Home recordings and records their timing and hashes. `verify_release_apk.ps1` verifies the current APK against the captured source hashes and previous signing certificate, reading the Android version from pubspec. `verify_intro_apk.ps1` retains the historical build 18 checks. The recording script is `../docs/NEW_UPDATE_RECORDING_SCRIPT.md`.

The subsequent Home garden source refresh adds four supplied background frames and two house PNGs. At that stage, the asset audit resolved 687 assets, and the source checks are in `home_garden_verification.json`. The earlier build 14 APK does not contain these six additional assets and will not pass verification against the refreshed asset audit. See `../docs/HOME_GARDEN_ART_REFRESH.md`.


Home voice import: `import_home_voices.py` combines the four supplied intro takes, aligns spoken onsets, balances levels, and limits peaks. It also balances the four menu recordings. The five final MP3s are in `assets/audio/home/`; input copies and FFmpeg tooling stay in ignored `build/home_voice_import/` and `build/audio_tools/`. Flutter has no FFmpeg dependency. Measurements and original hashes are in `home_voice_import_report.json`. No Quick Check recordings were included in this ZIP.


Quick Check narration: run `python tools/import_quick_check_voices.py <supplied-zip-path>` with the same FFmpeg tooling used for Home. It imports 11 real clips, corrects filename typos, balances active speech levels and checks duration and peak headroom. Only the 11 final MP3s under `assets/audio/quick_check/` are bundled; originals remain in ignored `build/quick_check_voice_import/`. See `quick_check_voice_import_report.json`.

The source UI refresh is described in `../docs/QUICK_CHECK_UI_REFRESH.md`. The version 1.0.10 build 11 report records the earlier supplied choice sheets. The current version uses drawn colorful Quick Check buttons and the Sound Match orb described in `../docs/SOUND_MATCH_UI.md`. The Home village adds four unchanged supplied PNGs under `assets/images/home_village/`; see `../docs/HOME_VILLAGE_REDESIGN.md`. The refreshed asset audit includes 681 required files with no unused candidates; all 681 were verified against the version 1.0.13 build 14 APK.
