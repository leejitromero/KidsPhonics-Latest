# Classroom home screen

The home screen uses the three supplied `home_bg_01`, `home_bg_02` and
`home_bg_03` images. Their bytes are preserved in
`assets/images/home_classroom/morning.png`, `sunset.png` and `night.png`.
The KidsPhonics sign, Lessons and Games row, and centered Practice button keep
the reference positions. The complete portrait image fills the screen without
cropping, following the app's existing fullscreen artwork convention.

Lala appears behind Lessons and Lulu behind Games. The chosen boy/girl waves
on the rug between them, remains editable by tapping the character, and walks
offscreen before opening the selected category. One day-cycle controller paints
both the room and the original button silhouettes in front of these characters.
This preserves the reference buttons and keeps both layers synchronized through
the 650 ms fade between morning, sunset and night at 3.5 second intervals.
Motion pauses with app lifecycle, covered routes, and reduced-motion settings.

Small wooden Progress and Parent shortcuts sit in the upper safe corners.
They open the existing screens, including the existing Parent PIN flow. Games
restrictions apply to both the Games button and its guide. Tap targets are at
least 48 logical pixels tall and keep the bottom safe inset clear.

The Practice plaque follows saved adventure progress. The original A artwork
is retained initially; only the printed letter areas are covered when the next
letter changes. Completing all letters displays Review Letters. Existing voice,
character setup, progress, rewards, and navigation logic remain in use.

## 8K exports

- `output/home_classroom/8k/morning-8k.png`
- `output/home_classroom/8k/sunset-8k.png`
- `output/home_classroom/8k/night-8k.png`

All three exports are **5120 x 7680 pixels**, retaining the 2:3 portrait ratio.
These are high-quality bicubic upscales of the 1024 x 1536 supplied sources,
not native 8K renders with newly recovered detail. Source and export SHA-256
hashes and dimensions are recorded in `output/home_classroom/8k/manifest.json`.
Regenerate them with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/export_home_classroom_8k.ps1
```

The built-in imagegen tool was tried for enhancement. It returned a 1024 x 1536
variant, saved for comparison as `output/home_classroom/morning-enhanced.png`.
Its prompt and actual resolution are in `output/home_classroom/imagegen.json`.
The supplied sources were selected for the app and 8K exports to preserve the
exact approved composition. The app bundles the smaller originals and decodes
them to display size rather than loading three full 8K bitmaps into phone RAM.
The 8K files are standalone artwork deliverables outside the APK bundle.

## Checks and previews

`test/home_classroom_reference_test.dart` verifies source identity, actual 8K
PNG dimensions, direct Progress/Parent navigation, Games restrictions, and
synchronized foreground/background animation including lifecycle pauses.
Existing home, onboarding, speech, progress, asset, and layout regressions also
cover the revised screen. Layout checks include 320 x 568, 390 x 844,
430 x 932, tablet, and compact landscape sizes.

Run home previews with:

```powershell
flutter test test/home_classroom_reference_test.dart --dart-define=CAPTURE_UI=true
```

Morning, sunset and night previews are written to
`build/ui_previews/update_classroom_home_*.png`. Copies for review are saved in
`output/home_classroom/previews/`.

Validation completed: Flutter analysis found no issues; 90 scoped regression
tests passed, and all 5 reference tests passed again while capturing previews
at phone display density. The debug APK is
`build/app/outputs/flutter-apk/app-debug.apk`. Its three home images were
verified against the original source hashes, and 8K export masters are excluded
from the mobile bundle. The results and APK hash are recorded in
`tools/home_classroom_reference_verification.json`.
