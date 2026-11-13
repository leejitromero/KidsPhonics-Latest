import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/game_session_order.dart';
import 'package:kidsphonics/data/phonics_activity_data.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/screens/word_builder_screen.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/widgets/word_builder_choice_frame.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

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
  });

  Future<void> capture(WidgetTester t, String name) async {
    for (var i = 0; i < 8; i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
      await t.pump();
    }
    final boundary = t.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('builder-preview')));
    await t.runAsync(() async {
      final picture = await boundary.toImage(pixelRatio: 1);
      final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
      final folder = Directory('build/word_builder_frame')
        ..createSync(recursive: true);
      await File('${folder.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      picture.dispose();
    });
  }

  for (final difficulty in Difficulty.values) {
    for (final view in [
      (size: const Size(320, 568), scale: 1.0),
      (size: const Size(390, 844), scale: 1.0),
      (size: const Size(320, 568), scale: 2.0),
    ]) {
      testWidgets(
          '$difficulty framed choices fit ${view.size} at text ${view.scale}',
          (t) async {
        await t.binding.setSurfaceSize(view.size);
        addTearDown(() => t.binding.setSurfaceSize(null));
        final p = await mount(
            t,
            MediaQuery(
              data: MediaQueryData(
                  size: view.size, textScaler: TextScaler.linear(view.scale)),
              child: RepaintBoundary(
                  key: const ValueKey('builder-preview'),
                  child: WordBuilderScreen(difficulty: difficulty)),
            ));
        final frame = t.getRect(find.byType(WordBuilderChoiceFrame));
        expect(frame.left, greaterThanOrEqualTo(0));
        expect(frame.right, lessThanOrEqualTo(view.size.width));
        expect(frame.bottom, lessThanOrEqualTo(view.size.height));
        final choices =
            t.widgetList<GameAnswerButton>(find.byType(GameAnswerButton));
        expect(choices, hasLength(difficulty.index + 3));
        for (final choice in choices) {
          final rect = t.getRect(find.byKey(choice.buttonKey!));
          expect(frame.contains(rect.topLeft), isTrue);
          expect(frame.contains(rect.bottomRight), isTrue);
        }
        expect(find.byType(Scrollable), findsNothing);
        expect(t.takeException(), isNull);
        if (view.size.width == 390) {
          await capture(t, '${difficulty.name}-choices');
        }
        await close(t, p);
      });
    }
  }

  testWidgets(
      'repeated letters consume individual tiles and score only after all blanks',
      (t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final pool = wordPuzzlesForDifficulty(Difficulty.hard);
    final task = pool.singleWhere((puzzle) => puzzle.word == 'SPOON');
    final ids = pool.map((puzzle) => puzzle.word).toList();
    SharedPreferences.setMockInitialValues({
      'voice': false,
      'sfx': false,
      GameSessionHistory.storageKey: jsonEncode({
        'version': 1,
        'games': {
          'word_builder-hard': {
            'pool': ids,
            'remaining': [task.word, ...ids.where((id) => id != task.word)],
            'first': null,
            'last': null,
          },
        },
      }),
    });
    final p = await mount(
        t,
        const RepaintBoundary(
            key: ValueKey('builder-preview'),
            child: WordBuilderScreen(difficulty: Difficulty.hard)));
    final state = t.state<GameSessionUi>(find.byType(WordBuilderScreen));
    expect(task.correctLetters, ['P', 'O', 'O']);
    for (var index = 0; index < task.correctLetters.length; index++) {
      final letter = task.correctLetters[index];
      final available = find
          .byWidgetPredicate((w) => w is GameAnswerButton && w.label == letter)
          .first;
      final button = t.widget<GameAnswerButton>(available);
      final originalKey = button.buttonKey!;
      final stale = button.onPressed!;
      await t.tap(find.byKey(originalKey));
      await t.pump();
      expect(find.byKey(originalKey), findsNothing);
      expect(find.byType(WordBuilderEmptyPlace), findsNWidgets(index + 1));
      expect(
          find.byKey(const ValueKey('flying-builder-letter')), findsOneWidget);
      await t.pump(const Duration(milliseconds: 560));
      final blank = find.descendant(
          of: find.byKey(ValueKey('builder-blank-$index')),
          matching: find.byType(Text));
      expect(t.widget<Text>(blank).data, letter);
      expect(find.byType(GameAnswerButton), findsNWidgets(4 - index));
      if (index == 0) {
        stale();
        await t.pump();
        expect(find.byType(GameAnswerButton), findsNWidgets(4));
        expect(state.scoredAttempts, 0);
        await capture(t, 'hard-after-tile');
      }
      if (index == 1) {
        expect(
            find.byWidgetPredicate(
                (w) => w is GameAnswerButton && w.label == 'O'),
            findsOneWidget);
        expect(state.scoredAttempts, 0);
      }
    }
    expect((state.scoredAttempts, state.correctAttempts), (1, 1));
    expect(p.stars, 0);
    expect(t.takeException(), isNull);
    await close(t, p);
  });
}
