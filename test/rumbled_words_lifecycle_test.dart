import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/screens/rumbled_words_screen.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'quiz_audio_harness.dart';
import 'rumbled_words_audio_test.dart' show shownWord, spell, flushAudio;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
  });
  testWidgets('submitted arrangement waits while covered and backgrounded',
      (t) async {
    final audio = QuizAudioHarness()..install();
    final p = await mount(t, const RumbledWordsScreen());
    await flushAudio(t);
    await t.runAsync(() => p.toggleSfx());
    await t.pump();
    final task = shownWord(t);
    final word = task.toUpperCase();
    final selectionCount = await spell(t, audio, word);

    final context = t.element(find.byType(RumbledWordsScreen));
    showDialog<void>(
        context: context,
        builder: (_) => const AlertDialog(title: Text('Pause')));
    await t.pump();
    await flushAudio(t);
    await t.pump(const Duration(seconds: 2));
    expect(shownWord(t), task);
    expect(audio.starts.length, selectionCount);
    Navigator.of(context).pop();
    // Background before the covered answer can advance.
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump(const Duration(seconds: 3));
    expect(shownWord(t), task);
    expect(audio.starts.length, selectionCount);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump(const Duration(milliseconds: 400));
    expect(shownWord(t), isNot(task));
    expect(audio.starts.length, selectionCount);
    await close(t, p);
    p.phonicsAudio.dispose();
    await flushAudio(t);
    await t.pump(const Duration(seconds: 1));
    expect(t.takeException(), isNull);
  });
}
