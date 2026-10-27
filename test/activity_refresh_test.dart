import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/main.dart';
import 'package:kidsphonics/widgets/word_game_layout.dart';
import 'package:kidsphonics/widgets/loading_screen_art.dart';
import 'package:kidsphonics/widgets/animated_screen_art.dart';

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(800, 1280)
  ]) {
    testWidgets('loading scene fits $size with enlarged text without cropping',
        (t) async {
      await t.binding.setSurfaceSize(size);
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(MaterialApp(
        builder: (_, child) => MediaQuery(
            data: const MediaQueryData(
                textScaler: TextScaler.linear(2), disableAnimations: true),
            child: child!),
        home: const SplashScreen(),
      ));
      expect(find.text('KidsPhonics'), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
      expect(find.text('GRADE 1 · LEARN · PLAY · LEVEL UP'), findsOneWidget);
      final scene = t.getRect(find.byKey(const ValueKey('loading-scene')));
      expect(scene.width / scene.height, closeTo(941 / 1672, .001));
      expect(scene.left, greaterThanOrEqualTo(0));
      expect(scene.right, lessThanOrEqualTo(size.width));
      expect(scene.bottom, lessThanOrEqualTo(size.height));
      final status = t.getRect(find.byKey(const ValueKey('loading-status')));
      expect(status.top, greaterThan(scene.top + scene.height * .80),
          reason: 'Loading status must stay below the mascots.');
      expect(status.bottom, lessThanOrEqualTo(scene.bottom));
      final art = t.widget<AnimatedScreenArt>(
          find.byKey(const ValueKey('loading-scene')));
      expect(art.frames, loadingScreenFrames);
      expect(art.fit, BoxFit.contain);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 4));
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('letter choices wrap and keep usable targets with large text',
      (t) async {
    await t.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
      child: Padding(
          padding: const EdgeInsets.all(12),
          child: WordChoiceGrid(children: [
            for (final letter in ['A', 'E', 'I', 'O', 'U'])
              ElevatedButton(onPressed: () {}, child: Text(letter)),
          ])),
    ))));
    for (final button in find.byType(ElevatedButton).evaluate()) {
      final rect = t.getRect(find.byWidget(button.widget));
      expect(rect.width, greaterThanOrEqualTo(48));
      expect(rect.height, greaterThanOrEqualTo(48));
      expect(rect.right, lessThanOrEqualTo(320));
    }
    expect(t.getTopLeft(find.text('U')).dy,
        greaterThan(t.getTopLeft(find.text('A')).dy));
    expect(t.takeException(), isNull);
  });
}
