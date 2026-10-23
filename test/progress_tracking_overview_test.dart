import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/learning_progress.dart';
import 'package:kidsphonics/models/word_lesson_progress.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'learning_progress_test.dart' show mockProgressAudio;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
  });

  test('overview counts evidence, unique content and five lesson types',
      () async {
    final p = AppProvider();
    await p.ready;
    expect(
        (p.exploredLetterCount, p.exploredSoundCount, p.practicedLessonCount),
        (0, 0, 0));
    await p.markLetterViewed('A');
    await p.startWordLesson(WordLesson.cvc);
    await p.recordActivityCompleted();
    expect((p.exploredLetterCount, p.practicedLessonCount), (1, 0));
    await p.recordLetterListening('B', LetterListeningKind.name);
    expect(p.practicedLessonCount, 1);
    await p.recordLetterListening('B', LetterListeningKind.sound);
    await p.recordLetterListening('B', LetterListeningKind.sound);
    expect((p.exploredSoundCount, p.practicedLessonCount), (1, 2));
    await p.recordLetterListening('A', LetterListeningKind.sound);
    expect(p.practicedLessonCount, 3);
    await p.completeWordLessonWord(WordLesson.cvc, 'CAT');
    await p.completeWordLessonWord(WordLesson.cvc, 'CAT');
    await p.completeWordLessonWord(WordLesson.blending, 'SUN');
    await p.completeAdventure('C', List.filled(5, true), 'c');
    expect(
        (p.exploredLetterCount, p.exploredSoundCount, p.practicedLessonCount),
        (3, 2, 5));
    expect(p.quickCheckLetters.where((l) => l.mastered).length, 1);
    expect(p.wordLessonProgress(WordLesson.cvc).completed.length, 1);
    final restored = AppProvider();
    await restored.ready;
    expect((
      restored.exploredLetterCount,
      restored.exploredSoundCount,
      restored.practicedLessonCount
    ), (
      3,
      2,
      5
    ));
    expect((restored.xp, restored.stars), (30, 1));
    p.dispose();
    restored.dispose();
  });

  test(
      'badge goals use unique words and preserve mastery and earned milestones',
      () async {
    final p = AppProvider();
    await p.ready;
    for (final l in 'AEIOU'.split('')) {
      await p.completeAdventure(l, List.filled(5, true), l);
    }
    for (final word in WordLesson.cvc.words.take(5)) {
      await p.completeWordLessonWord(WordLesson.cvc, word);
      await p.completeWordLessonWord(WordLesson.cvc, word);
    }
    await p.completeWordLessonWord(WordLesson.blending, 'SUN');
    await p.completeAdventure('A', List.filled(5, false), 'a-retry');
    final restored = AppProvider();
    await restored.ready;
    for (final id in [
      'First Mastery',
      'Vowel Star',
      'CVC Explorer',
      'Blending Champion',
      '5 Letters Mastered'
    ]) {
      expect(
          restored.progressBadges.singleWhere((b) => b.id == id).earned, true);
    }
    expect(
        restored.progressBadges
            .singleWhere((b) => b.id == 'Halfway There')
            .earned,
        false);
    expect(restored.progressBadges.first.count, 1);
    expect((restored.xp, restored.stars), (150, 5));
    expect(restored.quickCheckAchievements.map((a) => a.unlocked).toList(),
        restored.progressBadges.map((b) => b.earned).toList());
    p.dispose();
    restored.dispose();
  });

  test('streak badge retains the best real run and excludes future dates',
      () async {
    SharedPreferences.setMockInitialValues({
      'lastPracticeDateV1': '2026-10-07',
      'streakV2': 3,
      'dailyActivityV1': jsonEncode({
        for (final day in [5, 6, 7]) '2026-10-0$day': {'speechAttempts': 1},
        for (final day in [21, 22, 23, 24])
          '2026-10-$day': {'questionsAnswered': 1},
      }),
    });
    final p = AppProvider(now: () => DateTime(2026, 10, 20));
    await p.ready;
    expect(p.streak, 0);
    expect(p.bestLearningStreak, 3);
    final badge = p.progressBadges.singleWhere((b) => b.id == '3-Day Streak');
    expect((badge.count, badge.earned), (3, true));
    p.dispose();
  });

  test('opening progress does not award rewards; reset clears derived goals',
      () async {
    final p = AppProvider();
    await p.ready;
    await p.completeWordLessonWord(WordLesson.blending, 'SUN');
    await p.addXP(250);
    await p.addStar();
    for (var i = 0; i < 3; i++) {
      expect(p.progressBadges.length, 8);
    }
    expect((p.xp, p.stars, p.level), (250, 1, 2));
    await p.parentAuth.setup('2580', '2580');
    await p.resetProgress();
    final restored = AppProvider();
    await restored.ready;
    expect(
        restored.progressBadges.every((b) => b.count == 0 && !b.earned), true);
    expect((restored.xp, restored.stars, restored.practicedLessonCount),
        (0, 0, 0));
    p.dispose();
    restored.dispose();
  });
}
