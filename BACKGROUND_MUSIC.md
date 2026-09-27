# Background music

The user-supplied backgroundtheme.mp3 is bundled unchanged at
assets/audio/backgroundtheme.mp3 for offline looping. The previous Carefree
track, its attribution file, and its in-app credits have been removed. No artist
or license attribution is inferred for the supplied replacement.

The music channel applies a 0.5 gain to the parent's volume setting. The default
12% setting therefore plays at 6% player volume; existing saved settings also
play at half their previous level. The 0-40% slider and music switch remain
independent of voice and sound-effect settings. The original audio is unchanged.

Instructional speech and sound effects pause the music. Overlapping holds keep
it paused until every foreground sound finishes. Speech recognition, background
app states, screen-time limits, music off, and zero volume also pause playback.

Replacement SHA-256:
69338B3FB88118F510075B881A813B7BCC6F77F8E6A63DADC4B3E634ECC694FD

Tests cover the new source, lower effective volume for default and saved values,
looping, playback priority, cancellation, settings persistence, and removal of
the old track. Final perceived loudness still needs listening on a phone.
