import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/letter_data.dart';
import 'package:kidsphonics/models/letter_adventure.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/letter_mastery_check_screen.dart';
import 'package:kidsphonics/services/mastery_audio_service.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';
import 'learning_progress_test.dart' show mockProgressAudio;

class AdventureTestAudio implements MasteryAudio {
  AdventureTestAudio({this.autoNarration = true});
  final bool autoNarration;
  Completer<bool>? pending;
  final keys = <String>[];
  @override
  Future<bool> play(String key) {
    keys.add(key);
    if (autoNarration && key.startsWith('adventure-')) {
      return Future.value(true);
    }
    pending = Completer<bool>();
    return pending!.future;
  }

  @override
  Future<void> stop() async {
    if (pending != null && !pending!.isCompleted) pending!.complete(false);
    pending = null;
  }

  @override
  Future<void> dispose() => stop();
}

Future<void> flushAdventure(WidgetTester t) async {
  for (var i = 0; i < 5; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await t.pump();
  }
}

Future<void> press(WidgetTester t, Finder finder) async {
  await t.ensureVisible(finder);
  await t.pump();
  await t.tap(finder);
  await flushAdventure(t);
}

Future<void> hear(WidgetTester t, AdventureTestAudio audio, String key,
    {bool success = true}) async {
  await press(t, find.byKey(ValueKey('listen-$key')));
  expect(audio.pending, isNotNull);
  audio.pending!.complete(success);
  await flushAdventure(t);
}

Future<AppProvider> openAdventure(WidgetTester t, AdventureTestAudio audio,
    {String letter = 'B'}) async {
  late AppProvider p;
  await t.runAsync(() async {
    p = AppProvider();
    await p.ready;
  });
  await t.pumpWidget(ChangeNotifierProvider.value(
      value: p,
      child: MaterialApp(
          home: LetterMasteryCheckScreen(
              letter: letterContent(letter), audio: audio))));
  await t.pump();
  return p;
}

Future<void> finishHunt(WidgetTester t, String letter) async {
  final targets = <int>[];
  for (var i = 0; i < 12; i++) {
    final button = t.widget<FilledButton>(find.byKey(ValueKey('hunt-$i')));
    if ((button.child! as Text).data!.toUpperCase() == letter) targets.add(i);
  }
  expect(targets, hasLength(4));
  for (final i in targets) {
    await press(t, find.byKey(ValueKey('hunt-$i')));
  }
  await press(t, find.text('See Result'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
    TestWidgetsFlutterBinding
            .instance.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(TestWidgetsFlutterBinding
        .instance.platformDispatcher.clearAccessibilityFeaturesTestValue);
  });
  test(
      'A-Z content has real word/sound/image assets, valid blanks and unique options',
      () {
    expect(adventureContents.map((c) => c.letter).toSet(), hasLength(26));
    for (final c in adventureContents) {
      expect(c.maskedWord.replaceFirst('_', c.letter), c.word.toUpperCase());
      for (final word in [c.word, c.pictureWord]) {
        if (word != 'Zebra') {
          expect(adventurePicture(word), isNot(contains('lesson_frames/')),
              reason: '$word artwork must not reveal a printed target letter');
        }
      }
      for (var seed = 0; seed < 20; seed++) {
        final s = AdventureSession(c.letter, random: Random(seed));
        for (final choices in [
          s.matchOptions,
          s.soundOptions,
          s.spellingOptions,
          s.pictureOptions
        ]) {
          expect(choices, hasLength(4));
          expect(choices.toSet(), hasLength(4));
        }
        expect(s.huntLetters.where((l) => l.toUpperCase() == c.letter),
            hasLength(4));
        expect(s.huntLetters, hasLength(12));
        if (['C', 'K'].contains(c.letter)) {
          expect(s.soundOptions.where((l) => ['C', 'K', 'Q'].contains(l)),
              [c.letter]);
        }
        for (final word in [c.word, ...s.pictureOptions]) {
          expect(word.toLowerCase(), isNot('umbrella'));
          expect(File(adventurePicture(word)).existsSync(), isTrue,
              reason: word);
          final path =
              PhonicsAudioService.assetForPhrase(adventureWordKey(word));
          expect(path, isNotNull, reason: word);
          expect(File('assets/$path').existsSync(), isTrue, reason: word);
        }
        for (final sound in s.soundOptions) {
          expect(
              File('assets/${PhonicsAudioService.assetForPhrase('lesson-sound-$sound')}')
                  .existsSync(),
              isTrue);
        }
      }
    }
  });
  test('all scoring combinations enforce both essential sound skills', () {
    for (var mask = 0; mask < 32; mask++) {
      final answers = List.generate(5, (i) => (mask & (1 << i)) != 0);
      expect(AdventurePolicy.passes(answers),
          answers.where((v) => v).length >= 4 && answers[1] && answers[3]);
    }
    final session = AdventureSession('A');
    expect(session.submit(AdventureSkill.sound, false), isTrue);
    expect(session.submit(AdventureSkill.sound, true), isFalse);
    final wrong = session.huntLetters.indexWhere((l) => l.toUpperCase() != 'A');
    session.hunt(wrong);
    for (var i = 0; i < 12; i++) {
      if (session.huntLetters[i].toUpperCase() == 'A') session.hunt(i);
    }
    expect(session.firstAnswers[4], isFalse);
    expect(session.hunted, hasLength(4));
  });
  test(
      'new progress persists separately, essential failure does not pass, rewards never duplicate',
      () async {
    final p = AppProvider();
    await p.ready;
    await p.completeLetterAssessment('B', 5, 5);
    expect(p.recommendedAdventureLetter, 'A');
    final failed =
        await p.completeAdventure('A', [true, false, true, true, true], 'a1');
    expect(failed.xp, 5);
    expect(p.overallMasteredCount, 0);
    final pass =
        await p.completeAdventure('A', [true, true, true, true, false], 'a2');
    expect(pass.xp, 25);
    expect(pass.stars, 1);
    expect(p.recommendedAdventureLetter, 'B');
    final duplicate =
        await p.completeAdventure('A', [true, true, true, true, false], 'a2');
    expect(duplicate.xp, 0);
    expect(p.adventureProgress('A').completed, 2);
    await p.completeAdventure('A', List.filled(5, false), 'a3');
    expect(p.adventureProgress('A').mastered, isTrue);
    expect(p.xp, 30);
    expect(p.stars, 1);
    expect(p.masteredLetters, {'B'});
    final reloaded = AppProvider();
    await reloaded.ready;
    expect(reloaded.adventureProgress('A').lastScore, 0);
    expect(reloaded.overallMasteredCount, 1);
    expect(reloaded.masteredLetters, {'B'});
    expect(reloaded.dailyActivity.values.single.questionsAnswered, 15);
    reloaded.dispose();
    p.dispose();
  });
  testWidgets('Zebra spelling uses an illustration without a printed Z hint',
      (t) async {
    final audio = AdventureTestAudio();
    final p = await openAdventure(t, audio, letter: 'Z');
    await press(t, find.byKey(const ValueKey('start-adventure')));
    await press(t, find.byKey(const ValueKey('adventure-option-z')));
    await press(t, find.text('Next Challenge'));
    await hear(t, audio, 'lesson-sound-Z');
    await press(t, find.byKey(const ValueKey('adventure-option-Z')));
    await press(t, find.text('Next Challenge'));
    expect(find.text('🦓'), findsOneWidget);
    expect(find.text('_EBRA'), findsOneWidget);
    expect(
        t.widgetList<Image>(find.byType(Image)).any((image) =>
            image.image is AssetImage &&
            (image.image as AssetImage).assetName.contains('zebra_Z')),
        isFalse);
    await t.pumpWidget(const SizedBox());
    p.dispose();
  });
  testWidgets(
      'sound preview does not submit; interrupted audio cannot unlock a choice',
      (t) async {
    final audio = AdventureTestAudio();
    final p = await openAdventure(t, audio);
    await press(t, find.byKey(const ValueKey('start-adventure')));
    await press(t, find.byKey(const ValueKey('adventure-option-b')));
    await press(t, find.text('Next Challenge'));
    ElevatedButton choice() => t.widget<ElevatedButton>(
        find.byKey(const ValueKey('adventure-option-B')));
    expect(choice().onPressed, isNull);
    await hear(t, audio, 'lesson-sound-B', success: false);
    expect(choice().onPressed, isNull);
    await press(t, find.byKey(const ValueKey('listen-lesson-sound-B')));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await flushAdventure(t);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await flushAdventure(t);
    expect(choice().onPressed, isNull);
    await hear(t, audio, 'lesson-sound-B');
    expect(choice().onPressed, isNotNull);
    expect(find.text('Next Challenge'), findsNothing);
    expect(p.dailyActivity, isEmpty);
    await t.pumpWidget(const SizedBox());
    p.dispose();
    expect(t.takeException(), isNull);
  });
  for (final width in [320.0, 390.0, 800.0]) {
    testWidgets(
        'five activities, drag alternative and guided review fit width $width',
        (t) async {
      await t.binding.setSurfaceSize(Size(width, width == 320 ? 568 : 900));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final audio = AdventureTestAudio();
      final p = await openAdventure(t, audio);
      await press(t, find.byKey(const ValueKey('start-adventure')));
      // Wrong first response stays scored even after guided practice.
      final wrong = t
          .widgetList<ElevatedButton>(find.byType(ElevatedButton))
          .firstWhere((b) =>
              b.key is ValueKey<String> &&
              (b.key as ValueKey<String>)
                  .value
                  .startsWith('adventure-option-') &&
              b.key != const ValueKey('adventure-option-b'));
      await press(t, find.byKey(wrong.key!));
      await press(t, find.text('Next Challenge'));
      await hear(t, audio, 'lesson-sound-B');
      await press(t, find.byKey(const ValueKey('adventure-option-B')));
      await press(t, find.text('Next Challenge'));
      await hear(t, audio, adventureWordKey('Bag'));
      await press(t, find.byKey(const ValueKey('adventure-option-B')));
      await press(t, find.text('Next Challenge'));
      await hear(t, audio, 'lesson-sound-B');
      await hear(t, audio, adventureWordKey('Bag'));
      expect(find.text('Next Challenge'), findsNothing);
      await press(t, find.byKey(const ValueKey('adventure-option-Bag')));
      await press(t, find.text('Next Challenge'));
      await finishHunt(t, 'B');
      expect(find.text('Score: 4 / 5'), findsOneWidget);
      expect(p.adventureProgress('B').mastered, isTrue);
      expect(p.xp, 30);
      expect(p.stars, 1);
      await press(t, find.text('Practice these skills'));
      // Drag-and-drop is equivalent to tapping the lowercase option.
      final from = find.byKey(const ValueKey('adventure-option-b'));
      final to = find.byKey(const ValueKey('lowercase-drop'));
      await t.ensureVisible(from);
      await t.pump();
      await t.drag(from, t.getCenter(to) - t.getCenter(from));
      await flushAdventure(t);
      expect(find.text('Nice work!'), findsOneWidget);
      await press(t, find.text('Continue'));
      expect(find.text('Score: 4 / 5'), findsOneWidget);
      expect(p.adventureProgress('B').completed, 1);
      expect(p.dailyActivity.values.single.questionsAnswered, 5);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      p.dispose();
    });
  }
}
