# Shared Games theme

The four original `g1.png`–`g4.png` frames from the supplied `game screen.zip`
are bundled under `assets/images/screen_frames/games`. `GameThemeBackground`
reserves space for the hanging Game Zone sign and uses the existing frame player
with a gentle 650 ms crossfade. Reduced-motion, background and route visibility
behavior come from the shared animation component.

The menu and all GameScaffold activities use this background. Flappy Letters
uses the same wrapper behind its course; pipes, bird, physics and inputs remain
in the course's own coordinate system. Answer feedback tints the scene while
keeping the supplied artwork visible.

`GameDifficultyDialog` implements the supplied difficulty reference as live UI:
cream panel, blue border, puppy illustration, wood-style game title, green Easy,
purple Medium, orange Hard and blue Cancel. Titles and descriptions come from
each game, so Alphabet Order's letter counts are not reused for unrelated games.
Labels scale, the panel scrolls on smaller screens, and cancel/back and the
existing duplicate-selection guard are retained. Existing local artwork is used
for the puppy; the reference screenshot is not a static clickable overlay.
