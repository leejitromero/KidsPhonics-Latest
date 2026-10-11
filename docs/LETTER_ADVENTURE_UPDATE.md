# Letter Adventure

Home's recommended letter now opens a five-part assessment directly: uppercase/lowercase matching (drag or tap), sound selection, missing-letter spelling, sound-to-picture matching, and letter hunt. All 26 letters have explicit content and existing local audio/image assets. I and U use middle sounds; X uses final /ks/; Q is presented with Qu for /kw/. Umbrella is excluded.

The first answer is locked for each activity. Sound and word questions require completed playback before submission, with separate replay controls. Corrections wait until the complete assessment; guided practice cannot overwrite its score. In letter hunt, all four targets must be found and a wrong selection makes that activity incorrect.

Passing requires at least 4/5 and correct answers on both sound activities. This is a configurable app rule, not a validated diagnostic assessment. Mastery remains earned after a later unsuccessful review. First completion awards 5 XP; first mastery adds 25 XP and one star. Repeat attempts and repeated submission of the same current session cannot repeat those rewards.

New results are stored under `letterAdventuresV1` in the existing authoritative preference snapshot. Earlier Quick Check data remains separate and visible. Overall mastery, letter access, and milestones appear in Progress. Home recommends attempted unmastered letters before new ones, then moves on after mastery.

Existing sound/word recordings work now. Optional intro, instruction and result narration is wired but awaits the eleven supplied recordings listed in `LETTER_ADVENTURE_RECORDING_SCRIPT.md`. Audio stops on navigation, backgrounding and time limits; interrupted recordings do not unlock answer controls.

Assessment pictures use existing artwork without a printed target letter. Zebra uses a native zebra illustration because the supplied zebra lesson images include a large Z that would reveal the answer. No additional image file is needed.

Validate actual pronunciation and volume on a device, particularly short vowels, hard C/G, Qu and final X. Automated asset checks establish that files exist; they do not establish phonetic correctness. This change adds no generated narration or additional media files.

## Validation

The final regression run passed 115 tests across Letter Adventure, production audio playback, Home, Progress, legacy assessments, dashboard layouts, image decoding, asset coverage and save recovery. Focused analysis of 15 affected source/test files reported no issues. Phone previews were inspected for Home and the five assessment activities; device pronunciation and performance checks remain in `MANUAL_TEST_CHECKLIST.md`.

The broader suite initially exposed stale expectations for the old Home recommendation, Progress scroll positions, a fixed image count and the previous Flappy mascot widget. Those expectations were updated to verify the current behavior, and their affected suites passed in the final regression run. Native audio tests run separately from injected fake audio to keep player initialization independent.
