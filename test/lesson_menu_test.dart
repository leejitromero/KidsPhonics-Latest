import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/screens/lessons_screen.dart';
import 'package:kidsphonics/screens/letter_sounds_screen.dart';
import 'package:kidsphonics/widgets/mascot_guide.dart';
import 'package:kidsphonics/screens/journey_lesson_screen.dart';
import 'package:kidsphonics/data/lesson_journey.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestWidgetsFlutterBinding
            .instance.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(TestWidgetsFlutterBinding
        .instance.platformDispatcher.clearAccessibilityFeaturesTestValue);
  });
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(800, 1024)
  ]) {
    testWidgets('lesson logos remain reachable at $size', (t) async {
      await t.binding.setSurfaceSize(size);
      addTearDown(() => t.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      mockProgressAudio();
      final p = await mount(t, const LessonsScreen());
      await t.pumpAndSettle();
      for (final name in [
        'letter_recognition',
        'letter_sounds',
        'vowel_sounds',
        'cvc_words',
        'blending_sounds',
      ]) {
        final logo = find.byWidgetPredicate((w) {
          if (w is! Image) return false;
          final provider = w.image is ResizeImage
              ? (w.image as ResizeImage).imageProvider
              : w.image;
          return provider is AssetImage &&
              provider.assetName == 'assets/images/lesson_logos/$name.png';
        });
        // The compact phone keeps readable cards and scrolls the third row.
        if (logo.evaluate().isEmpty) {
          await t.drag(find.byType(GridView), const Offset(0, -200));
          await t.pumpAndSettle();
        }
        expect(logo, findsOneWidget);
      }
      expect(find.byType(MascotGuide), findsOneWidget);
      expect(t.widget<MascotGuide>(find.byType(MascotGuide)).mascot,
          LearningMascot.wigloo);
      expect(t.getRect(find.byType(MascotGuide)).bottom,
          lessThanOrEqualTo(t.getRect(find.byType(GridView)).top));
      expect(
          (t.widget<GridView>(find.byType(GridView)).gridDelegate
                  as SliverGridDelegateWithFixedCrossAxisCount)
              .mainAxisExtent,
          lessThanOrEqualTo(220));
      expect(find.text('Rhyming Words'), findsNothing);
      expect(find.text('Tricky Letters'), findsNothing);
      await t.ensureVisible(find.text('Blending Sounds'));
      await t.pumpAndSettle();
      expect(t.getRect(find.text('Blending Sounds')).bottom,
          lessThan(size.height));
      expect(t.takeException(), isNull);
      await t.scrollUntilVisible(find.text('Short Vowel Sounds'), -150);
      await t.pumpAndSettle();
      await t.tap(find.text('Short Vowel Sounds'));
      await t.pump();
      await t.runAsync(() => Future<void>.delayed(Duration.zero));
      await t.pump(const Duration(milliseconds: 500));
      expect(
          t
              .widget<LetterSoundsScreen>(find.byType(LetterSoundsScreen))
              .vowelsOnly,
          isTrue);
      await close(t, p);
    });
  }
  testWidgets('lesson records first answers and saves completion after finish',
      (t) async {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
    final lesson = lessonJourney[2].lessons[0];
    final p = await mount(t, JourneyLessonScreen(lesson: lesson));
    for (var i = 0; i < lesson.questions.length; i++) {
      final q = lesson.questions[i];
      final answer = i == 0 ? q.choices.first : q.answer;
      await t.ensureVisible(find.widgetWithText(ElevatedButton, answer));
      await t.tap(find.widgetWithText(ElevatedButton, answer));
      await t.pump();
      expect(p.journeyScore(lesson.id), isNull);
      final next = find.text(i == 2 ? 'Finish Lesson' : 'Next');
      await t.ensureVisible(next);
      await t.tap(next);
      await t.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await t.pumpAndSettle();
    }
    expect(find.text('Lesson complete!'), findsOneWidget);
    expect(p.journeyScore('blend'), 67);
    final reloaded = AppProvider();
    await t.runAsync(() => reloaded.ready);
    expect(reloaded.journeyScore('blend'), 67);
    reloaded.dispose();
    await close(t, p);
  });
}
