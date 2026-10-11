# CVC Words lesson

Implemented from `CVC WORDS LESSON SCENARIO.docx` on October 3, 2026.
The Lessons menu opens this guided lesson using the supplied cat/CAT logo.

The current 17 words follow the user-supplied replacement ZIP. Each word
shows a picture, its spelling and three tappable sound cards. Automatic playback
highlights each sound, moves the cards together through slow and faster blending,
then enlarges the completed word with sparkles and spoken encouragement.
Previous, Hear Again and Next remain available. Browsing does not record quiz
answers, award points or mark mastery.

## Audio and pictures

The lesson uses 35 supplied MP3 files: one introduction, 17 word-only recordings and 17 praise recordings. Praise matches the new wording, for example: "Cat! Nice work! C-A-T makes cat!" Individual letter sounds reuse existing phoneme recordings.

All 17 words have supplied artwork stored as verified lossless WebP. The old WAV files and retired voice generators have been removed. See [CVC/Blending refresh](docs/CVC_BLENDING_REFRESH.md) and [recording script](BLENDING_CVC_RECORDING_SCRIPT.md).

Playback advances after audio completion. New actions cancel previous sequences,
including pending delays; leaving or backgrounding the lesson stops playback.
Muted lessons still demonstrate the visual sequence. Reduced-motion settings
show the same stages without movement. Small screens and enlarged text can
scroll the content while the three bottom controls remain visible.
