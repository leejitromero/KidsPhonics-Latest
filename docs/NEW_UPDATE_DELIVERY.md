# New school scene update

The artwork from `New update changes.zip` is bundled unchanged in
`assets/images/update_scene/`. Spaces in filenames were replaced with underscores;
the supplied spelling `lessin_signage.png` is retained. The supplied reference was
used for placement, rather than bundled as a flattened interactive screen.

Home uses `bg_new.png`, the separate `kids.png` logo, the two talking mascots and
the two signage images. Signs sit near the left and right edges. The selected
student stands in the center, above the practice button. There is no Home
navigation bar or app bar. Tapping the student opens profile editing.

First-time flow: loading → Lessons introduction → Next → Games introduction →
Done → character/name setup → Home. Completion and the selected character/name
are saved with the existing authoritative preference snapshot. Previously named
profiles are retained and skip first-time setup. Editing identity retains learning
progress. Blank names are rejected.

Home entry uses a 1.8-second walk. Frames 2–5 face Games on the right; frames 7–10
face Lessons on the left. The student travels beyond the viewport and fades at
the end, then the destination opens. Repeated navigation taps and backgrounding
are guarded. Reduced motion opens destinations without walking.

Lessons, Games, Progress and Parents use their supplied morning, sunset and night
images. Each scene begins at 3.5-second intervals, with a 650 ms crossfade at the
end of the interval. The cycle repeats morning → sunset → night → morning. It
pauses when covered or backgrounded; reduced motion shows morning.

These category screens share themed bottom navigation and the learner's framed
portrait, name, level and stars. They have no app bar or category banner. Progress's
previous navigation bar was removed to prevent duplicate menus. Existing lesson
activities, game mechanics, parent authentication and saved learning data remain
in their existing flows.

The Lessons and Games help buttons show the supplied talking mascot and readable
guidelines. The new introduction and guideline audio mappings are ready for the
recordings listed in `NEW_UPDATE_RECORDING_SCRIPT.md`. Text and controls work
while the new recordings are pending. Existing short category welcome audio is
retained.

Validation covers first-time ordering, required name entry, restored profiles,
left/right walking and category navigation, background timing and lifecycle,
parent controls and failed-save recovery. Screenshots cover 320, 390, 430 and 768
logical-pixel widths.

Preview images are in `build/ui_previews/update_*.png`. Regenerate them with:

```powershell
C:/flutter/bin/flutter.bat test test/updated_scene_test.dart --dart-define=CAPTURE_UI=true
```

The targeted regression run of `updated_scene_test.dart`,
`parent_controls_widget_test.dart` and `save_recovery_test.dart` passed 23 tests.
`flutter analyze --no-pub` reported no issues after the final source refinements.
