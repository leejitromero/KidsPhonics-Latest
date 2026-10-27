# Phonics Quiz: sound-position questions

The quiz uses the existing CVC word recordings and pictures. Its 15 words
exclude silent letters, consonant clusters, and digraphs. Easy asks for beginning
sounds; Medium balances beginning and ending sounds; Hard balances beginning,
middle, and ending sounds. Sessions keep 5/6/8 distinct words and three sound
choices. Words and question positions vary on replay.

The supplied `main_intro.mp3` replaces the former first-letter-only instruction.
After that introduction, each question automatically plays its word recording
and its beginning/middle/end prompt. Hear Word, Hear Question, and the sound
speakers allow explicit replay. Manual playback takes priority over automatic
cues. Voice can be disabled without disabling answer selection.

Selecting a letter changes the selection without grading. Check Answer submits
once. Correct answers earn the existing difficulty-scaled 5 XP and one star.
Both correct and incorrect submissions reveal the correct letter in its word,
replay the word and target sound, then advance automatically. Feedback waits
through backgrounding, route coverage, disabled access, and screen-time blocks.
The existing completion bonus is awarded once per quiz.

The results dialog offers Review Mistakes when needed. Review contains only the
originally missed questions and retains the original score. Review submissions
do not change daily answer counts, activity completion, XP, stars, or mastery.
Play Again starts a new quiz with a fresh ledger.

The four recordings are stored byte-for-byte under
`assets/audio/game_instructions/`. Source paths, hashes, levels, and the former
intro hash are recorded in `tools/phonics_quiz_audio_import.json`. The replaced
intro is backed up in `build/phonics_quiz_audio_originals/`.
