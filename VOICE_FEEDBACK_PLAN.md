# Natural English voice feedback

Requested voice: natural female English AI voice. Generation service is pending.
The user supplied an Emma - Bright Kids Educator recording with the stated
script "Wow! Great job!". It is installed as
`assets/audio/phonics/feedback/emma_wow_great_job.mp3` and mapped to the existing
`Great job!` phrase. Listening validation remains pending. Other new recordings
and game-event integration remain pending.

Generate short, warm, clearly spoken recordings with one consistent voice,
without music or sound effects. Bundle the resulting files for offline playback.
Do not substitute Windows Zira for the requested neural voice.

## Proposed first recording batch

| Clip | Script | Trigger |
| --- | --- | --- |
| praise_1 | Great job! | Correct answer |
| praise_2 | Yes, you got it! | Correct answer |
| praise_3 | Nice work! | Correct answer |
| wrong_1 | Good try. Try again! | Incorrect answer |
| wrong_2 | Let's try one more time. | Incorrect answer |
| win_great | Great work! You finished the activity! | Completed activity |
| win_good | Good effort! Keep practicing! | Completed activity with retries |
| intro_voice | Tap the microphone and say the word. | Speech practice introduction |
| recognized | The word was recognized! | Speech recognizer matches the target |
| not_recognized | Let's try again. Say the word clearly. | Recognizer returns a different word |
| level_up | You reached a new level! | Reward level increases |
| achievement_xp | You earned one hundred points! | First crossing of 100 XP |
| achievement_streak | You practiced three days in a row! | Three-day practice streak |

## Integration still required

- Generate and listen to the new clips before replacing current assets.
- Connect answer and completion feedback to game events; most current games use effects only.
- Respect Voice Assistance and prevent overlap with word cues and microphone capture.
- Cancel feedback on navigation, replay, and app backgrounding.
- Speech recognition feedback must not claim perfect pronunciation.
- Verify playback on the target Android device and produce a fresh APK when requested.

Existing reward announcements now check Voice Assistance before starting.
