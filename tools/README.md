# Historical asset utilities

These files are retained for project provenance. They are not imported by the Android app and are not run by `flutter pub get`, tests, or builds.

| Files | Historical purpose | Current status |
|---|---|---|
| `generate_audio.dart`, `generate_voice_feedback.dart`, `generate_phonics_audio.py` | Generated old phonics/feedback recordings using external TTS | Retained only; **do not run**. Their old wording must not overwrite validated content. |
| `generate_missing_sound_match.py`, `generate_missing_sound_match.js`, `generate_missing_rhyming.js` | Filled gaps in the old recording set | Historical only; not a current asset-replacement workflow. |
| `generate_icon.dart`, `generate_icon_png.dart` | Online SVG-to-PNG experiments | Historical only. The current icon already exists; these network utilities are unnecessary for setup. |

Dart CLI output uses `stdout.writeln`; it is not production-app logging. `http` remains a development dependency for these retained tools. The obsolete `dart:math` import and unused endpoint list in `generate_icon_png.dart` were removed after checking references. None of these generators was executed during stabilization.

When icon regeneration is deliberately needed, the configured existing tool is `dart run flutter_launcher_icons`. This cleanup did not regenerate icons.

For future human recordings, use `../PHONICS_RECORDING_SCRIPT.md`, `../AUDIO_REPLACEMENT_AUDIT.md`, and `../PHONICS_TEACHER_VALIDATION.md` after manual app testing and teacher review.

