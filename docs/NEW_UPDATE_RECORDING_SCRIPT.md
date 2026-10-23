# Lala and Lulu — Home dialogue recording script

Lala is the purple Lessons mascot. Lulu is the blue Games mascot.
Record each row as its own MP3 file, with clear, unhurried words and no background
music. Give Lala a calm, encouraging voice and Lulu an energetic, playful voice.
Leave a short pause at the beginning and end of each file.

This script replaces the earlier introduction script. Each dialogue row is one
audio clip and one dialogue-box step. Finishing an audio clip does not advance
the dialogue; wait for the child to press Next. Stop the current audio before
playing the next clip. Never overlap speakers.

## Requested flow

1. Loading finishes. Show Home with Lala and Lulu behind their signs, without
   the selected boy/girl character.
2. Wait 1.5 seconds silently, then show Lala's first dialogue above her and play
   `lessons_intro_01.mp3`.
3. Each Next press shows and plays the next Lala dialogue. Next after her last
   dialogue switches to Lulu's first dialogue.
4. Each Next press advances Lulu's dialogue. Her final dialogue has a Get Started
   button, which opens character/name setup.
5. Save the chosen character and name, then show Home with that character in the
   center.
6. Selecting Lessons plays the selected character's “Let’s learn!” clip; selecting
   Games plays “Let’s play!”. Let the clip finish, then walk toward the selected
   side and off the screen before opening the category.

Suggested dialogue artwork: `dialogue_box_2.png` for Lala (purple),
`dialogue_box_1.png` for Lulu (blue), `dialogue_box_3.png` for the boy (gold), and
`dialogue_box_4.png` for the girl (pink).

## 1. Lala — Lessons introduction

| Filename | Script |
| --- | --- |
| `lessons_intro_01.mp3` | Hi, friend! Welcome to KidsPhonics! I’m Lala, your Lessons guide! |
| `lessons_intro_02.mp3` | I’ll help you learn letters, their sounds, and how to read words. We’ll learn together, one step at a time! |
| `lessons_intro_03.mp3` | Tap the Lessons sign to visit me. Listen carefully to the sounds, then try the activities! |
| `lessons_intro_04.mp3` | You can replay a sound whenever you need. The Practice This Letter button helps you practice your next letter! |
| `lessons_intro_05.mp3` | Ready to meet my friend Lulu? Tap Next! |

Show a Next button for every Lala dialogue. After dialogue 05, Next starts Lulu's
first dialogue. Lulu stays silent while Lala is speaking.

## 2. Lulu — Games introduction

| Filename | Script |
| --- | --- |
| `games_intro_01.mp3` | Hi, friend! I’m Lulu, your Games guide! |
| `games_intro_02.mp3` | We’ll practice letters, sounds, and words through fun games. Learning can be an adventure! |
| `games_intro_03.mp3` | Tap the Games sign to visit me. Choose a game, pick a difficulty, and follow the instructions! |
| `games_intro_04.mp3` | Keep trying! You can see your stars and learning journey in Progress. |
| `games_intro_05.mp3` | Ready for your adventure? Tap Get Started to choose your character! |

Show Next for dialogues 01–04. Show Get Started for dialogue 05. Do not open
character setup until the child presses Get Started. Lala stays silent while
Lulu is speaking.

## 3. Character and name setup — Lulu

Lulu continues guiding the child through setup.

| Filename | Script |
| --- | --- |
| `profile_setup_01.mp3` | Choose the boy or girl character you like. This character will represent you on your learning adventure! |
| `profile_setup_02.mp3` | Type your name in the box. When you’re ready, tap Let’s go! |

Wait for character selection, a name, and Let’s go before opening Home.
Play clip 01 when the picker opens, then show/play clip 02 after the child picks a
character. Do not repeat the prompts on every name-field keystroke.

## 4. Selected boy character — category entry

Use the boy character's own voice, distinct from Lala and Lulu.

| Filename | Script | Trigger |
| --- | --- | --- |
| `boy_lets_learn.mp3` | Let’s learn! | Boy selected; child taps Lessons. |
| `boy_lets_play.mp3` | Let’s play! | Boy selected; child taps Games. |

## 5. Selected girl character — category entry

Use the girl character's own voice, distinct from Lala and Lulu.

| Filename | Script | Trigger |
| --- | --- | --- |
| `girl_lets_learn.mp3` | Let’s learn! | Girl selected; child taps Lessons. |
| `girl_lets_play.mp3` | Let’s play! | Girl selected; child taps Games. |

Play only the selected character's matching clip. The other character and both
mascots stay silent during entry. Prevent repeated taps from starting another
clip or another walk while the entry sequence is active.

Deliver **16 separate MP3 files** using these exact filenames: five Lala clips,
five Lulu introduction clips, two Lulu setup clips, and four character-entry
clips. Record only the words in the Script column; timing and button notes are
instructions for the app.

The supplied recordings are integrated as separate Home dialogue steps. Next and
Get Started wait for the current recording to finish; audio completion does not
advance the introduction automatically. Student entry speech finishes before
the walking animation begins. Files supplied as `lesson_intro_01` through `05`
are imported as `lessons_intro_01` through `05` to match this script.
