# School home and student sprites

The Home screen now uses the five user-supplied images, copied unchanged from Downloads into `assets/images/school_home/`:

| Source | Bundled file |
| --- | --- |
| `new_BG.png` | `background.png` |
| `BOY FRAME.png` | `boy_wave.png` |
| `GIRL FRAME.png` | `girl_wave.png` |
| `lesson_mascot.png` | `lessons_mascot.png` |
| `game_mascots.png` | `games_mascot.png` |

The purple guide sits left of the student and the blue guide sits right. Classroom signs and bottom navigation are already part of the background; aligned semantic tap regions open Lessons, Games, Progress, Parents and student Settings. Parent authentication, game restrictions, learning progress and existing narration remain in their existing flows.

Both 2172 × 724 sprite sheets have five poses. `StudentWave` uses registered crop boundaries, because the poses are not evenly spaced. It shows a brief wave followed by an idle pause and stops animation when backgrounded, covered by another route, or reduced motion is enabled. These are image sprites, not rigged 3D models or walking frames. Classroom entry translates and scales the student during the existing short navigation transition.

The supplied 1024 × 1536 background keeps its logo, school and navigation proportions. A central courtyard slice extends on taller screens; short screens can scroll. Hit regions follow the same mapping and navigation targets are at least 48 logical pixels.

Tap the student or Settings to choose Boy/Girl and enter a nickname. Selection is saved in the existing preference snapshot without resetting progress. Until customized, Home shows the boy with “Hi, friend!”; forced first-launch onboarding is not part of this change.

Home suggestions still use the existing next-letter/review recommendation and open Quick Check. Audio uses existing recordings; the nickname is displayed as text and does not have a generated voice.

Local preview screenshots can be regenerated with:

```powershell
flutter test test/home_mascot_menu_test.dart --dart-define=CAPTURE_UI=true
```

Outputs: `build/ui_previews/school_home_320.png`, `school_home_390.png`, `school_home_430.png`, `school_home_768.png`, and `school_home_girl.png`.
