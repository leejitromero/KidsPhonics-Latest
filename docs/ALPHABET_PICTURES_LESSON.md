# Alphabet & Pictures

Lesson 4, after Short Vowel Sounds. The original five lesson screens retain
their behavior. The menu now contains six lessons.

The supplied `IMAGES A-Z.zip` is imported into `assets/images/lesson_frames/`:
26 letters, three original PNGs per letter. Import hashes and dimensions are in
`tools/alphabet_picture_import.json`. `tools/import_alphabet_pictures.py` verifies
the ZIP and copies the original bytes without changing the artwork.

The page shares the lesson background, title, instruction dialogue, image frame,
speaker artwork, Previous/Next controls and alphabet picker with the existing
letter lessons. The three picture frames respect Reduced Animations.

On entry, the two supplied instruction recordings play in order with matching
captions, followed by the A sentence. Each step waits for actual audio completion.
The originals `alphabet_pictures_1.mp3` and `alphabet_picture_2.mp3` are preserved
in `assets/audio/lesson_instructions/`; hashes and MPEG validation are recorded
in `tools/alphabet_picture_instruction_import.json`. Voice Off uses the shared
readable-caption fallback. An interrupted intro does not restart automatically.

On Next, Previous or selection in the A-Z grid, the new picture is painted
before its sentence plays. Sound repeats the current sentence. Either action
interrupts the intro immediately. Navigation,
opening the picker, leaving the page, backgrounding, Voice Off or a time limit
stops playback. A cancelled/failed recording never counts as listening.

Browsing records an explored letter. A completed recording increments the
existing word-listening evidence, the menu's Listened count and the sixth lesson
type in the learning summary. Browsing and listening award no mastery, XP,
stars, scored attempts or streak days.

## Recordings

The 26 original recordings from `A_Z_sounds.zip` are imported into
`assets/audio/alphabet_pictures/`, with their original filenames and bytes.
The supplied `k.mp3` maps to K. ZIP hashes, per-file hashes and MPEG frame
validation are recorded in `tools/alphabet_picture_audio_import.json`.

`alphabetPictureRecordings` in `lib/data/alphabet_picture_data.dart` connects
automatic playback and Sound to the existing local audio service. There is no
TTS fallback or substitution with isolated letter/word recordings. The intended
sentences follow the image collection:

A ant, B ball, C cat, D drum, E egg, F fish, G giraffe, H hat, I igloo,
J juice, K kite, L lion, M monkey, N nest, O orange, P penguin, Q queen,
R rabbit, S sun, T turtle, U umbrella, V van, W whale, X xylophone,
Y yoyo, Z zebra. Example: **A is for ant.**
