import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/letter_adventure.dart';
import 'package:kidsphonics/widgets/quick_check_design.dart';
import 'package:kidsphonics/widgets/quick_choice_art.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'letter_mastery_check_test.dart'
    show AdventureTestAudio, press, hear, flushAdventure, openAdventure;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
    mockProgressAudio();
  });

  testWidgets(
      'separate speakers play only audio and keep assessment choices independent',
      (t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final audio = AdventureTestAudio();
    final p = await openAdventure(t, audio);
    final content = adventureContents.singleWhere((c) => c.letter == 'B');
    int answered() =>
        t.widget<QuickProgress>(find.byType(QuickProgress)).completed;
    ElevatedButton answer(String value) => t.widget<ElevatedButton>(
        find.byKey(ValueKey('adventure-option-$value')));
    void checkSeparateButtons() {
      final cells =
          t.widgetList<QuickAudioChoice>(find.byType(QuickAudioChoice));
      expect(cells, hasLength(4));
      for (final cell in cells) {
        final group = find.byWidget(cell);
        final choice =
            find.descendant(of: group, matching: find.byType(ElevatedButton));
        final speaker =
            find.descendant(of: group, matching: find.byType(QuickAudioButton));
        expect(t.getRect(choice).overlaps(t.getRect(speaker)), isFalse);
        expect(t.widget<QuickAudioButton>(speaker).embedded, isFalse);
        expect(t.getSize(speaker).shortestSide, greaterThanOrEqualTo(48));
      }
    }

    await press(t, find.byKey(const ValueKey('start-adventure')));
    await press(t, find.byKey(const ValueKey('adventure-option-b')));
    await press(t, find.text('Next Challenge'));
    checkSeparateButtons();
    final sounds = t
        .widgetList<QuickAudioButton>(find.descendant(
            of: find.byType(QuickAudioChoice),
            matching: find.byType(QuickAudioButton)))
        .toList();
    expect(answered(), 1);
    await press(t, find.byKey(const ValueKey('listen-lesson-sound-B')));
    expect(audio.keys.last, 'lesson-sound-B');
    expect(answer('B').onPressed, isNull);
    for (final key in sounds.map((button) => button.key!)) {
      expect(t.widget<QuickAudioButton>(find.byKey(key)).onPressed, isNull,
          reason: 'A sound still playing cannot overlap another preview');
    }
    expect(answered(), 1);
    audio.pending!.complete(true);
    await flushAdventure(t);
    expect(answer('B').onPressed, isNotNull);
    expect(answered(), 1);
    // A second tap on the speaker replays rather than submitting the answer.
    await hear(t, audio, 'lesson-sound-B');
    expect(answered(), 1);
    await press(t, find.byKey(const ValueKey('adventure-option-B')));
    expect(answered(), 2);
    await press(t, find.text('Next Challenge'));
    await hear(t, audio, adventureWordKey(content.word));
    await press(t, find.byKey(const ValueKey('adventure-option-B')));
    await press(t, find.text('Next Challenge'));
    checkSeparateButtons();
    expect(answered(), 3);

    final pictureButtons = t
        .widgetList<QuickAudioButton>(find.descendant(
            of: find.byType(QuickAudioChoice),
            matching: find.byType(QuickAudioButton)))
        .toList();
    for (final button in pictureButtons) {
      final key =
          (button.key! as ValueKey<String>).value.substring('listen-'.length);
      await hear(t, audio, key);
      expect(answered(), 3);
      expect(answer(content.pictureWord).onPressed, isNull,
          reason:
              'A picture preview does not replace the required target sound');
    }
    await hear(t, audio, content.soundKey);
    expect(answer(content.pictureWord).onPressed, isNotNull);
    await hear(t, audio, adventureWordKey(content.pictureWord));
    expect(answered(), 3);
    await press(
        t, find.byKey(ValueKey('adventure-option-${content.pictureWord}')));
    expect(answered(), 4);
    expect(p.adventureProgress('B').completed, 0);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await flushAdventure(t);
    p.dispose();
  });
}
