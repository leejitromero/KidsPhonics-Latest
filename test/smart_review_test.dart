import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:kidsphonics/data/smart_review_catalog.dart';
import 'package:kidsphonics/data/letter_data.dart';
import 'package:kidsphonics/data/phonics_activity_data.dart';
import 'package:kidsphonics/data/rhyming_jar_data.dart';
import 'package:kidsphonics/data/rumbled_words_data.dart';
import 'package:kidsphonics/data/cvc_lesson_data.dart';
import 'package:kidsphonics/data/blending_lesson_data.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/models/smart_review.dart';
import 'package:kidsphonics/models/letter_adventure.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'save_recovery_test.dart' show FailingStore;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
  });

  test('correct-only evidence is not a weakness; repeated errors rank first',
      () {
    final state = SmartReviewState();
    const a = ReviewTarget.vowel('A'), e = ReviewTarget.vowel('E');
    state.observe(a, true);
    expect(state.pending, isEmpty);
    state.observe(e, false);
    state.observe(e, false);
    state.observe(a, false);
    expect(state.pending.first.target.key, e.key);
    state.observe(e, true);
    expect(state.pending.any((p) => p.target.key == e.key), true);
    state.observe(e, true);
    expect(state.pending.map((p) => p.target.key), [a.key]);
    state.observe(e, false);
    expect(state.pending.any((p) => p.target.key == e.key), true);
  });

  test('histories stay bounded and a mistake resets recovery', () {
    final state = SmartReviewState();
    const target = ReviewTarget.word('CAT');
    for (var i = 0; i < 100; i++) {
      state.observe(target, false);
    }
    expect(state.pending.single.recent, hasLength(6));
    state.observe(target, true);
    expect(state.pending.single.recovery, 1);
    state.observe(target, false);
    expect(state.pending.single.recovery, 0);
    expect(() => state.pending.clear(), throwsUnsupportedError);
    expect(() => state.pending.single.recent.clear(), throwsUnsupportedError);
  });

  test('sound choices do not offer C and K as different correct answers', () {
    for (final letter in ['C', 'K']) {
      for (var seed = 0; seed < 50; seed++) {
        final q = SmartReviewCatalog.question(
            ReviewTarget.sound(letter), Random(seed));
        expect(q.options, isNot(contains(letter == 'C' ? 'K' : 'C')));
      }
    }
  });

  test('focused vowel repetitions use different words within a session', () {
    final state = SmartReviewState()
      ..observe(const ReviewTarget.vowel('E'), false);
    for (var seed = 0; seed < 25; seed++) {
      final questions =
          SmartReviewCatalog.plan(state.pending, random: Random(seed));
      expect(questions[0].phrases.single, isNot(questions[1].phrases.single));
      expect(questions[0].heading, isNot(contains(' E')));
    }
  });

  test('malformed and unsupported saves are ignored without throwing', () {
    for (final value in [
      null,
      '',
      [],
      {'version': 7, 'entries': []},
      {
        'version': 1,
        'entries': [
          null,
          3,
          {},
          {
            'target': {'skill': 'word', 'value': 'UNKNOWN'},
            'recent': [false],
            'recovery': 0,
            'sequence': 1
          },
          {
            'target': {'skill': 'vowel', 'value': 'E'},
            'recent': ['false'],
            'recovery': 0,
            'sequence': 1
          },
        ]
      }
    ]) {
      final state = SmartReviewState()
        ..load(value, SmartReviewCatalog.supported);
      expect(state.pending, isEmpty);
    }
  });

  test('saved recovery is checked against actual recent evidence', () {
    final state = SmartReviewState()
      ..load({
        'version': 1,
        'entries': [
          {
            'target': const ReviewTarget.vowel('E').toJson(),
            'recent': [false, true],
            'recovery': 2,
            'sequence': 1
          }
        ]
      }, SmartReviewCatalog.supported);
    expect(state.pending.single.recovery, 1);
  });

  test('review plan is short, prioritized and does not consume evidence', () {
    final state = SmartReviewState();
    for (final letter in 'BCDFGHJKLM'.split('')) {
      state.observe(ReviewTarget.sound(letter), false);
    }
    final before = jsonEncode(state.toJson());
    final plan = SmartReviewCatalog.plan(state.pending, random: Random(1));
    expect(plan, hasLength(5));
    expect(plan.first.target.key, state.pending.first.target.key);
    expect(jsonEncode(state.toJson()), before);
    expect(() => plan.clear(), throwsUnsupportedError);
    state.clear();
    state.observe(const ReviewTarget.vowel('E'), false);
    expect(SmartReviewCatalog.plan(state.pending), hasLength(2));
  });

  test(
      'all supported game/lesson targets have unambiguous choices and bundled cues',
      () {
    final targets = <String, ReviewTarget>{};
    void add(ReviewTarget t) {
      targets[t.key] = t;
    }

    for (final letter in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')) {
      add(ReviewTarget.letter(letter));
      add(ReviewTarget.sound(letter));
    }
    for (final word in [...cvcLessonWords, ...blendingLessonWords]) {
      add(ReviewTarget.word(word.word));
    }
    for (final family in rhymingFamilies) {
      add(ReviewTarget.rhyme(family.target));
    }
    for (final d in Difficulty.values) {
      for (final q in soundRoundsForDifficulty(d)) {
        add(ReviewTarget.sound(q.correctLetter));
      }
      for (final q in quizQuestionsForDifficulty(d)) {
        add(ReviewTarget.sound(q.correctLetter));
      }
      for (final q in vowelPuzzlesFor(d)) {
        add(ReviewTarget.vowel(q.vowel));
      }
      for (final q in wordPuzzlesForDifficulty(d)) {
        add(ReviewTarget.word(q.word));
      }
      for (final q in pictureRoundsFor(d)) {
        add(ReviewTarget.word(q.word.toUpperCase()));
      }
      for (final q in rumbledWordsFor(d)) {
        add(ReviewTarget.word(q.word.toUpperCase()));
      }
      for (final q in positionRoundsFor(d)) {
        add(ReviewTarget.position(q.word.toUpperCase(), q.targetLetter));
      }
    }
    for (final target in targets.values) {
      expect(SmartReviewCatalog.supported(target), true, reason: target.key);
      final restored = ReviewTarget.fromJson(target.toJson());
      expect(restored, isNotNull, reason: target.key);
      expect(restored!.key, target.key);
      final q = SmartReviewCatalog.question(target, Random(1));
      expect(q.options.toSet(), hasLength(3), reason: target.key);
      expect(q.options.where((o) => o == q.expected), hasLength(1));
      expect(q.phrases, isNotEmpty);
      for (final phrase in q.phrases) {
        final path = PhonicsAudioService.assetForPhrase(phrase);
        expect(path, isNotNull, reason: '$phrase for ${target.key}');
        expect(File('assets/$path').existsSync(), true,
            reason: '$path for ${target.key}');
      }
    }
  });

  test(
      'game evidence survives restart while existing rewards and progress remain intact',
      () async {
    SharedPreferences.setMockInitialValues(
        {'studentName': 'Jit', 'xp': 123, 'stars': 7, 'gameAccess': true});
    final p = AppProvider();
    await p.ready;
    await p.recordDailyAnswer(
        correct: false, reviewTarget: const ReviewTarget.vowel('E'));
    await p.recordDailyAnswer(
        correct: false, reviewTarget: const ReviewTarget.word('EGGPLANT'));
    expect(p.smartReviewSuggestions, hasLength(2));
    final reopened = AppProvider();
    await reopened.ready;
    expect(reopened.smartReviewSuggestions.map((e) => e.target.key).toSet(),
        p.smartReviewSuggestions.map((e) => e.target.key).toSet());
    expect(
        (reopened.studentName, reopened.xp, reopened.stars), ('Jit', 123, 7));
    expect(reopened.dailyActivity.values.single.questionsAnswered, 2);
    expect(reopened.overallMasteredCount, 0);
    p.dispose();
    reopened.dispose();
  });

  test('review practice never changes game stats, streak, mastery or rewards',
      () async {
    final p = AppProvider();
    await p.ready;
    const target = ReviewTarget.vowel('E');
    await p.recordDailyAnswer(correct: false, reviewTarget: target);
    final before = (
      p.xp,
      p.stars,
      p.streak,
      p.overallMasteredCount,
      jsonEncode(p.dailyActivity.map((k, v) => MapEntry(k, v.toJson())))
    );
    await p.recordSmartReviewPractice(target, true);
    expect(p.smartReviewSuggestions.single.recovery, 1);
    await p.recordSmartReviewPractice(target, true);
    expect(p.smartReviewSuggestions, isEmpty);
    expect((
      p.xp,
      p.stars,
      p.streak,
      p.overallMasteredCount,
      jsonEncode(p.dailyActivity.map((k, v) => MapEntry(k, v.toJson())))
    ), before);
    final reopened = AppProvider();
    await reopened.ready;
    expect(reopened.smartReviewSuggestions, isEmpty);
    await reopened.recordSmartReviewPractice(
        const ReviewTarget.word('CAT'), false);
    expect(reopened.smartReviewSuggestions, isEmpty);
    p.dispose();
    reopened.dispose();
  });

  test('Quick Check retries keep existing scoring and session deduplication',
      () async {
    final p = AppProvider();
    await p.ready;
    final earned =
        await p.completeAdventure('E', [true, false, true, false, true], 'one');
    expect(earned, (xp: 5, stars: 0));
    expect(p.smartReviewSuggestions.single.target.key,
        const ReviewTarget.vowel('E').key);
    expect(p.smartReviewSuggestions.single.recent, [false, false]);
    final before = jsonEncode(p.smartReviewSuggestions.single.toJson());
    expect(
        await p.completeAdventure('E', [true, false, true, false, true], 'one'),
        (xp: 0, stars: 0));
    expect(jsonEncode(p.smartReviewSuggestions.single.toJson()), before);
    expect(
        await p.completeAdventure('E', [true, true, true, true, true], 'two'),
        (xp: 25, stars: 1));
    expect(p.smartReviewSuggestions, isEmpty);
    expect(p.overallMasteredCount, 1);
    expect(p.dailyActivity.values.single.questionsAnswered, 10);
    p.dispose();
  });

  test(
      'existing Quick Check skill evidence migrates without modifying assessed progress',
      () async {
    const old = AdventureProgress(
        completed: 1,
        best: 3,
        lastAnswers: [true, false, true, false, true],
        sessionId: 'old');
    SharedPreferences.setMockInitialValues({
      'xp': 55,
      'stars': 3,
      'letterAdventuresV1': jsonEncode({'E': old.toJson()})
    });
    final p = AppProvider();
    await p.ready;
    expect(p.smartReviewSuggestions.single.target.key,
        const ReviewTarget.vowel('E').key);
    expect(p.adventureProgress('E').toJson(), old.toJson());
    expect((p.xp, p.stars), (55, 3));
    expect(p.dailyActivity, isEmpty);
    await p.recordSmartReviewPractice(const ReviewTarget.vowel('E'), true);
    await p.recordSmartReviewPractice(const ReviewTarget.vowel('E'), true);
    final reopened = AppProvider();
    await reopened.ready;
    expect(reopened.smartReviewSuggestions, isEmpty);
    p.dispose();
    reopened.dispose();
  });

  test('invalid review payload does not erase other saved data', () async {
    SharedPreferences.setMockInitialValues(
        {'xp': 55, 'studentName': 'Jit', 'smartReviewV1': '{broken'});
    final p = AppProvider();
    await p.ready;
    expect(p.smartReviewSuggestions, isEmpty);
    expect((p.studentName, p.xp), ('Jit', 55));
    p.dispose();
  });

  test('review practice respects an exhausted daily time limit', () async {
    final review = SmartReviewState()
      ..observe(const ReviewTarget.vowel('E'), false);
    SharedPreferences.setMockInitialValues({
      'screenTimeDateV2': '2026-11-12',
      'screenTimeUsedSecondsV2': 1800,
      'screenTimeLimitEnabledV2': true,
      'screenTimeLimitMinutesV2': 30,
      'smartReviewV1': jsonEncode(review.toJson()),
    });
    final p = AppProvider(now: () => DateTime(2026, 11, 12, 12));
    await p.ready;
    expect(p.timeLimitReached, true);
    await p.recordSmartReviewPractice(const ReviewTarget.vowel('E'), true);
    expect(p.smartReviewSuggestions.single.recent, [false]);
    p.dispose();
  });

  test('a failed review save can be retried without losing original progress',
      () async {
    final previousStore = SharedPreferencesStorePlatform.instance;
    final store = FailingStore();
    SharedPreferencesStorePlatform.instance = store;
    addTearDown(() => SharedPreferencesStorePlatform.instance = previousStore);
    final p = AppProvider();
    await p.ready;
    const target = ReviewTarget.vowel('E');
    await p.addXP(20);
    await p.recordDailyAnswer(correct: false, reviewTarget: target);
    store
      ..failures = 3
      ..failKey = 'appStateV1';
    await p.recordSmartReviewPractice(target, true);
    expect(p.hasUnsavedChanges, true);
    expect(p.smartReviewSuggestions.single.recovery, 1);
    await p.retrySaving();
    expect(p.hasUnsavedChanges, false);
    final reopened = AppProvider();
    await reopened.ready;
    expect(reopened.smartReviewSuggestions.single.recovery, 1);
    expect(reopened.xp, 20);
    expect(reopened.dailyActivity.values.single.questionsAnswered, 1);
    p.dispose();
    reopened.dispose();
  });

  test('parent reset clears review and stale practice cannot restore it',
      () async {
    final p = AppProvider();
    await p.ready;
    const target = ReviewTarget.vowel('E');
    await p.recordDailyAnswer(correct: false, reviewTarget: target);
    await p.parentAuth.setup('2580', '2580');
    expect(await p.resetProgress(), true);
    expect(p.smartReviewSuggestions, isEmpty);
    await p.recordSmartReviewPractice(target, false);
    final reopened = AppProvider();
    await reopened.ready;
    expect(reopened.smartReviewSuggestions, isEmpty);
    expect(reopened.dailyActivity, isEmpty);
    p.dispose();
    reopened.dispose();
  });
}
