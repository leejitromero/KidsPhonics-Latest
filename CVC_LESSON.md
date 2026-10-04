# CVC Words lesson

Implemented from `CVC WORDS LESSON SCENARIO.docx` on October 3, 2026.
The Lessons menu opens this guided lesson using the supplied cat/CAT logo.

The 25 words follow the document's Short A, E, I, O and U columns. Each word
shows a picture, its spelling and three tappable sound cards. Automatic playback
highlights each sound, moves the cards together through slow and faster blending,
then enlarges the completed word with sparkles and spoken encouragement.
Previous, Hear Again and Next remain available. Browsing does not record quiz
answers, award points or mark mastery.

## Audio and pictures

The 51 WAV files in `assets/audio/cvc_lesson/` are generated offline with the
installed Microsoft Zira Desktop computer voice. `tools/generate_cvc_narration.ps1`
recreates the introduction, 25 whole words and 25 praise phrases. The praise
spells each letter name before saying “makes [word]”. Existing supplied phoneme
recordings remain the source for individual sounds and blending.

Available supplied artwork is reused for CAT, HAT, FAN, PEN, NET, DOG and SUN.
Other words use pictograms/emoji; WIG, FIN, SIT and TOP have dedicated vector
illustrations. These visuals and narration can be replaced with supplied CVC
artwork and voice recordings independently of the lesson flow.

Playback advances after audio completion. New actions cancel previous sequences,
including pending delays; leaving or backgrounding the lesson stops playback.
Muted lessons still demonstrate the visual sequence. Reduced-motion settings
show the same stages without movement. Small screens and enlarged text can
scroll the content while the three bottom controls remain visible.
