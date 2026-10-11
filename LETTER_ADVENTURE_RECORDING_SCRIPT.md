# Letter Adventure — recording script

Record each row as a separate MP3. Use a warm, clear voice, a gentle pace, and the exact text shown. These are shared instructions for all 26 letters, so **11 recordings total**, not 11 per letter.

| Filename | Exact recording text |
|---|---|
| intro.mp3 | Complete five fun challenges. Take your time and do your best! |
| match.mp3 | Find the little letter. Drag it into the box, or tap it. |
| sound.mp3 | Listen to each sound. Choose the sound for this letter. |
| spelling.mp3 | Listen to the word. Choose the missing letter. |
| picture-beginning.mp3 | Listen to the sound. Find the picture with that beginning sound. |
| picture-middle.mp3 | Listen to the sound. Find the picture with that middle sound. |
| picture-end.mp3 | Listen to the sound. Find the picture with that ending sound. |
| hunt.mp3 | Find all the big and little letters that match. |
| saved.mp3 | Answer saved! Let us try the next challenge. |
| mastered.mp3 | Wonderful work! You completed your letter adventure! |
| practice.mp3 | Good effort! Let us practice a little more. |

Put these files together in a ZIP named `letter-adventure-instructions.zip`. The app already uses existing letter-sound and word recordings. These eleven additional clips supply instruction narration and result feedback.

`saved.mp3` is neutral feedback while answers are being assessed. Corrective feedback happens after the five challenges, so the first score reflects the child's own answers.

Developer import: add supplied paths to `adventureNarrationAssets` in `lib/data/adventure_narration.dart`, relative to `assets/`, and register the folder in `pubspec.yaml`. Do not add paths until the actual recordings exist.


Imported from the supplied `sound feedbacl for quick check.zip`: all 11 clips are now bundled under `assets/audio/quick_check/`. The source names `picture-beggining.mp3` and `picture-ending.mp3` are mapped to `picture-beginning.mp3` and `picture-end.mp3`. Recordings are balanced without changing their duration or content. Original hashes and audio measurements are in `tools/quick_check_voice_import_report.json`.
