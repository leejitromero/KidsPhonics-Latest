import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:kidsphonics/models/word_lesson_progress.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'save_recovery_test.dart' show FailingStore;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
  });
  Future<AppProvider> load() async {
    final provider = AppProvider();
    await provider.ready;
    return provider;
  }

  Future<void> cvcGoal(AppProvider provider) async {
    for (final word in WordLesson.cvc.words.take(5)) {
      await provider.completeWordLessonWord(WordLesson.cvc, word);
    }
  }

  test('only a completed goal queues a badge; claim changes no rewards',
      () async {
    final provider = await load();
    expect(provider.pendingBadgeUnlocks, isEmpty);
    await provider.startWordLesson(WordLesson.cvc);
    await provider.completeWordLessonWord(WordLesson.cvc, 'CAT');
    expect(provider.pendingBadgeUnlocks, isEmpty);
    await cvcGoal(provider);
    expect(provider.pendingBadgeUnlocks, ['CVC Explorer']);
    final before = (provider.xp, provider.stars, provider.dailyActivity.length);
    final badge = await provider.claimBadgeUnlock('CVC Explorer');
    expect(badge?.title, 'CVC Explorer');
    expect(provider.pendingBadgeUnlocks, isEmpty);
    expect(
        (provider.xp, provider.stars, provider.dailyActivity.length), before);
    expect(await provider.claimBadgeUnlock('CVC Explorer'), isNull);
    await cvcGoal(provider);
    expect(provider.pendingBadgeUnlocks, isEmpty);
    provider.dispose();
  });

  test('simultaneous achievements queue once and survive reopening', () async {
    final provider = await load();
    for (final letter in 'AEIOU'.split('')) {
      await provider.completeAdventure(
          letter, List.filled(5, true), 'first-$letter');
    }
    expect(provider.pendingBadgeUnlocks,
        ['First Mastery', 'Vowel Star', '5 Letters Mastered']);
    await provider.completeAdventure('U', List.filled(5, true), 'retry-u');
    expect(provider.pendingBadgeUnlocks, hasLength(3));
    final before = (provider.xp, provider.stars);
    await provider.claimBadgeUnlock('First Mastery');
    provider.dispose();
    final restored = await load();
    expect(restored.pendingBadgeUnlocks, ['Vowel Star', '5 Letters Mastered']);
    expect((restored.xp, restored.stars), before);
    await restored.claimBadgeUnlock('Vowel Star');
    await restored.claimBadgeUnlock('5 Letters Mastered');
    restored.dispose();
    final reopened = await load();
    expect(reopened.pendingBadgeUnlocks, isEmpty);
    expect(reopened.progressBadges.where((b) => b.earned), hasLength(3));
    reopened.dispose();
  });

  test('old saved badges form a baseline without startup celebrations',
      () async {
    SharedPreferences.setMockInitialValues({
      'wordLessonProgressV1': jsonEncode({
        'cvc': {
          'started': true,
          'completed': WordLesson.cvc.words.take(5).toList()
        },
      }),
    });
    final provider = await load();
    expect(
        provider.progressBadges
            .singleWhere((b) => b.id == 'CVC Explorer')
            .earned,
        isTrue);
    expect(provider.pendingBadgeUnlocks, isEmpty);
    await provider.completeWordLessonWord(WordLesson.blending, 'SUN');
    expect(provider.pendingBadgeUnlocks, ['Blending Champion']);
    provider.dispose();
    final restored = await load();
    expect(restored.pendingBadgeUnlocks, ['Blending Champion']);
    restored.dispose();
  });

  test('damaged or unearned presentation IDs cannot unlock or suppress badges',
      () async {
    SharedPreferences.setMockInitialValues({
      'badgeUnlockPresentationV1': jsonEncode({
        'shown': ['unknown', 'CVC Explorer', 3],
        'pending': ['Blending Champion', 'Blending Champion', 'unknown'],
      }),
    });
    final provider = await load();
    expect(provider.pendingBadgeUnlocks, isEmpty);
    expect(await provider.claimBadgeUnlock('unknown'), isNull);
    expect(await provider.claimBadgeUnlock('Blending Champion'), isNull);
    await cvcGoal(provider);
    expect(provider.pendingBadgeUnlocks, ['CVC Explorer']);
    provider.dispose();
  });

  test('authoritative snapshot retains the presentation queue', () async {
    final provider = await load();
    await cvcGoal(provider);
    final prefs = await SharedPreferences.getInstance();
    final snapshot = jsonDecode(prefs.getString('appStateV1')!) as Map;
    final ledger = jsonDecode(snapshot['badgeUnlockPresentationV1']) as Map;
    expect(ledger['pending'], ['CVC Explorer']);
    final attempts = await Future.wait([
      provider.claimBadgeUnlock('CVC Explorer'),
      provider.claimBadgeUnlock('CVC Explorer'),
    ]);
    expect(attempts.where((b) => b != null), hasLength(1));
    expect(provider.hasUnsavedChanges, isFalse);
    provider.dispose();
  });

  test('three real practice days unlock the streak badge only once', () async {
    var date = DateTime(2026, 11, 1);
    final provider = AppProvider(now: () => date);
    await provider.ready;
    for (var day = 1; day <= 3; day++) {
      date = DateTime(2026, 11, day);
      await provider.recordDailyAnswer(correct: true);
    }
    expect(provider.pendingBadgeUnlocks, ['3-Day Streak']);
    await provider.claimBadgeUnlock('3-Day Streak');
    date = DateTime(2026, 11, 4);
    await provider.recordDailyAnswer(correct: true);
    expect(provider.pendingBadgeUnlocks, isEmpty);
    provider.dispose();
  });

  test('parent-authorized reset clears history and permits future new unlocks',
      () async {
    final provider = await load();
    await cvcGoal(provider);
    await provider.claimBadgeUnlock('CVC Explorer');
    await provider.completeWordLessonWord(WordLesson.blending, 'SUN');
    await provider.parentAuth.setup('2580', '2580');
    expect(await provider.resetProgress(), isTrue);
    expect(provider.pendingBadgeUnlocks, isEmpty);
    await cvcGoal(provider);
    expect(provider.pendingBadgeUnlocks, ['CVC Explorer']);
    provider.dispose();
  });

  test('failed presentation save keeps the badge queued until storage recovers',
      () async {
    final store = FailingStore();
    SharedPreferencesStorePlatform.instance = store;
    final provider = await load();
    await cvcGoal(provider);
    store
      ..failKey = 'appStateV1'
      ..failures = 3;
    expect(await provider.claimBadgeUnlock('CVC Explorer'), isNull);
    expect(provider.hasUnsavedChanges, isTrue);
    expect(provider.pendingBadgeUnlocks, ['CVC Explorer']);
    await provider.retrySaving();
    expect(provider.hasUnsavedChanges, isFalse);
    expect(
        (await provider.claimBadgeUnlock('CVC Explorer'))?.id, 'CVC Explorer');
    provider.dispose();
  });
}
