# Games reference update

The Games menu uses the existing classroom cycle, all eleven game routes and
difficulty options, current saved character, profile editor, and shared wooden
navigation. Home and Lessons layouts are unchanged. Game logic, reward formulas,
mastery rules, and persistence were not modified.

The supplied `screen animations/frames for games.png` has opaque black pixels
both inside and outside its border. A transparent copy is saved at
`assets/images/games_menu/games_card_frame.png`; the source file is untouched.
The built-in imagegen tool performed the extraction. The full edit prompt and
source/output hashes are recorded in `tools/games_frame_provenance.json`.
The second supplied frame was inspected; the simpler star/cloud frame was
selected to keep the cards consistent and avoid additional ornaments.

Each card uses a Stack: a colored interior, original transparent game
illustration plus the saved selected character, live title/description/Play
control, and the frame PNG overlay. Safe insets keep content inside the frame.
The original frame is 1536 x 1024. A quarter-turn in Flutter displays it in
portrait while preserving every image's proportions with BoxFit.contain.
No Flutter border or gradient substitutes for the frame. Existing illustrations
are reused; the existing retired cat/hat illustration is copied into the new
asset directory for Rhyming Words. Original composite game-card PNGs remain.

The grid uses GridView.builder, always two columns, with a maximum width of 560
logical pixels. Header, horizontal category filters, and bottom navigation stay
fixed. The header uses the existing 3D letter assets and wood base. Profile and
Back controls match the Lessons styling; the Games profile stays pink for both
saved character choices. A compact header supports shorter viewports.

All Games includes eleven entries. Letters includes Flappy Letters and Alphabet
Order. Sounds includes Sound Match, Phonics Quiz, and Speak & Recognize. Words
contains the remaining six games. Filters retain their own scroll positions;
game returns preserve both the current filter and grid offset. The existing
saved Rhyming Words completion flag updates its Completed indicator. Other
games retain their existing activity/result/progress displays without inventing
new completion records.

Card taps scale to 0.97 and illuminate the same frame PNG for 90 ms, return for
90 ms, then open the existing difficulty chooser. Existing button audio plays
once per accepted tap. The screen blocks duplicate opens through difficulty
selection and until returning from the activity. Game entry fades for 300 ms.
Reduced-motion preferences skip the press delay and entry animation.

Tests cover real frame alpha, original aspect ratios, seven viewport/text-size
combinations, reachability of all eleven games, all difficulty-to-route mappings,
saved profile and reward preservation, filter/scroll restoration, the existing
completion flag, parent restrictions, navigation state, and press/glow timing.

Generate previews with:

```powershell
flutter test test/games_reference_test.dart --dart-define=CAPTURE_UI=true
```

Previews are saved under `build/ui_previews/update_games_reference_390.png` and
`build/ui_previews/update_games_reference_768.png`.
