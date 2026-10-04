# NEW UI design references

The 13 original PNG mockups from `NEW UI.zip` are preserved in `new_ui/`.
They are design references, not runtime screenshots or executable instructions.
They are deliberately outside the Flutter asset bundle.

User clarification: **apply the new designs without the large header/banner**.
Back, Help and Pause remain usable. The existing questions, difficulties,
audio, rewards, timers, parent PIN and progress persistence remain live.

| Reference | Implementation |
| --- | --- |
| game zone ui.png | `games_screen.dart`, responsive pastel `GameZoneCard` grid |
| alphabet order UI.png | Star placeholders, colorful letter tiles, live placement |
| flappy letter UI.png | Blue bird, shaded green pipes, compact cream score/lives panel |
| memory flip UI.png | Collection panel, star placeholders and glossy flip tiles |
| missing vowel UI.png | Word illustration, cream word panel, teal audio and vowel tiles |
| phonics quiz UI..png | Word illustration, instruction pill, teal audio and letter tiles |
| picture match.png | Word/audio above the picture target, two-column picture choices |
| rhyming words UI.png | Cream question sign, illustration, illustrated choices when available |
| rumbled words.png | Word illustration, selected slots, hint/audio and framed tile tray |
| sound match UI.png | Word illustration, sound control and colorful letter choices |
| speak and recognize UI.png | Lavender picture panel, word plaque, audio and microphone information |
| world bulder UI.png | Word illustration, cream blank-letter panel and colorful answer tiles |
| parent ui design.png | Garden background, cream overview cards, pastel statistics and live progress |

Common components live in `lib/widgets/game_design.dart`. They are scoped to
games so lesson controls keep their own appearance. Existing game word
illustrations, menu logos and animated backgrounds are reused. The new runtime
assets are documented in `assets/images/new_ui/README.md`.

Mockup examples are not hardcoded game data. In particular, the pictured rhyme
choices for NEST do not provide a correct rhyme; the app retains its validated
round data. Statistics and dates in the Parent mockup are also illustrative.
All 11 games remain available although the menu mockup displays only six.

## Local checks and previews

```powershell
C:/flutter/bin/flutter.bat analyze --no-pub
C:/flutter/bin/flutter.bat test --no-pub --dart-define=CAPTURE_UI=true test/new_ui_layout_test.dart
```

The layout test covers 320×568, 390×844 and 800×1024, including Hard layouts.
The optional capture flag saves actual Flutter renders to `build/ui_previews/`.
Previews use seeded empty progress and disabled decorative animation.
The image references are not used as static screens or invisible tap targets.
No APK build or deployment is part of this design update.
