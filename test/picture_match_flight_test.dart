import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/screens/picture_word_match_screen.dart';
import 'package:kidsphonics/widgets/game_word_picture.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close, flushWrites;

void main() {
  for (final reduced in [false, true]) {
    testWidgets('correct picture lands and resets; reduced motion $reduced',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      mockProgressAudio();
      SharedPreferences.setMockInitialValues({});
      tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: reduced);
      addTearDown(tester
          .binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
      late AppProvider p;
      await tester.runAsync(() async {
        p = AppProvider();
        await p.ready;
      });
      await tester.pumpWidget(ChangeNotifierProvider.value(
          value: p,
          child: const MaterialApp(
              home: PictureWordMatchScreen(difficulty: Difficulty.hard))));
      await tester.pump();
      expect(find.byType(Scrollable), findsNothing);
      for (final choice in tester
          .widgetList<GameAnswerButton>(find.byType(GameAnswerButton))) {
        final rect = tester.getRect(find.byWidgetPredicate(
            (w) => w is GameAnswerButton && w.label == choice.label));
        expect(rect.bottom, lessThanOrEqualTo(568));
        expect(rect.width, lessThanOrEqualTo(100));
      }
      final pictures = tester
          .widgetList<GameWordPicture>(find.byType(GameWordPicture))
          .toList();
      final correct = pictures.singleWhere(
          (pic) => find.text(pic.word.toUpperCase()).evaluate().isNotEmpty);
      final wrong = pictures.firstWhere((pic) => pic.word != correct.word);
      Finder buttonFor(String word) => find.ancestor(
          of: find
              .byWidgetPredicate((w) => w is GameWordPicture && w.word == word),
          matching: find.byType(GameAnswerButton));
      await tester.ensureVisible(buttonFor(wrong.word));
      await tester.tap(find.descendant(
          of: buttonFor(wrong.word), matching: find.byType(ElevatedButton)));
      await tester.pump(const Duration(milliseconds: 950));
      expect(find.byKey(const ValueKey('matched-picture')), findsNothing);
      expect(find.byKey(const ValueKey('flying-match-picture')), findsNothing);
      await tester.ensureVisible(buttonFor(correct.word));
      await tester.tap(find.descendant(
          of: buttonFor(correct.word), matching: find.byType(ElevatedButton)));
      await tester.pump();
      if (!reduced) {
        expect(
            find.byKey(const ValueKey('flying-match-picture')), findsOneWidget);
      }
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump();
      expect(find.byKey(const ValueKey('flying-match-picture')), findsNothing);
      expect(
          tester
              .widget<GameWordPicture>(
                  find.byKey(const ValueKey('matched-picture')))
              .word
              .toUpperCase(),
          correct.word.toUpperCase());
      expect(find.text('Correct match!'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
      expect(tester.takeException(), isNull);
      if (!reduced) {
        await tester.pump(const Duration(milliseconds: 1100));
        expect(find.text('Correct match!'), findsOneWidget);
      }
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(find.byKey(const ValueKey('matched-picture')), findsNothing);
      expect(find.text('Your picture goes here'), findsOneWidget);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpWidget(const SizedBox());
      p.dispose();
    });
  }

  for (final interruption in ['background', 'dialog', 'access', 'ticker']) {
    testWidgets('automatic next waits during $interruption and scores once',
        (t) async {
      mockProgressAudio();
      SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
      final active = ValueNotifier(true);
      addTearDown(active.dispose);
      final p = await mount(
          t,
          MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: ValueListenableBuilder<bool>(
                  valueListenable: active,
                  child: const PictureWordMatchScreen(),
                  builder: (_, enabled, child) =>
                      TickerMode(enabled: enabled, child: child!))));
      final scaffold = find.byType(GameScaffold);
      final context = t.element(scaffold);
      Future<void> toggleAccess() async {
        var saved = false;
        p.toggleGameAccess().then((_) => saved = true);
        // Drain the fake clock as well as the real preference mock callbacks.
        for (var i = 0; i < 100 && !saved; i++) {
          await t.pump();
          await t.runAsync(() => Future<void>.delayed(Duration.zero));
        }
        expect(saved, isTrue);
      }
      final correct = t.widget<GameAnswerButton>(find.byWidgetPredicate(
          (w) => w is GameAnswerButton && w.label == 'Picture 1'));
      correct.onPressed!();
      correct.onPressed!();
      await t.pump();
      expect(find.text('Correct match!'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
      await flushWrites(t);
      if (interruption == 'background') {
        addTearDown(() => t.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed));
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      } else if (interruption == 'dialog') {
        showDialog<void>(
            context: context,
            builder: (_) => const AlertDialog(title: Text('Covered')));
      } else if (interruption == 'access') {
        await t.runAsync(() => p.parentAuth.setup('2580', '2580'));
        await toggleAccess();
      } else {
        active.value = false;
      }
      await t.pump();
      await t.pump(const Duration(seconds: 3));
      expect(
          t
              .widget<GameScaffold>(
                  find.byType(GameScaffold, skipOffstage: false))
              .current,
          1);
      if (interruption == 'background') {
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      } else if (interruption == 'dialog') {
        Navigator.of(context).pop();
      } else if (interruption == 'access') {
        await toggleAccess();
      } else {
        active.value = true;
      }
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(t.widget<GameScaffold>(scaffold).current, 2);
      expect(find.byKey(const ValueKey('matched-picture')), findsNothing);
      await flushWrites(t);
      expect(p.stars, 1);
      expect(p.xp, 8);
      expect(p.dailyActivity.values.single.questionsAnswered, 1);
      await close(t, p);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('leaving during correct feedback cancels automatic next',
      (t) async {
    mockProgressAudio();
    SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
    final p = await mount(
        t,
        const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: PictureWordMatchScreen()));
    t
        .widget<GameAnswerButton>(find.byWidgetPredicate(
            (w) => w is GameAnswerButton && w.label == 'Picture 1'))
        .onPressed!();
    await t.pump();
    expect(find.text('Correct match!'), findsOneWidget);
    await flushWrites(t);
    await close(t, p);
    await t.pump(const Duration(seconds: 3));
    expect(find.byType(GameResultDialog), findsNothing);
    expect(t.takeException(), isNull);
  });
}
