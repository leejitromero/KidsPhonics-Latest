import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/letter_data.dart';
import 'package:kidsphonics/models/letter_adventure.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/letter_mastery_check_screen.dart';
import 'package:kidsphonics/widgets/quick_check_design.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'letter_mastery_check_test.dart'
    show AdventureTestAudio, press, hear, flushAdventure;

void main() {
  testWidgets('header shows the saved character and tracks profile changes',
      (t) async {
    mockProgressAudio();
    SharedPreferences.setMockInitialValues({
      'studentCharacter': 'girl',
      'studentName': 'Mia',
      'voice': false,
    });
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    late AppProvider p;
    await t.runAsync(() async {
      p = AppProvider();
      await p.ready;
    });
    await t.pumpWidget(ChangeNotifierProvider.value(
        value: p,
        child: MaterialApp(
            home: LetterMasteryCheckScreen(
                letter: letterContent('A'), audio: AdventureTestAudio()))));
    await flushAdventure(t);
    expect(
        find.byKey(const ValueKey('quick-check-profile-girl')), findsOneWidget);
    expect(find.byKey(const ValueKey('quick-check-profile-boy')), findsNothing);
    expect(t.getRect(find.byKey(const ValueKey('quick-check-profile'))).left,
        greaterThan(t.getRect(find.text('Quick Check')).right));
    await t.runAsync(() => p.setStudentCharacter('boy', 'Mia'));
    await t.pump();
    expect(
        find.byKey(const ValueKey('quick-check-profile-boy')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('quick-check-profile-girl')), findsNothing);
    expect(find.byType(Scrollable), findsNothing);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    p.dispose();
  });

  testWidgets(
      'Back leaves intro directly and confirms before discarding a task',
      (t) async {
    mockProgressAudio();
    SharedPreferences.setMockInitialValues({});
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    late AppProvider p;
    await t.runAsync(() async {
      p = AppProvider();
      await p.ready;
    });
    final audio = AdventureTestAudio();
    await t.pumpWidget(ChangeNotifierProvider.value(
        value: p,
        child: MaterialApp(
          home: Builder(
              builder: (context) => Scaffold(
                  body: Center(
                      child: FilledButton(
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (_) => LetterMasteryCheckScreen(
                                      letter: letterContent('A'),
                                      audio: audio))),
                          child: const Text('Open check'))))),
        )));
    await press(t, find.text('Open check'));
    await t.pumpAndSettle();
    await press(t, find.byTooltip('Back'));
    await t.pumpAndSettle();
    expect(find.text('Open check'), findsOneWidget);
    expect(find.byKey(const ValueKey('game-leave-dialog')), findsNothing);
    await press(t, find.text('Open check'));
    await t.pumpAndSettle();
    await press(t, find.byKey(const ValueKey('start-adventure')));
    await press(t, find.byTooltip('Back'));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('game-leave-dialog')), findsOneWidget);
    await press(t, find.byKey(const ValueKey('leave-cancel')));
    await t.pumpAndSettle();
    expect(find.byType(QuickProgress), findsOneWidget);
    await press(t, find.byTooltip('Back'));
    await t.pumpAndSettle();
    await press(t, find.byKey(const ValueKey('leave-confirm')));
    await t.pumpAndSettle();
    expect(find.text('Open check'), findsOneWidget);
    expect(p.adventureProgress('A').completed, 0);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    p.dispose();
  });
  for (final scenario in [
    (size: const Size(320, 568), scale: 1.0),
    (size: const Size(390, 844), scale: 1.0),
    (size: const Size(768, 1024), scale: 1.0),
    (size: const Size(800, 600), scale: 1.0),
    (size: const Size(320, 568), scale: 1.8),
  ]) {
    testWidgets(
        'illustrated quick check fits ${scenario.size}, text ${scenario.scale}',
        (t) async {
      mockProgressAudio();
      SharedPreferences.setMockInitialValues({});
      t.view.physicalSize = scenario.size;
      t.view.devicePixelRatio = 1;
      t.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(() {
        t.view.resetPhysicalSize();
        t.view.resetDevicePixelRatio();
        t.view.resetPadding();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      });
      late AppProvider p;
      await t.runAsync(() async {
        p = AppProvider();
        await p.ready;
        await (FontLoader('Nunito')
              ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
              ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf')))
            .load();
        await (FontLoader('MaterialIcons')
              ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
            .load();
      });
      final audio = AdventureTestAudio();
      final boundary = GlobalKey();
      await t.pumpWidget(ChangeNotifierProvider.value(
          value: p,
          child: RepaintBoundary(
              key: boundary,
              child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  builder: (context, child) => MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                          textScaler: TextScaler.linear(scenario.scale)),
                      child: child!),
                  home: LetterMasteryCheckScreen(
                      letter: letterContent('C'), audio: audio)))));
      await t.pump();
      Future<void> capture(String name) async {
        expect(t.takeException(), isNull);
        expect(find.byType(Scrollable), findsNothing);
        if (find.byType(QuickInstruction).evaluate().isNotEmpty) {
          expect(
              t
                  .getRect(
                      find.byKey(const ValueKey('adventure-progress-stars')))
                  .bottom,
              lessThanOrEqualTo(t.getRect(find.byType(QuickInstruction)).top),
              reason: '$name: challenge progress stays above the instructions');
        }
        final safeScreen = Offset.zero & scenario.size;
        for (final element in find
            .byWidgetPredicate((widget) =>
                widget is ElevatedButton ||
                widget is FilledButton ||
                widget is TextButton)
            .evaluate()) {
          final button =
              find.byElementPredicate((other) => identical(other, element));
          final rect = t.getRect(button);
          expect(rect.left, greaterThanOrEqualTo(safeScreen.left));
          expect(rect.top, greaterThanOrEqualTo(safeScreen.top));
          expect(rect.right, lessThanOrEqualTo(safeScreen.right));
          expect(rect.bottom, lessThanOrEqualTo(safeScreen.bottom));
          expect(rect.width, greaterThanOrEqualTo(48 - .000001),
              reason: '$name: ${element.widget.key}');
          expect(rect.height, greaterThanOrEqualTo(48 - .000001),
              reason: '$name: ${element.widget.key}');
          // Choices stay compact even when a tablet has spare space.
          final key = element.widget.key;
          if (key is ValueKey<String> &&
              (key.value.startsWith('adventure-option-') ||
                  key.value.startsWith('hunt-'))) {
            expect(rect.width, lessThanOrEqualTo(180), reason: '$name: $key');
            expect(rect.height, lessThanOrEqualTo(112), reason: '$name: $key');
          }
        }
        if (!const bool.fromEnvironment('CAPTURE_UI') ||
            scenario.size.width != 390) {
          return;
        }
        await t.pumpAndSettle();
        await t.runAsync(() async {
          await Future.wait(t
              .widgetList<Image>(find.byType(Image))
              .map((w) => precacheImage(w.image, boundary.currentContext!)));
        });
        await t.pumpAndSettle();
        await t.runAsync(() async {
          final image = await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/ui_previews/quick_check/$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await capture('intro');
      await press(t, find.byKey(const ValueKey('start-adventure')));
      expect(t.widget<QuickProgress>(find.byType(QuickProgress)).completed, 0);
      await capture('matching');
      // Wrong answers still count as answered; stars do not expose correctness.
      final wrong = t
          .widgetList<ElevatedButton>(find.byType(ElevatedButton))
          .firstWhere((w) =>
              w.key is ValueKey<String> &&
              w.key != const ValueKey('adventure-option-c'));
      await press(t, find.byKey(wrong.key!));
      await capture('matching_answered');
      expect(t.widget<QuickProgress>(find.byType(QuickProgress)).completed, 1);
      await press(t, find.text('Next Challenge'));
      await capture('sounds');
      await hear(t, audio, 'lesson-sound-C');
      await press(t, find.byKey(const ValueKey('adventure-option-C')));
      await capture('sounds_answered');
      await press(t, find.text('Next Challenge'));
      await capture('spelling');
      await hear(t, audio, adventureWordKey('Cat'));
      await press(t, find.byKey(const ValueKey('adventure-option-C')));
      await capture('spelling_answered');
      await press(t, find.text('Next Challenge'));
      await capture('pictures');
      // The speaker inside a picture card previews audio without choosing it
      // or unlocking the answer before the requested sound has been heard.
      await hear(t, audio, adventureWordKey('Cow'));
      expect(t.widget<QuickProgress>(find.byType(QuickProgress)).completed, 3);
      expect(
          t
              .widget<ElevatedButton>(
                  find.byKey(const ValueKey('adventure-option-Cow')))
              .onPressed,
          isNull);
      await hear(t, audio, 'lesson-sound-C');
      await press(t, find.byKey(const ValueKey('adventure-option-Cow')));
      await capture('pictures_answered');
      await press(t, find.text('Next Challenge'));
      await capture('hunt');
      expect(t.widget<QuickProgress>(find.byType(QuickProgress)).completed, 4);
      for (var i = 0; i < 12; i++) {
        final button = t.widget<FilledButton>(find.byKey(ValueKey('hunt-$i')));
        if ((button.child! as Text).data!.toUpperCase() == 'C') {
          await press(t, find.byKey(ValueKey('hunt-$i')));
        }
      }
      expect(t.widget<QuickProgress>(find.byType(QuickProgress)).completed, 5);
      await capture('hunt_answered');
      await press(t, find.text('See Result'));
      expect(find.text('Score: 4 / 5'), findsOneWidget);
      await capture('result');
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await flushAdventure(t);
      p.dispose();
    });
  }
}
