import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/learning_progress.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/parent_screen.dart';
import 'package:kidsphonics/screens/progress_screen.dart';
import 'package:kidsphonics/screens/letter_mastery_check_screen.dart';
import 'package:kidsphonics/widgets/dashboard_widgets.dart';
import 'package:kidsphonics/widgets/learning_progress_widgets.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'package:kidsphonics/widgets/parent_weekly_summary.dart';
import 'package:kidsphonics/screens/tricky_letters_screen.dart';

void main() {
  setUp(() {
    mockProgressAudio();
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  Future<AppProvider> make(WidgetTester tester,
      {bool parent = false, bool empty = false}) async {
    SharedPreferences.setMockInitialValues({
      'letterProgressV2': jsonEncode(empty
          ? {}
          : {
              'A': const LetterProgress(
                      letter: 'A',
                      attempts: 5,
                      correctAnswers: 4,
                      completedAssessments: 1,
                      bestAssessmentScore: 4,
                      mastered: true,
                      masteredAt: '2026-09-23T12:00:00.000')
                  .toJson(),
              'B': const LetterProgress(
                      letter: 'B',
                      attempts: 6,
                      correctAnswers: 4,
                      completedAssessments: 1,
                      bestAssessmentScore: 3)
                  .toJson(),
              'C': const LetterProgress(letter: 'C', viewCount: 1).toJson(),
            }),
      'dailyActivityV1': jsonEncode(empty
          ? {}
          : {
              '2026-09-23': const DailyActivity(
                      questionsAnswered: 11,
                      correctAnswers: 8,
                      activitiesCompleted: 2)
                  .toJson(),
              '2026-09-01':
                  const DailyActivity(questionsAnswered: 100, correctAnswers: 0)
                      .toJson(),
            }),
      'screenTimeDateV2': '2026-09-23',
      'screenTimeUsedSecondsV2': 1080,
      'screenTimeLimitEnabledV2': true,
      'screenTimeLimitMinutesV2': 30,
      'extraTimeSecondsTodayV1': 900,
    });
    late AppProvider p;
    await tester.runAsync(() async {
      p = AppProvider(now: () => DateTime(2026, 9, 23, 12));
      await p.ready;
      if (parent) {
        await p.parentAuth.setup('2580', '2580');
        await p.screenTime.save();
      }
    });
    return p;
  }

  Widget app(AppProvider p, Widget child, {double scale = 1}) =>
      ChangeNotifierProvider.value(
          value: p,
          child: MaterialApp(
              theme: ThemeData.dark(),
              builder: (_, child) => MediaQuery(
                  data: MediaQueryData(
                      textScaler: TextScaler.linear(scale),
                      disableAnimations: true),
                  child: child!),
              home: child));
  Future<void> finish(WidgetTester tester, AppProvider p) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    p.dispose();
  }

  testWidgets(
      'parent weekly snapshot uses weekly activity and real mastery dates',
      (tester) async {
    final p = await make(tester);
    await tester.pumpWidget(app(
        p,
        const Scaffold(
            body: SingleChildScrollView(child: ParentWeeklySummary()))));
    await tester.pumpAndSettle();
    expect(find.text('1 of 7 days with learning activity'), findsOneWidget);
    expect(find.text('New letters mastered: A'), findsOneWidget);
    expect(find.text('11'), findsOneWidget);
    expect(find.text('73%'), findsOneWidget);
    expect(find.text('Practice letter B with a short Quick Check.'),
        findsOneWidget);
    await finish(tester, p);
  });
  testWidgets('parent weekly snapshot has an honest empty state',
      (tester) async {
    final p = await make(tester, empty: true);
    await tester.pumpWidget(app(
        p,
        const Scaffold(
            body: SingleChildScrollView(child: ParentWeeklySummary()))));
    await tester.pumpAndSettle();
    expect(find.text('A fresh week of little discoveries awaits.'),
        findsOneWidget);
    expect(find.text('Not yet'), findsOneWidget);
    expect(find.text('Explore letter A in Letter Sounds.'), findsOneWidget);
    await finish(tester, p);
  });
  testWidgets(
      'tricky letters excludes mastered and unattempted letters and opens practice',
      (tester) async {
    final p = await make(tester);
    await tester.pumpWidget(app(p, const TrickyLettersScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tricky-letter-B')), findsOneWidget);
    expect(find.byKey(const ValueKey('tricky-letter-A')), findsNothing);
    expect(find.byKey(const ValueKey('tricky-letter-C')), findsNothing);
    final before = p.getLetterProgress('B').attempts;
    await tester.ensureVisible(find.text('Practice B'));
    await tester.tap(find.text('Practice B'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<LetterMasteryCheckScreen>(
                find.byType(LetterMasteryCheckScreen))
            .letter
            .letter,
        'B');
    expect(p.getLetterProgress('B').attempts, before);
    await finish(tester, p);
  });
  testWidgets('tricky letters does not invent weak letters for a new learner',
      (tester) async {
    final p = await make(tester, empty: true);
    await tester.pumpWidget(app(p, const TrickyLettersScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Explore Letter Sounds'), findsOneWidget);
    expect(find.text('Choose one little challenge'), findsNothing);
    await finish(tester, p);
  });
  testWidgets('progress tabs filter letters and open the selected practice',
      (tester) async {
    final p = await make(tester);
    await tester.pumpWidget(app(p, const ProgressScreen()));
    await tester.pumpAndSettle();
    expect(find.text('1 / 26'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('1 / 5'), 180,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('1 / 5'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('progress-tab-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Mastered (1)'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('progress-letter-B')), findsNothing);
    final letter = find.byKey(const ValueKey('progress-letter-A'));
    await tester.ensureVisible(letter);
    await tester.tap(letter);
    await tester.pumpAndSettle();
    expect(find.text('4 / 5'), findsNWidgets(2));
    expect(find.text('80%'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('progress-practice-letter')));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<LetterMasteryCheckScreen>(
                find.byType(LetterMasteryCheckScreen))
            .letter
            .letter,
        'A');
    expect(p.getLetterProgress('A').attempts, 5);
    await finish(tester, p);
  });

  testWidgets('all progress tabs fit small screens and enlarged text',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final p = await make(tester, empty: true);
    await tester.pumpWidget(app(p, const ProgressScreen(), scale: 1.6));
    for (var index = 0; index < 3; index++) {
      await tester.tap(find.byKey(ValueKey('progress-tab-$index')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final scrollable =
          tester.state<ScrollableState>(find.byType(Scrollable).first);
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.byKey(const ValueKey('progress-tab-1')));
    await tester.pumpAndSettle();
    final filter = find.widgetWithText(ChoiceChip, 'Mastered (0)');
    await tester.ensureVisible(filter);
    await tester.pumpAndSettle();
    await tester.tap(filter);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('No letters here yet.'), 180,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('No letters here yet.'), findsOneWidget);
    expect(p.xp, 0);
    await finish(tester, p);
  });

  testWidgets(
      'letter details distinguish empty, practiced and mastered without invalid values',
      (tester) async {
    final p = await make(tester);
    await tester.pumpWidget(app(
        p,
        const Scaffold(
            body: SingleChildScrollView(child: LetterProgressGrid()))));
    await tester.tap(find.byKey(const ValueKey('letter-status-B')));
    await tester.pumpAndSettle();
    expect(find.text('Status: Practiced'), findsOneWidget);
    expect(find.text('Letter Practice Accuracy: 67%'), findsOneWidget);
    expect(find.text('Best Quick Check: 3 / 5'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('letter-status-C')));
    await tester.pumpAndSettle();
    expect(
        find.text('Letter Practice Accuracy: No attempts yet'), findsOneWidget);
    expect(find.text('Best Quick Check: Not taken yet'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('letter-status-A')));
    await tester.pumpAndSettle();
    expect(find.text('Status: Mastered'), findsOneWidget);
    expect(find.textContaining('Mastered: Wednesday, September 23, 2026'),
        findsOneWidget);
    await finish(tester, p);
  });
  testWidgets(
      'weekly chart accuracy is weekly, never lifetime; recent history is real',
      (tester) async {
    final p = await make(tester);
    await tester.pumpWidget(app(
        p,
        const Scaffold(
            body: SingleChildScrollView(
                child: Column(children: [
          WeeklyActivityChart(),
          RecentLearningActivity(),
        ])))));
    expect(find.text('Overall Activity Accuracy: 73%'), findsOneWidget);
    expect(find.text('Questions Answered: 11'), findsOneWidget);
    expect(find.text('Correct Answers: 8'), findsOneWidget);
    expect(find.text('Activities Completed: 2'), findsOneWidget);
    await tester.tap(find.text('Recent Activity'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Today\n11 questions · 2 activities'),
        findsOneWidget);
    expect(find.textContaining('100 questions'), findsNothing);
    await finish(tester, p);
  });
  testWidgets(
      'screen-time summary uses actual configured and extra allowance and bypass',
      (tester) async {
    final p = await make(tester, parent: true);
    await tester
        .pumpWidget(app(p, const Scaffold(body: ParentScreenTimeSummary())));
    expect(find.text('18 / 45 minutes allowed today'), findsOneWidget);
    expect(find.text('27 minutes remaining'), findsOneWidget);
    expect(find.text('Configured Daily Limit: 30 minutes'), findsOneWidget);
    expect(find.text('Extra Time Today: 15 minutes'), findsOneWidget);
    await tester.runAsync(p.screenTime.bypassLimitForToday);
    await tester.pump();
    expect(find.text('Limit disabled for today'), findsOneWidget);
    expect(find.text('18 minutes used today'), findsOneWidget);
    await finish(tester, p);
  });
  testWidgets(
      'Needs Practice limits to five and View All shows remaining real letters',
      (tester) async {
    final p = await make(tester, empty: true);
    await tester.runAsync(() async {
      for (final letter in 'ABCDEFG'.split('')) {
        await p.recordLetterPractice(letter, false);
      }
    });
    await tester.pumpWidget(app(p,
        const Scaffold(body: SingleChildScrollView(child: NeedsPractice()))));
    expect(find.textContaining('E · 0 correct / 1 attempts'), findsOneWidget);
    expect(find.textContaining('F · 0 correct / 1 attempts'), findsNothing);
    await tester.tap(find.text('View All (7)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('F · 0 correct / 1 attempts'), findsOneWidget);
    await finish(tester, p);
  });
  testWidgets(
      'reset refreshes dashboard immediately and leaves parent settings',
      (tester) async {
    final p = await make(tester, parent: true);
    await tester.pumpWidget(app(
        p,
        const Scaffold(
            body: SingleChildScrollView(
                child: Column(children: [
          LearningProgressSummary(),
          NeedsPractice(),
          WeeklyActivityChart(),
        ])))));
    await tester.runAsync(p.resetProgress);
    await tester.pump();
    expect(find.text('Letters Mastered: 0 / 26'), findsOneWidget);
    expect(find.text('Not Started: 26'), findsOneWidget);
    expect(find.text('Practice a few letters first to see recommendations.'),
        findsOneWidget);
    expect(
        find.text('No learning activity recorded this week.'), findsOneWidget);
    expect(p.screenTime.usedSecondsToday, 1080);
    expect(p.parentAuth.hasPin, isTrue);
    await finish(tester, p);
  });
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(800, 1024)
  ]) {
    for (final parent in [false, true]) {
      testWidgets(
          '${parent ? 'Parent' : 'Progress'} layout at $size with enlarged text',
          (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final p = await make(tester, parent: parent);
        await tester.pumpWidget(app(
            p, parent ? const ParentScreen() : const ProgressScreen(),
            scale: 1.3));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final scroll = find.byType(ListView).first;
        for (var i = 0; i < 16; i++) {
          await tester.drag(scroll, const Offset(0, -300));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        if (parent) {
          for (final tab in [1, 2]) {
            await tester.tap(find.byKey(ValueKey('parent-tab-$tab')));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            for (var i = 0; i < 12; i++) {
              await tester.drag(scroll, const Offset(0, -300));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }
          }
          await tester.scrollUntilVisible(find.text('Data / Reset'), 300,
              scrollable: find.byType(Scrollable).first, maxScrolls: 50);
          expect(find.text('Data / Reset'), findsOneWidget);
        } else {
          expect(find.text('Daily Time Limit'), findsNothing);
          expect(find.text('Change Parent PIN'), findsNothing);
        }
        await finish(tester, p);
      });
    }
  }
}
