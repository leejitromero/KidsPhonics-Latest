# Background music

Carefree by Kevin MacLeod is bundled at `assets/audio/carefree.mp3` for offline playback. Attribution and the CC BY 4.0 license link are available under Parent Controls → Music Credits and in `assets/audio/carefree-LICENSE.txt`.

Music starts enabled at 12% volume. Parent Controls provides a separate music switch and a 0–40% volume slider; both persist independently of Voice Assistance and Sound Effects.

The music player loops and resumes its existing position after interruptions. Instructional recordings, mastery prompts, voice feedback, and sound effects pause it before playback. Overlapping audio owners keep it paused until all finish. The entire speech-recognition activity is quiet, including permission prompts and retries. Background/inactive app states, the screen-time limit, music off, and zero volume also pause it.

Track downloaded unchanged from:
https://incompetech.com/music/royalty-free/mp3-royaltyfree/Carefree.mp3

SHA-256: `8433b770a630d9b1594fd484442c677907ece899a4d149954cd2e74fd733e311`

Automated tests cover playback priority, overlapping holds, cancellation, decode failure, settings persistence, and bundled audio/credits. Physical-device listening is still needed to judge the final loudness balance.
