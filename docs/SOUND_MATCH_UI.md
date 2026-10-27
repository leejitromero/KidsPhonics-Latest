# Sound Match orb

Sound Match uses a transparent magical sound orb instead of a word illustration. The orb and the purple Hear Sound control share the existing local letter-sound recording, playback lock and audio failure state. Playback animates expanding waves; idle motion gently pulses the glow. Motion pauses behind another route, in the background and when reduced motion is enabled.

Every difficulty shows three distinct choices, including the correct letter, in blue, orange and green. Difficulty still selects the session's content and reward multiplier. A mistake briefly shakes the selected choice and displays Try Again, allowing the learner to hear and answer the same sound again. Correct choices bounce and light the orb with golden stars before advancing.

Each accepted choice, including a retry, contributes to attempts and daily accuracy, consistently with the other practice games. A completed question contributes one correct item and earns its existing XP and star once, even after a correction. Repeated taps during feedback and on previously selected choices remain blocked. The result shows completed items separately from accuracy across all attempts; existing saved history is preserved.

Regular phones show the orb, audio control and all three large choices without scrolling. Short screens, landscape and larger text can scroll while retaining readable controls and touch targets.

Artwork: `assets/images/new_ui/magical_sound_orb.png`, generated with the built-in imagegen tool using the user's attached orb as a visual reference. The generated alpha is preserved. The asset directory is already included in pubspec.yaml.

Generation prompt:

> Use case: stylized-concept. Asset type: transparent game sprite for the Grade 1 KidsPhonics Sound Match game. Create one colorful glossy 3D magical sound orb matching the attached reference image's style: luminous round blue/cyan/lavender crystal glass sphere, large clear blue speaker symbol at the center with three glowing golden-pink sound arcs, whimsical golden pedestal with cyan jewel, small golden star crown, several golden stars and pastel sparkles around swirling cyan and pink orbital ribbons. Centered front view, full object completely visible, roughly square composition with generous 8% transparent padding. Bright playful toy-like high-quality 3D educational fantasy illustration, clean readable silhouette at 200px. Actual transparent background, no black background, no scenery, no letters, no text, no watermark. The attached image is a STYLE AND SUBJECT REFERENCE, not an edit target. Create a polished similar asset with balanced simpler details for a tappable UI.

Tests cover the three-choice layout at every difficulty, small screens, landscape, larger text, actual local audio start/completion, playback cancellation, retry scoring and preserving feedback while another route or the background covers the game. Optional previews are saved under `build/ui_previews/sound_match_*.png` with `--dart-define=CAPTURE_UI=true`.
