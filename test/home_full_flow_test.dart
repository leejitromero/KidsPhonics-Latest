import 'package:kidsphonics/widgets/scene_dialogue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/main.dart';
import 'package:kidsphonics/data/home_narration.dart';
import 'package:kidsphonics/data/updated_scene.dart';
import 'package:kidsphonics/screens/home_screen.dart';
import 'package:kidsphonics/screens/welcome_screen.dart';
import 'package:kidsphonics/screens/lessons_screen.dart';
import 'package:kidsphonics/screens/games_screen.dart';
import 'package:kidsphonics/widgets/cloud_page_route.dart';
import 'package:kidsphonics/widgets/scene_controls.dart';
import 'package:kidsphonics/widgets/school_home_scene.dart';
import 'package:kidsphonics/widgets/student_wave.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';
import 'package:kidsphonics/services/audio_service.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'home_voice_test.dart' show waitForVoice, finishTitle, voiceDiagnostics;
import 'quiz_audio_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late QuizAudioHarness audio;
  setUp(() {
    mockProgressAudio();
    SharedPreferences.setMockInitialValues({'sfx': false});
    audio = QuizAudioHarness()..install();
  });

  for (final (character, category, destination) in [
    ('boy', 'lessons', LessonsScreen),
    ('girl', 'games', GamesScreen),
  ]) {
    testWidgets(
        'loading to setup, five-second prompt and $character $category exit',
        (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final p = await mount(t, const SplashScreen());
      expect(find.text('Loading your adventure...'), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsNothing);
      expect(find.byKey(const ValueKey('home-student')), findsNothing);
      expect(audio.starts, isEmpty);

      // Splash progress uses a real Stopwatch; wait for its three seconds,
      // then advance the fake timer to exercise the actual loading route.
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 3100)));
      await t.pump(const Duration(milliseconds: 30));
      expect(find.text('100%'), findsOneWidget);
      await t.pump(const Duration(milliseconds: 250));
      await t.pump();
      await waitForVoice(
          t, () => find.byType(WelcomeScreen).evaluate().isNotEmpty);
      await t.pump(); // Seed the route ticker before measuring its fade.
      await t.pump(const Duration(milliseconds: 601));
      await t.pump();
      expect(find.byType(WelcomeScreen), findsOneWidget);
      final welcomeRoute =
          ModalRoute.of(t.element(find.byType(WelcomeScreen)))!;
      expect(welcomeRoute.animation!.isCompleted, true,
          reason: 'Welcome fade: ${welcomeRoute.animation!.value}');
      voiceDiagnostics = () =>
          'Sources: ${audio.sources}; starts: ${audio.starts}; '
          'calls: ${audio.calls}; current: ${welcomeRoute.isCurrent}; '
          'voice enabled: ${p.voiceEnabled}; phrase: ${p.phonicsAudio.currentPhrase}';
      await waitForVoice(
          t,
          () => audio.starts
              .any((s) => s.endsWith('kidsphonics_title_chorus.mp3')));
      expect(find.byKey(const ValueKey('home-student')), findsNothing);
      expect(find.byKey(const ValueKey('scene-dialogue-text')), findsNothing);
      expect(find.byType(TextField), findsNothing);
      await finishTitle(t, audio);
      await t.pump(const Duration(milliseconds: 1499));
      expect(audio.starts, hasLength(1));
      await t.pump(const Duration(milliseconds: 1));

      for (final dialogue in homeIntroduction) {
        final clip = homeNarrationAssets[dialogue.phrase.substring(5)]!;
        await waitForVoice(t, () => audio.starts.any((s) => s.endsWith(clip)));
        final scene = t.widget<SchoolHomeScene>(find.byType(SchoolHomeScene));
        expect(scene.showStudent, false);
        expect(
            scene.speakingMascot?.name, dialogue.games ? 'games' : 'lessons');
        expect(
            find.byWidgetPredicate((widget) =>
                widget is SceneDialogue && widget.text == dialogue.text),
            findsOneWidget);
        expect(find.byType(TextField), findsNothing);
        expect(
            t
                .widget<SceneButton>(find.byKey(const ValueKey('welcome-next')))
                .onPressed,
            isNotNull);
        await t.runAsync(() => audio.completeSource(clip));
        await waitForVoice(
            t,
            () =>
                t
                    .widget<SceneButton>(
                        find.byKey(const ValueKey('welcome-next')))
                    .onPressed !=
                null);
        await t.tap(find.byKey(const ValueKey('welcome-next')));
        await t.pump(const Duration(milliseconds: 200));
        await t.pump();
      }

      await waitForVoice(
          t, () => audio.starts.any((s) => s.endsWith('profile_setup_01.mp3')));
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byKey(const ValueKey('home-student')), findsNothing);
      await t.runAsync(() => audio.completeSource('profile_setup_01.mp3'));
      await waitForVoice(
          t,
          () =>
              t
                  .widget<InkWell>(find.byKey(ValueKey('choose-$character')))
                  .onTap !=
              null);
      await t.tap(find.byKey(ValueKey('choose-$character')));
      await t.enterText(find.byType(TextField), 'Sam');
      await waitForVoice(
          t, () => audio.starts.any((s) => s.endsWith('profile_setup_02.mp3')));
      await t.runAsync(() => audio.completeSource('profile_setup_02.mp3'));
      await waitForVoice(
          t,
          () =>
              t
                  .widget<SceneButton>(
                      find.byKey(const ValueKey('save-student')))
                  .onPressed !=
              null);
      await t.runAsync(() async {
        await t.tap(find.byKey(const ValueKey('save-student')));
        await Future<void>.delayed(const Duration(milliseconds: 40));
      });
      await t.pump();
      await waitForVoice(
          t, () => find.byType(CloudScreenTransition).evaluate().isNotEmpty);
      await t.pump(); // Seed the cloud ticker before measuring its duration.
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const ValueKey('cloud-transition')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-lessons')).hitTestable(),
          findsNothing);
      await t.pump(const Duration(milliseconds: 401));
      await t.pump();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
          t.widget<StudentWave>(find.byType(StudentWave)).character, character);
      expect(p.studentName, 'Sam');
      expect(p.welcomeCompleted, true);

      final idle = character == 'girl'
          ? 'girl_automatic_prompt_1.mp3'
          : 'boy_automatic_prompt_4.mp3';
      await t.pump(const Duration(milliseconds: 4999));
      expect(audio.starts.where((s) => s.endsWith(idle)), isEmpty);
      await t.pump(const Duration(milliseconds: 1));
      await waitForVoice(t, () => audio.starts.any((s) => s.endsWith(idle)));
      expect(
          find.text(character == 'girl'
              ? girlAutomaticPrompts.first.text
              : boyAutomaticPrompts.first.text),
          findsOneWidget);
      await t.runAsync(() => audio.completeSource(idle));
      await waitForVoice(
          t,
          () => find
              .byKey(const ValueKey('scene-dialogue-text'))
              .evaluate()
              .isEmpty);

      final start = t.getRect(find.byKey(const ValueKey('home-student')));
      final left = category == 'lessons';
      final cue = '${character}_lets_${left ? 'learn' : 'play'}.mp3';
      await t.tap(find.byKey(ValueKey('home-$category')));
      await waitForVoice(t, () => audio.starts.any((s) => s.endsWith(cue)));
      expect(find.byKey(ValueKey('walk-$character-$left')), findsNothing);
      expect(find.byType(destination), findsNothing);
      await t.runAsync(() => audio.completeSource(cue));
      await waitForVoice(
          t,
          () =>
              t
                  .widget<SchoolHomeScene>(find.byType(SchoolHomeScene))
                  .studentSpeech ==
              null);
      await t.pump();
      await t.pump(const Duration(milliseconds: 900));
      expect(find.byKey(ValueKey('walk-$character-$left')), findsOneWidget);
      final walking = t.getRect(find.byKey(const ValueKey('home-student')));
      expect(walking.width, closeTo(start.width, .001));
      expect(walking.height, closeTo(start.height, .001));
      expect(
          left
              ? walking.center.dx < start.center.dx
              : walking.center.dx > start.center.dx,
          true);
      await t.pump(const Duration(milliseconds: 880));
      final stopped = t.getRect(find.byKey(const ValueKey('home-student')));
      final mascot = t.getRect(find.byKey(ValueKey('home-$category-mascot')));
      expect(
          left
              ? stopped.center.dx > mascot.center.dx
              : stopped.center.dx < mascot.center.dx,
          true);
      expect(stopped.left, greaterThanOrEqualTo(0));
      expect(stopped.right, lessThanOrEqualTo(390));
      expect(find.byKey(ValueKey('walk-$character-$left')), findsNothing);
      expect(
          find.byKey(const ValueKey('home-character-cloud')), findsOneWidget);
      expect(find.byType(destination), findsNothing);
      await t.pump(const Duration(milliseconds: 471));
      await t.pump();
      await waitForVoice(
          t, () => find.byType(destination).evaluate().isNotEmpty);
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
      expect(find.byType(destination), findsOneWidget);
      expect(
          audio.starts.where((s) => s.endsWith('kidsphonics_title_chorus.mp3')),
          hasLength(1));
      expect(t.takeException(), isNull);
      await close(t, p);
      await t.runAsync(() async {
        await PhonicsAudioService().stop();
        PhonicsAudioService().dispose();
        AudioService().dispose();
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      await t.pump();
    });
  }
}
