# Unused asset cleanup

The user's scope is to remove unused files and media, preserve current app behavior,
and deliver `phonics_jit_v3.apk`. Active images and recordings are not recompressed,
resized, replaced, or removed to meet an arbitrary size target.

## Review before deletion

- Start at `lib/main.dart` and follow Dart imports, exports and parts. Inspect
  retired widgets separately so a test-only import does not make an obsolete
  menu background part of the shipping app.
- Evaluate the actual A–Z image/audio getters, game word catalogs, Quick Check
  examples, CVC/blending words and praise, rhyming families, instruction scripts,
  day-cycle backgrounds, character animation frames, button variants, navigation
  states and font registrations. Resolve audio precedence through
  `PhonicsAudioService.assetForPhrase` instead of guessing from filenames.
- Retain the original active PNG/WebP/MP3/WAV bytes and both font licenses.
  Retain the illustration used by the tested Tricky Letters compatibility screen.
- No byte-identical media duplicates were found. The evaluated runtime mapping
  still uses the audio files, so no recordings were proposed for removal.
- Review each proposed asset by path, byte count, SHA-256 and a reason. The
  read-only dry run checks every target before permitting any deletion.
- Delete individual ordinary files inside this workspace only. The script rejects
  linked targets/parents, changed hashes, runtime source files and required media.
  It does not recursively delete directories or touch files outside the project.

## Artifacts

- `tools/runtime_asset_cleanup_review.json`: reviewed candidates before deletion.
- `tools/runtime_asset_cleanup.json`: removed paths and every retained media hash.
- `test/runtime_asset_cleanup_test.dart`: evaluated runtime inventory and checks
  for deleted candidates, unchanged active bytes and preexisting missing paths.
- `build/cleanup_before_tests.log`: full test baseline before deletion.
- `build/runtime_asset_cleanup_audit.json`: read-only evaluated usage report.

## Known baseline limitations

The pre-cleanup test run already reports failures. Some tests still describe old
layouts or old artwork. Dynamic lesson getters also contain preexisting references
to deleted WebP files; the replacement Alphabet & Pictures lesson uses the current
PNG originals. The cleanup manifest records the missing paths found by the audit
so cleanup cannot silently add another missing dependency. Existing failures must
be distinguished from new cleanup regressions. This cleanup does not claim to fix
unrelated layout or lesson behavior.

The final APK verification and before/after measurements are recorded after the
cleanup, tests and release build complete.

## Reviewed removals and preservation

- Removed 38 media/concept files and 10 unreachable presentation source files:
  63,738,084 source bytes in total. Of these, 63,650,580 bytes were media/concepts;
  some concept files were never bundled, so the APK saving is measured separately.
- The largest group is the 16 superseded composite activity cards. Other removals
  include old menu/transition frames, unused concept characters, the replaced dock
  frame, unused button art. Medium/SemiBold fonts were reconsidered and retained after
  inspecting GoogleFonts asset discovery.
- Preserved the original bytes of all 851 retained assets, including all 406 audio
  files. No source audio or image was transcoded, resized or replaced.
- Removed eight empty/nonexistent asset-directory registrations. Current images,
  font registrations, license files, application package ID and signing identity
  remain available to the release build.
- The full baseline run completed with 940 passing tests and 24 preexisting
  failures. Stale tests that explicitly demanded retired decorative art now verify
  the corresponding current art; unrelated failing tests are not rewritten to
  conceal their results. The before/after comparison is recorded in
  `tools/runtime_cleanup_test_comparison.json`.

## Validation after removal

- Full post-cleanup run: 943 passed, 22 failed. The comparison identifies 21
  preexisting failures and one offline-font failure caused by the initial test
  asset bundle, which had been generated before the two fonts were restored.
- Restored the original Medium/SemiBold bytes from the previous verified APK,
  retained them in the usage inventory, and rebuilt test assets. All four final
  inventory/offline-font checks pass. The unchanged original
  `stabilization_test.dart` also passes in full on recheck; its JSON events verify
  the exact previously failing offline-font test succeeds.
- No unresolved cleanup regression remains. The 21 preexisting failures concern
  older layout expectations and already-missing legacy media; they are explicitly
  retained in the comparison rather than reported as passing.
- Full Flutter analysis: no issues found. Current game-card, navigation, home
  mascot, lesson/audio and reward tests remain part of the full suite.

## Delivered APK

- File: `output/apk/phonics_jit_v3.apk`.
- Before: 553,799,167 bytes (528.14 MiB).
- After: 493,879,185 bytes (471.00 MiB).
- APK saving: 59,919,982 bytes (57.14 MiB), or 10.82%.
- All 851 bundled source assets match their retained source hashes. Retired
  assets are absent from the package; supplied A–Z artwork/recordings and current
  UI frames remain unchanged. All three previously supported Android architectures
  are still included.
- Signing verification succeeds and the certificate matches the preceding APK.
  The delivered copy matches the verified build byte-for-byte. No physical device
  installation was performed.
- APK SHA-256: `3C6A2C649818E4B3546654E355615E0A33B6AD7542278291E18D671C65E05B84`.
- Detailed package evidence: `tools/phonics_jit_v3_verification.json`.
