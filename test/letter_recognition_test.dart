import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/letter_recognition_screen.dart';
import 'package:kidsphonics/screens/letter_sounds_screen.dart';
import 'package:kidsphonics/screens/lessons_screen.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'learner_ui_test.dart' show mount, close;
import 'learning_progress_test.dart' show mockProgressAudio;

class _LocalLetterCache extends AudioCache {
  @override
  Future<Uri> fetchToMemory(String fileName) async =>
      Uri.file('${Directory.current.path}/assets/$fileName');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<MethodCall> calls;
  late AudioCache previousCache;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
    calls = [];
    previousCache = AudioCache.instance;
    AudioCache.instance = _LocalLetterCache();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        calls.add(call);
        final id = (call.arguments as Map)['playerId'];
        if (call.method == 'create') {
          messenger.setMockMethodCallHandler(
              MethodChannel('xyz.luan/audioplayers/events/$id'),
              (_) async => null);
        }
        if (call.method == 'setSourceUrl') {
          await messenger.handlePlatformMessage(
            'xyz.luan/audioplayers/events/$id',
            const StandardMethodCodec().encodeSuccessEnvelope(
                {'event': 'audio.onPrepared', 'value': true}),
            (_) {},
          );
        }
        return null;
      },
    );
    TestWidgetsFlutterBinding
            .instance.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  });

  tearDown(() {
    AudioCache.instance = previousCache;
    TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue();
  });

  Finder navigation(String label) => find.widgetWithText(OutlinedButton, label);

  String displayedLetter(WidgetTester t) => t
      .widget<Image>(find.byKey(const ValueKey('recognition-letter')))
      .semanticLabel!;

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(800, 1024),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('letter, sound and bottom controls fit $size, text $scale',
          (t) async {
        await t.binding.setSurfaceSize(size);
        addTearDown(() => t.binding.setSurfaceSize(null));
        late AppProvider p;
        await t.runAsync(() async {
          p = AppProvider();
          await p.ready;
        });
        await t.pumpWidget(ChangeNotifierProvider.value(
          value: p,
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const LetterRecognitionScreen(),
          ),
        ));
        await t.pumpAndSettle();
        final image =
            t.getRect(find.byKey(const ValueKey('recognition-letter')));
        final sound = t.getRect(navigation('Sound'));
        final previous = t.getRect(navigation('Previous'));
        final grid = t.getRect(navigation('A–Z Grid'));
        final next = t.getRect(navigation('Next'));
        expect(image.bottom, lessThan(sound.top));
        expect(sound.bottom, lessThan(previous.top));
        expect(previous.top, grid.top);
        expect(grid.top, next.top);
        expect(previous.right, lessThan(grid.left));
        expect(grid.right, lessThan(next.left));
        expect(next.right, lessThanOrEqualTo(size.width));
        expect(
            [previous.bottom, grid.bottom, next.bottom]
                .reduce((a, b) => a > b ? a : b),
            lessThan(size.height));
        expect(find.byType(AudioButton), findsOneWidget);
        expect(t.widget<AudioButton>(find.byType(AudioButton)).phrase, 'A');
        expect(t.takeException(), isNull);
        await t.tap(navigation('A–Z Grid'));
        await t.pumpAndSettle();
        await t.scrollUntilVisible(
          find.byKey(const ValueKey('pick-letter-Z')),
          180,
          scrollable: find.descendant(
            of: find.byKey(const ValueKey('recognition-grid')),
            matching: find.byType(Scrollable),
          ),
        );
        await t.ensureVisible(find.byKey(const ValueKey('pick-letter-Z')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const ValueKey('pick-letter-Z')));
        await t.pumpAndSettle();
        expect(displayedLetter(t), 'Letter Z');
        expect(t.takeException(), isNull);
        await close(t, p);
      });
    }
  }

  testWidgets('A–Z navigation uses every image and name without scoring',
      (t) async {
    final p = await mount(t, const LetterRecognitionScreen());
    expect(t.widget<OutlinedButton>(navigation('Previous')).onPressed, isNull);
    for (var index = 0; index < 26; index++) {
      final letter = String.fromCharCode(65 + index);
      expect(displayedLetter(t), 'Letter $letter');
      expect(t.widget<AudioButton>(find.byType(AudioButton)).phrase, letter);
      final image =
          t.widget<Image>(find.byKey(const ValueKey('recognition-letter')));
      final asset = (image.image as ResizeImage).imageProvider as AssetImage;
      expect(
          asset.assetName, 'assets/images/letters/${letter.toLowerCase()}.png');
      expect(File(asset.assetName).existsSync(), isTrue);
      expect(
          File('assets/audio/phonics/lesson_audio/letters/'
                  'letter-${letter.toLowerCase()}.mp3')
              .existsSync(),
          isTrue);
      if (index < 25) {
        await t.tap(navigation('Next'));
        await t.pump();
      }
    }
    await t.runAsync(() => Future<void>.delayed(Duration.zero));
    expect(p.viewedLetterCount, 26);
    expect(p.masteredLetterCount, 0);
    expect(p.xp, 0);
    expect(p.getLetterProgress('Z').attempts, 0);
    expect(t.widget<OutlinedButton>(navigation('Next')).onPressed, isNull);
    await t.tap(navigation('Previous'));
    await t.pump();
    expect(displayedLetter(t), 'Letter Y');
    // Navigation does not automatically play speech.
    expect(
        calls.where((c) => c.method == 'setSourceUrl').where(
            (c) => ((c.arguments as Map)['url'] as String).contains('letter-')),
        isEmpty);
    await close(t, p);
  });

  for (final sounds in [false, true]) {
    final mode = sounds ? 'phoneme' : 'name';
    testWidgets('sound plays only the $mode; navigation and exit stop it',
        (t) async {
      final p = await mount(
          t,
          sounds
              ? const LetterSoundsScreen()
              : const LetterRecognitionScreen());
      final folder = sounds ? 'sounds/sound' : 'letters/letter';
      Future<void> playName(String letter) async {
        calls.clear();
        await t.runAsync(() async {
          await t.tap(navigation('Sound'));
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await t.pump();
        final sources = calls
            .where((c) => c.method == 'setSourceUrl')
            .map((c) => (c.arguments as Map)['url'] as String)
            .toList();
        expect(sources.where((s) => s.endsWith('.mp3')),
            [endsWith('/$folder-${letter.toLowerCase()}.mp3')]);
        expect(find.text('Listening…'), findsOneWidget);
      }

      await playName('A');
      await t.tap(navigation('Next'));
      await t.pump();
      await t.runAsync(() => Future<void>.delayed(Duration.zero));
      await t.pump();
      expect(displayedLetter(t), 'Letter B');
      expect(find.textContaining('Audio unavailable'), findsNothing);
      await playName('B');
      final speechId = (calls
          .singleWhere((c) =>
              c.method == 'setSourceUrl' &&
              ((c.arguments as Map)['url'] as String)
                  .endsWith('/$folder-b.mp3'))
          .arguments as Map)['playerId'];
      calls.clear();
      await close(t, p);
      expect(
          calls
              .where((c) => c.method == 'stop')
              .any((c) => (c.arguments as Map)['playerId'] == speechId),
          isTrue);
    });

    testWidgets('voice setting disables $mode while navigation still works',
        (t) async {
      SharedPreferences.setMockInitialValues({'voice': false});
      final p = await mount(
          t,
          sounds
              ? const LetterSoundsScreen()
              : const LetterRecognitionScreen());
      await t.pump();
      expect(t.widget<OutlinedButton>(navigation('Sound')).onPressed, isNull);
      expect(find.text('Audio is turned off.'), findsOneWidget);
      await t.tap(navigation('Next'));
      await t.pump();
      expect(displayedLetter(t), 'Letter B');
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }

  testWidgets('Letter Sounds menu and grid keep the selected phoneme',
      (t) async {
    final p = await mount(t, const LessonsScreen());
    await t.tap(find.text('Letter Sounds A–Z'));
    await t.pump();
    await t.runAsync(() => Future<void>.delayed(Duration.zero));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.byType(LetterSoundsScreen), findsOneWidget);
    expect(t.widget<AudioButton>(find.byType(AudioButton)).phrase,
        'lesson-sound-A');
    await t.tap(navigation('A–Z Grid'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('pick-letter-C')));
    await t.pumpAndSettle();
    expect(displayedLetter(t), 'Letter C');
    expect(t.widget<AudioButton>(find.byType(AudioButton)).phrase,
        'lesson-sound-C');
    await close(t, p);
  });

  testWidgets('Lessons opens Letter Recognition from the supplied logo card',
      (t) async {
    final p = await mount(t, const LessonsScreen());
    await t.tap(find.text('Letter Recognition'));
    await t.pump();
    await t.runAsync(() => Future<void>.delayed(Duration.zero));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.byType(LetterRecognitionScreen), findsOneWidget);
    expect(displayedLetter(t), 'Letter A');
    await close(t, p);
  });
}
