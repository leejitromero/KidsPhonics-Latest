# Startup title voice

On the first-time Home scene, the title recording starts after the loading-to-Home
fade has completed. No learner character or introduction bubble appears yet.
All four supplied `kidsphonics_intro_01` through `04` voices play together.
After the actual playback-complete event and a 1.5-second pause, Lala begins.
Lulu, profile setup and the cloud reveal retain their existing order. The title
does not repeat during the cloud reveal or when returning from a classroom.

The four original MP3s are preserved unchanged in `tools/title_audio_sources/`.
`tools/mix_title_audio.py` decodes them to the same sample rate, starts all four
at sample zero and mixes them at equal, fixed gain into the single runtime asset
`assets/audio/home_intro/kidsphonics_title_chorus.mp3`. This avoids separate
native players starting at slightly different times or competing for audio
focus. The cue lasts 1.567 seconds; its decoded peak is below clipping.

Loading preloads the cue. Playback uses the existing scene voice controller,
audio focus and background music handling. Muted voice skips the cue without
blocking onboarding. Backgrounding stops it; resuming during the title restarts
the chorus before Lala. A late completion from the canceled playback cannot
start the introductions. Interrupted mascot instructions still replay on resume.

Evidence: `tools/title_audio_import_verification.json` compares copied recordings
with the supplied originals, `tools/title_audio_mix_verification.json` records
all four input timings and hashes, and `tools/intro_audio_verification.json`
verifies decoding of the runtime cue. `test/home_voice_test.dart` checks the
completion-driven handoff, full onboarding, interruption/resume, muting and
unchanged character speech/walking. This update is included in
[release 1.0.18 / build 19](RELEASE_1_0_18.md).
Physical-device playback has not been checked.

Final verification: all 37 scoped regression checks passed
(`build/title-voice-tests.log`), and Flutter analysis found no issues
(`build/title-voice-analysis.log`). All 19 runtime Home recordings decoded.
