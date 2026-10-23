import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/data/game_instruction_scripts.dart';
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
import 'package:kidsphonics/widgets/game_mascot_coach.dart';
import 'package:kidsphonics/widgets/game_instruction_guide.dart';
import 'package:kidsphonics/widgets/sound_match_design.dart';
import 'package:kidsphonics/widgets/category_navigation.dart';
import 'package:kidsphonics/widgets/kids_navigation_bar.dart';

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
      await p.completeAdventure(
          'Q', [true, false, true, false, true], 'parent-practice-q');
    });
    await t.pumpAndSettle();
    final recommended = p.recommendedAdventureLetter!;
    final start = find.byKey(const ValueKey('home-start-adventure'));
    await t.ensureVisible(start);
    await t.pumpAndSettle();
    await t.tap(start);
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
                child: RepaintBoundary(
                    key: boundary,
                    child: Builder(
                        builder: (context) =>
                            entry.key == 'game_zone' || entry.key == 'parent'
                                ? MediaQuery(
                                    data: MediaQuery.of(context).copyWith(
                                        padding: const EdgeInsets.only(
                                            top: 24, bottom: 24)),
                                    child: entry.value)
                                : entry.value))));
        final hasCharacterGuide = const {
          'memory_flip',
          'phonics_quiz',
          'word_builder',
          'speak_recognize',
          'alphabet_order',
          'missing_vowel',
          'picture_match',
          'rumbled_words',
          'rhyming_words',
          'sound_match'
        }.contains(entry.key);
        final character = size.width == 390 ? 'girl' : 'boy';
        if (hasCharacterGuide) {
          await t.runAsync(() => p.setStudentCharacter(character, ''));
        }
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
        if (entry.key == 'game_zone' || entry.key == 'parent') {
          expect(find.byType(CategoryNavigation), findsNothing);
          expect(find.byType(KidsNavigationBar), findsOneWidget);
          expect(find.byKey(const ValueKey('category-nav-home')), findsNothing);
          final room = entry.key == 'game_zone' ? 'games' : 'parents';
          expect(t.getRect(find.byKey(ValueKey('room-$room-background'))),
              Offset.zero & size);
          final menu =
              t.getRect(find.byKey(const ValueKey('kids-navigation-bar')));
          expect(menu.top, greaterThanOrEqualTo(24));
          expect(menu.bottom, lessThanOrEqualTo(size.height - 24));
        } else {
          expect(find.byTooltip('Back'), findsOneWidget);
        }
        if (entry.key == 'sound_match') {
          expect(find.byType(MagicalSoundOrb), findsOneWidget);
          expect(find.byType(GameAnswerButton), findsNWidgets(3));
          expect(find.text('Hear Sound'), findsOneWidget);
        }
        if (hasCharacterGuide) {
          expect(find.byType(GameInstructionGuide), findsOneWidget);
          expect(
              find.text(gameInstructionScripts[
                      t.widget<GameScaffold>(find.byType(GameScaffold)).title]!
                  .text),
              findsOneWidget);
          expect(find.byKey(const ValueKey('game-mascot')), findsNothing);
          final guide =
              t.getRect(find.byKey(const ValueKey('game-instruction-guide')));
          expect(guide.width, lessThanOrEqualTo(340));
          expect(guide.height, lessThanOrEqualTo(112));
          for (final (key, name) in [
            ('lesson-guide-profile', '${character}_profile.png'),
            ('lesson-dialogue-art', 'instructions_dialogue_$character.png'),
          ]) {
            final image = t.widget<Image>(find.byKey(ValueKey(key)));
            expect(
                ((image.image as ResizeImage).imageProvider as AssetImage)
                    .assetName,
                'assets/images/lesson_header/$name');
            expect(image.fit, BoxFit.contain);
          }
          final ink =
              t.getRect(find.byKey(const ValueKey('lesson-instruction-text')));
          final opening =
              t.getRect(find.byKey(const ValueKey('lesson-dialogue-content')));
          expect(opening.inflate(.01).contains(ink.topLeft), isTrue);
          expect(opening.inflate(.01).contains(ink.bottomRight), isTrue);
          if (entry.key == 'memory_flip') {
            final timer = t.getRect(find.byKey(const ValueKey('memory-timer')));
            expect(guide.bottom, lessThan(timer.top));
            for (var i = 0; i < 8; i++) {
              final card = t.getRect(find.byKey(ValueKey('memory-$i')));
              expect(card.top, greaterThan(timer.bottom));
              expect(card.bottom, lessThanOrEqualTo(size.height));
              expect(card.width, greaterThan(0));
              expect(card.height, greaterThan(0));
            }
          } else if (entry.key == 'phonics_quiz') {
            final speaker = t.getRect(find.byType(AudioButton));
            expect(guide.bottom, lessThan(speaker.top));
          } else if (entry.key == 'sound_match') {
            expect(guide.bottom,
                lessThan(t.getRect(find.byType(MagicalSoundOrb)).top));
          } else if (entry.key == 'word_builder') {
            expect(guide.bottom,
                lessThan(t.getRect(find.byType(AudioButton)).top));
          } else if (entry.key == 'alphabet_order') {
            final target = t.getRect(find.text('Find A'));
            expect(guide.bottom, lessThan(target.top));
            final choice =
                t.getRect(find.byKey(const ValueKey('alphabet-choice-A')));
            expect(target.bottom, lessThan(choice.top));
            expect(choice.bottom, lessThanOrEqualTo(size.height));
          } else if (entry.key == 'missing_vowel') {
            expect(guide.bottom,
                lessThan(t.getRect(find.byType(AudioButton)).top));
          } else if (entry.key == 'picture_match') {
            expect(guide.bottom,
                lessThan(t.getRect(find.byType(AudioButton)).top));
          } else if (entry.key == 'rumbled_words') {
            expect(
                guide.bottom,
                lessThan(
                    t.getRect(find.byKey(const ValueKey('word-hint'))).top));
          } else if (entry.key == 'rhyming_words') {
            final pause = t.getRect(find.byTooltip('Pause'));
            final mute = t.getRect(find.byTooltip('Mute'));
            if (size.width < 364) {
              expect(guide.bottom, lessThanOrEqualTo(pause.top));
            } else {
              expect(guide.right, lessThanOrEqualTo(pause.left));
            }
            expect(pause.right, lessThanOrEqualTo(mute.left));
            expect(
                guide.bottom,
                lessThan(
                    t.getRect(find.byKey(const ValueKey('rhyme-target'))).top));
          } else {
            expect(
                guide.bottom,
                lessThan(t
                    .getRect(find.byKey(const ValueKey('speech-picture-card')))
                    .top));
          }
        }
        if (entry.key != 'game_zone' &&
            entry.key != 'parent' &&
            entry.key != 'sound_match' &&
            entry.key != 'rhyming_words' &&
            entry.key != 'flappy_letters' &&
            !hasCharacterGuide) {
          final coach = t.widget<GameMascotCoach>(find.byType(GameMascotCoach));
          expect(coach.instructions, isNotEmpty);
          expect(find.byTooltip('Hear Instructions'), findsNothing);
          expect(find.byKey(const ValueKey('game-mascot')), findsOneWidget);
        }
        if (entry.key == 'flappy_letters') {
          expect(
              find.byKey(const ValueKey('flappy-status-bar')), findsOneWidget);
          expect(find.byTooltip('How to Play'), findsOneWidget);
          expect(find.text('Start flying'), findsOneWidget);
        }
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
