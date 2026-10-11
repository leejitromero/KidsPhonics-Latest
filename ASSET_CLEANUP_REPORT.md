# Verified asset cleanup — October 7, 2026

Removed replaced artwork and unused files after checking imports, asset getters,
audio lookup precedence, voice prompts, tests, and build tools. Current lessons,
games, mascots, recordings, parent settings and progress data are preserved.

## Review and removals

- 19 obsolete runtime PNGs: eight old Home menu frames, five old Parents
  backgrounds, five replaced lesson backgrounds and the old single Flappy bird.
  These accounted for 28,876,428 bytes (27.54 MiB).
- 28 unused source/reference PNG copies: 46.02 MiB. Current runtime mascot
  PNGs/GIFs, splash animation and launcher artwork remain.
- One unused widget file, `lib/widgets/shared_widgets.dart`, containing the old
  emoji navigation. No application or test imports used it.
- Five completed one-off scripts in `.dart_tool/` for mascot preparation and
  superseded APK verification. The current APK verifier lives in `tools/`.
- Five asset README files moved to `tools/asset_notes/` to retain provenance and
  font documentation without bundling developer documentation in the APK.
- Removed unused Home/Parents declarations from `pubspec.yaml` and the old frame
  constants. Current independent home mascots and garden UI remain.

All current sounds resolved to files used by the app. Blending's `try-another.wav`
was explicitly checked against its controller and retained. Emoji text that is
still used as a fallback or in game data is tiny and remains; it is not an image
file contributing significant APK size. Tested legacy screens/data were retained
where tests still exercise them.

`tools/removed_unused_assets.json` contains exact removed paths, reasons, byte
counts and SHA-256 checksums. `tools/asset_usage_audit.json` contains 658 evaluated
runtime assets and zero unused candidates after cleanup. The audit evaluates
generated paths for all letters, lesson/game vocabulary, narration, controls and
animated/static mascots instead of relying only on filename searches.

## Validation

The complete test run passed 342 tests and exposed five stale assertions for the
previous UI. Updated those assertions for illustrated answer frames, the Qu
label, current feedback background and hidden picture labels. All ten tests in
the affected files passed after focused rechecks, including fail/pass/retry
mastery flows. No runtime behavior was changed by those test updates.

Flutter analysis passed with no issues. The release APK is rebuilt and verified
against all 658 asset checksums and both retired-file inventories before delivery.

## Size results and delivery

- 53 reviewed files removed: 77,137,824 bytes (73.56 MiB) from source assets and
  unused preparation scripts.
- Release APK: 461,161,129 bytes (439.80 MiB) before cleanup;
  432,276,531 bytes (412.25 MiB) after cleanup. Reduction: 27.55 MiB (6.26%).
- Generated `build/` and `.dart_tool/flutter_build/` contents: 3,426,910,271
  bytes (3.19 GiB) removed after validation.
- Delivered file: `KidsPhonics-latest-1.0.5.apk`, with its `.sha256` checksum.
  `tools/cleanup_apk_verification.json` records all 658 verified assets and
  confirms that 365 earlier retired assets and 53 cleanup files are absent.

The remaining APK size is mainly artwork and animations actively used by the
lessons and games. This cleanup preserves their image quality, animation frames,
offline recordings and support for all currently packaged Android architectures.

Generated build directories are removed after copying the cleaned APK into the
project root. Package metadata, supplied source ZIPs/documents and saved source
baselines in `.dart_tool/` are retained. The next build/test recreates its caches.

## Subsequent game audio change

At the user's later request, the 18 generated game instruction/praise WAVs,
their unused phrase registry and generation script were removed too. Supplied
letter/word recordings and sound effects remain. These additional 20 removals
are included in `tools/removed_unused_assets.json`; the fresh runtime inventory
also includes the new Home logo. The APK size figures above describe the
earlier cleanup build.
