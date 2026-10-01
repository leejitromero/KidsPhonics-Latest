import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/learning_progress.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/tricky_letters_screen.dart';
import 'package:kidsphonics/screens/letter_mastery_check_screen.dart';
import 'learning_progress_test.dart' show mockProgressAudio;

void main() {
  setUpAll(() async {
    final fonts = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'));
    await fonts.load();
  });
  for (final size in [const Size(320, 568), const Size(390, 844)]) {
    testWidgets('Practice picks fit $size and open the selected letter',
        (tester) async {
      mockProgressAudio();
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue();
      });
      SharedPreferences.setMockInitialValues({
        'letterProgressV2': jsonEncode({
          for (final letter in ['B', 'D', 'P'])
            letter:
                LetterProgress(letter: letter, attempts: 2, correctAnswers: 1)
                    .toJson(),
        })
      });
      late AppProvider p;
      await tester.runAsync(() async {
        p = AppProvider();
        await p.ready;
      });
      await tester.pumpWidget(ChangeNotifierProvider.value(
          value: p, child: const MaterialApp(home: TrickyLettersScreen())));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final state
          in tester.stateList<ScrollableState>(find.byType(Scrollable))) {
        expect(state.position.maxScrollExtent, 0);
      }
      expect(find.text('Start here • 5 questions'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tricky-letter-D')));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<LetterMasteryCheckScreen>(
                  find.byType(LetterMasteryCheckScreen))
              .letter
              .letter,
          'D');
      await tester.pumpWidget(const SizedBox());
      p.dispose();
    });
  }
}
