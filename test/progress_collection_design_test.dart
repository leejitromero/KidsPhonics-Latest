import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/progress_screen.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show close;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
    dispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
  });
  setUpAll(() async {
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  Future<AppProvider> open(WidgetTester t, {GlobalKey? boundary}) async {
    SharedPreferences.setMockInitialValues({
      'xp': 950,
      'stars': 94,
      'streakV2': 3,
      'lastPracticeDateV1': '2026-10-07',
      'letterProgressV2': jsonEncode({
        'A': {'letter': 'A', 'attempts': 1, 'correctAnswers': 0},
        for (var code = 66; code <= 75; code++)
          String.fromCharCode(code): {
            'letter': String.fromCharCode(code),
            'viewCount': 1
          },
      }),
      'dailyActivityV1': jsonEncode({
        for (final date in ['2026-10-05', '2026-10-06', '2026-10-07'])
          date: {
            'questionsAnswered': 1,
            'correctAnswers': 0,
            'activitiesCompleted': 0
          },
      }),
    });
    mockProgressAudio();
    late AppProvider p;
    await t.runAsync(() async {
      p = AppProvider(now: () => DateTime(2026, 10, 7, 12));
      await p.ready;
    });
    await t.pumpWidget(ChangeNotifierProvider.value(
        value: p,
        child: MaterialApp(
            home: RepaintBoundary(
                key: boundary, child: const ProgressScreen()))));
    await t.pumpAndSettle();
    return p;
  }

  Future<void> tab(WidgetTester t, int index) async {
    await t.tap(find.byKey(ValueKey('progress-tab-$index')));
    await t.pumpAndSettle();
  }

  testWidgets('collection filters reflect mutually exclusive saved statuses',
      (t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final p = await open(t);
    await tab(t, 1);
    for (final label in [
      'All 26',
      'New (15)',
      'Explored (10)',
      'Practiced (1)',
      'Mastered (0)'
    ]) {
      expect(find.widgetWithText(ChoiceChip, label), findsOneWidget);
    }
    await t.tap(find.widgetWithText(ChoiceChip, 'Practiced (1)'));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('progress-letter-A')), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-letter-B')), findsNothing);
    await t.tap(find.widgetWithText(ChoiceChip, 'Mastered (0)'));
    await t.pumpAndSettle();
    expect(find.text('No letters here yet.'), findsOneWidget);
    await t.tap(find.widgetWithText(ChoiceChip, 'All 26'));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('progress-letter-Z')), findsOneWidget);
    expect(p.xp, 950);
    expect(p.stars, 94);
    await close(t, p);
  });

  testWidgets('treasure shelf and badge details preserve actual rewards',
      (t) async {
    final p = await open(t);
    await tab(t, 2);
    for (final label in ['Level 5', '94 Stars', '950 XP']) {
      expect(find.text(label), findsOneWidget);
    }
    final badgesHeading = find.textContaining('My Badges');
    await t.scrollUntilVisible(badgesHeading, 150,
        scrollable: find.byType(Scrollable).first);
    await t.pumpAndSettle();
    expect(badgesHeading, findsOneWidget);
    final locked = find.byKey(const ValueKey('progress-badge-First Mastery'));
    await t.scrollUntilVisible(locked, 180,
        scrollable: find.byType(Scrollable).first);
    await t.pumpAndSettle();
    await t.tap(locked);
    await t.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Keep exploring!')),
        findsOneWidget);
    await t.tap(find.text('Close'));
    await t.pumpAndSettle();
    final earned = find.byKey(const ValueKey('progress-badge-3-Day Streak'));
    await t.scrollUntilVisible(earned, 180,
        scrollable: find.byType(Scrollable).first);
    await t.pumpAndSettle();
    await t.tap(earned);
    await t.pumpAndSettle();
    expect(
        find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('You earned it!')),
        findsOneWidget);
    await t.tap(find.text('Close'));
    await t.pumpAndSettle();
    expect(p.masteredLetterCount, 0);
    expect(p.xp, 950);
    expect(p.stars, 94);
    expect(t.takeException(), isNull);
    await close(t, p);
  });

  for (final (size, scale) in [
    (const Size(320, 568), 2.0),
    (const Size(800, 1024), 1.3)
  ]) {
    testWidgets('collection and badges fit $size at text scale $scale',
        (t) async {
      await t.binding.setSurfaceSize(size);
      t.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(() {
        t.binding.setSurfaceSize(null);
        t.platformDispatcher.clearTextScaleFactorTestValue();
      });
      final p = await open(t);
      for (final index in [1, 2]) {
        await tab(t, index);
        expect(t.takeException(), isNull);
        final scroll =
            t.state<ScrollableState>(find.byType(Scrollable).first).position;
        scroll.jumpTo(scroll.maxScrollExtent);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      }
      await close(t, p);
    });
  }

  if (const bool.fromEnvironment('CAPTURE_UI')) {
    testWidgets('capture letter collection and badge cards', (t) async {
      await t.binding.setSurfaceSize(const Size(390, 844));
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(() {
        t.binding.setSurfaceSize(null);
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      });
      final boundary = GlobalKey();
      final p = await open(t, boundary: boundary);
      final metrics = <String, double>{};
      for (final (name, index, bottom) in [
        ('journey', 0, false),
        ('letters', 1, false),
        ('rewards', 2, false),
        ('badges', 2, true)
      ]) {
        await tab(t, index);
        metrics[name] = t
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .maxScrollExtent;
        if (bottom) {
          final scroll =
              t.state<ScrollableState>(find.byType(Scrollable).first).position;
          scroll.jumpTo(scroll.maxScrollExtent);
        }
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
          final file = File('build/ui_previews/progress_$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      const label =
          String.fromEnvironment('LAYOUT_LABEL', defaultValue: 'after');
      File('build/ui_previews/progress_metrics_$label.json').writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(metrics));
      await close(t, p);
    });
  }
}
