# Manual Test Checklist — KidsPhonics

Use the cleaned version on the target Android phone. Leave boxes unchecked until actually tested. Record any failure with device/Android version, steps, expected result, and actual result. This checklist covers current features and assets only.

Device / Android version: ____________________
Tester / date / build identifier: ____________________

## App startup

- [ ] App opens without crashing, including a first launch in airplane mode.
- [ ] If reading saved data fails, startup offers Retry rather than remaining on loading. Retry restores existing progress and learner time tracking without saving an empty replacement.
- [ ] Cleaned APK displays all current pictures/animation frames and plays lesson, game, retry and feedback sounds offline without missing-asset errors.
- [ ] Home text, mascot, rewards, and navigation display properly.
- [ ] Home matches the sky-path reference: moving KidsPhonics logo at the top, airplane below/right, then larger Lessons on the left, Games in the center, Progress farther down/right, and smaller Parents at the lower right. A pastel road, clouds and star posts connect the destinations. The next practice letter and saved level/XP/stars appear at the bottom, with the streak on its own row. Each button opens the correct screen; disabled Games stays locked.
- [ ] Home buttons have separate stationary tap areas while their artwork gently floats. The complete layout and footer remain reachable on short phones, tablets and with larger system text; Parents never covers Progress.
- [ ] Home mascots float/sway gently without shifting their tap areas. Motion pauses when leaving Home or backgrounding the app, and reduced motion keeps the artwork still.
- [ ] No overflow/clipped buttons on a small portrait phone or with larger system text.

## Lessons

- [ ] Letter Sounds and Short Vowel Sounds open.
- [ ] Previous, Next, and A–Z/vowel grid navigation work.
- [ ] Hear Letter and Hear Word play the expected existing recordings.
- [ ] Quick Check opens once after rapid taps; audio questions wait for playback.
- [ ] 3/5 records practice; 4/5 masters the letter.
- [ ] Retrying a mastered letter preserves mastery/date without duplicate milestones.
- [ ] Browsing letters alone does not award mastery, XP, or stars.

## Games

Repeat the behavior checks for every activity and each difficulty:

- [ ] Sound Match opens.
- [ ] Flappy Letters follows the illustrated reference: cream progress/lives panel with round Back/Help/Pause controls, airplane mascot above a sky/lavender card, mascot speech bubble, outlined Ready to fly title and gold Start flying button. Pause, Continue and Play again use the same styled card. On small screens or with enlarged text, scroll to reach the main action; header controls stay visible.
- [ ] Memory Flip opens.
- [ ] Phonics Quiz opens.
- [ ] Phonics Quiz advances automatically after the chosen sound and a 1.5-second correct-answer pause, has no Next button, and lets the learner retry an incorrect answer.
- [ ] Each Phonics Quiz choice plays the selected letter's phonics sound before answer feedback; auto-advance waits for the sound to finish and Voice Off mutes it.
- [ ] Word Builder opens.
- [ ] Speak & Recognize opens.
- [ ] Alphabet Order opens.
- [ ] Missing Vowel opens.
- [ ] Picture Match opens.
- [ ] Sound Position opens.
- [ ] Rhyming Words opens from Lessons.
- [ ] Instructions and current/total progress display correctly.
- [ ] Correct and incorrect answers show appropriate icons/text.
- [ ] Score reflects actual scored attempts; scored retries are explained.
- [ ] Result XP equals the change in saved XP, including completion bonus.
- [ ] Result stars equal the change in saved stars.
- [ ] Rapid answers/Next/completion taps never duplicate rewards.
- [ ] Play Again resets question, selections, score, completion, and per-play rewards.
- [ ] Back before starting returns directly; Back after starting offers Cancel/Leave.
- [ ] Cancel stays in the game; Leave returns to its source.
- [ ] Back to Games/Lessons and Home navigation do not build duplicate screen stacks.

## Progress

- [ ] My Letters matches the cloud-card design. All 26, New, Explored, Practiced and Mastered filters show the saved counts and open the selected letter's practice details.
- [ ] My Rewards shows the saved level, stars and XP on the treasure shelf. Locked badges remain purple, earned badges are gold, and tapping a badge opens its details without awarding rewards.
- [ ] Mastery count and percentage match completed Quick Checks.
- [ ] Not Started, Viewed, Practiced, and Mastered labels match real activity.
- [ ] Needs Practice lists attempted but unmastered letters.
- [ ] Recommended Next is consistent with the recorded progress.
- [ ] Weekly activity updates for actual scored answers/completions.
- [ ] Rewards are visually separated from mastery and accuracy.

## Parents

- [ ] Overview contains only the weekly summary, recommended Quick Check and detailed Progress link. Overall Letter Mastery, the duplicated learning summary and A–Z status cards appear only in Progress.
- [ ] Opening Quick Check or detailed Progress from Parents ends parent access, counts subsequent learner time and requires the PIN when returning to Parents.
- [ ] Activity tab uses green garden cards. Seven daily bars, weekly totals and daily accuracy agree with saved data; empty days show no activity. Recent Activity scrolls to Daily Breakdown, rows expand and View All lists earned/locked badges.
- [ ] Parent Panel matches the garden design: cream cards, green tabs, mascot, yellow switches and music slider. All Settings sections fit and scroll on small phones and with enlarged text.
- [ ] PIN creation requires matching valid four-digit entries.
- [ ] Wrong PIN is rejected; repeated failures trigger the existing cooldown.
- [ ] Correct PIN opens the parent dashboard.
- [ ] Changing the PIN requires the current PIN.
- [ ] Game access control blocks Game Zone through all available entry points.
- [ ] Reset Progress requires parent access and explicit confirmation.
- [ ] Rapid reset/PIN taps act once.
- [ ] Reset clears learning/rewards but retains the PIN, settings, and screen-time state.
- [ ] If saving a reset fails, the message says the reset is waiting to save. Retry persists the reset and reopening confirms zero progress.

## Screen time

- [ ] Time increases only while the learner app is in the foreground.
- [ ] Backgrounding/locking the phone does not consume learner time.
- [ ] Closing/reopening the app does not reset today's saved time.
- [ ] Navigating repeatedly does not speed up the timer.
- [ ] Limit blocks lessons, games, dialogs, and system Back.
- [ ] Parent unlock and extra time restore learner access correctly.
- [ ] Parent controls do not consume learner time.
- [ ] A new local day resets usage/extra time and keeps the configured limit.

## Speak & Recognize

- [ ] The microphone explanation appears before the first permission request.
- [ ] Permission denial shows a safe message without crashing.
- [ ] With permission and an available recognition service, Start Listening works.
- [ ] Stop, Next, Back, and rapid taps do not leave the microphone listening.
- [ ] “I heard”, “Recognized”, or “Try Again” matches the recognition result.
- [ ] No pronunciation-score/phonetic-analysis claim is shown.
- [ ] Test recognition in airplane mode and record whether the device has offline language support.

## Completion celebration

- [ ] Completing a game on Easy, Medium, or Hard shows a brief fireworks, stars, and confetti celebration with the results.
- [ ] Flappy Letters celebrates after all 26 letters are cleared; collisions and pauses do not trigger it.
- [ ] Play Again and Choose Next Game remain tappable during the celebration; reduced motion disables moving particles.

## Audio

- [ ] At a fixed device media volume, all A-Z letter names and phonics sounds are clear and similarly loud, including quieter F/H sounds. Check Lessons, quiz options, Rumbled Words, Word Builder, Speak & Recognize spelling, and Flappy Letters; no crackling or harsh clipped peaks.
- [ ] Button clicks are gentle and quieter than letter feedback. Rapid taps never interrupt a letter recording, and Sound Effects Off keeps clicks silent.
- [ ] Speak & Recognize follows the reference layout: top round/guide, purple picture and word plaque, green Hear Word, orange microphone, pink I heard card, and bottom cream tip. Permission/recognition messages and Next Word use styled controls; large text and small phones can scroll without overflow.
- [ ] Speak & Recognize Hear Word spells NET using letter names N, E, T (not phoneme sounds). Each matching letter grows while its recording plays; only after T finishes does the whole Net recording play. Repeated letters are animated separately.
- [ ] Speak & Recognize disables microphone capture during spelling. Repeated Hear Word taps cannot overlap; muting, Help/Leave, backgrounding, blocked access, and leaving stop all remaining spelling audio. Return stays silent until Hear Word is tapped again.
- [ ] Rumbled Words: every available letter option plays its supplied letter sound. Erase has the styled button and returns the last selected tile; chosen slots can also be tapped to edit.
- [ ] Rumbled Words difficulty selection shows the spelling lengths: Easy only 3-letter words (5 tasks), Medium only 4–5-letter words (6 tasks), Hard only words with 6 or more letters (8 tasks). Check a complete round and Play Again for each level; words never cross levels and each round has unique randomized tasks. MOON belongs to Medium; UMBRELLA and ELEPHANT belong to Hard.
- [ ] Rumbled Words: filling the slots checks the answer automatically. A correct word highlights and sounds each letter in order (including both O tiles in MOON), then highlights the whole word and plays its word recording before automatically advancing. No Check/Next button is needed.
- [ ] Rumbled Words: opening Help/Leave or backgrounding during completed-word playback pauses the sequence. Returning replays the interrupted step; leaving stops playback and does not advance. Muting voice retains the visual sequence and rewards are awarded once.
- [ ] Word Builder options play letter sounds before answer feedback; correct letters fly into their individual blank slots, including repeated letters. Wrong answers leave the slots empty.
- [ ] Hear Letter/Hear Word show their playing state and resist repeated taps.
- [ ] Switching recordings, answering, or leaving a screen stops/replaces the previous clip.
- [ ] Missing/disabled audio does not crash or invent a replacement recording.
- [ ] Sound-effects and voice settings work as currently designed.
- [ ] Generated CVC and Blending lesson instructions and positive feedback use a cheerful male voice; spelling remains clear and easy to follow.
- [ ] Games have no generated instruction voice, Hear Instructions button or spoken praise. Existing word/letter recordings and correct/wrong sound effects still work.
- [ ] Letter audio stops when muted, paused, backgrounded, covered by a dialog or using the microphone. Flappy Letters immediately plays the supplied letter recording each time a letter is cleared.

## Restart and lifecycle

- [ ] Home → Lessons/Games/Progress/Parents uses the four supplied cloud frames: the curtain closes, switches screens under full cloud cover, and opens in about 800 ms; Back reverses the curtain. Navigation and page controls reject repeated taps while moving. Check smoothness on the target Android phone and tablet.
- [ ] Reduce Motion skips the cloud transition and frame decoding. Missing transition artwork falls back to normal navigation; the destination still opens without an error.
- [ ] Learning progress and rewards survive a complete restart.
- [ ] Parent PIN/settings survive restart; the parent session requires authentication again.
- [ ] Today's screen-time state survives restart.
- [ ] Backgrounding/resuming during audio, Quick Check, and a game does not crash.
- [ ] Closing the PIN form during a pending action does not crash.

## Additional checks from the 2026-10-07 review

- [ ] All games with an active round show the illustrated Leave confirmation: rabbit above the cream/lavender panel, golden exit door, leaves/stars/clouds, purple Cancel, and gold Leave over a dimmed, blurred game. Cancel/device Back preserves the round; Leave exits once, including rapid taps. Buttons remain reachable on small phones and with large text.
- [ ] Sound Match, Phonics Quiz, and Word Builder keep the current task/answer while the Leave dialog is open. Cancel resumes automatic advancement; Leave does not trigger a later task/result.
- [ ] Background or lock the phone immediately after an answer in those games. No next task appears until the learner returns.
- [ ] Reach the daily limit during answer feedback. Tasks wait while access is blocked and continue after parent-authorized extra time.
- [ ] Complete the final task while opening Leave/backgrounding. Check that celebration and rewards appear once, when the game is accessible.
- [ ] Deny microphone access, grant it in Android Settings, and retry without leaving Speak & Recognize. Try Microphone Again reinitializes permission/service support; permanent denial offers Open Device Settings.
- [ ] Background Speak & Recognize during listening and open a dialog during recognition. Check whether listening stops and whether a late result changes the covered task.
- [ ] Try a different valid word one letter away from the speech target; it must be rejected. Easy/Medium accept the exact target within a phrase; Hard requires the target alone. This is recognized-word matching, not pronunciation assessment.
- [ ] Progress and parent recommendations open Meet Letter for new/viewed letters and Quick Check for practiced/mastered letters. Hear Letter, Hear Sound, and Hear Word use the supplied recordings.
- [ ] Parent listening counts update only after completed playback. Listening alone never awards mastery; letter/word Quick Check status stays separate.
- [ ] Parent Activity shows speech attempts, recognized words, and completed speech activities separately from phonics accuracy. Speech practice can maintain the learning streak.
- [ ] How to Play shows visual examples for each game. New help guides open on demand; the original Flappy/Memory/Builder guides retain their first-visit behavior.
- [ ] Every game's How to Play follows the purple/gold banner, three step indicators, sky/garden example, gold step title, dashed cream instructions, pale Skip and purple Next/Let's Play design. Skip/Next stay visible while long content scrolls; Back revisits the previous step. Reduced motion disables the example entrance animation.
- [ ] Help examples match each game: Alphabet Order starts at A and places letters in order; Sound Match advances after answer feedback; Memory uses matching pictures and explains the 3-second preview; Speak & Recognize explains letter-name spelling then the whole word. Skip/completion keeps first-visit persistence and manual Help replay.
- [ ] A wrong Sound Match choice briefly shows the correct letter before advancing.
- [ ] Verify the optimized artwork retains transparency and clarity on Android. Check every game/lesson background, Home mascot, letter card, and animation.
- [ ] After a temporary save failure, the Parent Panel reports pending changes. Retry saves the latest state; reopening restores progress and screen time correctly.
- [ ] On the lowest-spec target phone, measure launch time, memory, and animation frame timing in profile/release mode; exercise all screens with large text and TalkBack.
- [ ] Compare word/letter recording loudness on the target speaker, including Flappy Letters; confirm generated game instruction/praise voices remain absent.

## CVC / Blending recordings imported 2026-10-08

- [ ] With voice enabled, confirm both lesson intros and Blending's "Try another spot!" use the supplied recordings.
- [ ] Browse all 17 CVC words and 22 Blending words in `docs/CVC_BLENDING_REFRESH.md`. Each uses the supplied picture, word-only recording, and praise; verify MOP word-only and MOP praise play at the correct stages.
- [ ] CVC completion displays "Cat! Nice work! C-A-T makes cat!" (and the matching sentence for each word); Blending uses "Great job!". Listen for text/audio agreement, pronunciation, and consistent volume.
- [ ] Confirm replay, Next, mute, and leaving a lesson stop or advance playback correctly with the new recording lengths; compare volume on the target phone speaker.
- [ ] The complete replacement uses 81 supplied MP3 recordings and 39 optimized pictures. The 119 old lesson WAV files are removed. Shared isolated letter sounds remain available across lessons/games.

## Easy / Medium / Hard recordings refreshed 2026-10-08

- [ ] Listen to the 23 Easy, 23 Medium and 24 Hard replacements in `tools/game_audio_refresh_manifest.json`; compare word agreement, pronunciation and volume on the target speaker.
- [ ] Hear/replay the same word across applicable games (including Rumbled Words, Word Builder, Picture Match and Speak & Recognize); confirm the shared new recording plays and navigation/mute cancels it correctly.
- [ ] Confirm Jacket and Ice Cream resolve the new files despite source filename differences, and Yarn displays both new picture frames.
- [ ] Violin plays the separately supplied new recording. Umbrella is absent from every game and difficulty, including Hard Rumbled Words; the U lesson still works.
- [ ] Confirm the recently replaced CVC/Blending narration still plays its own word/praise clips.

## Letter Adventure

- [ ] Home's Start Quick Check opens the recommended letter; after mastery it recommends the next unmastered letter.
- [ ] Complete all five activities using both tap and drag for matching. Confirm small screens, landscape and larger text remain usable.
- [ ] Sound previews do not submit answers; unfinished playback cannot unlock choices. Listen/replay controls stay separate from selecting answers.
- [ ] Check actual short-vowel, hard C/G, Qu and final X pronunciation against the displayed tasks. Umbrella never appears.
- [ ] First answers stay locked. Guided correction after the result leaves the original score unchanged.
- [ ] A score of 4/5 fails when either sound activity is wrong; it passes when both sound activities are correct.
- [ ] Letter hunt includes four targets in both letter cases. Duplicate taps do not count; mistakes are reflected in the score.
- [ ] First completion/mastery rewards appear once. Restarting or revisiting preserves mastery without repeating rewards.
- [ ] Close and reopen the app; new overall mastery and earlier Quick Check progress remain intact and separate.
- [ ] Progress's letter selector opens any A–Z adventure; milestone locks match actual mastery count.
- [ ] Complete a new Quick Check, reopen the app and compare Progress and Parents: mastery, best/latest score, status and achievements must agree. Older assessment results must not appear as current mastery; lesson listening counts remain visible.
- [ ] Check the smaller Home recommendation/status panels and larger logo/mascots. Tap areas must remain separate on every screen size.
- [ ] Match result, mastery and encouragement card colors/layout to the supplied references; scores and rewards must show real values. Check all result actions and the practice/retained mastery states.
- [ ] Supplied colorful choice frames display the actual letter/picture. Speaker taps preview only; Choose remains locked until playback finishes. Test letters outside a/b/c/d and both letter cases.
- [ ] Background, navigation, time limit and audio controls stop speech cleanly.
- [ ] Check all eleven supplied instruction recordings against the recording script; Voice Assistance controls narration and turning it off stops an active instruction.

## Review findings log

| Steps / screen | Expected | Actual | Device / evidence |
|---|---|---|---|
| | | | |

## Rhyming Jar Adventure (2026-10-09)
- [ ] Intro and target word play before answers unlock.
- [ ] Choice taps use only correct/wrong effects, with no word voice.
- [ ] Three different correct choices send star energy into the jar; duplicate taps do not earn rewards.
- [ ] Wrong choices shake; progress does not change and the learner can retry.
- [ ] Full jar moves/grows into the center, then family words emerge and the praise recording reads the target first.
- [ ] Check every family recording for target/rhyme pronunciation and varied praise, especially LED pronounced like BED.
- [ ] Replay individual revealed words; Next Jar waits for playback.
- [ ] Pause during a star flight; resume retains collected energy. Background during speech; resume safely restarts that recording.
- [ ] Mute/unmute, leave/cancel, parental time limits and game lock remain usable.
- [ ] Easy/Medium/Hard show 5/7/9 choices, with exactly three correct rhymes. Umbrella never appears.
- [ ] Finish and Play Again preserve saved rewards and reset jar progress.
- [ ] Check phone performance and visual fill alignment on the jar and EXP gauge.


## Animated Home redesign

- [ ] Opening reveals the logo, airplane, four destinations, Quick Check, and badges in about 3.6 seconds. Skip intro finishes immediately.
- [ ] Open a destination during the intro; returning Home does not replay the intro. Parent game lock still works.
- [ ] Background the app during the intro; animation pauses and resumes. Reduced motion displays everything immediately.
- [ ] Check 320px phones, tall phones, landscape, and large text. All controls and badges remain reachable by scrolling.
- [ ] Quick Check shows Practice for a new letter, Review for an attempted unmastered letter, and Alphabet Master after all 26.
- [ ] Verify Level, XP, Stars, and Streak match saved progress after reopening.
- [ ] Hear the four-voice KidsPhonics cheer once at logo entrance; Skip intro stops it.
- [ ] Lessons, Games, Progress, and Parents play their supplied lines on tap without delaying navigation.
- [ ] Voice Assistance off, parent game lock, backgrounding, and rapid navigation cancel or prevent Home speech.
- [ ] Quick Check now includes all eleven supplied recordings; verify automatic instructions, Replay instruction, neutral answer-saved feedback and mastered/practice result praise.


## Quick Check illustrated design

- [ ] Compact wooden Quick Check title keeps the task visible; no large Game Zone banner.
- [ ] Intro uses the selected letter, wooden adventure sign, mascot instructions, five empty stars and Start Adventure.
- [ ] All five activities use consistent purple panels, buttons and skill titles.
- [ ] Progress and gold stars count submitted challenges, including incorrect first answers; no correctness hint is shown before results.
- [ ] Matching supports tap and drag; sounds and pictures retain separate Listen and Choose controls.
- [ ] Four selected hunt targets turn green; wrong taps remain retryable and count toward the existing assessment policy.
- [ ] Check short phones, landscape, large text and A?Z letters. Scroll reaches all controls; Back during a task asks before leaving.
- [ ] Result rewards, mastery and guided review preserve the original score and save correctly.
