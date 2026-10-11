import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/screens/rumbled_words_screen.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'quiz_audio_harness.dart';
import 'rumbled_words_audio_test.dart'
    show shownWord, spell, audioStarted, highlighted, flushAudio;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
  });
  testWidgets('covered and backgrounded playback waits and replays same step',
      (t) async {
    final audio = QuizAudioHarness()..install();
    final p = await mount(t, const RumbledWordsScreen());
    await t.runAsync(() => p.toggleSfx());
    await t.pump();
    final task = shownWord(t);
    final word = task.toUpperCase();
    await spell(t, audio, word);
    await t.runAsync(() => audio.completeSound(word[word.length - 1]));
    await audioStarted(t, audio, word.length + 1);
    final context = t.element(find.byType(RumbledWordsScreen));
    showDialog<void>(
        context: context,
        builder: (_) => const AlertDialog(title: Text('Pause')));
    await t.pump();
    await flushAudio(t);
    await t.pump(const Duration(seconds: 2));
    expect(shownWord(t), task);
    expect(audio.starts.length, word.length + 1);
    Navigator.of(context).pop();
    await t.pump(const Duration(milliseconds: 400));
    await audioStarted(t, audio, word.length + 2);
    expect(highlighted(t, 0), isTrue);
    expect(audio.starts.last,
        endsWith('/sounds/sound-${word[0].toLowerCase()}.mp3'));

    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump();
    await flushAudio(t);
    await t.pump(const Duration(seconds: 3));
    expect(audio.starts.length, word.length + 2);
    expect(shownWord(t), task);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    await t.pump(const Duration(milliseconds: 250));
    await audioStarted(t, audio, word.length + 3);
    expect(highlighted(t, 0), isTrue);
    await close(t, p);
    p.phonicsAudio.dispose();
    await flushAudio(t);
    await t.pump(const Duration(seconds: 1));
    expect(t.takeException(), isNull);
  });
}
