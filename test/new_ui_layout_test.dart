import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/screens/games_screen.dart';
import 'package:kidsphonics/screens/alphabet_order_screen.dart';
import 'package:kidsphonics/screens/flappy_letters_screen.dart';
import 'package:kidsphonics/screens/memory_game_screen.dart';
import 'package:kidsphonics/screens/missing_vowel_screen.dart';
import 'package:kidsphonics/screens/phonics_quiz_screen.dart';
import 'package:kidsphonics/screens/picture_word_match_screen.dart';
import 'package:kidsphonics/screens/rhyming_words_screen.dart';
import 'package:kidsphonics/screens/rumbled_words_screen.dart';
import 'package:kidsphonics/screens/sound_match_screen.dart';
import 'package:kidsphonics/screens/voice_recognition_screen.dart';
import 'package:kidsphonics/screens/word_builder_screen.dart';
import 'package:kidsphonics/screens/parent_screen.dart';
import 'package:kidsphonics/screens/letter_mastery_check_screen.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/theme/kids_ui.dart';
import 'learner_ui_test.dart' show mount, close;
import 'learning_progress_test.dart' show mockProgressAudio;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const capture = bool.fromEnvironment('CAPTURE_UI');
  setUpAll(() async {
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf')))
        .load();
    for (final (family, file) in [('Fredoka', 'Fredoka-Regular.ttf')]) {
      await (FontLoader(family)..addFont(rootBundle.load('assets/fonts/$file')))
          .load();
    }
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  testWidgets('parent practice action opens the recommended letter', (t) async {
    t.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
        t.binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
    final p = await mount(t, const ParentScreen());
    await t.runAsync(() async {
      await p.parentAuth.setup('2580', '2580');
      await p.recordLetterPractice('Q', false);
    });
    await t.pumpAndSettle();
    final recommended = p.recommendedNextPractice!.letter;
    await t.ensureVisible(find.text('Go to Practice'));
    await t.pumpAndSettle();
    await t.tap(find.text('Go to Practice'));
    await t.pumpAndSettle();
    expect(
        t
            .widget<LetterMasteryCheckScreen>(
                find.byType(LetterMasteryCheckScreen))
            .letter
            .letter,
        recommended);
    await close(t, p);
  });
  const pages = <String, Widget>{
    'game_zone': GamesScreen(),
    'alphabet_order': AlphabetOrderScreen(difficulty: Difficulty.hard),
    'flappy_letters': FlappyLettersScreen(),
    'memory_flip': MemoryGameScreen(difficulty: Difficulty.hard),
    'missing_vowel': MissingVowelScreen(difficulty: Difficulty.hard),
    'phonics_quiz': PhonicsQuizScreen(difficulty: Difficulty.hard),
    'picture_match': PictureWordMatchScreen(difficulty: Difficulty.hard),
    'rhyming_words': RhymingWordsScreen(difficulty: Difficulty.hard),
    'rumbled_words': RumbledWordsScreen(difficulty: Difficulty.hard),
    'sound_match': SoundMatchScreen(difficulty: Difficulty.hard),
    'speak_recognize': VoiceRecognitionScreen(difficulty: Difficulty.hard),
    'word_builder': WordBuilderScreen(difficulty: Difficulty.hard),
    'parent': ParentScreen(),
  };
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(800, 1024)
  ]) {
    for (final entry in pages.entries) {
      testWidgets('${entry.key} new design fits $size without large headers',
          (t) async {
        await t.binding.setSurfaceSize(size);
        addTearDown(() => t.binding.setSurfaceSize(null));
        t.binding.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
            t.binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
        SharedPreferences.setMockInitialValues({});
        mockProgressAudio();
        final boundary = GlobalKey();
        final p = await mount(
            t,
            Theme(
                data: KidsUi.theme,
                child: RepaintBoundary(key: boundary, child: entry.value)));
        if (entry.key == 'parent') {
          await t.runAsync(() => p.parentAuth.setup('2580', '2580'));
        }
        // The flight ticker intentionally stays active even on its ready screen.
        if (entry.key == 'flappy_letters') {
          await t.pump(const Duration(milliseconds: 500));
        } else {
          await t.pumpAndSettle();
        }
        await t.runAsync(() async {
          await Future.wait(t.widgetList<Image>(find.byType(Image)).map(
              (image) => precacheImage(image.image, boundary.currentContext!)));
        });
        await t.pump(const Duration(milliseconds: 100));
        expect(t.takeException(), isNull);
        expect(find.byType(AppBar), findsNothing);
        expect(find.byType(LearnerHeader), findsNothing);
        expect(find.byTooltip('Back'), findsOneWidget);
        if (capture && size.width == 390) {
          if (entry.key == 'flappy_letters') {
            await t.tap(find.text('Start flying'));
            for (var i = 0; i < 4; i++) {
              await t.pump(const Duration(milliseconds: 300));
              await t.tap(find.byKey(const ValueKey('flight-play-area')));
            }
            await t.pump();
          }
          await t.runAsync(() async {
            final image = await (boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File('build/ui_previews/${entry.key}.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await close(t, p);
      });
    }
  }
}
