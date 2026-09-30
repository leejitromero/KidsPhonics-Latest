import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/screens/lessons_screen.dart';
import 'package:kidsphonics/screens/letter_sounds_screen.dart';
import 'package:kidsphonics/widgets/mascot_guide.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(800, 1024)
  ]) {
    testWidgets('lesson logos fit without scrolling at $size', (t) async {
      await t.binding.setSurfaceSize(size);
      addTearDown(() => t.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      mockProgressAudio();
      final p = await mount(t, const LessonsScreen());
      await t.pumpAndSettle();
      for (final name in [
        'tricky_letters',
        'letter_sounds',
        'vowel_sounds',
        'rhyming_words'
      ]) {
        expect(find.byWidgetPredicate((w) {
          if (w is! Image) return false;
          final provider = w.image is ResizeImage
              ? (w.image as ResizeImage).imageProvider
              : w.image;
          return provider is AssetImage &&
              provider.assetName == 'assets/images/lesson_logos/$name.png';
        }), findsOneWidget);
      }
      final scroll = t.state<ScrollableState>(find.byType(Scrollable));
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
      expect(scroll.position.maxScrollExtent, closeTo(0, .01));
      expect(
          t.getRect(find.text('Rhyming Words')).bottom, lessThan(size.height));
      expect(t.takeException(), isNull);
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
}
