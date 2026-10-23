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
import 'package:kidsphonics/screens/parent_screen.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show close;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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

  Future<AppProvider> open(WidgetTester t,
      {bool empty = false, GlobalKey? boundary}) async {
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferences.setMockInitialValues({
      'xp': empty ? 0 : 950,
      'stars': empty ? 0 : 94,
      'streakV2': empty ? 0 : 3,
      'lastPracticeDateV1': '2026-10-07',
      'dailyActivityV1': jsonEncode(empty
          ? {}
          : {
              '2026-10-05': {
                'questionsAnswered': 106,
                'correctAnswers': 72,
                'activitiesCompleted': 12
              },
              '2026-10-06': {
                'questionsAnswered': 18,
                'correctAnswers': 14,
                'activitiesCompleted': 1
              },
              '2026-10-07': {
                'questionsAnswered': 12,
                'correctAnswers': 9,
                'activitiesCompleted': 0
              },
              // Old totals must not affect this week's graph or accuracy.
              '2026-09-01': {
                'questionsAnswered': 1000,
                'correctAnswers': 0,
                'activitiesCompleted': 99
              },
            }),
    });
    mockProgressAudio();
    late AppProvider p;
    await t.runAsync(() async {
      p = AppProvider(now: () => DateTime(2026, 10, 7, 12));
      await p.ready;
      await p.parentAuth.setup('2580', '2580');
    });
    await t.pumpWidget(ChangeNotifierProvider.value(
        value: p,
        child: MaterialApp(
            home:
                RepaintBoundary(key: boundary, child: const ParentScreen()))));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('parent-tab-1')));
    await t.pumpAndSettle();
    return p;
  }

  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(390, 844), 1.0),
    (const Size(320, 568), 2.0),
    (const Size(800, 1024), 1.3),
  ]) {
    testWidgets('activity design fits $size at text scale $scale', (t) async {
      await t.binding.setSurfaceSize(size);
      t.platformDispatcher.textScaleFactorTestValue = scale;
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(() {
        t.binding.setSurfaceSize(null);
        t.platformDispatcher.clearTextScaleFactorTestValue();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      });
      final p = await open(t);
      expect(t.takeException(), isNull);
      for (final title in ['Recent Activity', 'Daily Breakdown', 'Rewards']) {
        await t.scrollUntilVisible(find.text(title), 200,
            scrollable: find.byType(Scrollable).first);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: title);
      }
      await close(t, p);
    });
  }

  testWidgets('weekly totals, daily details and rewards use recorded data',
      (t) async {
    final p = await open(t);
    expect(find.text('3-Day Learning Streak'), findsOneWidget);
    for (final number in ['136', '95', '13', '70%']) {
      expect(find.text(number), findsOneWidget);
    }
    final peak = t
        .getSize(find.byKey(const ValueKey('parent-week-bar-2026-10-05')))
        .height;
    final smaller = t
        .getSize(find.byKey(const ValueKey('parent-week-bar-2026-10-06')))
        .height;
    expect(peak, greaterThan(smaller));
    await t.ensureVisible(find.text('Recent Activity'));
    await t.pumpAndSettle();
    await t.tap(find.text('Recent Activity'));
    await t.pumpAndSettle();
    final breakdown = t.getRect(find.text('Daily Breakdown'));
    expect(breakdown.top, greaterThanOrEqualTo(0));
    expect(breakdown.bottom, lessThan(600));
    final day = find.byKey(const ValueKey('parent-day-2026-10-05'));
    await t.ensureVisible(day);
    await t.pumpAndSettle();
    await t
        .tap(find.descendant(of: day, matching: find.byType(ListTile)).first);
    await t.pumpAndSettle();
    expect(
        find.text(
            'Questions Answered: 106\nCorrect Answers: 72\nActivities Completed: 12\nOverall Activity Accuracy: 68%'),
        findsOneWidget);
    await t.scrollUntilVisible(find.text('View All'), 200,
        scrollable: find.byType(Scrollable).first);
    await t.ensureVisible(find.text('View All'));
    await t.pumpAndSettle();
    expect(find.text('950'), findsOneWidget);
    expect(find.text('94'), findsOneWidget);
    expect(find.text('1 / 8 Achievements'), findsOneWidget);
    await t.tap(find.text('View All'));
    await t.pumpAndSettle();
    expect(find.text('3-Day Streak · Unlocked'), findsOneWidget);
    expect(find.text('First Mastery · Locked'), findsOneWidget);
    await t.tap(find.byTooltip('Close achievements'));
    await t.pumpAndSettle();
    expect(p.xp, 950);
    expect(p.stars, 94);
    await close(t, p);
  });

  testWidgets('new learner shows zero bars and no invented accuracy',
      (t) async {
    final p = await open(t, empty: true);
    expect(
        find.text('No learning activity recorded this week.'), findsOneWidget);
    expect(find.text('Not yet'), findsOneWidget);
    expect(find.text('0-Day Learning Streak'), findsOneWidget);
    expect(find.text('0%'), findsNothing);
    expect(find.text('No activity yet'), findsNWidgets(7));
    expect(t.takeException(), isNull);
    await close(t, p);
  });

  if (const bool.fromEnvironment('CAPTURE_UI')) {
    testWidgets('capture activity design', (t) async {
      await t.binding.setSurfaceSize(const Size(390, 844));
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(() {
        t.binding.setSurfaceSize(null);
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      });
      final boundary = GlobalKey();
      final p = await open(t, boundary: boundary);
      await t.runAsync(() async {
        await Future.wait(t
            .widgetList<Image>(find.byType(Image))
            .map((w) => precacheImage(w.image, boundary.currentContext!)));
      });
      final metrics = <String, double>{};
      for (final (name, index) in [
        ('overview', 0),
        ('activity', 1),
        ('settings', 2)
      ]) {
        await t.tap(find.byKey(ValueKey('parent-tab-$index')));
        await t.pumpAndSettle();
        metrics[name] = t
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .maxScrollExtent;
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
          final file = File('build/ui_previews/parent_compact_$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      const label =
          String.fromEnvironment('LAYOUT_LABEL', defaultValue: 'after');
      File('build/ui_previews/parent_metrics_$label.json').writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(metrics));
      await t.tap(find.byKey(const ValueKey('parent-tab-1')));
      await t.pumpAndSettle();
      for (final (name, title) in [
        ('weekly', null),
        ('daily', 'Daily Breakdown'),
        ('rewards', 'Rewards')
      ]) {
        if (title != null) {
          await t.ensureVisible(find.text(title));
        }
        await t.pumpAndSettle();
        await t.runAsync(() async {
          final image = await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/ui_previews/parent_activity_$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await close(t, p);
    });
  }
}
