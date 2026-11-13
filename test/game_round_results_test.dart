import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'save_recovery_test.dart' show FailingStore;
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/widgets/game_difficulty_dialog.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

class _RoundHarness extends StatefulWidget {
  const _RoundHarness({super.key});
  @override
  State<_RoundHarness> createState() => _RoundHarnessState();
}

class _RoundHarnessState extends State<_RoundHarness>
    with GameSessionUi<_RoundHarness> {
  @override
  String get gameTitle => 'Phonics Quiz';
  @override
  Difficulty get roundDifficulty => Difficulty.easy;
  @override
  int get totalGameItems => 5;
  @override
  Widget gameForDifficulty(Difficulty difficulty) =>
      Scaffold(body: Text('New ${difficulty.label} round'));
  void answer(int id, bool correct) {
    if (recordGameAnswer(
            correct: correct,
            itemId: 'item-$id',
            prompt: 'Beginning sound',
            selected: correct ? 'H' : 'Z',
            expected: 'H',
            word: 'HAT',
            highlightedIndex: 0) &&
        correct) {
      awardGameXp(5);
    }
  }

  void finish() {
    if (resultOpen) return;
    setState(() => resultOpen = true);
    unawaited(showGameResult(() => setState(() {}),
        reviewCount: 1, onReview: () => setState(() => resultOpen = false)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      body: Center(
          child: TextButton(
              onPressed: finish, child: const Text('Finish round'))));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Nunito');
    for (final weight in ['Regular', 'Bold', 'ExtraBold', 'Black']) {
      font.addFont(rootBundle.load('assets/fonts/Nunito-$weight.ttf'));
    }
    await font.load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
    mockProgressAudio();
    TestWidgetsFlutterBinding
            .instance.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(TestWidgetsFlutterBinding
        .instance.platformDispatcher.clearAccessibilityFeaturesTestValue);
  });
  Future<void> flush(WidgetTester t) async {
    for (var i = 0; i < 20; i++) {
      await t.pump();
      await t.runAsync(() => Future<void>.delayed(Duration.zero));
    }
    await t.pumpAndSettle();
  }

  test('rating is based on original score with exact integer thresholds', () {
    for (final total in [1, 2, 5, 8, 10, 13, 26]) {
      for (var score = 0; score <= total; score++) {
        final expected = score == total
            ? 3
            : score * 100 >= total * 60
                ? 2
                : 1;
        expect(gameRoundStars(correct: score, total: total, completed: true),
            expected);
        expect(
            gameRoundStars(correct: score, total: total, completed: false), 0);
      }
    }
    expect(gameRoundStars(correct: 0, total: 0, completed: true), 0);
  });
  for (final score in [0, 2, 3, 4, 5]) {
    testWidgets('$score/5 saves one final rating and review cannot improve it',
        (t) async {
      final key = GlobalKey<_RoundHarnessState>();
      final p = await mount(t, _RoundHarness(key: key));
      for (var i = 0; i < 5; i++) {
        key.currentState!.answer(i, i < score);
      }
      key.currentState!
          .answer(0, true); // A second answer never replaces the first.
      await flush(t);
      expect(p.stars, 0, reason: 'No per-answer stars before completion');
      expect(key.currentState!.scoredAttempts, 5);
      key.currentState!.finish();
      key.currentState!.finish();
      await flush(t);
      final stars = score == 5
          ? 3
          : score >= 3
              ? 2
              : 1;
      final result = t.widget<GameResultDialog>(find.byType(GameResultDialog));
      expect((result.correctItems, result.totalItems, result.earnedStars),
          (score, 5, stars));
      expect(p.stars, stars);
      expect(p.xp, score * 5);
      expect(result.answers, hasLength(5));
      if (score < 5) {
        expect(find.text('Your answer: Z'), findsWidgets);
        expect(find.text('Correct answer: H'), findsWidgets);
      }
      await t.ensureVisible(find.byKey(const ValueKey('quiz-review-mistakes')));
      await t.tap(find.byKey(const ValueKey('quiz-review-mistakes')));
      await flush(t);
      key.currentState!.finish();
      await flush(t);
      expect(p.stars, stars);
      expect(p.xp, score * 5);
      expect(key.currentState!.scoredAttempts, 5);
      expect(p.dailyActivity.values.single.questionsAnswered, 5);
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }

  testWidgets(
      'difficulty can be cancelled and selected without replaying rewards',
      (t) async {
    final key = GlobalKey<_RoundHarnessState>();
    final p = await mount(t, _RoundHarness(key: key));
    for (var i = 0; i < 5; i++) {
      key.currentState!.answer(i, true);
    }
    key.currentState!.finish();
    await flush(t);
    await t.tap(find.byKey(const ValueKey('result-change-difficulty')));
    await t.pumpAndSettle();
    expect(find.byType(GameDifficultyDialog), findsOneWidget);
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(find.byType(GameResultDialog), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('result-change-difficulty')));
    await t.pumpAndSettle();
    await t.tap(find.text('Hard'));
    await t.pumpAndSettle();
    expect(find.text('New Hard round'), findsOneWidget);
    expect(p.stars, 3);
    expect(t.takeException(), isNull);
    await close(t, p);
  });

  testWidgets('failed reward writes can retry without awarding the round twice',
      (t) async {
    final store = FailingStore();
    SharedPreferencesStorePlatform.instance = store;
    final key = GlobalKey<_RoundHarnessState>();
    final p = await mount(t, _RoundHarness(key: key));
    for (var i = 0; i < 5; i++) {
      key.currentState!.answer(i, true);
    }
    await flush(t);
    store
      ..failKey = 'appStateV1'
      ..failures = 99;
    key.currentState!.finish();
    await flush(t);
    expect(p.stars, 3);
    expect(p.hasUnsavedChanges, isTrue);
    final retry = find.byKey(const ValueKey('result-retry-save'));
    await t.ensureVisible(retry);
    await t.pumpAndSettle();
    expect(retry, findsOneWidget);
    store.failures = 0;
    await t.tap(retry);
    await flush(t);
    expect(p.hasUnsavedChanges, isFalse);
    expect(p.stars, 3);
    expect(p.xp, 25);
    expect(find.byKey(const ValueKey('result-retry-save')), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    await t.runAsync(prefs.reload);
    expect(prefs.getInt('stars'), 3);
    await close(t, p);
  });

  const answers = [
    GameRoundAnswer(
        id: 'q1',
        prompt: 'Beginning sound',
        selected: 'H',
        expected: 'H',
        correct: true),
    GameRoundAnswer(
        id: 'q2',
        prompt: 'Ending sound',
        selected: 'T',
        expected: 'T',
        correct: true),
    GameRoundAnswer(
        id: 'q3',
        prompt: 'Beginning sound',
        selected: 'Z',
        expected: 'H',
        correct: false,
        word: 'HAT',
        highlightedIndex: 0),
    GameRoundAnswer(
        id: 'q4',
        prompt: 'Middle sound',
        selected: 'A',
        expected: 'A',
        correct: true),
    GameRoundAnswer(
        id: 'q5',
        prompt: 'Ending sound',
        selected: 'T',
        expected: 'T',
        correct: true),
  ];
  for (final view in [
    (size: const Size(390, 844), scale: 1.0),
    (size: const Size(320, 568), scale: 1.0),
    (size: const Size(320, 568), scale: 2.0),
    (size: const Size(800, 1024), scale: 1.0),
    (size: const Size(844, 390), scale: 1.0)
  ]) {
    testWidgets('approved result frame fits ${view.size} at ${view.scale}',
        (t) async {
      await t.binding.setSurfaceSize(view.size);
      addTearDown(() => t.binding.setSurfaceSize(null));
      const key = ValueKey('result-preview');
      await t.pumpWidget(MaterialApp(
          home: MediaQuery(
        data: MediaQueryData(
            size: view.size,
            textScaler: TextScaler.linear(view.scale),
            disableAnimations: true),
        child: RepaintBoundary(
            key: key,
            child: Scaffold(
                backgroundColor: const Color(0xFFFFD79A),
                body: GameResultDialog(
                    title: 'Phonics Quiz',
                    correct: 4,
                    attempts: 5,
                    totalItems: 5,
                    earnedXp: 20,
                    earnedStars: 2,
                    answers: answers,
                    onAgain: () {},
                    onBack: () {},
                    onDifficultySelected: (_) {}))),
      )));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      for (final name in [
        'result-play-again',
        'result-change-difficulty',
        'result-back'
      ]) {
        expect(find.byKey(ValueKey(name)).hitTestable(), findsOneWidget);
        final rect = t.getRect(find.byKey(ValueKey(name)));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(view.size.width));
        expect(rect.bottom, lessThanOrEqualTo(view.size.height));
      }
      if (view.size.width == 390 && view.scale == 1) {
        final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(key));
        await t.runAsync(() async {
          final snapshot = await boundary.toImage(pixelRatio: 2);
          final bytes =
              await snapshot.toByteData(format: ui.ImageByteFormat.png);
          final dir = Directory('output/game_results_preview');
          await dir.create(recursive: true);
          await File('${dir.path}/approved-result.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          snapshot.dispose();
        });
      }
    });
  }
}
