import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/adventure_narration.dart';
import 'package:kidsphonics/models/letter_adventure.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';
import 'letter_mastery_check_test.dart'
    show AdventureTestAudio, openAdventure, press, hear, flushAdventure;
import 'learning_progress_test.dart' show mockProgressAudio;

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
      'all eleven actual recordings resolve, with normalized beginning/end filenames',
      () async {
    expect(adventureNarrationAssets.keys.toSet(),
        adventureInstructions.keys.toSet());
    for (final entry in adventureNarrationAssets.entries) {
      expect(PhonicsAudioService.assetForPhrase('adventure-${entry.key}'),
          entry.value);
      expect((await rootBundle.load('assets/${entry.value}')).lengthInBytes,
          greaterThan(1000));
    }
    expect(Directory('assets/audio/quick_check').listSync().whereType<File>(),
        hasLength(11));
  });

  Future<void> finish(
      WidgetTester t, AdventureTestAudio audio, String key) async {
    await flushAdventure(t);
    expect(audio.keys.last, 'adventure-$key');
    expect(audio.pending, isNotNull);
    audio.pending!.complete(true);
    await flushAdventure(t);
  }

  for (final passed in [true, false]) {
    testWidgets(
        'automatic instructions, saved feedback and ${passed ? 'mastered' : 'practice'} result',
        (t) async {
      final audio = AdventureTestAudio(autoNarration: false);
      final p = await openAdventure(t, audio, letter: 'C');
      await flushAdventure(t);
      expect(
          t
              .widget<FilledButton>(
                  find.byKey(const ValueKey('start-adventure')))
              .onPressed,
          isNull);
      await finish(t, audio, 'intro');
      await press(t, find.byTooltip('Replay instruction'));
      await finish(t, audio, 'intro');
      await press(t, find.byKey(const ValueKey('start-adventure')));
      await finish(t, audio, 'match');
      await press(t, find.byKey(const ValueKey('adventure-option-c')));
      expect(
          t
              .widget<FilledButton>(
                  find.widgetWithText(FilledButton, 'Next Challenge'))
              .onPressed,
          isNull);
      await finish(t, audio, 'saved');
      await press(t, find.text('Next Challenge'));
      await finish(t, audio, 'sound');
      final choices = t.widgetList<ElevatedButton>(find.byType(ElevatedButton));
      final chosen = passed
          ? 'C'
          : (choices
                  .firstWhere(
                      (b) => b.key != const ValueKey('adventure-option-C'))
                  .key as ValueKey<String>)
              .value
              .substring('adventure-option-'.length);
      await hear(t, audio, 'lesson-sound-$chosen');
      await press(t, find.byKey(ValueKey('adventure-option-$chosen')));
      await finish(t, audio, 'saved');
      await press(t, find.text('Next Challenge'));
      await finish(t, audio, 'spelling');
      await hear(t, audio, adventureWordKey('Cat'));
      await press(t, find.byKey(const ValueKey('adventure-option-C')));
      await finish(t, audio, 'saved');
      await press(t, find.text('Next Challenge'));
      await finish(t, audio, 'picture-beginning');
      await hear(t, audio, 'lesson-sound-C');
      await press(t, find.byKey(const ValueKey('adventure-option-Cow')));
      await finish(t, audio, 'saved');
      await press(t, find.text('Next Challenge'));
      await finish(t, audio, 'hunt');
      for (var i = 0; i < 12; i++) {
        final button = t.widget<FilledButton>(find.byKey(ValueKey('hunt-$i')));
        if ((button.child! as Text).data!.toUpperCase() == 'C') {
          await press(t, find.byKey(ValueKey('hunt-$i')));
        }
      }
      await finish(t, audio, 'saved');
      await press(t, find.text('See Result'));
      await finish(t, audio, passed ? 'mastered' : 'practice');
      expect(p.adventureProgress('C').mastered, passed);
      expect(p.adventureProgress('C').completed, 1);
      expect(audio.keys.where((k) => k == 'adventure-saved'), hasLength(5));
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      p.dispose();
    });
  }

  testWidgets(
      'muting and background stop instruction speech without recording an answer',
      (t) async {
    final audio = AdventureTestAudio(autoNarration: false);
    final p = await openAdventure(t, audio);
    await flushAdventure(t);
    expect(audio.keys.last, 'adventure-intro');
    await t.runAsync(() => p.toggleVoice());
    await flushAdventure(t);
    expect(audio.pending, isNull);
    expect(
        t
            .widget<FilledButton>(find.byKey(const ValueKey('start-adventure')))
            .onPressed,
        isNotNull);
    await press(t, find.byKey(const ValueKey('start-adventure')));
    expect(audio.keys, ['adventure-intro']);
    await t.runAsync(() => p.toggleVoice());
    await flushAdventure(t);
    await press(t, find.byTooltip('Replay instruction'));
    expect(audio.keys.last, 'adventure-match');
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await flushAdventure(t);
    expect(audio.pending, isNull);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await flushAdventure(t);
    expect(p.adventureProgress('B').completed, 0);
    expect(p.dailyActivity, isEmpty);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    p.dispose();
  });

  for (final item in [
    (letter: 'I', word: 'Pin', position: 'middle'),
    (letter: 'X', word: 'Box', position: 'end')
  ]) {
    testWidgets(
        '${item.letter} uses the supplied ${item.position} sound instruction',
        (t) async {
      final audio = AdventureTestAudio();
      final p = await openAdventure(t, audio, letter: item.letter);
      await flushAdventure(t);
      await press(t, find.byKey(const ValueKey('start-adventure')));
      await press(
          t,
          find.byKey(
              ValueKey('adventure-option-${item.letter.toLowerCase()}')));
      await press(t, find.text('Next Challenge'));
      await hear(t, audio, 'lesson-sound-${item.letter}');
      await press(t, find.byKey(ValueKey('adventure-option-${item.letter}')));
      await press(t, find.text('Next Challenge'));
      await hear(t, audio, adventureWordKey(item.word));
      await press(t, find.byKey(ValueKey('adventure-option-${item.letter}')));
      await press(t, find.text('Next Challenge'));
      expect(audio.keys.last, 'adventure-picture-${item.position}');
      expect(find.byTooltip('Replay instruction'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      p.dispose();
    });
  }
}
