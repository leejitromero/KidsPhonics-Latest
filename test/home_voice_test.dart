import 'package:kidsphonics/widgets/scene_dialogue.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/home_narration.dart';
import 'package:kidsphonics/controllers/scene_voice_controller.dart';
import 'package:kidsphonics/data/updated_scene.dart';
import 'package:kidsphonics/screens/home_screen.dart';
import 'package:kidsphonics/screens/welcome_screen.dart';
import 'package:kidsphonics/screens/lessons_screen.dart';
import 'package:kidsphonics/screens/games_screen.dart';
import 'package:kidsphonics/widgets/scene_controls.dart';
import 'package:kidsphonics/widgets/school_home_scene.dart';
import 'package:kidsphonics/widgets/cloud_page_route.dart';
import 'package:kidsphonics/widgets/student_wave.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';
import 'package:kidsphonics/services/audio_service.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'quiz_audio_harness.dart';

String Function() voiceDiagnostics = () => '';

Future<void> waitForVoice(WidgetTester t, bool Function() ready) async {
  for (var i = 0; i < 150 && !ready(); i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await t.pump();
  }
  expect(ready(), true, reason: voiceDiagnostics());
}

Future<void> finishTitle(WidgetTester t, QuizAudioHarness audio) async {
  await waitForVoice(
      t,
      () =>
          audio.starts.any((s) => s.endsWith('kidsphonics_title_chorus.mp3')));
  await t.runAsync(() => audio.completeSource('kidsphonics_title_chorus.mp3'));
  await waitForVoice(
      t,
      () => !t
          .widgetList<ListenableBuilder>(find.byType(ListenableBuilder))
          .map((w) => w.listenable)
          .whereType<SceneVoiceController>()
          .any((voice) => voice.playing));
  await t.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late QuizAudioHarness audio;
  setUp(() {
    mockProgressAudio();
    SharedPreferences.setMockInitialValues({'sfx': false});
    audio = QuizAudioHarness()..install();
    voiceDiagnostics = () =>
        'Sources: ${audio.sources}\nStarted: ${audio.starts}\nCalls: ${audio.calls}';
  });
  Future<void> finish(WidgetTester t, AppProvider p) async {
    await close(t, p);
    await t.runAsync(() async {
      await PhonicsAudioService().stop();
      PhonicsAudioService().dispose();
      AudioService().dispose();
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await t.pump();
  }

  test('every mapped voice exists, including the mixed title cue', () async {
    for (final entry in homeNarrationAssets.entries) {
      expect(
          PhonicsAudioService.assetForPhrase('home-${entry.key}'), entry.value);
      expect((await rootBundle.load('assets/${entry.value}')).lengthInBytes,
          greaterThan(1000));
    }
    expect(Directory('assets/audio/home_intro').listSync().whereType<File>(),
        hasLength(25));
  });

  for (final duringTitle in [true, false]) {
    testWidgets(
        'Skip cancels ${duringTitle ? 'title' : 'mascot'} narration and requires setup',
        (t) async {
      final p = await mount(t, const WelcomeScreen());
      await waitForVoice(
          t,
          () => audio.starts.any(
              (source) => source.endsWith('kidsphonics_title_chorus.mp3')));
      if (!duringTitle) {
        await finishTitle(t, audio);
        await t.pump(const Duration(milliseconds: 1500));
        await waitForVoice(
            t,
            () => audio.starts
                .any((source) => source.endsWith('lessons_intro_01.mp3')));
      }
      final introductionCount =
          audio.starts.where((source) => source.contains('intro_')).length;
      await t.tap(find.byKey(const ValueKey('welcome-skip')));
      await t.pump();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byKey(const ValueKey('welcome-skip')), findsNothing);
      expect(find.byKey(const ValueKey('home-practice-art')), findsNothing);
      expect(p.welcomeCompleted, false);
      await waitForVoice(
          t,
          () => audio.starts
              .any((source) => source.endsWith('profile_setup_01.mp3')));
      await t.runAsync(() => audio.completeSource('profile_setup_01.mp3'));
      await t.pump(const Duration(seconds: 5));
      expect(audio.starts.where((source) => source.contains('intro_')),
          hasLength(introductionCount));
      expect(find.byType(TextField), findsOneWidget);
      expect(p.welcomeCompleted, false);
      expect(t.takeException(), isNull);
      await finish(t, p);
    });
  }

  testWidgets(
      'empty home finishes the title chorus before Lala and Lulu introductions',
      (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final p = await mount(t, const WelcomeScreen());
    expect(find.byKey(const ValueKey('home-student')), findsNothing);
    await waitForVoice(
        t,
        () => audio.starts
            .any((s) => s.endsWith('kidsphonics_title_chorus.mp3')));
    await t.pump(const Duration(seconds: 8));
    expect(audio.starts, hasLength(1));
    expect(find.byKey(const ValueKey('scene-dialogue-text')), findsNothing);
    expect(find.byKey(const ValueKey('welcome-next')), findsOneWidget);
    await finishTitle(t, audio);
    await t.pump(const Duration(milliseconds: 1499));
    expect(audio.starts, hasLength(1));
    await t.pump(const Duration(milliseconds: 1));
    for (var i = 0; i < homeIntroduction.length; i++) {
      final clip =
          homeNarrationAssets[homeIntroduction[i].phrase.substring(5)]!;
      await waitForVoice(t, () => audio.starts.any((s) => s.endsWith(clip)));
      expect(
          find.byWidgetPredicate((widget) =>
              widget is SceneDialogue &&
              widget.text == homeIntroduction[i].text),
          findsOneWidget);
      expect(
          t
              .widget<SceneButton>(find.byKey(const ValueKey('welcome-next')))
              .onPressed,
          isNotNull);
      final scene = t.widget<SchoolHomeScene>(find.byType(SchoolHomeScene));
      expect(scene.showStudent, false);
      expect(scene.speakingMascot?.name, i < 5 ? 'lessons' : 'games');
      // An arbitrarily long completed clip still does not advance automatically.
      await t.runAsync(() => audio.completeSource(clip));
      await waitForVoice(
          t,
          () =>
              t
                  .widget<SceneButton>(
                      find.byKey(const ValueKey('welcome-next')))
                  .onPressed !=
              null);
      await t.pump(const Duration(seconds: 1));
      expect(
          find.byWidgetPredicate((widget) =>
              widget is SceneDialogue &&
              widget.text == homeIntroduction[i].text),
          findsOneWidget);
      await t.tap(find.byKey(const ValueKey('welcome-next')));
      await t.tap(find.byKey(const ValueKey('welcome-next')),
          warnIfMissed: false);
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
                .widget<InkWell>(find.byKey(const ValueKey('choose-girl')))
                .onTap !=
            null);
    await t.enterText(find.byType(TextField), 'Mia');
    await t.tap(find.byKey(const ValueKey('choose-girl')));
    await t.tap(find.byKey(const ValueKey('save-student')));
    expect(
        p.welcomeCompleted, false); // Same-frame Save cannot cut setup speech.
    await waitForVoice(
        t, () => audio.starts.any((s) => s.endsWith('profile_setup_02.mp3')));
    await t.enterText(find.byType(TextField), 'Mia');
    expect(
        t
            .widget<SceneButton>(find.byKey(const ValueKey('save-student')))
            .onPressed,
        isNull);
    await t.runAsync(() => audio.completeSource('profile_setup_02.mp3'));
    await waitForVoice(
        t,
        () =>
            t
                .widget<SceneButton>(find.byKey(const ValueKey('save-student')))
                .onPressed !=
            null);
    await t.runAsync(() async {
      await t.tap(find.byKey(const ValueKey('save-student')));
      await Future<void>.delayed(const Duration(milliseconds: 40));
    });
    await t.pump();
    await waitForVoice(
        t, () => find.byType(CloudScreenTransition).evaluate().isNotEmpty);
    await t.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('cloud-transition')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('home-lessons')).hitTestable(), findsNothing);
    await t.pump(const Duration(milliseconds: 500));
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('home-student')), findsOneWidget);
    expect(p.studentCharacter, 'girl');
    expect(p.welcomeCompleted, true);
    expect(
        audio.starts.where((s) => s.endsWith('kidsphonics_title_chorus.mp3')),
        hasLength(1)); // The cloud reveal does not repeat the startup cue.
    expect(t.takeException(), isNull);
    await finish(t, p);
  });

  testWidgets('interrupted title restarts before Lala after resume', (t) async {
    final p = await mount(t, const WelcomeScreen());
    await waitForVoice(
        t,
        () => audio.starts
            .any((s) => s.endsWith('kidsphonics_title_chorus.mp3')));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t
        .runAsync(() => audio.completeSource('kidsphonics_title_chorus.mp3'));
    await t.pump(const Duration(seconds: 8));
    expect(audio.starts, hasLength(1));
    expect(find.byKey(const ValueKey('scene-dialogue-text')), findsNothing);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    await waitForVoice(
        t,
        () =>
            audio.starts
                .where((s) => s.endsWith('kidsphonics_title_chorus.mp3'))
                .length ==
            2);
    await finishTitle(t, audio);
    await t.pump(const Duration(milliseconds: 1500));
    await waitForVoice(
        t, () => audio.starts.any((s) => s.endsWith('lessons_intro_01.mp3')));
    expect(
        find.byWidgetPredicate((widget) =>
            widget is SceneDialogue &&
            widget.text == homeIntroduction.first.text),
        findsOneWidget);
    await finish(t, p);
  });

  testWidgets(
      'muted title is skipped without blocking first-time introductions',
      (t) async {
    SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
    final p = await mount(t, const WelcomeScreen());
    await t.pump(const Duration(milliseconds: 1499));
    expect(find.byKey(const ValueKey('scene-dialogue-text')), findsNothing);
    await t.pump(const Duration(milliseconds: 1));
    expect(
        find.byWidgetPredicate((widget) =>
            widget is SceneDialogue &&
            widget.text == homeIntroduction.first.text),
        findsOneWidget);
    expect(audio.starts, isEmpty);
    await finish(t, p);
  });

  testWidgets(
      'Next interrupts the title and every spoken guideline immediately',
      (t) async {
    final p = await mount(t, const WelcomeScreen());
    const title = 'kidsphonics_title_chorus.mp3';
    await waitForVoice(t, () => audio.starts.any((s) => s.endsWith(title)));
    expect(find.byKey(const ValueKey('welcome-skip')).hitTestable(),
        findsOneWidget);
    expect(find.byKey(const ValueKey('welcome-next')).hitTestable(),
        findsOneWidget);
    await t.tap(find.byKey(const ValueKey('welcome-next')));
    await t.runAsync(() => audio.completeSource(title));
    await t.pump(const Duration(milliseconds: 200));
    await t.pump();
    for (var step = 0; step < homeIntroduction.length; step++) {
      final clip =
          homeNarrationAssets[homeIntroduction[step].phrase.substring(5)]!;
      await waitForVoice(t, () => audio.starts.any((s) => s.endsWith(clip)));
      expect(
          find.byWidgetPredicate((widget) =>
              widget is SceneDialogue &&
              widget.text == homeIntroduction[step].text),
          findsOneWidget);
      final next = t
          .widget<SceneButton>(find.byKey(const ValueKey('welcome-next')))
          .onPressed;
      expect(next, isNotNull);
      next!();
      next(); // A repeated tap during the short text fade cannot skip a step.
      expect(p.phonicsAudio.currentPhrase, isNull);
      // A late completion of the interrupted recording must not advance again.
      await t.runAsync(() => audio.completeSource(clip));
      await t.pump(const Duration(milliseconds: 200));
      await t.pump();
    }
    await waitForVoice(
        t, () => audio.starts.any((s) => s.endsWith('profile_setup_01.mp3')));
    expect(find.byType(TextField), findsOneWidget);
    expect(p.welcomeCompleted, false);
    expect(t.takeException(), isNull);
    await finish(t, p);
  });

  testWidgets('Skip cancels a pending Next instruction during its short fade',
      (t) async {
    final p = await mount(t, const WelcomeScreen());
    await finishTitle(t, audio);
    await t.pump(const Duration(milliseconds: 1500));
    await waitForVoice(
        t, () => audio.starts.any((s) => s.endsWith('lessons_intro_01.mp3')));
    await t.tap(find.byKey(const ValueKey('welcome-next')));
    await t.tap(find.byKey(const ValueKey('welcome-skip')));
    await t.pump(const Duration(milliseconds: 200));
    await waitForVoice(
        t, () => audio.starts.any((s) => s.endsWith('profile_setup_01.mp3')));
    expect(audio.starts.any((s) => s.endsWith('lessons_intro_02.mp3')), false);
    expect(find.byType(TextField), findsOneWidget);
    expect(t.takeException(), isNull);
    await finish(t, p);
  });

  for (final character in ['boy', 'girl']) {
    testWidgets('$character waves and speaks once after five idle seconds',
        (t) async {
      SharedPreferences.setMockInitialValues(
          {'studentCharacter': character, 'sfx': false});
      final p = await mount(t, const HomeScreen());
      expect(
          t.widget<StudentWave>(find.byType(StudentWave)).character, character);
      await t.pump(const Duration(milliseconds: 4999));
      expect(audio.starts, isEmpty);
      await t.pump(const Duration(milliseconds: 1));
      final clip = character == 'girl'
          ? 'girl_automatic_prompt_1.mp3'
          : 'boy_automatic_prompt_4.mp3';
      await waitForVoice(t, () => audio.starts.any((s) => s.endsWith(clip)));
      expect(
          find.text(character == 'girl'
              ? girlAutomaticPrompts.first.text
              : boyAutomaticPrompts.first.text),
          findsOneWidget);
      expect(t.widget<StudentWave>(find.byType(StudentWave)).animate, true);
      await t.runAsync(() => audio.completeSource(clip));
      await waitForVoice(
          t,
          () => find
              .byKey(const ValueKey('scene-dialogue-text'))
              .evaluate()
              .isEmpty);
      await t.pump(const Duration(seconds: 20));
      expect(audio.starts.where((s) => s.endsWith(clip)), hasLength(1));
      expect(t.takeException(), isNull);
      await finish(t, p);
    });
  }

  for (final character in ['girl', 'boy']) {
    testWidgets('$character automatic recordings rotate with matching text',
        (t) async {
      SharedPreferences.setMockInitialValues(
          {'studentCharacter': character, 'sfx': false});
      final prompts =
          character == 'girl' ? girlAutomaticPrompts : boyAutomaticPrompts;
      final p = await mount(t, const HomeScreen());
      final navigator = Navigator.of(t.element(find.byType(HomeScreen)));
      for (var turn = 0; turn < 4; turn++) {
        await t.pump(const Duration(milliseconds: 4999));
        expect(audio.starts, hasLength(turn));
        await t.pump(const Duration(milliseconds: 1));
        final number = turn % 3 + (character == 'girl' ? 1 : 4);
        final clip = '${character}_automatic_prompt_$number.mp3';
        await waitForVoice(
            t,
            () =>
                audio.starts.length == turn + 1 &&
                audio.starts.last.endsWith(clip));
        expect(find.text(prompts[turn % 3].text), findsOneWidget);
        await t.runAsync(() => audio.completeSource(clip));
        await waitForVoice(
            t,
            () => find
                .byKey(const ValueKey('scene-dialogue-text'))
                .evaluate()
                .isEmpty);
        await t.pump(const Duration(seconds: 20));
        expect(audio.starts, hasLength(turn + 1));
        if (turn < 3) {
          navigator.push(PageRouteBuilder<void>(
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              pageBuilder: (_, __, ___) =>
                  const Scaffold(body: Text('Other page'))));
          await t.pump();
          await t.pump(const Duration(seconds: 5));
          expect(audio.starts, hasLength(turn + 1));
          navigator.pop();
          await t.pump();
          await t.pump();
        }
      }
      expect(t.takeException(), isNull);
      await finish(t, p);
    });
  }

  testWidgets(
      'touch restarts idle countdown and Lessons cancels the idle voice',
      (t) async {
    final p = await mount(t, const HomeScreen());
    await t.pump(const Duration(seconds: 4));
    final scene = t.getRect(find.byType(SchoolHomeScene));
    await t.tapAt(Offset(scene.left + 4, scene.center.dy));
    await t.pump(const Duration(seconds: 4));
    expect(audio.starts, isEmpty);
    await t.pump(const Duration(seconds: 1));
    await waitForVoice(
        t,
        () =>
            audio.starts.any((s) => s.endsWith('boy_automatic_prompt_4.mp3')));
    await t.tap(find.byKey(const ValueKey('home-lessons')));
    await waitForVoice(
        t, () => audio.starts.any((s) => s.endsWith('boy_lets_learn.mp3')));
    expect(find.text(boyAutomaticPrompts.first.text), findsNothing);
    expect(find.byKey(const ValueKey('walk-boy-true')), findsNothing);
    await t.runAsync(() => audio.completeSource('boy_lets_learn.mp3'));
    await waitForVoice(
        t,
        () =>
            p.phonicsAudio.currentPhrase == null &&
            find
                .byKey(const ValueKey('scene-dialogue-text'))
                .evaluate()
                .isEmpty);
    await t.pump(); // Seed the walking ticker before measuring its duration.
    await t.pump(const Duration(milliseconds: 16));
    expect(find.byKey(const ValueKey('walk-boy-true')), findsOneWidget);
    await t.pump(const Duration(milliseconds: 900));
    await t.pump(const Duration(milliseconds: 1400));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(find.byType(LessonsScreen), findsOneWidget);
    await finish(t, p);
  });

  testWidgets(
      'background and covered routes suppress idle voice until Home is visible',
      (t) async {
    final p = await mount(t, const HomeScreen());
    await t.pump(const Duration(seconds: 4));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump(const Duration(seconds: 8));
    expect(audio.starts, isEmpty);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump(const Duration(seconds: 4));
    expect(audio.starts, isEmpty);
    final navigator = Navigator.of(t.element(find.byType(HomeScreen)));
    navigator.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Other page'))));
    await t.pump();
    await t.pump(const Duration(seconds: 8));
    expect(audio.starts, isEmpty);
    final route =
        ModalRoute.of(t.element(find.byType(HomeScreen, skipOffstage: false)))!;
    navigator.pop();
    await t.pump();
    for (var i = 0; i < 60 && !route.secondaryAnimation!.isDismissed; i++) {
      await t.pump(const Duration(milliseconds: 16));
    }
    expect(route.secondaryAnimation!.isDismissed, true);
    await t.pump();
    await t.pump(const Duration(milliseconds: 4999));
    expect(audio.starts, isEmpty);
    await t.pump(const Duration(milliseconds: 1));
    final nativeDiagnostics = voiceDiagnostics;
    voiceDiagnostics = () =>
        '${nativeDiagnostics()}\nCurrent: ${route.isCurrent}, animation: ${route.animation?.status}, secondary: ${route.secondaryAnimation?.status}, phrase: ${p.phonicsAudio.currentPhrase}, ready: ${p.isReady}, voice: ${p.voiceEnabled}';
    await waitForVoice(
        t,
        () =>
            audio.starts.any((s) => s.endsWith('boy_automatic_prompt_4.mp3')));
    await finish(t, p);
  });

  testWidgets('muting voice cancels the pending automatic prompt', (t) async {
    final p = await mount(t, const HomeScreen());
    await t.pump(const Duration(seconds: 4));
    await t.runAsync(() => p.toggleVoice());
    await t.pump();
    await t.pump(const Duration(seconds: 10));
    expect(audio.starts, isEmpty);
    expect(find.byKey(const ValueKey('scene-dialogue-text')), findsNothing);
    await finish(t, p);
  });

  for (final character in ['boy', 'girl']) {
    for (final games in [false, true]) {
      testWidgets(
          '$character says ${games ? 'play' : 'learn'} before walking and navigation',
          (t) async {
        SharedPreferences.setMockInitialValues(
            {'studentCharacter': character, 'sfx': false});
        final p = await mount(t, const HomeScreen());
        await t.runAsync(() => p.setStudentCharacter(character, 'Sam'));
        await t.pump();
        final category = games ? 'games' : 'lessons';
        final clip = '${character}_lets_${games ? 'play' : 'learn'}.mp3';
        await t.ensureVisible(find.byKey(ValueKey('home-$category')));
        final start = t.getRect(find.byKey(const ValueKey('home-student')));
        await t.tap(find.byKey(ValueKey('home-$category')));
        final nativeDiagnostics = voiceDiagnostics;
        voiceDiagnostics = () =>
            '${nativeDiagnostics()}\nVoice: ${p.voiceEnabled}, phrase: ${p.phonicsAudio.currentPhrase}, busy: ${t.widget<SchoolHomeScene>(find.byType(SchoolHomeScene)).busy}';
        await waitForVoice(t, () => audio.starts.any((s) => s.endsWith(clip)));
        await t.pump(const Duration(seconds: 3));
        expect(t.getRect(find.byKey(const ValueKey('home-student'))), start);
        expect(find.byType(games ? GamesScreen : LessonsScreen), findsNothing);
        await t.tap(find.byKey(ValueKey('home-$category')),
            warnIfMissed: false);
        expect(audio.starts.where((s) => s.endsWith(clip)), hasLength(1));
        await t.runAsync(() => audio.completeSource(clip));
        await waitForVoice(
            t,
            () =>
                p.phonicsAudio.currentPhrase == null &&
                find
                    .byKey(const ValueKey('scene-dialogue-text'))
                    .evaluate()
                    .isEmpty);
        await t.pump(const Duration(milliseconds: 900));
        expect(
            find.byKey(ValueKey('walk-$character-${!games}')), findsOneWidget);
        final position =
            t.getRect(find.byKey(const ValueKey('home-student'))).center.dx;
        expect(games ? position > start.center.dx : position < start.center.dx,
            true);
        await t.pump(const Duration(milliseconds: 1400));
        await t.pump();
        await t.pump(const Duration(milliseconds: 500));
        expect(
            find.byType(games ? GamesScreen : LessonsScreen), findsOneWidget);
        expect(t.takeException(), isNull);
        await finish(t, p);
      });
    }
  }

  testWidgets(
      'background cancels entry and late audio completion cannot navigate',
      (t) async {
    final p = await mount(t, const HomeScreen());
    await t.ensureVisible(find.byKey(const ValueKey('home-lessons')));
    await t.tap(find.byKey(const ValueKey('home-lessons')));
    await waitForVoice(
        t, () => audio.starts.any((s) => s.endsWith('boy_lets_learn.mp3')));
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused
    ]) {
      t.binding.handleAppLifecycleStateChanged(state);
    }
    await t.runAsync(() => audio.completeSource('boy_lets_learn.mp3'));
    await t.pump(const Duration(seconds: 5));
    expect(find.byType(LessonsScreen), findsNothing);
    expect(p.phonicsAudio.currentPhrase, isNull);
    for (final state in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed
    ]) {
      t.binding.handleAppLifecycleStateChanged(state);
    }
    await t.pump();
    expect(t.widget<SchoolHomeScene>(find.byType(SchoolHomeScene)).busy, false);
    expect(find.byKey(const ValueKey('walk-boy-true')), findsNothing);
    await finish(t, p);
  });

  testWidgets('interrupted onboarding replays the same step after resume',
      (t) async {
    final p = await mount(t, const WelcomeScreen());
    await finishTitle(t, audio);
    await t.pump(const Duration(milliseconds: 1500));
    await waitForVoice(
        t, () => audio.starts.any((s) => s.endsWith('lessons_intro_01.mp3')));
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused
    ]) {
      t.binding.handleAppLifecycleStateChanged(state);
    }
    await t.runAsync(() => audio.completeSource('lessons_intro_01.mp3'));
    await t.pump(const Duration(seconds: 3));
    expect(p.phonicsAudio.currentPhrase, isNull);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is SceneDialogue &&
            widget.text == homeIntroduction.first.text),
        findsOneWidget);
    for (final state in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed
    ]) {
      t.binding.handleAppLifecycleStateChanged(state);
    }
    await waitForVoice(
        t,
        () =>
            audio.starts
                .where((s) => s.endsWith('lessons_intro_01.mp3'))
                .length ==
            2);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is SceneDialogue &&
            widget.text == homeIntroduction.first.text),
        findsOneWidget);
    expect(
        t
            .widget<SceneButton>(find.byKey(const ValueKey('welcome-next')))
            .onPressed,
        isNotNull);
    await finish(t, p);
  });
}
