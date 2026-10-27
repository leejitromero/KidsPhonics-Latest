# KidsPhonics Application Flowchart
Date: 26 October 2026. Source baseline: current Flutter application, version 1.0.37+38.
Caption: Application flowchart of the KidsPhonics mobile application.

## Paano basahin
Ito ang application-level flow ng actual KidsPhonics system. Ang double-bordered boxes ay predefined subprocesses: may sariling selection, validation, replay at Back actions sa loob. Hindi kailangang tapusin muna ang lesson bago ma-access ang Quick Check. Hindi rin automatic na bumabalik sa Home pagkatapos ng bawat task; ang A connector ay return route kapag pinili ang Back o navigation.

A = Home / navigation. B = Quick Check letter selection. C = Lessons selection.
Actual bottom tabs: Home, Progress, Parents, Settings. Lessons, Games at recommended Quick Check ay activities mula sa Home; hindi sila anim na bottom tabs.

## Source-confirmed workflows
1. Startup: splash loads saved learner state, progress and preferences. A load failure shows Retry. Existing completed setup opens Home; first use presents the introduction and requires character selection plus a learner name, validated and saved locally.
2. Lessons: six live modules — Letter Recognition; Letter Sounds A-Z; Short Vowel Sounds; Alphabet & Pictures; CVC Words; Blending Sounds. Learners view images/animation, listen to local audio and interact. Exposure, listening and per-word completion are recorded. Viewing a lesson does not itself award Quick Check mastery.
3. Quick Check: recommended or selected A-Z letter; five activities — Big and little letters, Letter sounds, Missing letters, Sounds in words, Letter hunt. Answers determine mastery and eligible rewards. Passing requires at least four of five first responses correct AND the two sound activities correct. Duplicate completion of the same session cannot award twice.
   Actual result options include Continue to the recommended letter when applicable, Try Again, Practice these skills, Review Lesson, View My Progress and Back to Home. Continue/Try Again stay in the Quick Check subprocess. Review Lesson opens the letter-specific introduction/picture/audio screen; it is not a mandatory jump to the six-module Lessons menu. Guided review does not rescore the completed assessment.
4. Games: parent game-access switch must allow play. Choose a game and Easy, Medium or Hard difficulty, read/listen to instructions, then play and receive feedback. Results/rewards are recorded only where applicable. Replay and return remain available.
   The eleven live games are Flappy Letters; Sound Match; Memory Flip; Phonics Quiz; Word Builder; Speak & Recognize; Alphabet Order; Missing Vowel; Picture Match; Rumbled Words; Rhyming Words. Flappy Letters is motor practice and records activity completion; it does not establish letter mastery. Speak & Recognize is speech-recognition practice, not a clinical pronunciation-scoring feature; microphone permission and device speech support are needed for that activity.
5. Progress: My Journey, My Letters and My Rewards read local evidence. A letter practice action can open Quick Check (B); skill rows may open related lesson screens (C summarizes their lesson route). Browse-only navigation returns through A.
6. Parents: set up a four-digit PIN if none exists, otherwise unlock the PIN. Rejected PINs remain at authentication and lockout rules apply. Authenticated parents can view Overview/Activity and control game access, daily time allowance and PIN protection. Progress reset is optional and requires explicit confirmation; it is never part of normal startup or routine app exit. Leaving the Parents area ends the parent session.
7. Settings: everyday sound, display, character/profile, introduction replay, Help and About. Protected game/time/PIN controls stay in Parents; ordinary Settings does not itself require a parent PIN.
8. Global daily-time-limit guard: can cover any screen when the allowance is reached and no parent session is authenticated. It blocks interaction and pauses covered tickers. Parent Unlock requires valid PIN authentication; the parent can add 10, 15 or 30 minutes, or allow the rest of today, then resume the previously covered screen. Invalid/cancelled unlock remains blocked; Exit closes the application.
9. Storage: app state is stored on-device through the existing local preference/save services. Save errors expose Retry; the diagram's save nodes describe actual successful persistence, not a guarantee that every device write succeeds. No online learner registration, cloud account, administrator portal or teacher login is introduced in this diagram.

## Source mapping
- Startup, readiness and first-use routing: lib/main.dart; lib/widgets/time_limit_overlay.dart; lib/screens/welcome_screen.dart; lib/widgets/student_character_picker.dart.
- Home activities and four retained tabs: lib/screens/home_screen.dart; lib/widgets/main_navigation_scope.dart; lib/widgets/main_navigation_shell.dart.
- Six lesson modules: lib/screens/lessons_screen.dart.
- Five-task Quick Check and result routes: lib/models/letter_adventure.dart; lib/screens/letter_mastery_check_screen.dart; lib/screens/letter_introduction_screen.dart; lib/providers/app_provider.dart.
- Eleven games, access/difficulty checks: lib/screens/games_screen.dart.
- Progress links: lib/widgets/progress_journey_view.dart.
- PIN and protected parent area: lib/screens/parent_screen.dart; lib/widgets/parent_pin_form.dart; lib/services/parent_auth_service.dart.
- Ordinary settings: lib/screens/settings_screen.dart.
- Global time limit: lib/widgets/time_limit_overlay.dart; lib/services/screen_time_service.dart.

## Files and thesis use
Use the SVG or PDF for sharp vector printing; the PNG is 5000 × 3800 pixels. The landscape layout is intended for A3 or a zoomable digital appendix; avoid shrinking the full figure into a narrow A4 portrait text column. The DOCX contains the figure and explanatory notes. Editable process text is also supplied as Mermaid; SVG objects can be edited in a vector editor. The DOCX figure is an embedded image, not individual Word flowchart shapes.

The current classroom teaching-process flow is a separate research diagram and is not inferred from the application's source. No changes were made to application source, assets, APKs or learner data while producing this application diagram.
