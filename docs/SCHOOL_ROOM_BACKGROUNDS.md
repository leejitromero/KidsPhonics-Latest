# School room backgrounds — 1.0.16 (17)

The four user-supplied PNGs are copied unchanged into `assets/images/school_rooms/`: `LESSONS.png` → `lessons.png`, `GAMES.png` → `games.png`, `PROGRESS.png` → `progress.png`, and `PARENTS.png` → `parents.png`.

`SchoolRoomBody` displays the matching artwork on each main screen. It preserves the header and footer proportions while stretching the middle of the room for different screen heights. Existing content scrolls below the illustrated title. A semantic, minimum 48-pixel tap target makes the back arrow in each image interactive. Parent PIN entry has a light panel for readability.

The replaced parent garden asset is retained outside the bundle at `tools/retired_menu_art/parent_garden.webp`.

Validation: Flutter analysis passed; relevant existing lesson/game layout, parent controls/settings/activity, progress collection/rewards, and asset audit tests passed after updating scroll interactions for the new headers. Phone, tablet, and enlarged text layouts were exercised. Previews are in `build/ui_previews/`. Physical-device installation was not performed.

Release APK: `releases/KidsPhonics-1.0.16-build17.apk`. APK metadata confirms version 1.0.16, build 17. `tools/release_1_0_16_verification.json` records SHA-256 verification of 713 bundled assets and the complete APK checksum.
