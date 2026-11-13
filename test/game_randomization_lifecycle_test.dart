import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/game_session_order.dart';
import 'package:kidsphonics/screens/memory_game_screen.dart';
import 'package:kidsphonics/screens/missing_vowel_screen.dart';
import 'package:kidsphonics/screens/phonics_quiz_screen.dart';
import 'package:kidsphonics/screens/picture_word_match_screen.dart';
import 'package:kidsphonics/screens/rhyming_words_screen.dart';
import 'package:kidsphonics/screens/rumbled_words_screen.dart';
import 'package:kidsphonics/screens/sound_match_screen.dart';
import 'package:kidsphonics/screens/sound_position_screen.dart';
import 'package:kidsphonics/screens/voice_recognition_screen.dart';
import 'package:kidsphonics/screens/word_builder_screen.dart';
import 'package:kidsphonics/widgets/game_word_picture.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/widgets/phonics_quiz_design.dart';
import 'package:kidsphonics/widgets/speech_practice_design.dart';
import 'learner_ui_test.dart' show mount, close;
import 'learning_progress_test.dart' show mockProgressAudio;
import 'speech_practice_test.dart' show FakeSpeech;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
    mockProgressAudio();
  });

  Future<void> flushHistory(WidgetTester t) async {
    var saved = false;
    bool? result;
    GameSessionOrder.saved.then((success) {
      result = success;
      saved = true;
    });
    // Writes can begin in the widget fake-clock zone. Pump its microtasks
    // while also allowing the real platform reply to complete.
    for (var i = 0; i < 50 && !saved; i++) {
      await t.pump();
      await t.runAsync(() => Future<void>.delayed(Duration.zero));
    }
    expect(saved, isTrue);
    expect(result, isTrue);
  }

  final games = <String, Widget Function()>{
    'Sound Match': () => const SoundMatchScreen(),
    'Phonics Quiz': () => const PhonicsQuizScreen(),
    'Word Builder': () => const WordBuilderScreen(),
    'Speak & Recognize': () => VoiceRecognitionScreen(speech: FakeSpeech()),
    'Missing Vowel': () => const MissingVowelScreen(),
    'Picture Match': () => const PictureWordMatchScreen(),
    'Rumbled Words': () => const RumbledWordsScreen(),
    'Rhyming Words': () => const RhymingWordsScreen(),
    'Sound Position': () => const SoundPositionScreen(),
    'Memory Flip': () => const MemoryGameScreen(),
  };

  for (final entry in games.entries) {
    testWidgets(
        '${entry.key} keeps its task and draw history through interruptions',
        (t) async {
      await t.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final active = ValueNotifier(true);
      final page = entry.value();
      final provider = await mount(
          t,
          ValueListenableBuilder<bool>(
              valueListenable: active,
              child: page,
              builder: (_, enabled, child) =>
                  TickerMode(enabled: enabled, child: child!)));
      await flushHistory(t);
      final prefs = await t.runAsync(() => SharedPreferences.getInstance());
      final savedHistory = prefs!.getString(GameSessionHistory.storageKey);
      expect(savedHistory, isNotNull);
      final state = t.state<GameSessionUi>(find.byType(page.runtimeType));

      List<String> task() => [
            ...t
                .widgetList<GameWordPicture>(find.byType(GameWordPicture))
                .map((w) => 'picture:${w.word}'),
            ...t
                .widgetList<AudioButton>(find.byType(AudioButton))
                .map((w) => 'audio:${w.phrase}'),
            ...t
                .widgetList<SpeechPictureCard>(find.byType(SpeechPictureCard))
                .map((w) => 'speech:${w.word}'),
            ...t
                .widgetList<PhonicsQuizQuestionView>(
                    find.byType(PhonicsQuizQuestionView))
                .map((w) => 'quiz:${w.question.id}'),
          ];
      final before = task();

      Future<void> check() async {
        await flushHistory(t);
        expect(task(), before);
        expect(prefs.getString(GameSessionHistory.storageKey), savedHistory);
        expect(
            identical(t.state(find.byType(page.runtimeType)), state), isTrue);
        expect((state.scoredAttempts, state.earnedStars), (0, 0));
        expect((provider.xp, provider.stars, provider.dailyActivity.isEmpty),
            (0, 0, true));
        expect(t.takeException(), isNull);
      }

      active.value = false;
      await t.pump();
      await t.pump(const Duration(seconds: 2));
      active.value = true;
      await t.pump();
      await check();

      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await t.pump();
      await t.pump(const Duration(seconds: 2));
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      await check();

      // A settings notification rebuilds the screen without reserving a new round.
      await t.runAsync(() => provider.setTextSizeMultiplier(1.1));
      await t.pump();
      await check();

      await close(t, provider);
      provider.phonicsAudio.dispose();
      active.dispose();
    });
  }
}
