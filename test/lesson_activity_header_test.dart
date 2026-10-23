import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/controllers/blending_lesson_controller.dart';
import 'package:kidsphonics/controllers/cvc_lesson_controller.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/blending_sounds_screen.dart';
import 'package:kidsphonics/screens/cvc_words_screen.dart';
import 'package:kidsphonics/screens/letter_recognition_screen.dart';
import 'package:kidsphonics/screens/letter_sounds_screen.dart';
import 'package:kidsphonics/screens/vowel_sounds_screen.dart';
import 'package:kidsphonics/widgets/lesson_activity_header.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show close;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Nunito');
    for (final name in ['Regular', 'Bold', 'ExtraBold', 'Black']) {
      loader.addFont(rootBundle.load('assets/fonts/Nunito-$name.ttf'));
    }
    await loader.load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  setUp(() {
    mockProgressAudio();
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
    dispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
  });

  String asset(WidgetTester t, String key) {
    final image = t.widget<Image>(find.byKey(ValueKey(key)));
    expect(image.fit, BoxFit.contain);
    return ((image.image as ResizeImage).imageProvider as AssetImage).assetName;
  }

  for (final character in ['boy', 'girl']) {
    for (final viewport in [
      (size: const Size(320, 568), scale: 2.0),
      (size: const Size(390, 844), scale: 1.0),
      (size: const Size(800, 1024), scale: 2.0),
    ]) {
      for (final lesson in [
        (
          title: 'Letter Recognition',
          page: () => const LetterRecognitionScreen()
        ),
        (title: 'Letter Sounds', page: () => const LetterSoundsScreen()),
        (title: 'Short Vowel Sounds', page: () => const VowelSoundsScreen()),
        (
          title: 'CVC Words',
          page: () => CvcWordsScreen(
              controller: CvcLessonController(
                  play: (_) async => true,
                  stop: () async {},
                  voiceEnabled: false))
        ),
        (
          title: 'Blending Sounds',
          page: () => BlendingSoundsScreen(
              controller: BlendingLessonController(
                  play: (_) async => true,
                  stop: () async {},
                  voiceEnabled: false))
        ),
      ]) {
        testWidgets(
            '${lesson.title}, $character: safe header at ${viewport.size}, text ${viewport.scale}',
            (t) async {
          await t.binding.setSurfaceSize(viewport.size);
          addTearDown(() => t.binding.setSurfaceSize(null));
          SharedPreferences.setMockInitialValues({
            'studentCharacter': character,
            'voice': false,
            'sfx': false,
          });
          late AppProvider p;
          await t.runAsync(() async {
            p = AppProvider();
            await p.ready;
          });
          final boundary = GlobalKey();
          await t.pumpWidget(ChangeNotifierProvider.value(
              value: p,
              child: MaterialApp(
                  builder: (context, child) => MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                          padding: const EdgeInsets.only(top: 24, bottom: 24),
                          textScaler: TextScaler.linear(viewport.scale)),
                      child: child!),
                  home: RepaintBoundary(key: boundary, child: lesson.page()))));
          await t.pump();
          await t.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 50)));
          await t.pump(const Duration(milliseconds: 700));

          expect(
              t.widget<Text>(find.byKey(const ValueKey('lesson-title'))).data,
              lesson.title);
          expect(find.text(lesson.title), findsOneWidget);
          expect(asset(t, 'lessons-banner'),
              '$lessonHeaderAssets/banner_lessons.png');
          expect(asset(t, 'lesson-guide-profile'),
              '$lessonHeaderAssets/${character}_profile.png');
          expect(asset(t, 'lesson-dialogue-art'),
              '$lessonHeaderAssets/instructions_dialogue_$character.png');
          final banner =
              t.getRect(find.byKey(const ValueKey('lessons-banner')));
          final back = t.getRect(find.byTooltip('Back'));
          final dialogue =
              t.getRect(find.byKey(const ValueKey('lesson-dialogue-art')));
          final profile =
              t.getRect(find.byKey(const ValueKey('lesson-guide-profile')));
          expect(banner.width, lessThanOrEqualTo(288));
          expect(banner.height, lessThanOrEqualTo(96));
          expect(banner.center.dx, closeTo(viewport.size.width / 2, .01));
          expect(banner.left, greaterThanOrEqualTo(back.right));
          expect(banner.bottom, lessThan(dialogue.top));
          expect(profile.right, lessThanOrEqualTo(dialogue.left));
          expect(back.width, greaterThanOrEqualTo(48));
          for (final (text, opening) in [
            ('lesson-title', 'lesson-title-content'),
            ('lesson-instruction-text', 'lesson-dialogue-content'),
          ]) {
            final rect = t.getRect(find.byKey(ValueKey(text)));
            final safe = t.getRect(find.byKey(ValueKey(opening)));
            expect(safe.inflate(.01).contains(rect.topLeft), isTrue);
            expect(safe.inflate(.01).contains(rect.bottomRight), isTrue);
          }
          expect(t.takeException(), isNull);

          if (const bool.fromEnvironment('CAPTURE_UI') &&
              viewport.size.width == 390 &&
              (lesson.title == 'Blending Sounds' ||
                  lesson.title == 'Letter Recognition')) {
            await t.runAsync(() async {
              await Future.wait(t.widgetList<Image>(find.byType(Image)).map(
                  (image) =>
                      precacheImage(image.image, boundary.currentContext!)));
            });
            await t.pump();
            await t.runAsync(() async {
              final render = boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary;
              final image = await render.toImage(pixelRatio: 2);
              final bytes =
                  await image.toByteData(format: ui.ImageByteFormat.png);
              final file = File(
                  'build/ui_previews/lesson_header_${character}_${lesson.title.replaceAll(' ', '_')}.png');
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

  testWidgets(
      'saved character changes update the profile and dialogue together',
      (t) async {
    SharedPreferences.setMockInitialValues(
        {'studentCharacter': 'boy', 'voice': false, 'sfx': false});
    late AppProvider p;
    await t.runAsync(() async {
      p = AppProvider();
      await p.ready;
    });
    await t.pumpWidget(ChangeNotifierProvider.value(
        value: p, child: const MaterialApp(home: LetterRecognitionScreen())));
    await t.runAsync(() => p.setStudentCharacter('girl', 'Learner'));
    await t.pump();
    expect(asset(t, 'lesson-guide-profile'),
        '$lessonHeaderAssets/girl_profile.png');
    expect(asset(t, 'lesson-dialogue-art'),
        '$lessonHeaderAssets/instructions_dialogue_girl.png');
    expect(p.xp, 0);
    expect(p.stars, 0);
    expect(t.takeException(), isNull);
    await close(t, p);
  });
}
