import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/controllers/player_welcome_voice.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/home_screen.dart';
import 'package:kidsphonics/services/audio_service.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';
import 'package:kidsphonics/widgets/school_home_scene.dart';
import 'package:kidsphonics/widgets/home_greeting_card.dart';
import 'package:kidsphonics/widgets/scene_dialogue.dart';
import 'updated_scene_test.dart' show capture;
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'home_voice_test.dart' show waitForVoice, finishTitle, voiceDiagnostics;
import 'quiz_audio_harness.dart';

class _WelcomeHarness {
  final requests = <Map<dynamic, dynamic>>[];
  final completions = <Completer<bool>>[];
  final stops = <String>[];
  bool unavailable = false;
  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(PlayerWelcomeVoice.channel, (call) async {
      final args = call.arguments as Map;
      if (call.method == 'stop') {
        stops.add(args['id'] as String);
        return true;
      }
      requests.add(args);
      if (unavailable) return false;
      final done = Completer<bool>();
      completions.add(done);
      return done.future;
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late QuizAudioHarness audio;
  late _WelcomeHarness welcome;
  const title = 'kidsphonics_title_chorus.mp3';
  setUp(() {
    voiceDiagnostics = () => '';
    mockProgressAudio();
    SharedPreferences.setMockInitialValues({
      'sfx': false,
      'welcomeCompletedV1': true,
      'studentName': 'Sam',
      'studentCharacter': 'boy',
    });
    audio = QuizAudioHarness()..install();
    welcome = _WelcomeHarness()..install();
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

  bool busy(WidgetTester t) =>
      t.widget<SchoolHomeScene>(find.byType(SchoolHomeScene)).busy;

  test('welcome uses the saved name and normalizes spaces', () {
    expect(PlayerWelcomeVoice.greeting('  Anne   Marie  ', returning: false),
        "Welcome, Anne Marie! Let's learn and play!");
    expect(PlayerWelcomeVoice.greeting("O'Neil", returning: true),
        "Welcome back, O'Neil! Let's learn and play!");
    expect(PlayerWelcomeVoice.greeting('A' * 40, returning: false),
        "Welcome, ${'A' * 24}! Let's learn and play!");
  });

  testWidgets('name finishes before chorus, then idle; no replay on return',
      (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final boundary = GlobalKey();
    final p = await mount(
        t,
        RepaintBoundary(
            key: boundary,
            child: Builder(
                builder: (context) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                        padding: const EdgeInsets.only(top: 24, bottom: 24)),
                    child: const HomeScreen(announceTitle: true)))));
    await waitForVoice(t, () => welcome.requests.length == 1);
    await capture(t, boundary, 'home_greeting_card');
    expect(welcome.requests.single['text'],
        "Welcome back, Sam! Let's learn and play!");
    expect(
        find.byKey(const ValueKey('player-welcome-dialogue')), findsOneWidget);
    expect(busy(t), true);
    await t.pump(const Duration(seconds: 8));
    expect(audio.starts, isEmpty);
    welcome.completions.single.complete(true);
    await waitForVoice(t, () => audio.starts.any((s) => s.endsWith(title)));
    expect(find.byKey(const ValueKey('player-welcome-dialogue')), findsNothing);
    expect(busy(t), true);
    await finishTitle(t, audio);
    await waitForVoice(t, () => !busy(t));
    await t.pump(const Duration(milliseconds: 4999));
    expect(audio.starts, hasLength(1));
    await t.pump(const Duration(milliseconds: 1));
    await waitForVoice(
        t,
        () =>
            audio.starts.any((s) => s.endsWith('boy_automatic_prompt_4.mp3')));
    await t.runAsync(() => audio.completeSource('boy_automatic_prompt_4.mp3'));
    await t.pump();
    final nav = Navigator.of(t.element(find.byType(HomeScreen)));
    nav.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Room'))));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    nav.pop();
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(welcome.requests, hasLength(1));
    expect(audio.starts.where((s) => s.endsWith(title)), hasLength(1));
    expect(t.takeException(), isNull);
    await finish(t, p);
  });

  testWidgets('new profile welcomes once without repeating introduction chorus',
      (t) async {
    final p = await mount(t, const HomeScreen(welcomePlayer: true));
    await waitForVoice(t, () => welcome.requests.isNotEmpty);
    expect(
        welcome.requests.single['text'], "Welcome, Sam! Let's learn and play!");
    welcome.completions.single.complete(true);
    await waitForVoice(t, () => !busy(t));
    expect(audio.starts, isEmpty);
    await finish(t, p);
  });

  for (final mode in ['offline voice unavailable', 'plugin absent', 'error']) {
    testWidgets('$mode falls back to existing title and enables Home',
        (t) async {
      if (mode == 'offline voice unavailable') welcome.unavailable = true;
      if (mode == 'plugin absent') {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(PlayerWelcomeVoice.channel, null);
      }
      if (mode == 'error') {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(PlayerWelcomeVoice.channel, (_) async {
          throw PlatformException(code: 'tts_error');
        });
      }
      final p = await mount(t, const HomeScreen(announceTitle: true));
      await finishTitle(t, audio);
      await waitForVoice(t, () => !busy(t));
      expect(t.takeException(), isNull);
      await finish(t, p);
    });
  }

  for (final muted in [true, false]) {
    testWidgets('${muted ? 'Voice off' : 'empty name'} skips native greeting',
        (t) async {
      SharedPreferences.setMockInitialValues({
        'sfx': false,
        'voice': !muted,
        'studentName': muted ? 'Sam' : '',
      });
      final p = await mount(t, const HomeScreen(announceTitle: true));
      if (!muted) await finishTitle(t, audio);
      await waitForVoice(t, () => !busy(t));
      expect(welcome.requests, isEmpty);
      if (muted) expect(audio.starts, isEmpty);
      await finish(t, p);
    });
  }

  testWidgets('background cancels greeting; late result cannot start chorus',
      (t) async {
    final p = await mount(t, const HomeScreen(announceTitle: true));
    await waitForVoice(t, () => welcome.requests.length == 1);
    final firstId = welcome.requests.first['id'];
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await waitForVoice(t, () => welcome.stops.contains(firstId));
    welcome.completions.first.complete(true);
    await t.pump(const Duration(seconds: 8));
    expect(audio.starts, isEmpty);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    await waitForVoice(t, () => welcome.requests.length == 2);
    expect(welcome.requests.last['id'], isNot(firstId));
    expect(audio.starts, isEmpty);
    welcome.completions.last.complete(true);
    await finishTitle(t, audio);
    await waitForVoice(t, () => !busy(t));
    await finish(t, p);
  });

  testWidgets('muting during greeting cancels it without awaiting native reply',
      (t) async {
    final p = await mount(t, const HomeScreen(announceTitle: true));
    await waitForVoice(t, () => welcome.requests.isNotEmpty);
    await t.runAsync(() => p.toggleVoice());
    await waitForVoice(t, () => !busy(t));
    expect(welcome.stops, contains(welcome.requests.single['id']));
    welcome.completions.single.complete(true);
    await t.pump();
    expect(audio.starts, isEmpty);
    expect(t.takeException(), isNull);
    await finish(t, p);
  });

  testWidgets('timeout stops speech before title is allowed to start',
      (t) async {
    final p = await mount(t, const HomeScreen(announceTitle: true));
    await waitForVoice(t, () => welcome.requests.isNotEmpty);
    await t.pump(const Duration(seconds: 22));
    await waitForVoice(t, () => audio.starts.any((s) => s.endsWith(title)));
    expect(welcome.stops, contains(welcome.requests.single['id']));
    welcome.completions.single.complete(true);
    await finishTitle(t, audio);
    await waitForVoice(t, () => !busy(t));
    expect(welcome.requests, hasLength(1));
    await finish(t, p);
  });

  testWidgets('disposing Home stops greeting and ignores native late reply',
      (t) async {
    final p = await mount(t, const HomeScreen(announceTitle: true));
    await waitForVoice(t, () => welcome.requests.isNotEmpty);
    await finish(t, p);
    expect(welcome.stops, contains(welcome.requests.single['id']));
    welcome.completions.single.complete(true);
    await t.pump();
    expect(audio.starts, isEmpty);
    expect(t.takeException(), isNull);
  });

  testWidgets('covered Home cancels speech and ignores old reply after return',
      (t) async {
    final p = await mount(t, const HomeScreen(announceTitle: true));
    voiceDiagnostics = () {
      final route = ModalRoute.of(t.element(find.byType(HomeScreen)));
      return 'requests: ${welcome.requests}; stops: ${welcome.stops}; '
          'audio: ${audio.starts}; current: ${route?.isCurrent}; '
          'primary: ${route?.animation?.status}; '
          'secondary: ${route?.secondaryAnimation?.status}; busy: ${busy(t)}';
    };
    await waitForVoice(t, () => welcome.requests.length == 1);
    final nav = Navigator.of(t.element(find.byType(HomeScreen)));
    nav.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Covered'))));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    await waitForVoice(
        t, () => welcome.stops.contains(welcome.requests.first['id']));
    expect(audio.starts, isEmpty);
    nav.pop();
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    // The uncovered route re-enables its ticker on the next frame.
    await t.pump(const Duration(milliseconds: 400));
    await waitForVoice(t, () => welcome.requests.length == 2);
    // An older native reply may arrive after a new greeting has started.
    welcome.completions.first.complete(true);
    await t.pump();
    expect(audio.starts, isEmpty);
    expect(busy(t), true);
    expect(welcome.stops, isNot(contains(welcome.requests.last['id'])));
    welcome.completions.last.complete(true);
    await finishTitle(t, audio);
    await waitForVoice(t, () => !busy(t));
    expect(t.takeException(), isNull);
    await finish(t, p);
  });

  testWidgets('profile changes stop speech containing the previous name',
      (t) async {
    final p = await mount(t, const SizedBox());
    final voice = PlayerWelcomeVoice(p, isCurrent: () => true);
    final result = voice.play('Sam', returning: true);
    await waitForVoice(t, () => welcome.requests.isNotEmpty);
    await t.runAsync(() => p.setStudentCharacter('girl', 'Alex'));
    await t.pump();
    expect(voice.playing, false);
    expect(await result, false);
    expect(welcome.stops, contains(welcome.requests.single['id']));
    welcome.completions.single.complete(true);
    await t.pump();
    voice.dispose();
    await finish(t, p);
  });

  testWidgets(
      'saving an edited name greets the new name within two seconds without restart',
      (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final p = await mount(t, const HomeScreen());
    t.widget<SchoolHomeScene>(find.byType(SchoolHomeScene)).onCharacter();
    await t.pump(const Duration(milliseconds: 350));
    await t.enterText(
        find.byKey(const ValueKey('character-selection-name')), 'Jit');
    await t.tap(find.byKey(const ValueKey('save-student')));
    await waitForVoice(t, () => find.byType(TextField).evaluate().isEmpty);
    await t.pump(const Duration(milliseconds: 350));
    expect(p.studentName, 'Jit');
    final prefs = await t.runAsync(SharedPreferences.getInstance);
    expect(prefs!.getString('studentName'), 'Jit');
    expect(welcome.requests, isEmpty);
    await t.pump(const Duration(milliseconds: 1200));
    await waitForVoice(t, () => welcome.requests.length == 1);
    expect(
        welcome.requests.single['text'], "Welcome, Jit! Let's learn and play!");
    expect(
        find.byKey(const ValueKey('player-welcome-dialogue')), findsOneWidget);
    expect(audio.starts.where((s) => s.endsWith(title)), isEmpty);
    welcome.completions.single.complete(true);
    await t.pump();
    await finish(t, p);
  });

  testWidgets(
      'rapid name updates greet only the latest saved name and no repeat on rebuild',
      (t) async {
    final p = await mount(t, const HomeScreen());
    await t.runAsync(() => p.setStudentCharacter('boy', 'Lee'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 800));
    await t.runAsync(() => p.setStudentCharacter('girl', 'Jit'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 1199));
    expect(welcome.requests, isEmpty);
    await t.pump(const Duration(milliseconds: 1));
    await waitForVoice(t, () => welcome.requests.length == 1);
    expect(welcome.requests.single['text'], contains('Jit!'));
    welcome.completions.single.complete(true);
    await t.pump();
    await t.runAsync(() => p.setStudentCharacter('boy', 'Jit'));
    await t.pump(const Duration(seconds: 2));
    expect(welcome.requests, hasLength(1));
    expect(t.takeException(), isNull);
    await finish(t, p);
  });

  for (final action in ['covered', 'background', 'muted', 'dispose']) {
    testWidgets(
        'edited-name greeting respects $action and never plays on a covered Home',
        (t) async {
      final p = await mount(t, const HomeScreen());
      await t.runAsync(() => p.setStudentCharacter('boy', 'Jit'));
      await t.pump();
      final nav = Navigator.of(t.element(find.byType(HomeScreen)));
      if (action == 'covered') {
        unawaited(nav.push(MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Room')))));
        await t.pump(const Duration(milliseconds: 350));
      } else if (action == 'background') {
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      } else if (action == 'muted') {
        await t.runAsync(() => p.toggleVoice());
      } else {
        await finish(t, p);
      }
      await t.pump(const Duration(seconds: 3));
      expect(welcome.requests, isEmpty);
      if (action == 'dispose') return;
      if (action == 'covered') {
        nav.pop();
        await t.pump();
        // Home has repeating scenery; settle the route rather than all tickers.
        Animation<double>? secondary() =>
            ModalRoute.of(t.element(find.byType(HomeScreen)))
                ?.secondaryAnimation;
        for (var i = 0; i < 60 && secondary()?.isDismissed == false; i++) {
          await t.pump(const Duration(milliseconds: 16));
        }
        expect(secondary()?.isDismissed, isTrue);
      } else if (action == 'background') {
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await t.pump();
      } else {
        await t.runAsync(() => p.toggleVoice());
        await t.pump();
      }
      await t.pump(const Duration(milliseconds: 1200));
      await waitForVoice(t, () => welcome.requests.length == 1);
      expect(welcome.requests.single['text'], contains('Jit!'));
      welcome.completions.single.complete(true);
      await t.pump();
      expect(t.takeException(), isNull);
      await finish(t, p);
    });
  }

  testWidgets('ordinary Home rebuilds never trigger a startup greeting',
      (t) async {
    final p = await mount(t, const HomeScreen());
    await t.runAsync(() => p.toggleVoice());
    await t.runAsync(() => p.toggleVoice());
    await t.pump();
    expect(welcome.requests, isEmpty);
    expect(audio.starts, isEmpty);
    await finish(t, p);
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(768, 1024),
    const Size(430, 932),
  ]) {
    for (final character in ['boy', 'girl']) {
      testWidgets(
          'long name fits an independent $character welcome card at $size',
          (t) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        t.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        SharedPreferences.setMockInitialValues({
          'sfx': false,
          'studentName': 'Alexandria Marie Isabella',
          'studentCharacter': character,
        });
        final p = await mount(
            t,
            Builder(
                builder: (context) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                        padding: const EdgeInsets.only(top: 24, bottom: 24)),
                    child: const HomeScreen(announceTitle: true))));
        await waitForVoice(t, () => welcome.requests.isNotEmpty);
        final card = find.byKey(const ValueKey('player-welcome-dialogue'));
        final content = find.descendant(
            of: card,
            matching: find.byKey(const ValueKey('home-greeting-content')));
        final text = find.descendant(of: card, matching: find.byType(Text));
        expect(text, findsOneWidget);
        expect(find.descendant(of: card, matching: find.byType(SceneDialogue)),
            findsNothing);
        final scene = t.widget<SchoolHomeScene>(find.byType(SchoolHomeScene));
        expect(scene.greeting, isA<HomeGreetingCard>());
        expect(scene.studentSpeech, isNull);
        expect(t.widget<Text>(text).textSpan!.toPlainText(),
            "Welcome back, ${p.studentName}!\nLet's learn and play!");
        final bounds = t.getRect(card);
        final student = t.getRect(find.byKey(const ValueKey('home-student')));
        final banner =
            t.getRect(find.byKey(const ValueKey('home-progress-banner')));
        expect(bounds.top, greaterThanOrEqualTo(banner.bottom + 7.9));
        expect(bounds.bottom, lessThanOrEqualTo(student.top - 11.9));
        expect(bounds.left, greaterThanOrEqualTo(11.9));
        expect(bounds.right, lessThanOrEqualTo(size.width - 11.9));
        expect(
            t.getRect(content).inflate(.5).contains(t.getTopLeft(text)), true);
        expect(t.getRect(content).inflate(.5).contains(t.getBottomRight(text)),
            true);
        expect(t.takeException(), isNull);
        await finish(t, p);
        welcome.completions.single.complete(false);
        await t.pump();
      });
    }
  }
}
