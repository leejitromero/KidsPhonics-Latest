import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/letter_data.dart';
import 'package:kidsphonics/data/lesson_example_data.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/widgets/lesson_picture.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/letter_sounds_screen.dart';
import 'learning_progress_test.dart' show mockProgressAudio;

void main() {
  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('lesson audio shares one row at width $width, text $scale',
          (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        late AppProvider p;
        await tester.runAsync(() async {
          p = AppProvider();
          await p.ready;
        });
        await tester.pumpWidget(ChangeNotifierProvider.value(
          value: p,
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const LetterSoundsScreen(),
          ),
        ));
        await tester.pump();
        final bounds = ['letter-A', 'sound-A', 'word-A']
            .map((key) => tester.getRect(find.byKey(ValueKey(key))))
            .toList();
        expect(bounds[0].top, bounds[1].top);
        expect(bounds[1].top, bounds[2].top);
        expect(bounds[0].right, lessThan(bounds[1].left));
        expect(bounds[1].right, lessThan(bounds[2].left));
        expect(bounds[2].right, lessThanOrEqualTo(width));
        final navigation = ['Previous', 'A–Z Grid', 'Next →']
            .map((label) =>
                tester.getRect(find.widgetWithText(OutlinedButton, label)))
            .toList();
        expect(navigation[0].top, navigation[1].top);
        expect(navigation[1].top, navigation[2].top);
        expect(navigation[2].right, lessThanOrEqualTo(width));
        expect(tester.getSize(find.byType(LessonPicture)).height,
            lessThanOrEqualTo(170));
        if (scale == 1) expect(bounds.last.bottom, lessThan(800));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        p.dispose();
      });
    }
  }
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
      'open every A-Z lesson: consistent text and correctly named audio buttons',
      (tester) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late AppProvider p;
    await tester.runAsync(() async {
      p = AppProvider();
      await p.ready;
    });
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: p, child: const MaterialApp(home: LetterSoundsScreen())));
    for (final letter in allLetters) {
      await tester.pump();
      expect(find.text('${letter.letter} ${letter.lowercase}'), findsOneWidget);
      expect(find.text(letter.sound), findsOneWidget);
      final example =
          lessonExamples.firstWhere((e) => e.letter == letter.letter);
      expect(find.text(example.example), findsOneWidget);
      expect(find.text('LETTER'), findsOneWidget);
      expect(find.text('WORD'), findsOneWidget);
      expect(find.text('SOUND'), findsOneWidget);
      final buttons =
          tester.widgetList<AudioButton>(find.byType(AudioButton)).toList();
      expect(buttons.map((b) => b.phrase), [
        example.letterAudioKey,
        example.soundAudioKey,
        example.wordAudioKey
      ]);
      expect(p.getLetterProgress(letter.letter).mastered, isFalse);
      expect(p.getLetterProgress(letter.letter).attempts, 0);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Next →'));
      await tester.tap(find.text('Next →'));
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pumpWidget(const SizedBox());
    p.dispose();
  });

  testWidgets('vowels view clearly identifies its short-vowel scope',
      (tester) async {
    late AppProvider p;
    await tester.runAsync(() async {
      p = AppProvider();
      await p.ready;
    });
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: p,
        child: const MaterialApp(home: LetterSoundsScreen(vowelsOnly: true))));
    expect(find.text('Short Vowel Sounds'), findsOneWidget);
    expect(find.text('Practice This Letter'), findsNothing);
    final navigation = ['Previous', 'Vowel Grid', 'Next →']
        .map((label) =>
            tester.getRect(find.widgetWithText(OutlinedButton, label)))
        .toList();
    expect(navigation[0].top, navigation[1].top);
    expect(navigation[1].top, navigation[2].top);
    expect(find.textContaining('Ice Cream'), findsNothing);
    expect(find.text('A is for Ant.'), findsOneWidget);
    expect(find.text('SOUND'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    p.dispose();
  });
}
