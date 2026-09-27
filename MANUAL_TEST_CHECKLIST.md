# Manual Test Checklist — KidsPhonics

Use the cleaned version on the target Android phone. Leave boxes unchecked until actually tested. Record any failure with device/Android version, steps, expected result, and actual result. This checklist covers current features and assets only.

Device / Android version: ____________________
Tester / date / build identifier: ____________________

## App startup

- [ ] App opens without crashing, including a first launch in airplane mode.
- [ ] Home text, mascot, rewards, and navigation display properly.
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
- [ ] Memory Flip opens.
- [ ] Phonics Quiz opens.
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

- [ ] Mastery count and percentage match completed Quick Checks.
- [ ] Not Started, Viewed, Practiced, and Mastered labels match real activity.
- [ ] Needs Practice lists attempted but unmastered letters.
- [ ] Recommended Next is consistent with the recorded progress.
- [ ] Weekly activity updates for actual scored answers/completions.
- [ ] Rewards are visually separated from mastery and accuracy.

## Parents

- [ ] PIN creation requires matching valid four-digit entries.
- [ ] Wrong PIN is rejected; repeated failures trigger the existing cooldown.
- [ ] Correct PIN opens the parent dashboard.
- [ ] Changing the PIN requires the current PIN.
- [ ] Game access control blocks Game Zone through all available entry points.
- [ ] Reset Progress requires parent access and explicit confirmation.
- [ ] Rapid reset/PIN taps act once.
- [ ] Reset clears learning/rewards but retains the PIN, settings, and screen-time state.

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

## Audio

- [ ] Hear Letter/Hear Word show their playing state and resist repeated taps.
- [ ] Switching recordings, answering, or leaving a screen stops/replaces the previous clip.
- [ ] Missing/disabled audio does not crash or invent a replacement recording.
- [ ] Sound-effects and voice settings work as currently designed.
- [ ] No automatic AI voice feedback is introduced by these UI changes.

## Restart and lifecycle

- [ ] Learning progress and rewards survive a complete restart.
- [ ] Parent PIN/settings survive restart; the parent session requires authentication again.
- [ ] Today's screen-time state survives restart.
- [ ] Backgrounding/resuming during audio, Quick Check, and a game does not crash.
- [ ] Closing the PIN form during a pending action does not crash.

## Findings

| Steps / screen | Expected | Actual | Device / evidence |
|---|---|---|---|
| | | | |
