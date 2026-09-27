import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/learning_progress.dart';
import 'package:kidsphonics/providers/app_provider.dart';

void mockProgressAudio() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final channel in [
    'xyz.luan/audioplayers.global',
    'xyz.luan/audioplayers.global/events'
  ]) {
    messenger.setMockMethodCallHandler(
        MethodChannel(channel), (_) async => null);
  }
  messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'), (call) async {
    if (call.method == 'create') {
      final id = (call.arguments as Map)['playerId'];
      messenger.setMockMethodCallHandler(
          MethodChannel('xyz.luan/audioplayers/events/$id'), (_) async => null);
    }
    return null;
  });
}

Future<void> assessment(AppProvider p, String letter, int correct) async {
  for (var i = 0; i < 5; i++) {
    await p.recordLetterPractice(letter, i < correct);
  }
  await p.completeLetterAssessment(letter, correct, 5);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
  });

  test('fresh learner and A-Z browsing never award mastery or rewards',
      () async {
    final p = AppProvider();
    await p.ready;
    expect(p.masteredLetterCount, 0);
    expect(p.overallActivityAccuracy, isNull);
    expect(p.dailyActivity, isEmpty);
    expect(p.streak, 0);
    for (var i = 0; i < 26; i++) {
      await p.markLetterViewed(String.fromCharCode(65 + i));
    }
    expect(p.viewedLetterCount, 26);
    expect(p.masteredLetterCount, 0);
    expect(p.getLetterStatus('A'), LearningStatus.viewed);
    expect(p.xp, 0);
    expect(p.stars, 0);
    expect(p.dailyActivity, isEmpty);
    p.dispose();
  });

  test('failed check, passing retry, best score and persistence', () async {
    final p = AppProvider();
    await p.ready;
    await assessment(p, 'A', 3);
    expect(p.getLetterStatus('A'), LearningStatus.practiced);
    await assessment(p, 'A', 4);
    expect(p.masteredLetterCount, 1);
    expect(p.getLetterProgress('A').accuracy, 0.7);
    final masteredAt = p.getLetterProgress('A').masteredAt;
    await assessment(p, 'A', 0);
    expect(p.getLetterStatus('A'), LearningStatus.mastered);
    expect(p.getLetterProgress('A').masteredAt, masteredAt);
    final reopened = AppProvider();
    await reopened.ready;
    final a = reopened.getLetterProgress('A');
    expect(a.attempts, 15);
    expect(a.correctAnswers, 7);
    expect(a.completedAssessments, 3);
    expect(a.bestAssessmentScore, 4);
    expect(a.mastered, isTrue);
    final daily = reopened.dailyActivity.values.single;
    expect(daily.questionsAnswered, 15);
    expect(daily.correctAnswers, 7);
    expect(daily.activitiesCompleted, 3);
    p.dispose();
    reopened.dispose();
  });

  test('partial checks count practice only and invalid check size is rejected',
      () async {
    final p = AppProvider();
    await p.ready;
    for (var i = 0; i < 4; i++) {
      await p.recordLetterPractice('B', true);
    }
    expect(p.getLetterStatus('B'), LearningStatus.practiced);
    expect(p.getLetterProgress('B').completedAssessments, 0);
    await expectLater(
        p.completeLetterAssessment('B', 4, 4), throwsArgumentError);
    expect(p.masteredLetterCount, 0);
    p.dispose();
  });

  test('legacy letters migrate once to viewed, preserving rewards/settings',
      () async {
    SharedPreferences.setMockInitialValues({
      'learned': ['A', 'B'],
      'xp': 210,
      'stars': 8,
      'streak': 20,
      'voice': false,
      'sfx': false,
      'gameAccess': false
    });
    final p = AppProvider();
    await p.ready;
    expect(p.viewedLetterCount, 2);
    expect(p.masteredLetterCount, 0);
    expect(p.xp, 210);
    expect(p.stars, 8);
    expect(p.streak, 0);
    expect(p.voiceEnabled, isFalse);
    expect(p.sfxEnabled, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('learned'), isFalse);
    final reopened = AppProvider();
    await reopened.ready;
    expect(reopened.getLetterProgress('A').viewCount, 1);
    p.dispose();
    reopened.dispose();
  });

  test('streak uses local calendar days, same-day answers and missed days',
      () async {
    var date = DateTime(2026, 9, 20, 23, 59);
    final p = AppProvider(now: () => date);
    await p.ready;
    await p.recordDailyAnswer(correct: true);
    expect(p.streak, 1);
    await p.recordDailyAnswer(correct: false);
    expect(p.streak, 1);
    date = DateTime(2026, 9, 21);
    await p.recordDailyAnswer(correct: true);
    date = DateTime(2026, 9, 22);
    await p.recordDailyAnswer(correct: true);
    expect(p.streak, 3);
    expect(p.dailyActivity['2026-09-20']!.questionsAnswered, 2);
    date = DateTime(2026, 9, 24);
    expect(p.streak, 0);
    await p.recordActivityCompleted();
    expect(p.streak, 0);
    await p.recordDailyAnswer(correct: false);
    expect(p.streak, 1);
    final reopened = AppProvider(now: () => date);
    await reopened.ready;
    expect(reopened.streak, 1);
    p.dispose();
    reopened.dispose();
  });

  test(
      'reset clears learner progress but preserves preferences after reopening',
      () async {
    SharedPreferences.setMockInitialValues({
      'xp': 400,
      'stars': 20,
      'voice': false,
      'sfx': false,
      'gameAccess': false,
      'timeLimit': true,
      'rhymingDone': true,
      'learned': ['Z']
    });
    final p = AppProvider();
    await p.ready;
    await assessment(p, 'A', 5);
    if (!p.parentAuth.hasPin) await p.parentAuth.setup('2580', '2580');
    await p.resetProgress();
    final reopened = AppProvider();
    await reopened.ready;
    expect(reopened.xp, 0);
    expect(reopened.stars, 0);
    expect(reopened.streak, 0);
    expect(reopened.masteredLetterCount, 0);
    expect(reopened.viewedLetterCount, 0);
    expect(reopened.practicedLetterCount, 0);
    expect(reopened.dailyActivity, isEmpty);
    expect(reopened.rhymingWordsDone, isFalse);
    expect(reopened.overallActivityAccuracy, isNull);
    expect(reopened.voiceEnabled, isFalse);
    expect(reopened.sfxEnabled, isFalse);
    expect(reopened.gameAccess, isFalse);
    expect(reopened.timeLimitEnabled, isTrue);
    p.dispose();
    reopened.dispose();
  });

  test('all pass boundaries, 13 letters and three vowel mastery', () async {
    final p = AppProvider();
    await p.ready;
    for (var score = 0; score <= 5; score++) {
      final letter = String.fromCharCode(65 + score);
      await assessment(p, letter, score);
      expect(p.getLetterProgress(letter).mastered, score >= 4);
    }
    if (!p.parentAuth.hasPin) await p.parentAuth.setup('2580', '2580');
    await p.resetProgress();
    for (final letter in 'ABCDEFGHIJKLM'.split('')) {
      await assessment(p, letter, 4);
    }
    expect(p.masteredLetterCount, 13);
    expect(p.masteredLetterCount / 26, 0.5);
    expect(
        ['A', 'E', 'I', 'O', 'U'].where(p.masteredLetters.contains).length, 3);
    p.dispose();
  });

  test('interaction during preference loading preserves migration', () async {
    SharedPreferences.setMockInitialValues({
      'learned': ['B'],
      'xp': 200
    });
    final p = AppProvider();
    await p.markLetterViewed('A');
    expect(p.viewedLetterCount, 2);
    expect(p.xp, 200);
    p.dispose();
  });

  test(
      'letter accuracy excludes games and viewing; activity accuracy includes both',
      () async {
    final p = AppProvider();
    await p.ready;
    await p.markLetterViewed('A');
    expect(p.letterPracticeAccuracy, isNull);
    expect(p.overallActivityAccuracy, isNull);
    await p.recordDailyAnswer(correct: true);
    expect(p.letterPracticeAccuracy, isNull);
    expect(p.overallActivityAccuracy, 1);
    await p.recordLetterPractice('A', false);
    await p.recordLetterPractice('B', true);
    expect(p.letterPracticeAccuracy, 0.5);
    expect(p.overallActivityAccuracy, closeTo(2 / 3, 0.00001));
    await p.markLetterViewed('C');
    expect(p.letterPracticeAccuracy, 0.5);
    expect(p.overallActivityAccuracy, closeTo(2 / 3, 0.00001));
    p.dispose();
  });

  test('each check adds exactly five answers and one completed activity',
      () async {
    final p = AppProvider();
    await p.ready;
    await assessment(p, 'B', 3);
    expect(p.getLetterStatus('B'), LearningStatus.practiced);
    expect(p.dailyActivity.values.single.questionsAnswered, 5);
    expect(p.dailyActivity.values.single.activitiesCompleted, 1);
    await assessment(p, 'B', 4);
    expect(p.getLetterStatus('B'), LearningStatus.mastered);
    expect(p.dailyActivity.values.single.questionsAnswered, 10);
    expect(p.dailyActivity.values.single.activitiesCompleted, 2);
    await assessment(p, 'B', 2);
    expect(p.getLetterStatus('B'), LearningStatus.mastered);
    expect(p.dailyActivity.values.single.questionsAnswered, 15);
    expect(p.dailyActivity.values.single.activitiesCompleted, 3);
    p.dispose();
  });

  test('mastery milestones cross once, independently of XP and retries',
      () async {
    final p = AppProvider();
    await p.ready;
    final events = <int>[];
    final subscription = p.masteryMilestones.listen(events.add);
    for (var i = 0; i < 26; i++) {
      await assessment(p, String.fromCharCode(65 + i), 4);
    }
    expect(events, [1, 5, 13, 26]);
    expect(p.unlockedMasteryMilestones, {1, 5, 13, 26});
    await assessment(p, 'A', 5);
    await assessment(p, 'A', 0);
    await p.addXP(1);
    expect(events, [1, 5, 13, 26]);
    final reopened = AppProvider();
    await reopened.ready;
    expect(reopened.unlockedMasteryMilestones, {1, 5, 13, 26});
    final repeated = <int>[];
    final secondSubscription = reopened.masteryMilestones.listen(repeated.add);
    await assessment(reopened, 'A', 5);
    expect(repeated, isEmpty);
    if (!p.parentAuth.hasPin) await p.parentAuth.setup('2580', '2580');
    await p.resetProgress();
    expect(p.unlockedMasteryMilestones, isEmpty);
    await subscription.cancel();
    await secondSubscription.cancel();
    p.dispose();
    reopened.dispose();
  });

  test('JSON round trip preserves progress and nullable accuracy', () {
    const empty = LetterProgress(letter: 'A');
    expect(LetterProgress.fromJson(empty.toJson()).status,
        LearningStatus.notStarted);
    expect(empty.accuracy, isNull);
    const activity = DailyActivity(
        questionsAnswered: 12, correctAnswers: 8, activitiesCompleted: 2);
    expect(DailyActivity.fromJson(activity.toJson()).questionsAnswered, 12);
  });
}
