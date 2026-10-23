# KidsPhonics 1.0.20 / build 21

APK: [KidsPhonics-1.0.20-build21.apk](../releases/KidsPhonics-1.0.20-build21.apk).
The release build succeeded and was copied into `releases`. Its Android version
is 1.0.20, build 21. Signature verification passed and the certificate matches
the previous release, supporting an update with existing saved data retained.

The classroom Home preserves the supplied morning/sunset/night layout, with
Lala behind Lessons, Lulu behind Games, the chosen character in the center,
and working Progress/Parent shortcuts and recommended-letter Practice.

The complete first-setup flow was checked from the real loading widget:
loading -> welcome/title chorus -> Home without a learner -> talking mascot
guidelines -> character/name setup -> cloud transition -> Home with the chosen
character -> automatic prompt after five idle seconds -> Lessons/Games cue ->
constant-size walking animation -> complete offscreen exit -> destination.
Saved learners restore their character on later launches, hear the startup
chorus once, and skip completed guidelines/setup. See [Home startup flow](HOME_STARTUP_FLOW.md).

Validation passed **78 scoped tests** and Flutter analysis found no issues.
All **960 captured build inputs** stayed unchanged through compilation;
**788 required runtime assets** and all **795 bundled source assets** were
verified against source. This includes all three home backgrounds, the 19 Home
recordings, talking/walking frames and cloud transition art. The standalone
5120 x 7680 upscaled masters stay in `output/home_classroom/8k/` outside the APK.

APK size: **488,801,693 bytes (466.2 MiB)**.
SHA-256: `18BB5946A055DBF94271B39C2FA065ABC5A6E546644BE59FCE8B9DA96930D2AD`.
An adjacent `.apk.sha256` file contains the checksum.

Evidence:

- `build/release_1_0_20_tests.log`
- `build/release_1_0_20_analysis.log`
- `build/release_1_0_20_build.log`
- `tools/release_1_0_20_source_snapshot.json`
- `tools/release_1_0_20_verification.json`
- `tools/latest_apk_verification.json`

This is a local release build using the project's existing signing setup.
Physical-device installation and speaker playback have not been checked.
