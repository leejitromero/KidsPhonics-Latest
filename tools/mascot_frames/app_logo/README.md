# App mascot and launcher artwork

User-supplied `appicon.png` is the source for the static mascot and Android
launcher icon. The splash animation uses the supplied frames in numeric order:
1, 2, 3, 5, 6, 7. No frame 4 was supplied. Each frame lasts 160 ms and the GIF
loops, clearing to transparent between frames.

Runtime assets:
- `assets/images/app_mascot.gif`: 512 × 512 splash animation.
- `assets/images/app_mascot.png`: 512 × 512 static/reduced-motion mascot and
  adaptive foreground.
- `assets/images/app_icon.png`: 1024 × 1024 opaque purple launcher source.

Launcher icons are static. Regenerate Android densities using
`dart run flutter_launcher_icons`; configuration lives in `pubspec.yaml`.
The adaptive foreground has a 22 percent inset to protect artwork from masks.
The older `app_icon.svg` and historical icon generators are not the current
branding source.
