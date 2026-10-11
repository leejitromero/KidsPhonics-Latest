# KidsPhonics 1.0.8 ? build 9

Delivery: `releases/KidsPhonics-1.0.8-build9.apk` (311,671,927 bytes, 297.2 MiB). The adjacent SHA-256 file identifies this exact APK.

The release includes the current supplied CVC/Blending lists, recordings and artwork, refreshed shared game-word audio including Violin, Umbrella exclusion from games, Rhyming Jar Adventure, Letter Adventure and the earlier UI, audio, progress, parent and lifecycle improvements.

The eleven new Letter Adventure instruction recordings are still awaiting the user. The instruction text and optional playback support are included; existing word and phoneme recordings play now. See `LETTER_ADVENTURE_RECORDING_SCRIPT.md`.

A fresh release build followed removal of old build outputs, import copies, preview caches and retired voice generators. Source inputs were fingerprinted before compilation and remained unchanged afterward. Verification matched all 660 required bundled assets to source bytes, confirmed retired assets were absent, located current feature code in all three compiled architectures, verified the APK signature and checked versionName 1.0.8/versionCode 9. Full static analysis reported no issues; the preceding regression run passed 115 tests.

This universal APK supports arm64-v8a, armeabi-v7a and x86_64 on Android API 24 or newer. It retains application ID `com.example.kidsphonics` and the existing development signing certificate. No Android device was connected for installation testing; use `MANUAL_TEST_CHECKLIST.md` for device validation.

The latest verification is `tools/latest_apk_verification.json`. Only the named delivery APK should be shared; historical documents refer to earlier builds.
