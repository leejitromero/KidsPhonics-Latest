import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/screens/letter_sounds_screen.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
    mockProgressAudio();
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
    for (final scale in [1.0, 2.0]) {
      testWidgets(
          'vowel tabs, phoneme and navigation work at $size text $scale',
          (t) async {
        await t.binding.setSurfaceSize(size);
        addTearDown(() => t.binding.setSurfaceSize(null));
        final p = await mount(
            t,
            MediaQuery(
                data: MediaQueryData(
                    size: size,
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true),
                child: const LetterSoundsScreen(vowelsOnly: true)));
        await t.pumpAndSettle();
        Finder nav(String label) => find.widgetWithText(OutlinedButton, label);
        expect(t.widget<OutlinedButton>(nav('Previous')).onPressed, isNull);
        for (final letter in ['A', 'E', 'I', 'O', 'U']) {
          final tab = find.byKey(ValueKey('vowel-tab-$letter'));
          await t.ensureVisible(tab);
          await t.pumpAndSettle();
          await t.tap(tab);
          await t.pumpAndSettle();
          expect(find.text(letter.toLowerCase()), findsOneWidget);
          final sound = t.widget<AudioButton>(find.byType(AudioButton));
          expect(sound.phrase, 'lesson-sound-$letter');
          expect(sound.label, '/${letter.toLowerCase()}/');
          expect(find.byKey(const ValueKey('vowel-letter')), findsOneWidget);
          expect(t.takeException(), isNull);
        }
        expect(t.widget<OutlinedButton>(nav('Next')).onPressed, isNull);
        await t.tap(nav('Previous'));
        await t.pumpAndSettle();
        expect(t.widget<AudioButton>(find.byType(AudioButton)).phrase,
            'lesson-sound-O');
        await t.tap(nav('Next'));
        await t.pumpAndSettle();
        expect(t.widget<AudioButton>(find.byType(AudioButton)).phrase,
            'lesson-sound-U');
        expect(t.getRect(nav('Next')).bottom, lessThan(size.height));
        expect(p.xp, 0);
        expect(p.masteredVowelCount, 0);
        await close(t, p);
      });
    }
  }
}
