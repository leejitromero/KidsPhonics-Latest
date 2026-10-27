import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/game_instruction_scripts.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/flappy_letters_screen.dart';
import 'package:kidsphonics/screens/sound_match_screen.dart';
import 'package:kidsphonics/screens/memory_game_screen.dart';
import 'package:kidsphonics/screens/phonics_quiz_screen.dart';
import 'package:kidsphonics/screens/word_builder_screen.dart';
import 'package:kidsphonics/screens/voice_recognition_screen.dart';
import 'package:kidsphonics/screens/alphabet_order_screen.dart';
import 'package:kidsphonics/screens/missing_vowel_screen.dart';
import 'package:kidsphonics/screens/picture_word_match_screen.dart';
import 'package:kidsphonics/screens/rumbled_words_screen.dart';
import 'package:kidsphonics/screens/rhyming_words_screen.dart';
import 'package:kidsphonics/services/audio_service.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';
import 'package:kidsphonics/widgets/game_instruction_guide.dart';
import 'learner_ui_test.dart' show mount, close;
import 'learning_progress_test.dart' show mockProgressAudio;
import 'quiz_audio_harness.dart';

class _DelayedIntroCache extends AudioCache {
  final loaded = Completer<void>();
  final release = Completer<void>();
  @override
  Future<Uri> fetchToMemory(String name) async {
    if (name.endsWith('game_instructions/sound_match.mp3')) {
      if (!loaded.isCompleted) loaded.complete();
      await release.future;
    }
    return Uri.file('${Directory.current.path}/assets/$name');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pages = <String, Widget>{
    'Flappy Letters': FlappyLettersScreen(),
    'Sound Match': SoundMatchScreen(),
    'Memory Flip': MemoryGameScreen(),
    'Phonics Quiz': PhonicsQuizScreen(),
    'Word Builder': WordBuilderScreen(),
    'Speak & Recognize': VoiceRecognitionScreen(),
    'Alphabet Order': AlphabetOrderScreen(),
    'Missing Vowel': MissingVowelScreen(),
    'Picture Match': PictureWordMatchScreen(),
    'Rumbled Words': RumbledWordsScreen(),
    'Rhyming Words': RhymingWordsScreen(),
  };
  late QuizAudioHarness audio;
  setUpAll(() async {
    final loader = FontLoader('Nunito');
    for (final weight in ['Regular', 'Bold', 'ExtraBold', 'Black']) {
      loader.addFont(rootBundle.load('assets/fonts/Nunito-$weight.ttf'));
    }
    await loader.load();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({'voice': true, 'sfx': false});
    mockProgressAudio();
    audio = QuizAudioHarness()..install();
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
    dispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
  });
  Future<void> drain(WidgetTester t) async {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await t.pump();
  }

  Future<void> until(WidgetTester t, bool Function() ready) async {
    for (var i = 0; i < 150 && !ready(); i++) {
      await drain(t);
    }
    expect(ready(), isTrue, reason: 'Audio starts: ${audio.starts}');
  }

  Future<void> finish(WidgetTester t, AppProvider p) async {
    await close(t, p);
    await t.runAsync(() async {
      PhonicsAudioService().dispose();
      AudioService().dispose();
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await t.pump();
  }

  String caption(WidgetTester t) => t
      .widget<Text>(find.byKey(const ValueKey('lesson-instruction-text')))
      .data!;
  void fits(WidgetTester t) {
    final ink =
        t.getRect(find.byKey(const ValueKey('lesson-instruction-text')));
    final opening =
        t.getRect(find.byKey(const ValueKey('lesson-dialogue-content')));
    expect(opening.inflate(.01).contains(ink.topLeft), isTrue);
    expect(opening.inflate(.01).contains(ink.bottomRight), isTrue);
  }

  test('all eleven supplied MP3s are bundled unchanged and mapped once',
      () async {
    final imports = jsonDecode(
            File('tools/game_instruction_audio_import.json').readAsStringSync())
        as List;
    expect(imports, hasLength(11));
    expect(gameInstructionScripts, hasLength(11));
    expect(
        gameInstructionScripts.values.map((s) => 'assets/${s.asset}').toSet(),
        imports.map((i) => i['path']).toSet());
    for (final entry in imports) {
      final bytes = await rootBundle.load(entry['path'] as String);
      expect(
          sha256.convert(bytes.buffer.asUint8List()).toString().toUpperCase(),
          entry['sha256']);
    }
    for (final s in gameInstructionScripts.values) {
      expect(PhonicsAudioService.assetForPhrase('game-instruction-${s.key}'),
          s.asset);
    }
    expect(PhonicsAudioService.assetForPhrase('rhyme-intro'),
        gameInstructionScripts['Rhyming Words']!.asset);
  });

  for (final entry in pages.entries) {
    testWidgets(
        '${entry.key}: current instructions and matching recorded intro',
        (t) async {
      await t.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final p = await mount(t, entry.value);
      final s = gameInstructionScripts[entry.key]!;
      final hasCurrentRecording = entry.key != 'Rumbled Words';
      if (hasCurrentRecording) {
        await until(
            t, () => audio.starts.any((path) => path.endsWith('/${s.asset}')));
      } else {
        await drain(t);
      }
      expect(caption(t), s.text);
      fits(t);
      await t.pump(const Duration(seconds: 5));
      expect(caption(t), s.text);
      expect(audio.starts.where((path) => path.endsWith('/${s.asset}')),
          hasLength(hasCurrentRecording ? 1 : 0));
      if (hasCurrentRecording) {
        await t.runAsync(() => audio.completeSource('/${s.asset}'));
      }
      await drain(t);
      await t.runAsync(() => p.setStudentCharacter('girl', ''));
      await drain(t);
      expect(caption(t), s.text);
      expect(audio.starts.where((path) => path.endsWith('/${s.asset}')),
          hasLength(hasCurrentRecording ? 1 : 0));
      expect((p.xp, p.stars), (0, 0));
      expect(t.takeException(), isNull);
      await finish(t, p);
    });

    for (final character in ['boy', 'girl']) {
      testWidgets(
          '${entry.key}: full $character sentence fits narrow dialogue at text 2x',
          (t) async {
        SharedPreferences.setMockInitialValues(
            {'voice': false, 'sfx': false, 'studentCharacter': character});
        await t.binding.setSurfaceSize(const Size(320, 568));
        addTearDown(() => t.binding.setSurfaceSize(null));
        final p = await mount(
            t,
            MediaQuery(
                data: const MediaQueryData(
                    size: Size(320, 568),
                    textScaler: TextScaler.linear(2),
                    disableAnimations: true),
                child: Scaffold(
                    body: Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                            width: 296,
                            child: Row(children: [
                              Expanded(
                                  child: GameInstructionGuide(
                                      gameTitle: entry.key)),
                              if (entry.key == 'Rhyming Words')
                                const SizedBox(width: 80, height: 40),
                            ]))))));
        await drain(t);
        expect(caption(t), gameInstructionScripts[entry.key]!.text);
        fits(t);
        expect(audio.starts, isEmpty);
        expect(t.takeException(), isNull);
        await finish(t, p);
      });
    }
  }

  testWidgets(
      'manual sound interrupts intro without changing its caption or restarting it',
      (t) async {
    final p = await mount(t, const SoundMatchScreen());
    final s = gameInstructionScripts['Sound Match']!;
    await until(
        t, () => audio.starts.any((path) => path.endsWith('/${s.asset}')));
    await t.tap(find.byKey(const ValueKey('sound-match-hear')));
    await until(
        t, () => audio.starts.any((path) => path.contains('/sounds/sound-')));
    expect(caption(t), s.text);
    expect(audio.starts.where((path) => path.endsWith('/${s.asset}')),
        hasLength(1));
    await finish(t, p);
  });

  testWidgets('a loading intro cannot take over a manually requested sound',
      (t) async {
    final cache = _DelayedIntroCache();
    AudioCache.instance = cache;
    final p = await mount(t, const SoundMatchScreen());
    await until(t, () => cache.loaded.isCompleted);
    await t.tap(find.byKey(const ValueKey('sound-match-hear')));
    await until(
        t, () => audio.starts.any((path) => path.contains('/sounds/sound-')));
    cache.release.complete();
    for (var i = 0; i < 5; i++) {
      await drain(t);
    }
    expect(audio.starts.where((path) => path.contains('/game_instructions/')),
        isEmpty);
    await finish(t, p);
  });

  for (final action in ['cover', 'background', 'mute']) {
    testWidgets('$action stops the instruction and never restarts it',
        (t) async {
      final p = await mount(t, const SoundMatchScreen());
      final s = gameInstructionScripts['Sound Match']!;
      await until(
          t, () => audio.starts.any((path) => path.endsWith('/${s.asset}')));
      if (action == 'cover') {
        unawaited(showDialog<void>(
            context: t.element(find.byType(SoundMatchScreen)),
            builder: (_) => const AlertDialog(title: Text('Help'))));
        await drain(t);
        Navigator.pop(t.element(find.text('Help')));
      } else if (action == 'background') {
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await drain(t);
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      } else {
        unawaited(p.toggleVoice());
        await drain(t);
      }
      await until(t, () => p.phonicsAudio.currentPhrase == null);
      for (var i = 0; i < 3; i++) {
        await drain(t);
      }
      expect(audio.starts.where((path) => path.endsWith('/${s.asset}')),
          hasLength(1));
      expect(caption(t), s.text);
      await finish(t, p);
    });
  }
}
