import 'package:flutter/material.dart';
import 'package:kidsphonics/data/game_session_order.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/letter_data.dart';
import 'package:kidsphonics/data/phonics_activity_data.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/models/learning_progress.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/home_screen.dart';
import 'package:kidsphonics/screens/lessons_screen.dart';
import 'package:kidsphonics/screens/letter_sounds_screen.dart';
import 'package:kidsphonics/screens/games_screen.dart';
import 'package:kidsphonics/screens/sound_match_screen.dart';
import 'package:kidsphonics/screens/phonics_quiz_screen.dart';
import 'package:kidsphonics/screens/missing_vowel_screen.dart';
import 'package:kidsphonics/screens/picture_word_match_screen.dart';
import 'package:kidsphonics/screens/sound_position_screen.dart';
import 'package:kidsphonics/screens/rhyming_words_screen.dart';
import 'package:kidsphonics/screens/word_builder_screen.dart';
import 'package:kidsphonics/screens/alphabet_order_screen.dart';
import 'package:kidsphonics/screens/memory_game_screen.dart';
import 'package:kidsphonics/screens/rumbled_words_screen.dart';
import 'package:kidsphonics/data/rumbled_words_data.dart';
import 'package:kidsphonics/screens/voice_recognition_screen.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/widgets/game_word_picture.dart';
import 'learning_progress_test.dart' show mockProgressAudio;

Future<AppProvider> mount(WidgetTester t, Widget page) async {
  late AppProvider p;
  await t.runAsync(() async {
    final prefs = await SharedPreferences.getInstance();
    for (final name in ['wordBuilder', 'memoryFlip', 'flappyLetters']) {
      await prefs.setBool('gameTutorialV1.$name', true);
    }
    p = AppProvider();
    await p.ready;
  });
  await t.pumpWidget(
      ChangeNotifierProvider.value(value: p, child: MaterialApp(home: page)));
  await t.pump();
  return p;
}

Future<void> close(WidgetTester t, AppProvider p) async {
  await t.pumpWidget(const SizedBox());
  await t.runAsync(() async {
    await Future<void>.delayed(Duration.zero);
  });
  p.dispose();
}

Future<void> choose(WidgetTester t, String label) async {
  final choice =
      find.byWidgetPredicate((w) => w is GameAnswerButton && w.label == label);
  expect(choice, findsOneWidget);
  await t.ensureVisible(choice);
  await t.pumpAndSettle();
  await t
      .tap(find.descendant(of: choice, matching: find.byType(ElevatedButton)));
  await t.pump();
  await t.runAsync(() async {
    await Future<void>.delayed(Duration.zero);
  });
}

Future<void> advance(WidgetTester t, {bool automatic = false}) async {
  await t.pump(const Duration(milliseconds: 1400));
  if (!automatic) {
    await t.ensureVisible(find.text('Next'));
    await t.tap(find.text('Next'));
  }
  await t.runAsync(() async {
    await Future<void>.delayed(Duration.zero);
  });
  await t.pumpAndSettle();
}

Future<void> flushWrites(WidgetTester t) async {
  final sessions = t
      .stateList<State>(find.byWidgetPredicate((w) => w is StatefulWidget))
      .whereType<GameSessionUi>()
      .toList();
  var saved = false;
  Future.wait(sessions.map((s) => s.rewardsSaved)).then((_) => saved = true);
  for (var i = 0; i < 100; i++) {
    await t.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await t.pump();
    final awaitingResult = sessions.any((s) => s.mounted && s.resultOpen) &&
        find.byType(GameResultDialog).evaluate().isEmpty;
    if (saved && !awaitingResult) break;
  }
  expect(saved, isTrue, reason: 'Reward persistence must finish');
  await t.pumpAndSettle();
}

Future<void> waitForWidget(WidgetTester t, Finder finder) async {
  for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
    await t.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await t.pump(const Duration(milliseconds: 16));
  }
  expect(finder, findsOneWidget);
  await t.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestWidgetsFlutterBinding
            .instance.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(TestWidgetsFlutterBinding
        .instance.platformDispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
  });

  testWidgets(
      'result displays supplied totals and guards repeated completion taps',
      (t) async {
    var again = 0;
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: GameResultDialog(
                correct: 3,
                attempts: 5,
                earnedXp: 47,
                earnedStars: 2,
                onAgain: () => again++,
                onBack: () {}))));
    expect(find.text('Score: 3 / 5'), findsOneWidget);
    expect(find.text('Activity Accuracy: 60%'), findsOneWidget);
    expect(find.text('XP Earned: +47'), findsOneWidget);
    expect(find.text('Stars Earned: +2'), findsOneWidget);
    final button = t.widget<ElevatedButton>(find.byType(ElevatedButton));
    button.onPressed!();
    button.onPressed!();
    await t.pump();
    expect(again, 1);
  });
  testWidgets('zero attempts and zero stars are displayed honestly', (t) async {
    await t.pumpWidget(MaterialApp(
        home: GameResultDialog(
            correct: 0,
            attempts: 0,
            earnedXp: 0,
            earnedStars: 0,
            onAgain: () {},
            onBack: () {})));
    expect(find.text('Activity Accuracy: No attempts yet'), findsOneWidget);
    expect(find.text('Stars Earned: +0'), findsOneWidget);
  });
  for (final scale in [1.0, 1.5]) {
    testWidgets('result actions stay visible on a small phone at text $scale',
        (t) async {
      t.view.physicalSize = const Size(320, 568);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!),
          home: GameResultDialog(
              correct: 4,
              attempts: 6,
              earnedXp: 30,
              earnedStars: 4,
              onAgain: () {},
              onBack: () {})));
      expect(t.takeException(), isNull);
      for (final label in ['Play Again', 'Choose Next Game']) {
        final finder = find.text(label);
        expect(finder.hitTestable(), findsOneWidget);
        expect(t.getRect(finder).bottom, lessThan(568));
      }
      if (scale == 1) {
        expect(
            t
                .getSize(find
                    .descendant(
                        of: find.byType(AlertDialog),
                        matching: find.byType(Material))
                    .first)
                .height,
            lessThanOrEqualTo(520));
      }
    });
  }
  testWidgets(
      'progress and all four learning status badges reflect supplied data',
      (t) async {
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Column(children: [
      const GameProgressHeader(current: 4, total: 10),
      for (final s in LearningStatus.values) LearningStatusBadge(status: s),
    ]))));
    expect(find.text('Question 4 of 10'), findsOneWidget);
    expect(
        t
            .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator))
            .value,
        .4);
    for (final label in ['Not Started', 'Viewed', 'Practiced', 'Mastered']) {
      expect(find.text(label), findsOneWidget);
    }
  });
  testWidgets('missing and disabled audio stay safe and cannot start playback',
      (t) async {
    final p = await mount(
        t,
        const LearnerPage(
            title: 'Audio',
            child: Column(children: [
              AudioButton(phrase: 'no-such-recording'),
              AudioButton(phrase: 'Cat', enabled: false),
            ])));
    expect(find.text('Audio unavailable.'), findsOneWidget);
    expect(find.text('Audio is turned off.'), findsOneWidget);
    expect(
        t
            .widgetList<OutlinedButton>(find.byType(OutlinedButton))
            .every((b) => b.onPressed == null),
        isTrue);
    expect(t.takeException(), isNull);
    await close(t, p);
  });
  testWidgets(
      'speech explains permission before any request and avoids pronunciation claims',
      (t) async {
    var permissions = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter.baseflow.com/permissions/methods'),
            (call) async {
      permissions++;
      return <int, int>{7: 0};
    });
    final p = await mount(t, const VoiceRecognitionScreen());
    expect(find.text('Speak & Recognize'), findsOneWidget);
    expect(
        find.text(
            'KidsPhonics uses the microphone only for Speak & Recognize.'),
        findsOneWidget);
    expect(find.text('Your voice is used to recognize the word you say.'),
        findsOneWidget);
    expect(find.textContaining('Pronunciation'), findsNothing);
    expect(permissions, 0);
    await t.ensureVisible(find.text('Start Listening'));
    await t.tap(find.text('Start Listening'));
    await t.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await t.pumpAndSettle();
    expect(permissions, 1);
    expect(
        find.textContaining('Microphone or speech recognition is unavailable.'),
        findsOneWidget);
    await close(t, p);
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(800, 1024)
  ]) {
    testWidgets(
        'all learner pages fit portrait $size and scroll to remaining controls',
        (t) async {
      await t.binding.setSurfaceSize(size);
      addTearDown(() => t.binding.setSurfaceSize(null));
      for (final page in <Widget>[
        const HomeScreen(),
        const LessonsScreen(),
        const LetterSoundsScreen(),
        const LetterSoundsScreen(vowelsOnly: true),
        const GamesScreen(),
        const RumbledWordsScreen(difficulty: Difficulty.hard),
        const SoundMatchScreen(difficulty: Difficulty.hard),
        const PhonicsQuizScreen(difficulty: Difficulty.hard),
        const MissingVowelScreen(difficulty: Difficulty.hard),
        const PictureWordMatchScreen(difficulty: Difficulty.hard),
        const SoundPositionScreen(difficulty: Difficulty.hard),
        const RhymingWordsScreen(difficulty: Difficulty.hard),
        const WordBuilderScreen(difficulty: Difficulty.hard),
        const AlphabetOrderScreen(difficulty: Difficulty.hard),
        const MemoryGameScreen(difficulty: Difficulty.hard),
        const VoiceRecognitionScreen(),
      ]) {
        final p = await mount(t, page);
        expect(t.takeException(), isNull,
            reason: '${page.runtimeType} initial $size');
        final scrolls = t.stateList<ScrollableState>(find.byType(Scrollable));
        for (final scroll in scrolls) {
          scroll.position.jumpTo(scroll.position.maxScrollExtent);
        }
        await t.pump();
        expect(t.takeException(), isNull,
            reason: '${page.runtimeType} scrolled $size');
        await close(t, p);
      }
    });
  }

  const d = Difficulty.medium;
  final cases = <(String, Widget, List<String>, int, int, bool)>[
    (
      'quiz',
      const PhonicsQuizScreen(difficulty: d),
      quizQuestionsForDifficulty(d)
          .map((q) => letterChoiceLabel(q.correctLetter))
          .toList(),
      5,
      20,
      false
    ),
    (
      'sound',
      const SoundMatchScreen(difficulty: d),
      soundRoundsForDifficulty(d)
          .map((q) => letterChoiceLabel(q.correctLetter))
          .toList(),
      5,
      10,
      true
    ),
    (
      'vowel',
      const MissingVowelScreen(difficulty: d),
      vowelPuzzlesFor(d).map((q) => q.vowel).toList(),
      8,
      15,
      false
    ),
    (
      'picture',
      const PictureWordMatchScreen(difficulty: d),
      pictureRoundsFor(d)
          .map((q) => 'Picture ${q.options.indexOf(q.correctEmoji) + 1}')
          .toList(),
      8,
      15,
      false
    ),
    (
      'position',
      const SoundPositionScreen(difficulty: d),
      positionRoundsFor(d).map((q) => q.correctPos.label).toList(),
      8,
      15,
      false
    ),
    (
      'rhyme',
      const RhymingWordsScreen(difficulty: d),
      rhymeRoundsForDifficulty(d).map((q) => q.correctRhyme).toList(),
      8,
      20,
      false
    ),
  ];
  for (final (name, page, answers, eachXp, bonus, automatic) in cases) {
    testWidgets(
        '$name actual rewards match result including rounded difficulty and bonus',
        (t) async {
      final p = await mount(t, page);
      final firstPhrase =
          t.widget<AudioButton>(find.byType(AudioButton).first).phrase;
      final roundCount =
          answers.length.clamp(0, GameSessionOrder.roundLength(d));
      for (var index = 0; index < roundCount; index++) {
        expect(t.widget<GameScaffold>(find.byType(GameScaffold)).answerResult,
            isNull);
        final phrase =
            t.widget<AudioButton>(find.byType(AudioButton).first).phrase;
        final word = phrase.toUpperCase();
        final answer = switch (name) {
          'quiz' => letterChoiceLabel(quizQuestionsForDifficulty(d)
              .firstWhere((q) => q.word.toUpperCase() == word)
              .correctLetter),
          'sound' => letterChoiceLabel(soundRoundsForDifficulty(d)
              .firstWhere((q) => q.word.toUpperCase() == word)
              .correctLetter),
          'vowel' => vowelPuzzlesFor(d).firstWhere((q) => q.word == word).vowel,
          'picture' => 'Picture 1',
          'position' => positionRoundsFor(d)
              .firstWhere(
                  (q) =>
                      q.word == word &&
                      find
                          .text('Where is ${q.soundDisplay} in ${q.word}?')
                          .evaluate()
                          .isNotEmpty,
                  orElse: () =>
                      positionRoundsFor(d).firstWhere((q) => q.word == word))
              .correctPos
              .label,
          'rhyme' => rhymeRoundsForDifficulty(d)
              .firstWhere((q) => find
                  .text('What rhymes with ${q.word}?')
                  .evaluate()
                  .isNotEmpty)
              .correctRhyme,
          _ => throw StateError(name),
        };
        await choose(t, answer);
        expect(t.widget<GameScaffold>(find.byType(GameScaffold)).answerResult,
            isTrue);
        await advance(t, automatic: automatic);
      }
      await flushWrites(t);
      final expectedXp = roundCount * (eachXp * d.xpMultiplier).round() +
          (bonus * d.xpMultiplier).round();
      expect(p.xp, expectedXp);
      expect(p.stars, roundCount);
      expect(find.text('XP Earned: +${p.xp}'), findsOneWidget);
      expect(find.text('Stars Earned: +${p.stars}'), findsOneWidget);
      expect(find.text('Score: $roundCount / $roundCount'), findsOneWidget);
      expect(p.dailyActivity.values.single.questionsAnswered, roundCount);
      await t.ensureVisible(find.text('Play Again'));
      await t.tap(find.text('Play Again'));
      await t.pumpAndSettle();
      expect(find.byType(GameResultDialog), findsNothing);
      expect(t.widget<AudioButton>(find.byType(AudioButton).first).phrase,
          isNot(firstPhrase));
      expect(p.xp, expectedXp);
      final session = t.state(find.byType(page.runtimeType)) as GameSessionUi;
      expect(session.earnedXp, 0);
      expect(session.earnedStars, 0);
      expect(session.scoredAttempts, 0);
      expect(session.resultOpen, isFalse);
      await close(t, p);
    });
  }
  testWidgets(
      'alphabet rapid taps score once and completion bonus is awarded once',
      (t) async {
    final p = await mount(t, const AlphabetOrderScreen());
    final first = t.widget<GameAnswerButton>(
        find.byWidgetPredicate((w) => w is GameAnswerButton && w.label == 'A'));
    first.onPressed!();
    first.onPressed!();
    await t.pump();
    await t.pump(const Duration(milliseconds: 800));
    await t.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await flushWrites(t);
    expect(p.xp, 3);
    expect(p.stars, 1);
    for (final letter in ['B', 'C', 'D', 'E', 'F']) {
      await choose(t, letter);
      await t.pump(const Duration(milliseconds: 800));
      await t.pump(const Duration(milliseconds: 600));
      await t.runAsync(() async {
        await Future<void>.delayed(Duration.zero);
      });
      await t.pumpAndSettle();
    }
    await flushWrites(t);
    expect(p.xp, 33);
    expect(p.stars, 6);
    expect(find.text('XP Earned: +33'), findsOneWidget);
    expect(p.dailyActivity.values.single.activitiesCompleted, 1);
    await close(t, p);
  });
  testWidgets(
      'word builder multi-blank rewards count completed words not blanks',
      (t) async {
    final p = await mount(t, const WordBuilderScreen(difficulty: d));
    final puzzles = wordPuzzlesForDifficulty(d);
    final roundCount = puzzles.length.clamp(0, GameSessionOrder.roundLength(d));
    var attempts = 0;
    for (var i = 0; i < roundCount; i++) {
      final word = t
          .widget<AudioButton>(find.byType(AudioButton).first)
          .phrase
          .toUpperCase();
      final puzzle = puzzles.firstWhere((q) => q.word == word);
      attempts += puzzle.correctLetters.length;
      for (final letter in puzzle.correctLetters) {
        await choose(t, letter);
        expect(
            t
                .widget<IconButton>(find.byWidgetPredicate(
                    (w) => w is IconButton && w.tooltip == 'How to Play'))
                .onPressed,
            isNull);
        await t.pump(const Duration(milliseconds: 1100));
        await t.runAsync(() async {
          await Future<void>.delayed(Duration.zero);
        });
        await t.pumpAndSettle();
      }
    }
    await flushWrites(t);
    expect(p.xp, roundCount * 15 + 23);
    expect(p.stars, roundCount);
    expect(find.text('XP Earned: +${p.xp}'), findsOneWidget);
    expect(find.text('Stars Earned: +${p.stars}'), findsOneWidget);

    expect(find.text('Score: $roundCount / $roundCount'), findsOneWidget);
    expect(t.widget<GameResultDialog>(find.byType(GameResultDialog)).attempts,
        attempts);
    await close(t, p);
  });
  testWidgets(
      'sound match wrong answers advance once and count against five questions',
      (t) async {
    final p =
        await mount(t, const SoundMatchScreen(difficulty: Difficulty.easy));
    final rounds = soundRoundsForDifficulty(Difficulty.easy);
    for (var i = 0; i < 5; i++) {
      final word = t.widget<AudioButton>(find.byType(AudioButton).first).phrase;
      final round =
          rounds.firstWhere((r) => r.word.toUpperCase() == word.toUpperCase());
      if (i < 2) {
        final wrong = round.options.firstWhere((v) => v != round.correctLetter);
        await choose(t, letterChoiceLabel(wrong));
        expect(find.text('Next question…'), findsOneWidget);
        expect(find.textContaining('Try again'), findsNothing);
      } else {
        await choose(t, letterChoiceLabel(round.correctLetter));
      }
      await advance(t, automatic: true);
    }
    await flushWrites(t);
    expect(find.text('Score: 3 / 5'), findsOneWidget);
    expect(find.text('Score: 5 / 7'), findsNothing);
    expect(find.text('Activity Accuracy: 60%'), findsOneWidget);
    expect(
        find.textContaining('Attempts: 5 • Wrong attempts: 2'), findsOneWidget);
    expect(p.xp, 25);
    expect(p.stars, 3);
    await t.ensureVisible(find.text('Play Again'));
    await t.tap(find.text('Play Again'));
    await t.pumpAndSettle();
    final session = t.state(find.byType(SoundMatchScreen)) as GameSessionUi;
    expect(session.scoredAttempts, 0);
    expect(session.correctGameItems, 0);
    expect(session.totalGameItems, 5);
    await close(t, p);
  });
  testWidgets('blocked game access and real lesson counts survive UI changes',
      (t) async {
    SharedPreferences.setMockInitialValues({'gameAccess': false});
    final p = await mount(t, const GamesScreen());
    expect(find.text('Games are turned off by a parent.'), findsOneWidget);
    expect(find.text('Sound Match'), findsNothing);
    await t.runAsync(() async {
      await p.markLetterViewed('B');
      await p.recordLetterPractice('A', true);
      await p.completeLetterAssessment('A', 4, 5);
    });
    await t.pumpWidget(ChangeNotifierProvider.value(
        value: p, child: const MaterialApp(home: LessonsScreen())));
    await t.pumpAndSettle();
    expect(find.text('1 / 26 Mastered'), findsOneWidget);
    expect(find.text('1 / 5 Mastered'), findsOneWidget);
    expect(find.text('In Progress'), findsNWidgets(2));
    await close(t, p);
  });
  testWidgets('navigation guards rapid opening and confirms only started games',
      (t) async {
    final p = await mount(
        t,
        Builder(
            builder: (ctx) => Scaffold(
                body: ElevatedButton(
                    onPressed: () => LearnerNavigation.open(ctx,
                        const PhonicsQuizScreen(difficulty: Difficulty.easy)),
                    child: const Text('Open game')))));
    var open = t.widget<ElevatedButton>(find.byType(ElevatedButton));
    open.onPressed!();
    open.onPressed!();
    await t.pumpAndSettle();
    expect(find.byType(PhonicsQuizScreen), findsOneWidget);
    await t.tap(find.byTooltip('Back'));
    await flushWrites(t);
    expect(find.text('Leave this game?'), findsNothing);
    await waitForWidget(t, find.text('Open game'));
    await t.tap(find.text('Open game'));
    await t.pumpAndSettle();
    final firstWord =
        t.widget<AudioButton>(find.byType(AudioButton).first).phrase;
    await choose(
        t,
        letterChoiceLabel(quizQuestionsForDifficulty(Difficulty.easy)
            .firstWhere((q) => q.word == firstWord)
            .correctLetter));
    await t.tap(find.byTooltip('Back'));
    await t.pumpAndSettle();
    expect(find.text('Leave this game?'), findsOneWidget);
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(find.byType(PhonicsQuizScreen), findsOneWidget);
    await t.tap(find.byTooltip('Back'));
    await t.pumpAndSettle();
    await t.tap(find.text('Leave'));
    await flushWrites(t);
    await waitForWidget(t, find.text('Open game'));
    expect(find.byType(PhonicsQuizScreen), findsNothing);
    await close(t, p);
  });
  testWidgets(
      'incorrect quiz answer counts once and result back returns to source',
      (t) async {
    final p = await mount(
        t,
        Builder(
            builder: (ctx) => Scaffold(
                body: ElevatedButton(
                    onPressed: () => LearnerNavigation.open(ctx,
                        const PhonicsQuizScreen(difficulty: Difficulty.easy)),
                    child: const Text('Open game')))));
    await t.tap(find.text('Open game'));
    await t.pumpAndSettle();
    final questions = quizQuestionsForDifficulty(Difficulty.easy);
    final roundCount = GameSessionOrder.roundLength(Difficulty.easy);
    for (var i = 0; i < roundCount; i++) {
      final word = t.widget<AudioButton>(find.byType(AudioButton).first).phrase;
      final q = questions.firstWhere((q) => q.word == word);
      final choice = i == 0
          ? q.options.firstWhere((x) => x != q.correctLetter)
          : q.correctLetter;
      await choose(t, letterChoiceLabel(choice));
      await advance(t);
    }
    await flushWrites(t);
    expect(find.text('Score: ${roundCount - 1} / $roundCount'), findsOneWidget);
    expect(p.xp, (roundCount - 1) * 5 + 20);
    expect(p.stars, roundCount - 1);
    final back = t.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Choose Next Game'));
    back.onPressed!();
    back.onPressed!();
    await t.pumpAndSettle();
    await waitForWidget(t, find.text('Open game'));
    expect(find.byType(PhonicsQuizScreen), findsNothing);
    await close(t, p);
  });
  for (final difficulty in Difficulty.values) {
    testWidgets('rumbled $difficulty hints reset and words award once',
        (t) async {
      await t.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final p = await mount(t, RumbledWordsScreen(difficulty: difficulty));
      final rounds = rumbledWordsFor(difficulty);
      final roundCount =
          rounds.length.clamp(0, GameSessionOrder.roundLength(difficulty));
      for (var roundIndex = 0; roundIndex < roundCount; roundIndex++) {
        final shownWord =
            t.widget<GameWordPicture>(find.byType(GameWordPicture).first).word;
        final round = rounds.firstWhere((w) => w.word == shownWord);
        final hint = find.byKey(const ValueKey('word-hint'));
        expect(t.widget<FilledButton>(hint).onPressed, isNotNull);
        await t.ensureVisible(hint);
        await t.tap(hint);
        await t.pump();
        expect(t.widget<FilledButton>(hint).onPressed, isNull);
        expect(find.text('Starts with ${round.word[0]}'), findsOneWidget);
        final word = round.word.toUpperCase();
        final letters = [
          for (var i = 0; i < word.length; i++)
            t
                .widget<Text>(find.descendant(
                    of: find.byKey(ValueKey('word-tile-$i')),
                    matching: find.byType(Text)))
                .data!
        ];
        expect(letters.join(), isNot(word));
        if (roundIndex == 0) {
          // A wrong arrangement must be editable without spending another hint.
          for (var i = 0; i < word.length; i++) {
            await t.ensureVisible(find.byKey(ValueKey('word-tile-$i')));
            await t.tap(find.byKey(ValueKey('word-tile-$i')));
            await t.pump();
          }
          await t.ensureVisible(find.text('Check'));
          await t.tap(find.text('Check'));
          await t.pump();
          expect(find.text('Try again! Tap Erase or a letter to change it.'),
              findsOneWidget);
          expect(t.widget<GameScaffold>(find.byType(GameScaffold)).answerResult,
              isFalse);
          for (var i = word.length - 1; i >= 0; i--) {
            final erase = find.byKey(const ValueKey('word-erase'));
            await t.ensureVisible(erase);
            await t.tap(erase);
            await t.pump();
            expect(
                t
                    .widget<ElevatedButton>(
                        find.byKey(ValueKey('word-tile-$i')))
                    .onPressed,
                isNotNull);
          }
          expect(
              t
                  .widget<OutlinedButton>(
                      find.byKey(const ValueKey('word-erase')))
                  .onPressed,
              isNull);
        }
        final used = <int>{};
        for (final letter in word.split('')) {
          final index = List.generate(letters.length, (i) => i)
              .firstWhere((i) => !used.contains(i) && letters[i] == letter);
          used.add(index);
          final tile = find.byKey(ValueKey('word-tile-$index'));
          await t.ensureVisible(tile);
          await t.tap(tile);
          await t.pump();
        }
        await t.ensureVisible(find.text('Check'));
        final check = t
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Check'))
            .onPressed!;
        check();
        check();
        await t.pump();
        expect(find.text('Correct!'), findsOneWidget);
        await t.ensureVisible(find.text('Next'));
        await t.tap(find.text('Next'));
        await t.pump();
        await flushWrites(t);
        expect(t.takeException(), isNull);
      }
      expect(p.stars, roundCount);
      expect(
          p.xp,
          roundCount * (8 * difficulty.xpMultiplier).round() +
              (15 * difficulty.xpMultiplier).round());
      expect(find.text('Score: $roundCount / $roundCount'), findsOneWidget);
      await t.ensureVisible(find.text('Play Again'));
      await t.pumpAndSettle();
      await t.tap(find.text('Play Again'));
      await t.pumpAndSettle();
      expect(
          t
              .widget<FilledButton>(find.byKey(const ValueKey('word-hint')))
              .onPressed,
          isNotNull);
      await close(t, p);
    });

    testWidgets('memory $difficulty fits all equal cards without scrolling',
        (t) async {
      await t.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final p = await mount(t, MemoryGameScreen(difficulty: difficulty));
      final count = memoryPairsForDifficulty(difficulty).length * 2;
      final first = t.getRect(find.byKey(const ValueKey('memory-0')));
      for (var i = 0; i < count; i++) {
        final rect = t.getRect(find.byKey(ValueKey('memory-$i')));
        expect(rect.size, first.size);
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(568));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(320));
      }
      for (final scroll
          in t.stateList<ScrollableState>(find.byType(Scrollable))) {
        expect(scroll.position.maxScrollExtent, closeTo(0, .01));
      }
      expect(find.text('Turn over'), findsNothing);
      await t.tap(find.byKey(const ValueKey('memory-0')));
      await t.pump();
      final picture = find.descendant(
          of: find.byKey(const ValueKey('memory-0')),
          matching: find.byType(GameWordPicture));
      expect(t.widget<GameWordPicture>(picture).word, isNotEmpty);
      expect(find.byType(GameImageCard), findsNothing);
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }

  testWidgets(
      'memory cards fit small phones and allow retries until every pair is matched',
      (t) async {
    await t.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final p =
        await mount(t, const MemoryGameScreen(difficulty: Difficulty.easy));
    final pairs = memoryPairsForDifficulty(Difficulty.easy).length;
    Finder card(int index) => find.byKey(ValueKey('memory-$index'));
    bool enabled(int index) =>
        t.widget<ElevatedButton>(card(index)).onPressed != null;
    Future<void> flip(int index) async {
      await t.ensureVisible(card(index));
      await t.pumpAndSettle();
      await t.tap(card(index));
      await t.pump();
    }

    var attempts = 0;
    bool ended() => find.byType(GameResultDialog).evaluate().isNotEmpty;
    for (var i = 0; i < pairs * 2; i++) {
      if (ended()) break;
      if (!enabled(i)) continue;
      for (var j = i + 1; j < pairs * 2; j++) {
        if (!enabled(j)) continue;
        await flip(i);
        await flip(j);
        attempts++;
        await t.pump(const Duration(milliseconds: 800));
        await t.pump(const Duration(milliseconds: 850));
        await t.pump(const Duration(milliseconds: 1600));
        await flushWrites(t);
        expect(t.takeException(), isNull);
        if (ended() || !enabled(i)) {
          break;
        }
      }
    }
    expect(find.byType(GameLives), findsNothing);
    expect(p.xp, pairs * 5 + 10);
    expect(p.stars, pairs);
    expect(find.text('XP Earned: +${p.xp}'), findsOneWidget);
    expect(find.text('Score: $pairs / $pairs'), findsOneWidget);
    expect(t.widget<GameResultDialog>(find.byType(GameResultDialog)).attempts,
        attempts);
    await close(t, p);
  });
}
