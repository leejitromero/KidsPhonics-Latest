import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/learning_progress.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/progress_screen.dart';
import 'package:kidsphonics/widgets/parent_garden_overview.dart';
import 'package:kidsphonics/widgets/progress_reference_design.dart';
import 'learning_progress_test.dart' show mockProgressAudio;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'letterProgressV2': jsonEncode({
        'A': {
          'letter': 'A',
          'viewCount': 1,
          'nameListens': 2,
          'attempts': 5,
          'correctAnswers': 5,
          'completedAssessments': 1,
          'bestAssessmentScore': 5,
          'mastered': true
        },
      }),
    });
    mockProgressAudio();
  });
  test(
      'new Quick Check persists and replaces legacy summaries without losing exposure',
      () async {
    final p = AppProvider(now: () => DateTime(2026, 10, 9, 17));
    await p.ready;
    expect(p.quickCheckLetter('A').mastered, isFalse);
    expect(p.quickCheckLetter('A').completedAssessments, 0);
    expect(p.quickCheckLetter('A').nameListens, 2);
    expect(p.quickCheckLetter('A').status, LearningStatus.viewed);
    await p.completeAdventure('B', [true, true, true, true, true], 'new-b');
    final masteredAt = p.adventureProgress('B').masteredAt;
    expect(masteredAt, '2026-10-09T17:00:00.000');
    await p.completeAdventure(
        'B', [false, false, true, true, false], 'retry-b');
    final restored = AppProvider();
    await restored.ready;
    expect(restored.overallMasteredCount, 1);
    expect(restored.adventureAssessments, 2);
    expect(restored.quickCheckLetter('B').bestAssessmentScore, 5);
    expect(restored.quickCheckLetter('B').correctAnswers, 2);
    expect(restored.quickCheckLetter('B').mastered, isTrue);
    expect(restored.quickCheckLetter('B').masteredAt, masteredAt);
    expect(restored.quickCheckLetter('A').nameListens, 2);
    expect(restored.quickCheckAchievements.first.unlocked, isTrue);
    expect(restored.masteredLetters, {'A'}); // Existing storage remains intact.
    p.dispose();
    restored.dispose();
  });

  for (final scale in [1.0, 1.8]) {
    testWidgets(
        'Progress and Parents show persisted current Quick Check at scale $scale',
        (t) async {
      await t.binding.setSurfaceSize(const Size(390, 844));
      t.platformDispatcher.textScaleFactorTestValue = scale;
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(() {
        t.binding.setSurfaceSize(null);
        t.platformDispatcher.clearTextScaleFactorTestValue();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      });
      late AppProvider p;
      await t.runAsync(() async {
        final original = AppProvider();
        await original.ready;
        await original.completeAdventure('B', List.filled(5, true), 'widget-b');
        original.dispose();
        p = AppProvider();
        await p.ready;
      });
      for (final screen in [
        const ProgressScreen(),
        const Scaffold(
            body: SingleChildScrollView(child: ParentGardenOverview()))
      ]) {
        if (screen is! ProgressScreen) {
          await t.runAsync(() => p.parentAuth.setup('2580', '2580'));
        }
        final boundary = GlobalKey();
        await t.pumpWidget(RepaintBoundary(
            key: boundary,
            child: ChangeNotifierProvider.value(
                value: p, child: MaterialApp(home: screen))));
        await t.pumpAndSettle();
        if (screen is ProgressScreen) {
          final panel = t.widget<ProgressSkillRow>(
              find.byKey(const ValueKey('journey-skill-letters')));
          expect(panel.current, 1);
          expect(p.adventureAssessments, 1);
        } else {
          expect(find.byType(ProgressSkillRow), findsNothing);
          expect(find.text('Child Learning Summary'), findsNothing);
          expect(find.text('Letter Status A–Z'), findsNothing);
          expect(find.text('This Week at a Glance'), findsOneWidget);
          expect(find.text('Practice Letter A'), findsOneWidget);
        }
        if (const bool.fromEnvironment('CAPTURE_UI') && scale == 1) {
          await t.runAsync(() async {
            await (FontLoader('Nunito')
                  ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
                  ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf')))
                .load();
            await (FontLoader('MaterialIcons')
                  ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
                .load();
            await Future.wait(t
                .widgetList<Image>(find.byType(Image))
                .map((w) => precacheImage(w.image, boundary.currentContext!)));
          });
          await t.pumpAndSettle();
          await t.runAsync(() async {
            final image = await (boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File(
                'build/ui_previews/current_${screen is ProgressScreen ? 'progress' : 'parent'}.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }

        expect(find.text('Earlier Quick Check results remain below.'),
            findsNothing);
        expect(find.text('Letter & Word Quick Checks'), findsNothing);
        if (screen is ProgressScreen) {
          await t.tap(find.byKey(const ValueKey('progress-tab-1')));
          await t.pumpAndSettle();
          await t.scrollUntilVisible(
              find.widgetWithText(ChoiceChip, 'Mastered (1)'), 150,
              scrollable: find.byType(Scrollable).first);
          await t.pumpAndSettle();
          expect(
              find.widgetWithText(ChoiceChip, 'Mastered (1)'), findsOneWidget);
          await t.tap(find.widgetWithText(ChoiceChip, 'Mastered (1)'));
          await t.pumpAndSettle();
          await t.scrollUntilVisible(
              find.byKey(const ValueKey('progress-letter-B')), 150,
              scrollable: find.byType(Scrollable).first);
          await t.pumpAndSettle();
          expect(
              find.byKey(const ValueKey('progress-letter-B')), findsOneWidget);
          expect(find.byKey(const ValueKey('progress-letter-A')), findsNothing);
        } else {
          expect(p.parentAuth.isAuthenticated, isTrue);
          await t.ensureVisible(
              find.byKey(const ValueKey('parent-open-progress')));
          await t.tap(find.byKey(const ValueKey('parent-open-progress')));
          await t.pumpAndSettle();
          expect(p.parentAuth.isAuthenticated, isFalse);
          expect(find.byType(ProgressScreen), findsOneWidget);
          expect(
              t
                  .widget<ProgressSkillRow>(
                      find.byKey(const ValueKey('journey-skill-letters')))
                  .current,
              1);
          Navigator.of(t.element(find.byType(ProgressScreen))).pop();
          await t.pumpAndSettle();
        }
        expect(t.takeException(), isNull);
      }
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      p.dispose();
    });
  }
}
