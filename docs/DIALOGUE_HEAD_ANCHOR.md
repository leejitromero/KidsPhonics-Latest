# Dialogue placement at the speaker's head

Home speech now sits above and to the right of the student's head, following
the supplied reference. The visible tail points toward the hair with an
eight-logical-pixel gap. Placement includes the wave atlas's small transparent
head margin and the bubble artwork's actual tail location, rather than using a
fixed screen percentage or the transparent image boundary.

Boy speech uses the blue oval bubble; girl speech uses the pink bubble. All
bubbles preserve their native aspect ratio. Text stays inside the white center.
Available space below the logo and inside screen insets limits bubble size.

Lala and Lulu introductions use their actual fitted mascot bounds. Lulu's
bubble is mirrored toward the right mascot. The speaker remains the anchor
after recording playback finishes, so the dialogue does not jump to the other
mascot. Guideline dialogs use the same placement geometry for the bubble and
speaker. Recorded voice timing, student walking and navigation remain intact.

Verification: the 18 new speaker-alignment checks cover both students, both
mascots, phone/tablet sizes and guideline dialogs. The existing 35 Home,
onboarding, voice and layout regressions passed. The final 29 layout checks
(18 alignment plus 11 existing layout checks) passed after refining the PNG
margin handling. Flutter analysis found no issues.

Logs: `build/dialogue-anchor-regressions.log`,
`build/dialogue-anchor-final-layout.log`, and `build/dialogue-anchor-analysis.log`.
Rendered previews: `build/ui_previews/update_dialogue_girl.png`,
`update_dialogue_boy.png`, `update_dialogue_lessons.png`, `update_dialogue_games.png`,
and `update_dialogue_guideline_*.png`. Physical-device playback and layout have
not been checked.
