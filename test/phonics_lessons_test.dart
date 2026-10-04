import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/letter_data.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/letter_sounds_screen.dart';
import 'learning_progress_test.dart' show mockProgressAudio;

void main() {
  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('letter sounds layout fits width $width, text $scale',
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
        expect(find.byType(AudioButton), findsOneWidget);
        expect(tester.widget<AudioButton>(find.byType(AudioButton)).phrase,
            'lesson-sound-A');
        final sound = tester.getRect(find.byType(AudioButton));
        final image =
            tester.getRect(find.byKey(const ValueKey('recognition-letter')));
        expect(image.bottom, lessThan(sound.top));
        final navigation = ['Previous', 'A–Z Grid', 'Next']
            .map((label) =>
                tester.getRect(find.widgetWithText(OutlinedButton, label)))
            .toList();
        expect(navigation[0].top, navigation[1].top);
        expect(navigation[1].top, navigation[2].top);
        expect(navigation[2].right, lessThanOrEqualTo(width));
        expect(sound.bottom, lessThan(navigation.first.top));
        expect(navigation.last.bottom, lessThan(800));
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
      'every A-Z letter uses its plain image and isolated sound recording',
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
      final image = tester
          .widget<Image>(find.byKey(const ValueKey('recognition-letter')));
      expect(image.semanticLabel, 'Letter ${letter.letter}');
      final asset = (image.image as ResizeImage).imageProvider as AssetImage;
      expect(asset.assetName, 'assets/images/letters/${letter.lowercase}.png');
      expect(find.text('Sound'), findsOneWidget);
      expect(find.text('LETTER'), findsNothing);
      expect(find.text('WORD'), findsNothing);
      expect(find.text('Practice This Letter'), findsNothing);
      final buttons =
          tester.widgetList<AudioButton>(find.byType(AudioButton)).toList();
      expect(buttons.map((b) => b.phrase), ['lesson-sound-${letter.letter}']);
      final recording =
          PhonicsAudioService.assetForPhrase(buttons.single.phrase);
      expect(recording,
          'audio/phonics/lesson_audio/sounds/sound-${letter.lowercase}.mp3');
      expect(File('assets/$recording').existsSync(), isTrue);
      expect(p.getLetterProgress(letter.letter).mastered, isFalse);
      expect(p.getLetterProgress(letter.letter).attempts, 0);
      expect(tester.takeException(), isNull);
      if (letter.letter != 'Z') {
        await tester.tap(find.text('Next'));
        await tester.pump();
      }
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
    final navigation = ['Previous', 'Next']
        .map((label) =>
            tester.getRect(find.widgetWithText(OutlinedButton, label)))
        .toList();
    expect(navigation[0].top, navigation[1].top);
    expect(find.textContaining('Ice Cream'), findsNothing);
    expect(find.text('A is for Ant.'), findsNothing);
    expect(find.text('Meet the Vowels!'), findsOneWidget);
    expect(find.byKey(const ValueKey('vowel-tab-A')), findsOneWidget);
    expect(tester.widget<AudioButton>(find.byType(AudioButton)).phrase,
        'lesson-sound-A');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    p.dispose();
  });
}
