# Lessons and Games card refresh

Updated 2026-10-11. The Lessons menu uses the five supplied lesson designs;
the Games menu uses the eleven supplied game designs. The artwork contains
its own frame and decorations, so the previous outer borders, padded logo
panels and extra game play button were removed. The whole card remains tappable.

The existing animated scenery, lesson banner, game category filters,
difficulty picker, destinations, game-access checks and saved progress remain.
The later [navigation and card polish](HOME_NAVIGATION_AND_CARD_POLISH.md)
removes duplicate game captions and gives every game card the same dimensions.
Lesson captions below the artwork scale with accessibility text settings. Lesson
mastery counts, progress bars and completion status continue using AppProvider.

## Layout and organization

- `lib/data/activity_card_art.dart` maps every activity explicitly. Archive
  spellings such as `world builder` and `recodnize` are normalized in filenames.
- `lib/widgets/activity_artwork.dart` renders complete art with `BoxFit.contain`
  for Lessons; Games normalize complete artwork to a shared aspect ratio with
  `BoxFit.fill`. Image decoding is bounded by display size, capped at 900 pixels wide.
- Games use two phone columns, three tablet columns and one column for large text.
- Lessons use two phone columns, three tablet columns and one column for large
  text. Grid row height includes measured caption/progress text, avoiding fixed
  height clipping while keeping normal rows compact.
- Current menu artwork is bundled in `assets/images/activity_cards/`.
- Three replaced, now-unused lesson logos are retained outside the Flutter
  asset bundle in `tools/retired_menu_art/`, alongside the three original PNGs
  used for the corrected variants. No original artwork was destroyed.
- `tools/activity_card_assets.json` records all sixteen ZIP entries, their
  preserved original copies, runtime paths and SHA-256 hashes.

## Artwork corrections

The archive's `lessons_blending sounds.png` was titled “Letter Recognition”.
Its corrected variant is
`assets/images/activity_cards/lesson_blending_sounds-v2.png` and reads
“Blending Sounds”. The design's original A/a letters and ABC blocks remain.

The supplied Word Builder and Alphabet Order files contained opaque black
backgrounds outside their cards. Corrected variants have transparent outer
corners and are bundled as:

- `assets/images/activity_cards/game_word_builder-v2.png`
- `assets/images/activity_cards/game_alphabet_order-v2.png`

These three edits used the built-in `image_gen` tool through the `imagegen`
skill, with transparent-background output requested. The thirteen other
runtime images are exact original ZIP copies. Generated edits were visually
reviewed; exact pixel preservation is not claimed for generated variants.

### Final prompt set

Blending Sounds:

> Use case: text-localization. Edit target: the supplied wide KidsPhonics lesson card. Correct only the title printed on the existing cream-and-gold bottom plaque: replace "Letter Recognition" with exactly "Blending Sounds", in the same glossy dark-brown rounded 3D letters with white outline, large and centered. Preserve the original purple-and-gold frame, A/a letters, ABC blocks, stars, flowers, foliage, rainbow, positions, vivid colors and cute glossy 3D style. Preserve the wide 3:2 composition and keep the whole card visible with no cropped edges. Outside the decorative card silhouette must be genuinely transparent, preserving leaves and glow. Do not add any other text or second frame.

Word Builder:

> Use case: background-extraction. Edit target: the supplied portrait green Word Builder game card. Remove ONLY the black background outside the complete green card and provide true transparent alpha. Preserve the entire original card exactly: green rounded rectangular frame and play button, orange cat, CAT tiles, Word Builder heading, exact caption "Build a word.", glossy 3D highlights, colors, layout and proportions. Keep all edges complete. No new elements or extra text. Portrait composition matches supplied image.

Alphabet Order:

> Use case: background-extraction. Edit target: the supplied portrait purple Alphabet Order game card. Remove ONLY the black background outside the complete purple card and provide true transparent alpha. Preserve the entire original card exactly: purple rounded rectangular frame and play button, number spheres 1 2 3, ABC blocks, yellow arrow, stars and clouds, Alphabet Order heading, exact caption "Put letters in order.", glossy 3D highlights, colors, layout and proportions. Keep all edges complete. No new elements or extra text. Portrait composition matches supplied image.

## Verification

The final automated results are recorded in
`tools/activity_card_verification.json`. Tests cover 320×568, 390×844,
800×1024, 800×600 and 320×568 with 2× text; artwork preservation, transparent
outer corners, scrolling and reachable controls; filters and difficulty
selection; lesson destinations, saved progress, game rewards and Home entry.

Screen previews are under `build/ui_previews/`, including
`games_cards_390_844_1x.png` and `lessons_cards_390_844_1x.png`.

No APK was rebuilt for this source update. Physical Android device validation
has not been performed for this refresh.
