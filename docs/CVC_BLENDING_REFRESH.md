# CVC and Blending refresh - completed 2026-10-08

Applied the user-supplied `new cvc and blending.zip`, `word-only.zip`, and the two separately supplied MOP files (praise and word-only).

| Lesson | Words / pictures | Intro / instructions | Word-only | Praise | Total audio |
| --- | ---: | ---: | ---: | ---: | ---: |
| CVC | 17 | 1 | 17 | 17 | 35 |
| Blending | 22 | 2 | 22 | 22 | 46 |
| Total | 39 | 3 | 39 | 39 | 81 |

CVC praise now displays "Cat! Nice work! C-A-T makes cat!" and the corresponding line for every word. Blending keeps "Great job!". The 39 new lesson entries use all supplied pictures, including MOP, and every entry has its new whole-word and praise recording.

## Storage and cleanup

- The supplied MP3s are used directly, without re-encoding or duplicate WAV copies.
- Removed all 119 obsolete WAV files from the two lesson audio folders after evaluating runtime references.
- Lesson narration decreased from 16,873,190 to 5,063,779 bytes: 11,809,411 bytes (11.8 MB) less raw asset data. This is not a measured APK size reduction.
- All 39 supplied PNGs were checked against lossless WebP output, with identical decoded RGBA pixels. Those optimized files already matched the 39 existing lesson images exactly, so they are reused without duplicate PNGs. Every image is now referenced by a new lesson entry.
- Shared letter sounds and assets used elsewhere remain available. The app asset audit reports zero unused media.
- Legacy CVC/Blending voice generators now stop immediately so they cannot recreate obsolete WAV files.
- Temporary source packages and a rollback backup are under ignored `build/cvc_blending_refresh_20261008/`; they are not part of the app's asset bundle.

## Verification

- All 81 supplied MP3s decode, contain non-silent audio, and fit the 30-second playback timeout.
- Installed audio hashes match the supplied files; image hashes match the verified lossless images.
- All 35 CVC, Blending, and asset-audit tests passed after replacement and cleanup. These cover bundled media, lesson sequence, replay, navigation, mute/cancellation, responsive layout, and unused assets.
- Manual pronunciation, volume, and text/audio listening review on the target device remains in `MANUAL_TEST_CHECKLIST.md`.
- No new APK was built during this refresh; the previous APK predates these changes.

## Word lists

CVC: CAT, BAT, HAT, MAP, FAN, BAG, BED, HEN, PEN, NET, RED, PIG, PIN, DOG, POT, RUG, RUN.

Blending: SUN, CUP, BUS, LOG, CAP, VAN, PAN, TEN, LEG, JET, WEB, LIP, DIG, BOX, MOP, MUG, NUT, HUT, BUG, SIT, TOP, WIG.

Recording lines: [current script](../BLENDING_CVC_RECORDING_SCRIPT.md). Source mappings, hashes, durations and removed-file inventory: [refresh manifest](../tools/cvc_blending_refresh_manifest.json).
