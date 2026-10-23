# Progress flow

The three Progress tabs read the same saved AppProvider state. They do not
award XP, stars, mastery, or lesson completion when opened or rebuilt.

## My Journey

| Row | Saved evidence | Destination |
| --- | --- | --- |
| Letters | Letters mastered in the current Quick Check, out of 26 | My Letters |
| Letter Sounds | Unique letters whose sound recordings have been heard, out of 26 | Letter Sounds lesson |
| Vowels | Quick Check mastery for A, E, I, O, U, out of 5 | Short Vowel lesson |
| CVC Words | Unique completed guided words, out of the current 17-word lesson | CVC lesson |
| Blending Sounds | Unique completed word puzzles, out of the current 22-word lesson | Blending lesson |

The learning summary counts unique explored letters, six distinct lesson types
with practice evidence, and total earned stars. A lesson type counts after an
actual letter-name/sound/picture-sentence listening event or a completed
CVC/blending word. Alphabet & Pictures uses the existing word-listening counts;
its recordings must finish successfully to count. It is lesson 4, after Short
Vowel Sounds. Browsing its pictures alone does not count as a practiced lesson.
Hearing a vowel sound supports both Letter Sounds and Short Vowels because that
content belongs to both categories. Opening a page alone does not count as a
practiced lesson. Word practice is not an assessed word-mastery score.

The recommendation uses the same saved target as Home and Parents. It retains
the target until mastery; when choosing another target it prioritizes completed,
unmastered checks, lower latest scores, then alphabetical order. Start Quick
Check opens that letter. When all letters are mastered, Choose a Letter opens
My Letters for review.

## My Letters

Each letter has one mutually exclusive state, so its four status counts sum to 26:

1. New: no recorded exposure, practice or completed current Quick Check.
2. Explored: exposure/listening without scored practice.
3. Practiced: practice or a completed current Quick Check, without mastery.
4. Mastered: passed a completed current Quick Check.

Tap a letter to see its latest score, best score, number of completed checks,
latest five skill results, and listening counts. Practice opens that letter's
Quick Check. Filters change the grid only; they do not change learning data.

Quick Check collects first responses to matching, letter sound, missing letter,
sound in a word, and letter hunt. Saving happens after all five challenges when
See Result is selected. A partial check is not saved. Mastery requires at least
4/5 **and** correct Letter Sounds and Sounds in Words answers. A later lower
score updates the latest result while retaining the best score and mastery.
Guided corrections do not replace the first-response result or award more XP.

The first completed check for a letter earns 5 XP. Its first mastery earns an
additional 25 XP and 1 star. Repeating a mastered letter does not repeat these
awards. Games keep their own existing award formulas; game rewards do not
establish assessed letter mastery.

## My Rewards

| Badge | Requirement |
| --- | --- |
| First Letter Mastery | 1 letter mastered in current Quick Check |
| Vowel Star | All 5 vowels mastered in current Quick Check |
| CVC Explorer | 5 different completed guided CVC words |
| Blending Champion | 1 completed blending word puzzle |
| 3-Day Streak | Scored questions or speaking practice on 3 consecutive days |
| 5 Letters Mastered | 5 mastered letters |
| Halfway There | 13 mastered letters |
| Alphabet Master | 26 mastered letters |

The first five are the main reference badges; the three alphabet milestones
preserve the existing achievement goals. Counts and bars are capped at each
goal. Badge details show requirements and can open the relevant practice.
The same eight achievement states are available to Parents summaries.

The streak card shows the current streak. The streak badge remembers the best
recorded run, so a break does not remove an earned badge. Viewing/listening,
completion-only days and XP awards do not count as streak activity. Speaking
practice counts even though it is tracked separately from scored questions.

My Treasure shows total XP, stars, and Level = floor(XP / 200) + 1, with the
remaining XP to the next level. Badges themselves grant no extra reward.

## Saving and safeguards

AppProvider serializes SharedPreferences snapshots on this device. Progress
uses existing letter, adventure, word-lesson and daily-activity records; no
separate badge flags are needed. CVC/blending completion uses unique word sets,
and duplicate delivery of the same current Quick Check session is ignored.
Legacy assessment records remain saved but do not replace current Quick Check
mastery. A changed character/name does not create another progress profile.

A loading state prevents showing empty progress before storage is ready. Load
errors offer Try Again. Failed saves show Retry saving progress. Time-limit
restrictions disable activity entry points while leaving progress readable.
The existing parent-authorized reset clears learning records and derived
badges; audio settings, parental controls and screen-time stores stay separate.
