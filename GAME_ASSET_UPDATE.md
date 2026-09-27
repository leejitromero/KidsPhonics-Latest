# Supplied game assets and replay order

Source: `DIFFICULTY IMAGES.zip` (the source ZIP is unchanged).

- Imported all 71 word recordings and all 142 frame assignments: 24 Easy,
  23 Medium, and 24 Hard words. Byte-identical paired frames share one file.
- Normalized filenames, including kangaroo, lollipop, ice cream, jacket,
  and yarn. The original supplied artwork and recordings are preserved.
- Sound Match, Phonics Quiz, Picture Match, Missing Vowel, Word Builder,
  Speak & Recognize, and Rumbled Words use the supplied difficulty vocabulary.
  Spelling games omit the spaced word “Ice Cream”; it remains available in the
  listening, picture, and speaking games.
- Memory Flip uses 4/6/8 randomly selected picture pairs, with supplied word
  audio on matching pairs. Its board still fits the viewport.
- Each game stores its shuffled question list for the whole session. Replay
  and reopening a game in the same app session use a different first word for
  that game/difficulty. Choices and spelling tiles are also shuffled. The pool
  itself is not mutated. Alphabet Order retains its educational alphabetical
  answer order; Flappy Letters retains exactly A–Z and speed-only difficulty.
- Matching lesson words reuse the new images/audio. Lesson-only vocabulary,
  the A–Z letter names and isolated sounds, mascots, icon, background music,
  and short nonverbal effects remain because the ZIP provides no equivalent.
  Removing these would break lessons or the requested Flappy Letters mascot.
- Retired spoken praise/instructions no longer resolve or play. Removed 365
  obsolete/replaced media files (31.35 MiB); see
  `tools/removed_legacy_assets.json`. Removed their asset-directory declarations.
  This saving does not mean the final APK is smaller: the new source artwork
  is substantially larger than the retired media.

Inventory: `tools/game_assets_manifest.json` and `lib/data/game_word_data.dart`.

Verification covers file existence, complete word/audio pairing, difficulty
vocabulary, unambiguous answers, 100 replays per difficulty, live game completion
and replay, rewards, small-screen layouts, lessons, parental controls, and
Flappy Letters. Test/build results are recorded below when complete.

Automatic approval review rejected a broad removal of obsolete Dart data
definitions; those definitions were retained. No source deletion was bypassed.
They do not cause removed media to be bundled in the APK.

Completed checks:
- `flutter analyze --no-pub`: no issues.
- Full `flutter test --no-pub`: 134 tests passed, including game completion,
  randomized replay, picture-pair memory, A–Z audio, and small-screen layouts.
- No Android device was connected for physical-device playback testing.

The first release-build attempt was interrupted. The resumed release build and
the APK's asset hash audit are tracked in `build/asset_apk_build_resume.log` and
`build/game_apk_verification.json` respectively.

Release build completed successfully in 320.3 seconds on the resumed run.
The local APK is `build/app/outputs/flutter-apk/app-release.apk` (276,561,686
bytes). All 209 unique supplied media files (138 PNGs and 71 MP3s) match their
source SHA-256 hashes inside the APK. All 365 retired files are absent.

APK SHA-256: `94A95B6F3F689F98CB06C921984A10A93F97BE450B9D716C42A8A6ECD681083D`.
The APK has not been sent; delivery waits for the user's instruction.
