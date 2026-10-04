import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/main.dart';
import 'package:kidsphonics/widgets/word_game_layout.dart';

void main() {
  testWidgets('original loading screen fits a small phone with enlarged text',
      (t) async {
    await t.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(MaterialApp(
      builder: (_, child) => MediaQuery(
          data: const MediaQueryData(
              textScaler: TextScaler.linear(2), disableAnimations: true),
          child: child!),
      home: const SplashScreen(),
    ));
    expect(find.text('KidsPhonics'), findsOneWidget);
    expect(find.text('Loading your adventure...'), findsOneWidget);
    expect(find.text('GRADE 1 · LEARN · PLAY · LEVEL UP'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.drag(find.byType(SingleChildScrollView), const Offset(0, -400));
    await t.pump();
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 4));
    expect(t.takeException(), isNull);
  });

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
