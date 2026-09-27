import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/learning_progress.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'learning_progress_test.dart' show mockProgressAudio, assessment;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppProvider p;
  var today = DateTime(2026, 9, 23, 12);
  setUp(() {
    mockProgressAudio();
    today = DateTime(2026, 9, 23, 12);
  });
  Future<void> load(
      {List<LetterProgress> letters = const [],
      Map<String, DailyActivity> days = const {},
      Map<String, Object> settings = const {}}) async {
    SharedPreferences.setMockInitialValues({
      'letterProgressV2':
          jsonEncode({for (final l in letters) l.letter: l.toJson()}),
      'dailyActivityV1':
          jsonEncode(days.map((k, v) => MapEntry(k, v.toJson()))),
      ...settings,
    });
    p = AppProvider(now: () => today);
    await p.ready;
    addTearDown(p.dispose);
  }

  int total() =>
      p.masteredLetterCount +
      p.practicedLetterCount +
      p.viewedLetterCount +
      p.notStartedLetterCount;

  test('fresh dashboard: 26 not started, zero mastery, absent accuracies',
      () async {
    await load();
    expect([
      p.masteredLetterCount,
      p.practicedLetterCount,
      p.viewedLetterCount,
      p.notStartedLetterCount
    ], [
      0,
      0,
      0,
      26
    ]);
    expect(p.masteryPercentage, 0);
    expect(p.letterPracticeAccuracy, isNull);
    expect(p.overallActivityAccuracy, isNull);
    expect(p.getWeeklySummary().accuracy, isNull);
    expect(p.unlockedAchievementCount, 0);
  });
  test('viewing then practicing then mastery remain exclusive and total 26',
      () async {
    await load();
    await p.markLetterViewed('A');
    expect(
        [p.viewedLetterCount, p.notStartedLetterCount, p.masteredLetterCount],
        [1, 25, 0]);
    await p.recordLetterPractice('A', false);
    expect(p.practicedLetterCount, 1);
    expect(p.viewedLetterCount, 0);
    expect(total(), 26);
    await assessment(p, 'A', 4);
    expect(p.masteredLetterCount, 1);
    expect(p.practicedLetterCount, 0);
    expect(total(), 26);
  });
  test('13 genuine masteries are 50%; vowels share letter progress', () async {
    await load();
    for (final letter in 'ABCDEFGHIJKLM'.split('')) {
      await assessment(p, letter, 4);
    }
    expect(p.masteryPercentage, 50);
    expect(p.masteredVowelCount, 3);
    expect(total(), 26);
  });
  test('letter accuracy weights scored answers and excludes game answers',
      () async {
    await load(letters: const [
      LetterProgress(letter: 'A', attempts: 5, correctAnswers: 4),
      LetterProgress(letter: 'B', attempts: 5, correctAnswers: 3),
    ]);
    expect(p.letterPracticeAccuracy, .7);
    for (var i = 0; i < 4; i++) {
      await p.recordDailyAnswer(correct: false);
    }
    expect(p.letterPracticeAccuracy, .7);
    expect(p.overallActivityAccuracy, 0);
  });
  test('unequal letter attempt counts use weighted ratio, not mean percentages',
      () async {
    await load(letters: const [
      LetterProgress(letter: 'A', attempts: 1, correctAnswers: 1),
      LetterProgress(letter: 'B', attempts: 9, correctAnswers: 0),
    ]);
    expect(p.letterPracticeAccuracy, .1);
  });
  test('needs practice sorts accuracy, excludes mastered and viewed-only',
      () async {
    await load(letters: const [
      LetterProgress(letter: 'A', attempts: 5, correctAnswers: 2),
      LetterProgress(letter: 'B', attempts: 10, correctAnswers: 7),
      LetterProgress(
          letter: 'C', attempts: 10, correctAnswers: 5, mastered: true),
      LetterProgress(letter: 'D', viewCount: 3),
      LetterProgress(letter: 'E', attempts: 5, correctAnswers: 2),
    ]);
    expect(p.lettersNeedingPractice.map((l) => l.letter), ['A', 'E', 'B']);
    expect(p.recommendedNextPractice!.letter, 'A');
  });
  test('recommendation fallback: viewed before unstarted, alphabetical ties',
      () async {
    await load(letters: const [LetterProgress(letter: 'Z', viewCount: 1)]);
    expect(p.recommendedNextPractice!.letter, 'Z');
    await assessment(p, 'Z', 4);
    expect(p.recommendedNextPractice!.letter, 'A');
  });
  test('all mastered has no fabricated recommendation', () async {
    await load(
        letters: List.generate(
            26,
            (i) => LetterProgress(
                letter: String.fromCharCode(65 + i), mastered: true)));
    expect(p.recommendedNextPractice, isNull);
    expect(p.lettersNeedingPractice, isEmpty);
    expect(p.masteryPercentage, 100);
    expect(p.masteredVowelCount, 5);
  });
  test('weekly summary includes exactly today and previous six days', () async {
    today = DateTime(2026, 10, 2, 0, 1);
    await load(days: const {
      '2026-09-25': DailyActivity(
          questionsAnswered: 100, correctAnswers: 100, activitiesCompleted: 10),
      '2026-09-26': DailyActivity(
          questionsAnswered: 10, correctAnswers: 7, activitiesCompleted: 2),
      '2026-09-30': DailyActivity(
          questionsAnswered: 5, correctAnswers: 3, activitiesCompleted: 1),
      '2026-10-02': DailyActivity(
          questionsAnswered: 5, correctAnswers: 4, activitiesCompleted: 1),
      '2026-10-03': DailyActivity(questionsAnswered: 100, correctAnswers: 100),
    });
    final week = p.getWeeklySummary();
    expect(week.days.map((d) => localDateKey(d.date)), [
      '2026-09-26',
      '2026-09-27',
      '2026-09-28',
      '2026-09-29',
      '2026-09-30',
      '2026-10-01',
      '2026-10-02'
    ]);
    expect(week.questionsAnswered, 20);
    expect(week.correctAnswers, 14);
    expect(week.activitiesCompleted, 4);
    expect(week.accuracy, .7);
    expect(p.overallActivityAccuracy, isNot(week.accuracy));
  });
  test('empty week has no accuracy; completion-only activity is retained',
      () async {
    await load(
        days: const {'2026-09-23': DailyActivity(activitiesCompleted: 1)});
    expect(p.getWeeklySummary().accuracy, isNull);
    expect(p.getWeeklySummary().questionsAnswered, 0);
    expect(p.getWeeklySummary().activitiesCompleted, 1);
    expect(p.getWeeklySummary().hasActivity, isTrue);
  });
  test('calendar week updates across year and leap-day boundaries', () async {
    await load();
    today = DateTime(2028, 3, 1, 23, 59);
    expect(localDateKey(p.getWeeklySummary().days[5].date), '2028-02-29');
    today = DateTime(2027, 1, 1);
    expect(localDateKey(p.getWeeklySummary().days.first.date), '2026-12-26');
  });
  test('XP does not unlock mastery or learning achievements', () async {
    await load();
    await p.addXP(1240);
    expect(p.level, 7);
    expect(p.masteryPercentage, 0);
    expect(p.unlockedAchievementCount, 0);
    expect(p.learningAchievements.any((a) => a.title.contains('XP')), isFalse);
  });
  test(
      'real three-day badge survives missed days and reopening without repeated awards',
      () async {
    await load();
    for (var i = 0; i < 3; i++) {
      await p.recordDailyAnswer(correct: true);
      today = today.add(const Duration(days: 1));
    }
    today = today.add(const Duration(days: 3));
    expect(p.streak, 0);
    expect(p.hasThreeDayLearningStreak, isTrue);
    expect(p.unlockedAchievementCount, 1);
    final reopened = AppProvider(now: () => today);
    await reopened.ready;
    expect(reopened.unlockedAchievementCount, 1);
    expect(reopened.unlockedAchievementCount, 1);
    reopened.dispose();
  });
  test(
      'views, XP, completion-only days and legacy migration cannot earn streak',
      () async {
    await load(days: const {
      '2026-09-21': DailyActivity(activitiesCompleted: 1),
      '2026-09-22': DailyActivity(activitiesCompleted: 2),
      '2026-09-23': DailyActivity(activitiesCompleted: 1),
    });
    await p.markLetterViewed('A');
    expect(p.hasThreeDayLearningStreak, isFalse);
    expect(p.unlockedAchievementCount, 0);
  });
  test(
      'authenticated reset immediately empties derived dashboard, preserving controls',
      () async {
    await load(settings: {
      'screenTimeLimitEnabledV2': true,
      'screenTimeLimitMinutesV2': 45,
      'gameAccess': false
    });
    await p.parentAuth.setup('2580', '2580');
    await assessment(p, 'A', 4);
    await p.addXP(20);
    await p.resetProgress();
    expect(total(), 26);
    expect(p.notStartedLetterCount, 26);
    expect(p.masteryPercentage, 0);
    expect(p.letterPracticeAccuracy, isNull);
    expect(p.getWeeklySummary().hasActivity, isFalse);
    expect(p.unlockedAchievementCount, 0);
    expect(p.parentAuth.hasPin, isTrue);
    expect(p.screenTime.dailyLimitMinutes, 45);
    expect(p.gameAccess, isFalse);
  });
}
