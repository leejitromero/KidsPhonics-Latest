# Rhyming Jar Adventure

Implemented from the supplied rhyming words.zip and cloud/jar PNG artwork on 2026-10-09.

- 51 supplied MP3 recordings, copied without re-encoding: intro, 40 individual words, 10 family praise recordings. Hashes and original ZIP paths: tools/rhyming_jar_import.json.
- Families: LIP/HIP/DIP/SIP; CAT/BAT/HAT/MAT; SUN/FUN/RUN/BUN; PEN/HEN/TEN/MEN; PIG/BIG/WIG/DIG; TOP/HOP/MOP/POP; FAN/MAN/PAN/CAN; BUG/HUG/MUG/RUG; PIN/FIN/WIN/BIN; BED/RED/FED/LED.
- Each session draws 5/6/8 unique families for Easy/Medium/Hard, rotating through all ten on replay. Each jar needs three unique answers. Choices contain 2/4/6 distractors from other families. No timer; cloud movement stays gentle.
- Intro plays once per session, then the target word. Choices stay locked during speech. Tapping a choice plays only the correct/wrong effect. Correct answers turn into flying star energy and fill the jar. Wrong answers shake without adding energy.
- After the third star arrives, clouds disappear and the jar grows/moves into the center. All four family words appear in target-first order; the supplied family praise recording plays once (its script includes target, rhymes, and varied praise). Individual words can be replayed afterward. Next Jar waits until playback finishes.
- Pause, app backgrounding, covered routes and parental game restrictions stop speech/movement. Resume restarts interrupted intro/target/family speech while retaining collected energy. Duplicate taps cannot grant rewards. Muting still allows progression.
- Scoring counts each of the three answers separately. Existing 8 XP times difficulty and one star per correct answer apply; the existing completion bonus is awarded once. Play Again resets the session ledger without removing saved rewards.
- A dynamic fill overlays the jar glass and its illustrated EXP gauge. Supplied PNG alpha is retained; no duplicate image copies are bundled.
- No game-complete.mp3 was supplied; the game uses the existing victory effect and result dialog. No voice was generated. Existing shared legacy word assets remain because other activities still resolve them.

Validation: actual audio-completion events check intro/target/choice/praise order; unique answer and wrong-answer state checks; animation pause; saved rewards and replay; phone/tablet layouts; evaluated asset audit. Device listening and animation review remain in MANUAL_TEST_CHECKLIST.md.

Verified checks:
- 16 tests passed across rhyming_jar_test, phonics_content_test and asset_usage_audit_test.
- 3 existing Rhyming Words header/layout tests passed at 320x568, 390x844 and 800x1024.
- All 51 MP3 files decoded successfully and match the source ZIP bytes.
- Focused static analysis found no issues.
- Asset usage audit: zero unused media.
- Choosing and full-jar previews inspected under build/ui_previews/rhyming_jar*.png (not bundled).
