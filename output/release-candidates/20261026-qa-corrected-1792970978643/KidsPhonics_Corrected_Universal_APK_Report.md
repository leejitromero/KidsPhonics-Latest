**BUILT AND VERIFIED — ACTUAL ANDROID DEVICE TESTING PENDING**

26 October 2026 | KidsPhonics corrected universal release candidate | Local build only

Na-build ang corrected APK mula sa CURRENT working source, kasama ang uncommitted QA corrections. Isolated ang build; walang existing APK, application source, original asset, Android configuration, o learner installation na pinalitan.

**Corrected APK**

C:/Users/leeji/KidsPhonicsProject/newphonics/Kidsphonics-latest/output/release-candidates/20261026-qa-corrected-1792970978643/KidsPhonics-1.0.37+38-QA-corrected-universal-CANDIDATE.apk

| Item | Verified result |
|---|---|
| Exact size | 515,866,438 bytes (515.866438 decimal MB; 491.968573 MiB) |
| SHA-256 | e9918d69415208828360468e4135d90164fb54fa9e25306fde804576323acb96 |
| Package / unchanged version | com.example.kidsphonics — 1.0.37+38 |
| Android requirement | minSdk 24 — Android 7.0 or later; targetSdk 36 |
| Supported native ABIs | arm64-v8a, armeabi-v7a, x86_64 |
| Signing | Signature verified; identical certificate to the original APK. Existing debug signing configuration and key preserved; no new key created. |
| Certificate SHA-256 | e51915ff388c75d5cb980d40ecb354a5379806fee2b3dc67a36ab4e701774f69 |
| Build | Universal release, exit 0; Flutter 3.41.5 / Dart 3.11.3; existing locked dependencies and SDK configuration retained. |

**Verification results**

| Item | Verified result |
|---|---|
| Application corrections | PNG fallback fix and new_ui airplane reference confirmed. Exact historical airplane hash verified before build and inside APK. |
| Learning assets and audio | All 863 declared source assets and all 863 evaluated runtime assets included; 446 images and 408 audio files. Zero missing, unexpected or changed source assets; every bundled source asset SHA-256 matches the build snapshot. |
| Native libraries | libapp.so and libflutter.so present for all three ABIs. All three Flutter engine libraries match the original; compiled Dart libraries differ for all three ABIs. |
| Flutter analysis | No issues found. |
| This build snapshot regressions | 37 passed / 0 failed / 0 skipped. Covers all 26 lesson mappings, 57 PNG fallback references, seven GameWord overrides/audio, Review Lesson navigation/rewards, Zebra safeguard, Flappy artwork/gameplay/audio and saved progress. |
| Separate strict asset audit | 1 passed / 0 failed. The first test command also exported a read-only runtime inventory; the retained-byte audit was rerun separately in its normal strict mode. |
| Previous full QA suite | 1,004 passed / 0 failed. Source snapshot matches the verified corrected QA source; this release task reran the focused checks above rather than repeating the entire suite. |
| Preservation | 1436 original working files unchanged; 5 original APK/build-metadata files unchanged; 863 current source assets unchanged; existing signing-key hash unchanged. All prior 182 Git status entries preserved. |
| QA backup | 1433 backup files revalidated; no changes to the verified backup. |

Build command: flutter --no-version-check --suppress-analytics build apk --release --no-pub --target-platform android-arm,android-arm64,android-x64. No split APK, SDK/dependency upgrade, version bump, signing change, image recompression or configuration edit was made. The build emitted Java source/target 8 obsolescence warnings; compilation succeeded without changing dependencies or settings.

The original universal APK remains 514,566,052 bytes. This candidate is 1,300,386 bytes larger. The new size includes restored artwork; no image optimization was performed.

**Still needs actual Android device testing**

The candidate was not installed or launched on a device. Verify installation/update and learner-data retention; all affected Review Lesson pictures and frame alignment; audible phonics/pronunciation; Zebra answer concealment; Flappy ready/pause/hit/win/loss, touch controls and resume; offline operation, performance, memory/storage and accessibility on representative low-end phones and tablets. Minimum SDK and bundled ABIs are package requirements, not proof that every random Android device works. No publication or distribution was performed.

**Backup and evidence**

Verified QA backup retained at: C:/Users/leeji/AppData/Local/Temp/kidsphonics-qa-corrections-1792969134362/backup

Recommended persistent backup outside temporary directories: C:/Users/leeji/KidsPhonicsBackups/2026-10-26-QA-Corrections/. Copy the verified backup together with its before-manifest.json, integrity-verification.json and approved-changes.patch; keep a separate corrected-source snapshot and this candidate/checksum. A second copy on another drive protects against loss of the current disk. The existing temporary backup remains intact; the recommended persistent copy has not been created by this build task.

Candidate, SHA256SUMS.txt, this report and selected verification evidence are saved together under: C:/Users/leeji/KidsPhonicsProject/newphonics/Kidsphonics-latest/output/release-candidates/20261026-qa-corrected-1792970978643

Detailed build/test logs and snapshot manifest: C:/Users/leeji/AppData/Local/Temp/kidsphonics-corrected-release-1792970978643
