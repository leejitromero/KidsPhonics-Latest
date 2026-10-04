# Latest APK delivery — October 2, 2026

File: `KidsPhonics-latest-2026-10-02.apk` (314,832,323 bytes; 300.2 MiB).
Built successfully from the current source, version 1.0.2+3, including the
three-frame Home artwork, restored four-card Lessons menu, removal of Home's
Continue Learning button, compact Game Zone welcome, and loading percentage.
APK v2 signature verification passed. All three new Home frames in the APK
match the source assets by SHA-256. No device installation test was performed.

SHA-256: `C052406C2E384ABABB72BF143B6BBAB72BA9C672CE212EFD2BB61327D749BF57`.
Checksum file: `KidsPhonics-latest-2026-10-02.apk.sha256`.

The notes below record earlier source updates and APK deliveries.

---

# Main screen replacement — October 2, 2026

## Compact Game Zone welcome — October 2, 2026

Replaced the large landscape welcome card, wooden sign, and speech bubble
with a transparent row over the shared sky: a 72-pixel Wigloo, a 28-pixel
Game Zone heading, and a 15-pixel message. White text outlines keep it readable.
Text wraps and scales for accessibility. Static analysis found no issues;
all four Game Zone layout, category, and difficulty-picker tests passed.
No APK rebuild was performed.

## Main screen practice shortcut removed — October 2, 2026

Removed Home's Continue Learning / Explore Lessons button. Practice remains
available through the existing Practice This Letter flow. The recommendation
text, rewards, and four artwork navigation controls remain. Static analysis
found no issues; the 14 Home layout and artwork tests passed. No APK rebuild.

## Lessons menu restored — October 2, 2026

Restored the previous two-column, four-card Lessons menu from the user's
screenshot: Practice My Tricky Letters, Letter Sounds A–Z, Short Vowel Sounds,
and Rhyming Words. The Wigloo welcome, mastery counts, progress indicators,
and Rhyming Words difficulty picker are restored. The five-level journey menu
is no longer shown on Lessons. Saved learner progress is retained.

Validation: static analysis found no issues; all 18 targeted lesson menu,
home layout, artwork navigation, and animation tests passed. No APK rebuild
was performed for this restoration.

Source: the user's `main screen (2).zip`. Its three PNGs are imported unchanged
as `assets/images/screen_frames/home/main-1.png` through `main-3.png`;
`framee2.png` is the second frame. SHA-256 checks confirm each imported file
matches its ZIP entry. All three canvases remain 941 × 1672 pixels.

- Home displays the entire supplied artwork, including KidsPhonics lettering
  and the Parents sign, over the existing animated sky background.
- Removed the separate Home title and Parents balloon to avoid duplicates.
- Lessons, Games, Progress, and Parents use tap regions aligned to the new art.
  Parents still opens the PIN gate; parent restrictions still disable Games.
- Three-frame playback uses 300 ms steps in a forward/back loop. Reduced
  motion, lifecycle pause/resume, Continue Learning, and rewards remain supported.
- Static analysis: no issues. All 14 targeted artwork/navigation/layout tests
  passed, plus the preview-render check. Layout checks cover 320, 600, and 900
  logical pixels with 1.8× text scaling.
- Visually reviewed previews with bundled fonts at 390 × 844:
  `build/main_screen_new.png` and `build/main_screen_new_bottom.png`.
- This update is in source only. No APK was rebuilt for this replacement;
  the APK details below describe the earlier October 1 delivery.

---

# Animated screen update — October 1, 2026

Sources: the user's `update screen.zip` and `parents logo.zip`. Imported only
the PNG frames, without modifying the source artwork. The background/menu frames
remain 941 × 1672 pixels; the five transparent Parents frames are 1254 × 1254.

## Screens

- Background: `bg-1.png` through `bg-5.png`, now used behind Home, Lessons,
  learner activities, Game Zone, and Progress. Frames blend in a forward/back
  loop with 450 ms per transition, avoiding a sudden jump from frame 5 to 1.
- Home: the five transparent `fr-*.png` plane/menu frames play at 300 ms per
  frame in a forward/back loop. Only transparent top/bottom margins are clipped
  when displaying the artwork; the asset files are unchanged.
- Parents: the supplied five-frame balloon logo replaces the plain header button.
  It shares Home's 300 ms frame interval and 2.4-second forward/back loop. The
  accessible button opens the existing PIN gate.
- Home's bottom panel is transparent. Outlined, colored lettering, Fredoka
  headings, and the gold Continue Learning button stay readable over the sky.
- The hanging Lessons, Games, and Progress artwork has actual navigation tap
  areas, semantic labels, tooltips, and focus feedback. Game access still obeys
  parent settings. Continue Learning, reward totals, and Parents remain available.
- The original dark gradient loading screen, mascot, gold title, Grade 1 caption,
  and bouncing loading dots are restored. The bundled Fredoka font is registered,
  large text can scroll, and reduced motion is supported.

## Animation behavior

- Frames are bundled offline, preloaded, and decoded at a capped display width.
- Repaint boundaries isolate artwork updates from the main controls.
- Playback pauses with app lifecycle and route ticker state, and shows a still
  frame when reduced motion is enabled.
- Supplied background/menu art replaces the previous home landscape illustration.
  Parent Panel retains its separate garden theme.

## Verification

- Static analysis: no issues.
- Current suite: 197 tests passed, including all fifteen frames, artwork
  navigation, the Parents PIN gate, blocked Games, the 300 ms Home/Parents
  cadence, animation pause/resume, original loader, and existing
  progress/audio/parent/game regressions. The additional preview-render test
  also passed (198 total in the combined verification command).
- Layout tests use reduced motion; animation behavior has its own playback test.
- Preview artifacts: `build/animated_previews/`.
- The updated Home preview was visually reviewed at 390 × 844. Home layout
  checks also cover 320, 600, and 900 logical pixels with 1.8× text scaling.
- No connected Android device was available in this session; device performance,
  installation, audio, and microphone checks remain manual checks.

## APK

Current source version: **1.0.2+3**, with existing app ID `com.example.kidsphonics` and development
signing configuration, preserving installation and local-progress continuity
when updating an app installed with the same signing key.

Current verified delivery: `KidsPhonics-animated-1.0.2.apk`

- Size: 309,728,700 bytes (295.4 MiB).
- Signature verification: APK v2 passed; same Android Debug certificate as the
  previously delivered APK.
- APK manifest: versionName 1.0.2, versionCode 3; minimum API 24, target API 36.
- Architectures: armeabi-v7a, arm64-v8a, x86_64.
- All fifteen screen frames in the APK match the source assets by SHA-256.
- The delivery copy matches the verified build by SHA-256.
- SHA-256: `1E208EB0832947FA2AD072C4D8C3EF77D069C510A9AF0BA70E07CEF445547F6A`.

Previous verified delivery: `KidsPhonics-animated-1.0.1.apk`

- Size: 304,250,162 bytes (290.2 MiB).
- Signature verification: APK v2 passed, same Android Debug certificate as the
  earlier delivered APK.
- APK manifest: versionName 1.0.1, versionCode 2; minimum API 24, target API 36.
- Architectures: armeabi-v7a, arm64-v8a, x86_64.
- All ten supplied screen PNGs are present in the APK.
- SHA-256: `85819A98A2B39C415FB81DF7ACB9C54707E269A76063C4148F1E08A0D4D6CCD1`.
