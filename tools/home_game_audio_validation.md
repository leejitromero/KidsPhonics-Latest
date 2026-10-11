# Home and game audio validation

Changes: animated transparent KidsPhonics logo above the Home airplane; Home
fills the available height with footer text at the bottom; generated game
instructions and spoken praise removed; original Flappy letter recordings
play when clearing pipes. Selected phonemes in Quiz and Word Builder remain.

Validation on 2026-10-07:

- Flutter analysis: no issues.
- Full suite: 343 passed, one new Flappy audio test needed real IO time between
  simulated pipes. After fixing the test's asset-loading wait, its focused
  recheck passed. All 344 tests are covered by these runs.
- Actual Flappy crossings play A and B in order without narration/praise.
- Quiz and Word Builder selected sounds finish before answer progression.
- Home placement, stable tap targets, gentle motion, pause and reduced motion
  checks pass at 320x568 and 390x844. The 390x844 footer ends at the screen bottom.
- Bundled asset audit: 641 required assets, zero unused media.

Logs and Home screenshots are in `build/`; these are generated files.
Logo preparation and its exact imagegen prompt are recorded in
`asset_notes/home_logo.md`.
