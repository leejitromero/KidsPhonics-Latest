import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/widgets/animated_screen_art.dart';
import 'package:kidsphonics/widgets/lessons_menu_page.dart';
import 'package:kidsphonics/widgets/quick_check_design.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
    mockProgressAudio();
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
    dispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: false);
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
  });

  for (final scenario in [
    (
      name: 'Quick Check',
      duration: const Duration(seconds: 5),
      page: QuickCheckPage(
          hasProgress: false,
          onLeave: () {},
          builder: (_, __) => const SizedBox()),
      frames: [
        for (var i = 1; i <= 3; i++)
          'assets/images/quick_check_background/quickcheck_newbg_$i.png',
      ],
    ),
    (
      name: 'Lessons',
      duration: const Duration(seconds: 3),
      page: const LessonsMenuPage(
          title: 'Letter Recognition',
          instruction: 'Tap Sound to hear the letter name.',
          child: SizedBox()),
      frames: lessonFrames,
    ),
  ]) {
    testWidgets('${scenario.name} reaches each frame at the requested interval',
        (t) async {
      await t.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final p = await mount(t, scenario.page);
      final art = find.byType(AnimatedScreenArt);
      final widget = t.widget<AnimatedScreenArt>(art);
      expect(widget.frameDuration, scenario.duration);
      expect(widget.frames, scenario.frames);
      await t.runAsync(() => Future.wait(scenario.frames.map((frame) =>
          precacheImage(
              ResizeImage(AssetImage(frame), width: 390), t.element(art)))));
      await t.pump();
      await t.pump();
      int current() => t
          .widgetList<Opacity>(
              find.descendant(of: art, matching: find.byType(Opacity)))
          .take(scenario.frames.length)
          .toList()
          .indexWhere((layer) => layer.opacity == 1);

      expect(current(), 0);
      for (var i = 1; i < scenario.frames.length; i++) {
        await t
            .pump(scenario.duration - Duration(milliseconds: i == 1 ? 10 : 20));
        expect(current(), i - 1, reason: 'Before frame ${i + 1}');
        await t.pump(const Duration(milliseconds: 20));
        expect(current(), i, reason: 'After frame ${i + 1}');
      }
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }
}
