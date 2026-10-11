# Blending Sounds lesson

Implements the supplied **BLENDING SOUNDS LESSON – DRAG AND DROP SCENARIO.docx**.
Open **Lessons → Blending Sounds** (the supplied SUN logo).

- The lesson uses the 22 words from the user-supplied replacement ZIP.
- A picture, three empty puzzle slots and three shuffled jigsaw pieces form each
  activity. Drag a piece to its matching position, or select a letter and tap a
  slot. Identical letters such as the two Ps in PUP are interchangeable, but each
  physical piece can only be placed once.
- A correct placement highlights the letter and plays its existing phoneme clip.
  Incorrect drops animate back with “Try another spot!” and no error sound.
- Completing the puzzle repeats the three sounds, brings the letters together,
  says the word and gives spoken praise with a small sparkle celebration.
- Hear Again replays the sounds and word. It never solves an incomplete puzzle.
  Try Again clears the current puzzle; Next clears it and advances. The last Next
  is disabled. No scores, lives, timers, difficulty prompts or mastery rewards.
- Navigation, mute changes, app backgrounding and disposal cancel pending audio.
  Narration temporarily holds background music. Visual practice works while muted
  or when a recording cannot play.
- The shared Lessons artwork and translucent cards are retained. Content scrolls
  on small screens and at larger text sizes; bottom controls remain accessible.
- Puzzle pieces use the supplied reference's red, yellow and blue frames with
  cream centers. Sound and Next controls use the original supplied button PNGs;
  Try Again uses a matching native replay button.

## Assets and narration

All 22 words have supplied illustrations, stored as verified lossless WebP. The lesson uses 46 supplied MP3 files: introduction, incorrect-placement feedback, 22 word-only recordings and 22 praise recordings. Individual letter sounds reuse existing phoneme recordings.

The 68 old Blending WAV files and the retired voice generator have been removed. See [CVC/Blending refresh](docs/CVC_BLENDING_REFRESH.md) for the imported files and current word list.

The new controller separates puzzle/audio sequencing from the screen. Tests cover
correct and incorrect placements, repeated letters, cancellation, replay, audio
failure, actual drag gestures, animated return/reset, six screen/text-size
combinations, asset availability, menu navigation and all 22 current words.

```powershell
flutter analyze --no-pub
flutter test test/blending_lesson_test.dart test/cvc_lesson_test.dart test/lesson_menu_test.dart test/letter_recognition_test.dart test/phonics_lessons_test.dart
```
