# Home reference update

Home now follows the supplied courtyard reference: a wooden hanging rainbow
KidsPhonics title, labeled purple Lessons and blue Games rooms, a centered
selected student, and a separate Lessons / Practice / Games button row.
The guides still appear in first-time onboarding; the regular Home row uses
the reference's book and controller buttons without additional mascots.

The background uses full-screen normalized coordinates with `BoxFit.fill`
so tall phones display both room signs and doorways in full. This adapts the
architecture's proportions to each screen. The student and button images keep
their own layout sizes. Buttons retain at least 48 logical pixels of tap height,
safe bottom insets, and visible gaps from one another and from the student.

After tapping Lessons or Games, the selected student finishes the recorded
“Let's learn!” or “Let's play!” cue before walking. Walking has constant size,
height, opacity, and horizontal speed. The student passes the corresponding
open doorway and continues fully beyond the screen's clipped edge before
the destination fade starts. Backgrounding cancels the visit, and reduced
motion skips the walk.

Every fresh launch with a saved learner profile now requests the existing mixed
KidsPhonics title recording after loading and the Home fade complete. First-time
onboarding retains its title-before-introductions sequence. The cue does not
repeat when returning from a room or after profile setup. An interrupted startup
cue restarts on resume; a completed cue does not. Muted voice skips it. The
student's five-second idle greeting starts only after the title finishes.

## Artwork

The built-in `image_gen` tool edited the existing classroom background, adding
the hanging wooden title and the room-board text while preserving the doorways
and empty foreground for animated overlays.

- Saved asset: [home_classrooms_reference.png](../assets/images/update_scene/home_classrooms_reference.png).
- Source: [home_classrooms.png](../assets/images/update_scene/home_classrooms.png).
- Exact final prompt and tool record: [home_reference_art_prompt.json](../tools/home_reference_art_prompt.json).

## Verification

Rendered previews: `build/ui_previews/school_home_320.png`, `school_home_390.png`,
`school_home_430.png`, `school_home_768.png`, and `school_home_girl.png`.
Layout checks include portrait phones, a tablet, landscape fallback, safe system
insets, separate tap targets, and large introduction text. Walking regressions
check unchanged size and height, absence of an opacity fade, and a fully exited
student before navigation. Startup audio checks exercise two fresh launches,
interruption/resume, returning routes, muting, and completion-driven idle speech.

All 62 scoped checks passed in `build/home-reference-verified-tests.log`;
static analysis found no issues (`build/home-reference-analysis.log`). The asset audit includes
the new background. Physical-device audio and animation have not been checked.
