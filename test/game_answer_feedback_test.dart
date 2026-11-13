import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/phonics_activity_data.dart';
import 'package:kidsphonics/data/rhyming_jar_data.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/screens/sound_match_screen.dart';
import 'package:kidsphonics/screens/phonics_quiz_screen.dart';
import 'package:kidsphonics/screens/missing_vowel_screen.dart';
import 'package:kidsphonics/screens/picture_word_match_screen.dart';
import 'package:kidsphonics/screens/word_builder_screen.dart';
import 'package:kidsphonics/screens/rumbled_words_screen.dart';
import 'package:kidsphonics/screens/alphabet_order_screen.dart';
import 'package:kidsphonics/screens/rhyming_words_screen.dart';
import 'package:kidsphonics/screens/voice_recognition_screen.dart';
import 'package:kidsphonics/screens/sound_position_screen.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/widgets/speech_practice_design.dart';
import 'package:kidsphonics/widgets/word_game_layout.dart';
import 'learner_ui_test.dart' show mount, close;
import 'learning_progress_test.dart' show mockProgressAudio;
import 'phonics_quiz_test_helpers.dart';
import 'quiz_audio_harness.dart';
import 'rumbled_words_swap_helpers.dart';
import 'speech_practice_test.dart' show FakeSpeech;

Future<void> drainFeedback(WidgetTester t) async {
  for (var i = 0; i < 20; i++) {
    await t.runAsync(() => Future<void>.delayed(Duration.zero));
    await t.pump();
  }
}

Future<void> submitAnswer(
    WidgetTester t, String game, bool correct, FakeSpeech speech) async {
  void pick(String answer) {
    if (answer == 'Q') answer = 'Qu';
    final options =
        t.widgetList<GameAnswerButton>(find.byType(GameAnswerButton));
    final choice = correct
        ? options.firstWhere((w) => w.label == answer)
        : options.firstWhere((w) => w.label != answer && w.onPressed != null);
    final action = choice.onPressed!;
    action();
    action(); // A stale callback must not score or play a second effect.
  }

  switch (game) {
    case 'Sound Match':
      pick(t
          .widget<AudioButton>(find.byType(AudioButton))
          .phrase
          .split('-')
          .last);
    case 'Phonics Quiz':
      final q = shownQuiz(t);
      pick(q.correctLetter);
    case 'Missing Vowel':
      final word = t.widget<WordGameLayout>(find.byType(WordGameLayout)).word;
      pick(vowelPuzzlesFor(Difficulty.easy)
          .firstWhere((q) => q.word == word)
          .vowel);
    case 'Picture Match':
      pick('Picture 1');
    case 'Word Builder':
      final word = t.widget<WordGameLayout>(find.byType(WordGameLayout)).word;
      pick(wordPuzzlesForDifficulty(Difficulty.easy)
          .firstWhere((q) => q.word == word)
          .correctLetters
          .first);
    case 'Rumbled Words':
      final word = t.widget<WordGameLayout>(find.byType(WordGameLayout)).word;
      if (correct) await arrangeBoard(t, word.toUpperCase());
      final action = t
          .widget<OutlinedButton>(find.byKey(const ValueKey('word-check')))
          .onPressed!;
      action();
      action();
    case 'Alphabet Order':
      pick('A');
    case 'Rhyming Words':
      final target =
          t.widget<Text>(find.byKey(const ValueKey('rhyme-target'))).data!;
      final family = rhymingFamilies.firstWhere((f) => f.target == target);
      final choices = t.widgetList<Text>(find.byWidgetPredicate((w) =>
          w is Text &&
          w.key is ValueKey<String> &&
          (w.key as ValueKey<String>).value.startsWith('rhyme-choice-')));
      final selected = choices
          .firstWhere((w) => family.rhymes.contains(w.data) == correct)
          .data!;
      final button = find.byKey(ValueKey('rhyme-choice-$selected'));
      await t.tap(button);
      await t.tap(button);
    case 'Speak & Recognize':
      final word =
          t.widget<SpeechPictureCard>(find.byType(SpeechPictureCard)).word;
      final mic = t.widget<ElevatedButton>(
          find.byKey(const ValueKey('speech-microphone')));
      mic.onPressed!();
      await drainFeedback(t);
      final callback = speech.result!;
      callback(correct ? word : 'zzzz', true);
      callback(correct ? word : 'zzzz', true);
    case 'Sound Position':
      final word =
          t.widget<AudioButton>(find.byType(AudioButton)).phrase.toUpperCase();
      final q =
          positionRoundsFor(Difficulty.easy).firstWhere((q) => q.word == word);
      pick(q.correctPos.label);
  }
  await drainFeedback(t);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'voice': false, 'sfx': true});
    mockProgressAudio();
    TestWidgetsFlutterBinding
            .instance.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(TestWidgetsFlutterBinding
        .instance.platformDispatcher.clearAccessibilityFeaturesTestValue);
  });
  final pages = <String, Widget>{
    'Sound Match': const SoundMatchScreen(difficulty: Difficulty.easy),
    'Phonics Quiz': const PhonicsQuizScreen(difficulty: Difficulty.easy),
    'Missing Vowel': const MissingVowelScreen(difficulty: Difficulty.easy),
    'Picture Match': const PictureWordMatchScreen(difficulty: Difficulty.easy),
    'Word Builder': const WordBuilderScreen(difficulty: Difficulty.easy),
    'Rumbled Words': const RumbledWordsScreen(difficulty: Difficulty.easy),
    'Alphabet Order': const AlphabetOrderScreen(difficulty: Difficulty.easy),
    'Rhyming Words': const RhymingWordsScreen(difficulty: Difficulty.easy),
    'Speak & Recognize': const SizedBox(),
    'Sound Position': const SoundPositionScreen(difficulty: Difficulty.easy),
  };
  for (final entry in pages.entries) {
    for (final correct in [true, false]) {
      testWidgets(
          '${entry.key}: ${correct ? 'green/correct' : 'red/wrong'} feedback plays once and resets',
          (t) async {
        t.view.physicalSize = const Size(390, 844);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final audio = QuizAudioHarness()..install();
        final speech = FakeSpeech();
        final page = entry.key == 'Speak & Recognize'
            ? VoiceRecognitionScreen(speech: speech)
            : entry.value;
        final p = await mount(t, page);
        await drainFeedback(t);
        expect(t.widget<GameScaffold>(find.byType(GameScaffold)).answerResult,
            isNull);
        await submitAnswer(t, entry.key, correct, speech);
        expect(t.widget<GameScaffold>(find.byType(GameScaffold)).answerResult,
            correct);
        final color = t
            .widget<ColoredBox>(
                find.byKey(const ValueKey('answer-background-effect')))
            .color;
        expect(correct ? color.g > color.r : color.r > color.g, isTrue);
        final effects = audio.starts
            .where((s) =>
                s.endsWith('/audio/correct.mp3') ||
                s.endsWith('/audio/wrong.mp3'))
            .toList();
        expect(effects, hasLength(1));
        expect(effects.single,
            endsWith('/audio/${correct ? 'correct' : 'wrong'}.mp3'));
        final state = t.state<GameSessionUi>(find.byType(page.runtimeType));
        expect((state.scoredAttempts, state.correctAttempts),
            (1, correct ? 1 : 0));
        expect(p.stars, 0);
        for (var i = 0; i < (entry.key == 'Phonics Quiz' ? 30 : 20); i++) {
          await t.pump(const Duration(milliseconds: 100));
          await t.runAsync(() => Future<void>.delayed(Duration.zero));
        }
        expect(t.widget<GameScaffold>(find.byType(GameScaffold)).answerResult,
            isNull);
        expect(state.scoredAttempts, 1);
        await t.runAsync(p.audio.stop);
        await close(t, p);
        p.audio.dispose();
        await drainFeedback(t);
        expect(t.takeException(), isNull);
      });
    }
  }
  testWidgets('SFX off keeps visual feedback without playing an answer effect',
      (t) async {
    SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
    final audio = QuizAudioHarness()..install();
    final p =
        await mount(t, const SoundMatchScreen(difficulty: Difficulty.easy));
    await submitAnswer(t, 'Sound Match', false, FakeSpeech());
    expect(t.widget<GameScaffold>(find.byType(GameScaffold)).answerResult,
        isFalse);
    expect(audio.starts.where((s) => s.endsWith('/audio/wrong.mp3')), isEmpty);
    await t.runAsync(p.audio.stop);
    await close(t, p);
    p.audio.dispose();
    await drainFeedback(t);
  });
  testWidgets('an answer effect stops a playing instruction before starting',
      (t) async {
    SharedPreferences.setMockInitialValues({'voice': true, 'sfx': true});
    final audio = QuizAudioHarness()..install();
    final p =
        await mount(t, const SoundMatchScreen(difficulty: Difficulty.easy));
    for (var i = 0; i < 100 && audio.starts.isEmpty; i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await t.pump();
    }
    expect(audio.starts.last, endsWith('/game_instructions/sound_match.mp3'));
    expect(p.phonicsAudio.currentPhrase, isNotNull);
    await submitAnswer(t, 'Sound Match', false, FakeSpeech());
    expect(p.phonicsAudio.currentPhrase, isNull);
    expect(audio.starts.last, endsWith('/audio/wrong.mp3'));
    expect(audio.starts.where((s) => s.endsWith('/audio/wrong.mp3')),
        hasLength(1));
    await t.runAsync(p.audio.stop);
    await close(t, p);
    p.audio.dispose();
    await drainFeedback(t);
  });

  testWidgets('Rhyming Words local mute keeps colors but silences effects',
      (t) async {
    final audio = QuizAudioHarness()..install();
    final p =
        await mount(t, const RhymingWordsScreen(difficulty: Difficulty.easy));
    await drainFeedback(t);
    await t.tap(find.byTooltip('Mute'));
    await t.pump();
    await submitAnswer(t, 'Rhyming Words', false, FakeSpeech());
    expect(t.widget<GameScaffold>(find.byType(GameScaffold)).answerResult,
        isFalse);
    expect(audio.starts.where((s) => s.endsWith('/audio/wrong.mp3')), isEmpty);
    await t.runAsync(p.audio.stop);
    await close(t, p);
    p.audio.dispose();
    await drainFeedback(t);
  });
}
