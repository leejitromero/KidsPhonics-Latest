# Current Quick Check presentation

Home follows the supplied layout references with larger Lessons, Games, Progress and Parents mascots. The compact recommendation places Start Quick Check beside the live letter details on regular phones, with Level, XP, Stars and Streak in one row below. Narrow screens and larger text stack the content and can scroll. Mascot tap areas remain separate.

Home, Progress and Parents share the same Quick Check recommendation card and saved recommended letter. Every Start Quick Check action opens the current five-challenge Letter Adventure directly, including for a letter that has only been viewed. The earlier Progress Up next and Parents Needs Practice cards are replaced by this shared entry point.

The result uses the supplied reference's wooden heading, purple mastery banner, gold score/reward panels, five individual skill rows, and illustrated action controls. Scores, earned XP/stars and the recommended next letter come from the actual saved assessment. Practice results and retained mastery are shown accurately; retries and guided correction keep the original scoring policy.

Progress reads Letter Adventure results for mastery, best/latest scores, A–Z statuses, vowel mastery and mastery badges. Parents uses these results only for the weekly newly mastered count and recommended practice. The old assessment records stay stored, while lesson views and recording-listening counts remain visible separately in Progress. New mastery timestamps survive reopening and allow Parents to report the actual week of mastery. Existing saved adventures without a timestamp remain readable.

The Overall Letter Mastery and encouragement cards follow the purple/gold reference with live values. Compact variants keep the letter selector and reward tabs usable.

Progress uses smaller card padding, headings, mastery rings, letter tiles, treasure statistics and badge medals across My Journey, My Letters and My Rewards. Letter tiles fit four columns on a regular phone, while narrow screens and larger text reduce the column count. Milestone chips and the mastery panel use compact layouts. Actions and live progress values remain available.

Parents uses compact garden cards across Overview, Activity and Settings, with smaller headings, icon badges, statistics, chart bars and gaps between sections. Overview contains the weekly summary, recommended Quick Check and a link to detailed Progress. The Overall Letter Mastery panel, duplicated learning summary and A–Z status cards were removed from Parents. The weekly chart grows naturally with text size. Settings retain their existing actions and readable controls, including the time limit, audio toggles, PIN change and reset confirmation. Opening Quick Check or detailed Progress from Parents ends the parent session so subsequent learner time is counted and returning requires the PIN.

Quick Check uses the approved blue, orange, green, violet and pink speaker-button palette. Flutter paints each rounded gradient face, matching rim, highlight and depth as one surface, with live letters or pictures inside it. Picture and sound cards share their surface with the speaker control, avoiding stacked frames or patches over sample letters. Hear sound is blue, Hear word is orange, and instruction replay is pink. Playback shows an equalizer icon. Speaker taps preview audio independently; a sound choice unlocks only after its recording completes.

The earlier letter/sound choice sheets are preserved as design references in `tools/design_references/quick_check/` and are no longer bundled in the app. Matching, spelling and letter hunt use the same painted button family, with a white outline for selected choices.

Relevant regression coverage includes `quick_check_progress_integration_test.dart`, the Quick Check design/narration tests, Home layout/voice tests, dashboard and parent controls tests. Screenshots are generated under ignored `build/ui_previews/` using `--dart-define=CAPTURE_UI=true`. These screenshots and source sheets outside assets are not packaged into the app.
