# Easy / Medium / Hard audio refresh - 2026-10-08

Installed the supplied `new sounds feedback.zip` recordings at the existing shared game-word paths.

Follow-up completed 2026-10-09: installed the separately supplied Violin recording and excluded Umbrella from every game tier, including Hard Rumbled Words.

| Source tier | New recordings |
| --- | ---: |
| Easy | 23 |
| Medium | 23 |
| Hard | 24 |
| Total | 70 |

## Shared playback

The game catalog already resolves each word to one `assets/audio/game_words/<slug>.mp3` recording through `PhonicsAudioService`. Replacing those files updates all game playback of those words, including spelling/replay flows, without maintaining separate audio copies per game. Rumbled Words keeps its existing word-length difficulty rules while using the same recordings.

The ZIP contains whole-word recordings. Existing correct/wrong effects, letter-name and letter-sound recordings retain their roles; no new generic congratulatory/error phrases were supplied. The separate CVC/Blending narration set remains intact.

## Mapping and pictures

- `jaacket.mp3` maps to the existing `jacket.mp3` asset.
- `ice cream.mp3` maps to `ice_cream.mp3`.
- All 142 supplied picture frames were compared with their existing game images, including known filename variations for Kangaroo, Lollipop, Jacket, Ice Cream and Yarn.
- Two Yarn frames differed and were replaced with lossless WebP versions of the supplied pictures, preserving their RGBA pixels. The remaining pictures match existing images and do not need duplicate copies. Four identical frame pairs reuse their existing single-file paths.

## Recordings absent from this ZIP

- **Violin:** absent from the original ZIP, then supplied separately and installed on 2026-10-09.
- **Umbrella:** excluded from all games, including Hard Rumbled Words. The shared `enabledInGames` rule is used by both difficulty-based and spelling-length game pools. Its existing assets remain for letter lessons.

## Storage

- Replaced all 70 old recordings at their existing filenames. Neither old alternate recordings nor new duplicate word paths were added to the runtime folders.
- The shared word directory still contains 71 MP3 files: 70 replacements and the Umbrella recording retained for lessons.
- The supplied recordings occupy 2,485,479 bytes versus 2,079,804 bytes for the replaced clips. Their bytes are preserved: the increase of 405,675 bytes comes from the new recordings, not duplicate files. This is not an APK size measurement.
- Source ZIP, preparation files and rollback copies are under ignored `build/game_audio_refresh_20261008/`, outside the app asset bundle.

## Validation

All supplied recordings decode successfully, contain non-silent audio, and fit the playback timeout. Installed-file hashes match the source MP3s. The runtime folder path sets are identical before and after replacement.

Integration-test results are recorded in `tools/game_audio_refresh_manifest.json`. Device listening review for pronunciation, word agreement and volume remains in `MANUAL_TEST_CHECKLIST.md`. No new APK has been built for this refresh.

All 16 existing game-audio, picture-animation and asset-audit tests passed. The asset audit reports zero unused media. All 81 CVC/Blending audio hashes were also checked and remain unchanged.

On 2026-10-09, all 12 follow-up game-catalog, Rumbled Words difficulty, and asset-audit tests passed after installing Violin and excluding Umbrella from all games. Hash checks verify all 70 replacement recordings, and the refreshed asset audit reports zero unused media.
