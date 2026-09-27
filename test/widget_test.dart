import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/widgets/learning_progress_widgets.dart';
import 'learning_progress_test.dart' show mockProgressAudio;

void main() {
  testWidgets('weekly chart shows seven actual dates with normalized counts',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'dailyActivityV1': jsonEncode({
        '2026-09-21': {'questionsAnswered': 12, 'correctAnswers': 10},
        '2026-09-23': {'questionsAnswered': 18, 'correctAnswers': 12},
        '2026-09-24': {'questionsAnswered': 8, 'correctAnswers': 6},
        '2026-09-10': {'questionsAnswered': 100, 'correctAnswers': 90},
      })
    });
    mockProgressAudio();
    late AppProvider provider;
    await tester.runAsync(() async {
      provider = AppProvider(now: () => DateTime(2026, 9, 27));
      await provider.ready;
    });
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: Scaffold(body: WeeklyActivityChart()))));
    expect(find.text('12'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(4));
    expect(find.text('100'), findsNothing);
    final bars = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) => c.color != null)
        .map((c) => c.constraints!.maxHeight)
        .toList();
    expect(bars, [80 * 12 / 18, 0.0, 80.0, 80 * 8 / 18, 0.0, 0.0, 0.0]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    provider.dispose();
  });

  testWidgets('new learner shows empty activity and real progress',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
    late AppProvider provider;
    await tester.runAsync(() async {
      provider = AppProvider();
      await provider.ready;
    });
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
            home: Scaffold(
                body: Column(children: [
          LearningProgressSummary(),
          WeeklyActivityChart(),
        ])))));
    expect(
        find.text('No learning activity recorded this week.'), findsOneWidget);
    expect(find.textContaining('Letters Mastered: 0 / 26'), findsOneWidget);
    expect(find.textContaining('No attempts yet'), findsNWidgets(2));
    await tester.pumpWidget(const SizedBox());
    provider.dispose();
  });
}
