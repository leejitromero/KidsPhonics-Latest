// lib/providers/app_provider.dart
import 'dart:async';
import 'dart:convert';
import '../services/parent_auth_service.dart';
import '../services/screen_time_service.dart';
import '../services/preference_write_queue.dart';
import '../models/learning_progress.dart';
import '../models/word_lesson_progress.dart';
import '../models/progress_badge.dart';
import '../models/letter_adventure.dart';
import '../models/weekly_learning_summary.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/audio_service.dart';
import '../services/phonics_audio_service.dart';

class AppProvider extends ChangeNotifier {
  final AudioService audio = AudioService();
  final PhonicsAudioService phonicsAudio = PhonicsAudioService();

  bool _voiceEnabled = true;
  bool _sfxEnabled = true;
  bool _musicEnabled = true;
  double _musicVolume = .12;
  bool get musicEnabled => _musicEnabled;
  double get musicVolume => _musicVolume;
  double _textSizeMultiplier = 1;
  bool _reducedAnimations = false;
  double get textSizeMultiplier => _textSizeMultiplier;
  bool get reducedAnimations => _reducedAnimations;

  Future<void> setTextSizeMultiplier(double value) async {
    await ready;
    if (!isReady || !value.isFinite) return;
    final next = value.clamp(1.0, 1.3).toDouble();
    if (_textSizeMultiplier == next) return;
    _textSizeMultiplier = next;
    _changed();
    await _savePrefs();
  }

  Future<void> setReducedAnimations(bool enabled) async {
    await ready;
    if (!isReady || _reducedAnimations == enabled) return;
    _reducedAnimations = enabled;
    _changed();
    await _savePrefs();
  }

  Future<void> toggleMusic() async {
    await ready;
    _musicEnabled = !_musicEnabled;
    _changed();
    await _savePrefs();
  }

  Future<void> setMusicVolume(double value) async {
    await ready;
    if (!value.isFinite) return;
    _musicVolume = value.clamp(0, .4);
    _changed();
    await _savePrefs();
  }

  bool _gameAccess = true;

  String _studentCharacter = 'boy';
  String _studentName = '';
  String get studentCharacter => _studentCharacter;
  String get studentName => _studentName;
  bool _welcomeCompleted = false;
  bool get welcomeCompleted => _welcomeCompleted;

  Future<bool> completeWelcome(String character, String name) async {
    if (name.trim().isEmpty) return false;
    await ready;
    if (!isReady) return false;
    final previous = _welcomeCompleted;
    _welcomeCompleted = true;
    try {
      await setStudentCharacter(character, name);
      if (!hasUnsavedChanges) return true;
    } catch (_) {
      _welcomeCompleted = previous;
      _changed();
      rethrow;
    }
    _welcomeCompleted = previous;
    _changed();
    return false;
  }

  Future<void> setStudentCharacter(String character, String name) async {
    if (character != 'boy' && character != 'girl') {
      throw ArgumentError.value(character, 'character');
    }
    await ready;
    if (!isReady) return;
    _studentCharacter = character;
    _studentName = name.trim().characters.take(24).toString();
    _changed();
    await _savePrefs();
  }

  bool _rhymingWordsDone = false;
  final Map<String, int> _journeyScores = {};
  int? journeyScore(String id) => _journeyScores[id];

  Future<void> completeJourneyLesson(String id, int correct, int total) async {
    if (total <= 0 || correct < 0 || correct > total) {
      throw ArgumentError('Invalid lesson result');
    }
    await ready;
    final percent = (correct * 100 / total).round();
    final previous = _journeyScores[id];
    if (previous == null || percent > previous) _journeyScores[id] = percent;
    _recordCompletion();
    _changed();
    await _savePrefs();
  }

  int _xp = 0;
  int _streak = 0;
  int _stars = 0;
  final Map<String, LetterProgress> _letterProgress = {};
  final Map<WordLesson, WordLessonProgress> _wordLessons = {};

  WordLessonProgress wordLessonProgress(WordLesson lesson) =>
      _wordLessons[lesson] ?? const WordLessonProgress();

  Future<void> startWordLesson(WordLesson lesson) async {
    await ready;
    if (!isReady || wordLessonProgress(lesson).started) return;
    _wordLessons[lesson] = const WordLessonProgress(started: true);
    _changed();
    await _savePrefs();
  }

  /// Idempotent per-word completion; replaying never duplicates progress/rewards.
  Future<void> completeWordLessonWord(WordLesson lesson, String word) async {
    if (!lesson.words.contains(word)) {
      throw ArgumentError.value(word, 'word', 'Unknown lesson word');
    }
    await ready;
    if (!isReady) return;
    final previous = wordLessonProgress(lesson);
    if (previous.completed.contains(word)) return;
    _wordLessons[lesson] = WordLessonProgress(
        started: true,
        completed: Set.unmodifiable({...previous.completed, word}));
    _changed();
    await _savePrefs();
  }

  final Map<String, AdventureProgress> _adventures = {};
  String? _recommendedAdventureLetter;
  AdventureProgress adventureProgress(String letter) =>
      _adventures[letter] ?? const AdventureProgress();
  int get overallMasteredCount =>
      _adventures.values.where((p) => p.mastered).length;
  int get adventureAssessments =>
      _adventures.values.fold(0, (sum, p) => sum + p.completed);

  /// Current Quick Check presentation, keeping lesson exposure independently.
  /// Legacy assessment mastery never substitutes for a new Letter Adventure.
  LetterProgress quickCheckLetter(String letter) {
    final exposure = getLetterProgress(letter);
    final check = adventureProgress(exposure.letter);
    final practiceAttempts =
        (exposure.attempts - exposure.completedAssessments * 5)
            .clamp(0, exposure.attempts);
    return LetterProgress(
        letter: exposure.letter,
        viewCount: exposure.viewCount,
        attempts: check.completed > 0 ? 5 : practiceAttempts,
        correctAnswers: check.completed > 0 ? check.lastScore : 0,
        completedAssessments: check.completed,
        bestAssessmentScore: check.best,
        mastered: check.mastered,
        masteredAt: check.masteredAt,
        nameListens: exposure.nameListens,
        soundListens: exposure.soundListens,
        wordListens: exposure.wordListens);
  }

  List<LetterProgress> get quickCheckLetters => [
        for (var code = 65; code <= 90; code++)
          quickCheckLetter(String.fromCharCode(code))
      ];
  int quickCheckStatusCount(LearningStatus status) =>
      quickCheckLetters.where((p) => p.status == status).length;
  int get quickCheckVowelsMastered => quickCheckLetters
      .where((p) => 'AEIOU'.contains(p.letter) && p.mastered)
      .length;
  static const adventureMilestones = [1, 5, 13, 26];

  int get exploredLetterCount => quickCheckLetters
      .where((letter) => letter.status != LearningStatus.notStarted)
      .length;
  int get exploredSoundCount =>
      allLetterProgress.where((letter) => letter.soundListens > 0).length;

  /// Distinct lesson types with actual listening or completed word practice.
  /// Opening a lesson or completing a game does not inflate this number.
  int get practicedLessonCount => [
        allLetterProgress.any((letter) => letter.nameListens > 0),
        exploredSoundCount > 0,
        allLetterProgress.any((letter) =>
            'AEIOU'.contains(letter.letter) && letter.soundListens > 0),
        allLetterProgress.any((letter) => letter.wordListens > 0),
        wordLessonProgress(WordLesson.cvc).completed.isNotEmpty,
        wordLessonProgress(WordLesson.blending).completed.isNotEmpty,
      ].where((practiced) => practiced).length;

  List<ProgressBadge> get progressBadges => [
        ProgressBadge(
            id: 'First Mastery',
            title: 'First Letter Mastery',
            description: 'Master 1 letter in Quick Check.',
            current: overallMasteredCount,
            target: 1),
        ProgressBadge(
            id: 'Vowel Star',
            title: 'Vowel Star',
            description: 'Master all 5 vowels in Quick Check.',
            current: quickCheckVowelsMastered,
            target: 5),
        ProgressBadge(
            id: 'CVC Explorer',
            title: 'CVC Explorer',
            description: 'Practice 5 different CVC words.',
            current: wordLessonProgress(WordLesson.cvc).completed.length,
            target: 5),
        ProgressBadge(
            id: 'Blending Champion',
            title: 'Blending Champion',
            description: 'Complete your first blending word puzzle.',
            current: wordLessonProgress(WordLesson.blending).completed.length,
            target: 1),
        ProgressBadge(
            id: '3-Day Streak',
            title: '3-Day Streak',
            description:
                'Answer questions or practice speaking on 3 consecutive days.',
            current: bestLearningStreak,
            target: 3),
        for (final (target, title) in [
          (5, '5 Letters Mastered'),
          (13, 'Halfway There'),
          (26, 'Alphabet Master')
        ])
          ProgressBadge(
              id: title,
              title: title,
              description: 'Master $target letters in Quick Check.',
              current: overallMasteredCount,
              target: target,
              milestone: true),
      ];
  String? get recommendedAdventureLetter {
    // Keep a child's current target through retries and unrelated activities.
    // Only the existing AdventurePolicy mastery decision advances it.
    final current = _recommendedAdventureLetter;
    if (current != null && !adventureProgress(current).mastered) return current;
    final pending = adventureContents
        .map((c) => c.letter)
        .where((letter) => !adventureProgress(letter).mastered)
        .toList();
    pending.sort((a, b) {
      final pa = adventureProgress(a), pb = adventureProgress(b);
      final attempted =
          (pa.completed == 0 ? 1 : 0).compareTo(pb.completed == 0 ? 1 : 0);
      if (attempted != 0) return attempted;
      final score = pa.lastScore.compareTo(pb.lastScore);
      return score != 0 ? score : a.compareTo(b);
    });
    return pending.isEmpty ? null : pending.first;
  }

  Future<({int xp, int stars})> completeAdventure(
      String letter, List<bool> answers, String sessionId) async {
    if (!RegExp(r'^[A-Z]$').hasMatch(letter) ||
        answers.length != 5 ||
        sessionId.isEmpty) {
      throw ArgumentError(
          'A letter adventure requires five first responses and a session identity.');
    }
    await ready;
    final previous = adventureProgress(letter);
    if (previous.sessionId == sessionId) return (xp: 0, stars: 0);
    _recommendedAdventureLetter ??= recommendedAdventureLetter;
    final score = answers.where((v) => v).length;
    final newMastery = !previous.mastered && AdventurePolicy.passes(answers);
    final xp = (previous.completed == 0 ? 5 : 0) + (newMastery ? 25 : 0);
    final stars = newMastery ? 1 : 0;
    _adventures[letter] = AdventureProgress(
        completed: previous.completed + 1,
        best: score > previous.best ? score : previous.best,
        mastered: previous.mastered || newMastery,
        masteredAt: previous.masteredAt ??
            (newMastery ? _now().toIso8601String() : null),
        lastAnswers: List.unmodifiable(answers),
        sessionId: sessionId);
    _recommendedAdventureLetter = recommendedAdventureLetter;
    for (final correct in answers) {
      _recordAnswer(correct);
    }
    _recordCompletion();
    _xp += xp;
    _stars += stars;
    _changed();
    await _savePrefs();
    return (xp: xp, stars: stars);
  }

  final Map<String, DailyActivity> _dailyActivity = {};
  final DateTime Function() _now;
  String? _lastPracticeDate;
  late Future<void> ready;
  Object? _loadError;
  bool get hasLoadError => _loadError != null;
  Future<void> retryLoading() {
    if (isReady || !hasLoadError) return ready;
    _loadError = null;
    ready = _loadPrefs();
    _changed();
    return ready;
  }

  final _saveQueue = PreferenceWriteQueue();
  bool get hasUnsavedChanges => _saveQueue.lastError != null;
  Future<void> retrySaving() async {
    await ready;
    await _savePrefs();
    await screenTime.save();
  }

  Object? _timeDisplay;
  void _screenTimeChanged() {
    final display = (
      screenTime.usedSecondsToday ~/ 60,
      screenTime.dateKey,
      screenTime.isLimitReached,
      screenTime.isLimitEnabled,
      screenTime.dailyLimitMinutes,
      screenTime.extraSecondsToday,
      screenTime.isBypassedToday,
      screenTime.hasUnsavedChanges
    );
    if (_timeDisplay == display) return;
    _timeDisplay = display;
    _changed();
  }

  bool _disposed = false;

  late final ParentAuthService parentAuth;
  late final ScreenTimeService screenTime;
  bool isReady = false;
  void _authChanged() {
    screenTime.setParentActive(parentAuth.isAuthenticated);
    _changed();
  }

  // Settings and learning statistics
  bool get voiceEnabled => _voiceEnabled;
  bool get sfxEnabled => _sfxEnabled;
  bool get gameAccess => _gameAccess;
  bool get timeLimitEnabled => screenTime.isLimitEnabled;
  bool get timeLimitReached => screenTime.isLimitReached;
  bool get rhymingWordsDone => _rhymingWordsDone;
  int get xp => _xp;
  int get streak {
    if (_lastPracticeDate == null) return 0;
    final gap =
        calendarDay(_now()) - calendarDay(DateTime.parse(_lastPracticeDate!));
    return gap > 1 ? 0 : _streak;
  }

  int get stars => _stars;
  List<LetterProgress> get allLetterProgress => List.unmodifiable(
      List.generate(26, (i) => getLetterProgress(String.fromCharCode(65 + i))));
  Set<String> get masteredLetters => Set.unmodifiable(
      allLetterProgress.where((p) => p.mastered).map((p) => p.letter));
  int get masteredLetterCount => masteredLetters.length;
  // Counts describe current, mutually exclusive states.
  int get practicedLetterCount => allLetterProgress
      .where((p) => p.status == LearningStatus.practiced)
      .length;
  int get viewedLetterCount =>
      allLetterProgress.where((p) => p.status == LearningStatus.viewed).length;
  int get notStartedLetterCount => allLetterProgress
      .where((p) => p.status == LearningStatus.notStarted)
      .length;
  double get masteryPercentage =>
      (masteredLetterCount / 26 * 100).clamp(0.0, 100.0);
  int get masteredVowelCount => const ['A', 'E', 'I', 'O', 'U']
      .where((letter) => getLetterProgress(letter).mastered)
      .length;
  List<LetterProgress> get lettersNeedingPractice {
    final letters =
        allLetterProgress.where((p) => p.attempts > 0 && !p.mastered).toList();
    letters.sort((a, b) {
      final order = a.accuracy!.compareTo(b.accuracy!);
      return order == 0 ? a.letter.compareTo(b.letter) : order;
    });
    return List.unmodifiable(letters);
  }

  LetterProgress? get recommendedNextPractice {
    final practice = lettersNeedingPractice;
    if (practice.isNotEmpty) return practice.first;
    for (final status in [LearningStatus.viewed, LearningStatus.notStarted]) {
      for (final letter in allLetterProgress) {
        if (letter.status == status) return letter;
      }
    }
    return null;
  }

  WeeklyLearningSummary getWeeklySummary() =>
      WeeklyLearningSummary(today, dailyActivity);

  // Retains an earned streak badge using actual stored learning days, without
  // adding a duplicate persisted flag or re-awarding anything on rebuild.
  bool get hasThreeDayLearningStreak => bestLearningStreak >= 3;

  int get bestLearningStreak {
    final dates = _dailyActivity.entries
        .where(
            (e) => e.value.questionsAnswered > 0 || e.value.speechAttempts > 0)
        .map((e) => DateTime.tryParse(e.key))
        .whereType<DateTime>()
        .map(calendarDay)
        .toSet()
        .toList()
      ..sort();
    var run = 0, best = 0;
    int? previous;
    for (final date in dates) {
      if (date > calendarDay(today)) continue;
      run = previous != null && date == previous + 1 ? run + 1 : 1;
      if (run > best) best = run;
      previous = date;
    }
    return best;
  }

  List<LearningAchievement> get learningAchievements => [
        LearningAchievement('First Mastery', 'Mastered your first letter',
            unlockedMasteryMilestones.contains(1)),
        LearningAchievement('5 Letters Mastered', 'Mastered 5 letters',
            unlockedMasteryMilestones.contains(5)),
        LearningAchievement('Halfway There', 'Mastered 13 letters',
            unlockedMasteryMilestones.contains(13)),
        LearningAchievement('Alphabet Master', 'Mastered all 26 letters',
            unlockedMasteryMilestones.contains(26)),
        LearningAchievement(
            '3-Day Streak',
            'Answered questions on 3 consecutive days',
            hasThreeDayLearningStreak),
      ];
  int get unlockedAchievementCount =>
      learningAchievements.where((a) => a.unlocked).length;
  List<LearningAchievement> get quickCheckAchievements => [
        for (final badge in progressBadges)
          LearningAchievement(badge.id, badge.description, badge.earned),
      ];
  double? get overallActivityAccuracy {
    final attempts =
        _dailyActivity.values.fold(0, (n, d) => n + d.questionsAnswered);
    if (attempts == 0) return null;
    return _dailyActivity.values.fold(0, (n, d) => n + d.correctAnswers) /
        attempts;
  }

  double? get letterPracticeAccuracy {
    final attempts = allLetterProgress.fold(0, (sum, p) => sum + p.attempts);
    if (attempts == 0) return null;
    return allLetterProgress.fold(0, (sum, p) => sum + p.correctAnswers) /
        attempts;
  }

  static const masteryThresholds = [1, 5, 13, 26];
  final _masteryMilestones = StreamController<int>.broadcast();
  Stream<int> get masteryMilestones => _masteryMilestones.stream;
  Set<int> get unlockedMasteryMilestones => masteryThresholds
      .where((threshold) => masteredLetterCount >= threshold)
      .toSet();

  Map<String, DailyActivity> get dailyActivity =>
      Map.unmodifiable(_dailyActivity);
  DateTime get today => _now();
  LetterProgress getLetterProgress(String letter) {
    final key = letter.toUpperCase();
    if (!RegExp(r'^[A-Z]$').hasMatch(key)) {
      throw ArgumentError.value(letter, 'letter');
    }
    return _letterProgress[key] ?? LetterProgress(letter: key);
  }

  LearningStatus getLetterStatus(String letter) =>
      getLetterProgress(letter).status;

  int get level => (_xp / 200).floor() + 1;

  AppProvider({DateTime Function()? now}) : _now = now ?? DateTime.now {
    ready = _loadPrefs();
  }

  // Local audio and settings

  /// Play pre-recorded audio for [text] — main speech player.
  Future<void> speak(String text) async {
    if (!_voiceEnabled) return;
    await audio.stop();
    await phonicsAudio.tryPlay(text);
  }

  /// Play a hint on the same replaceable instructional channel.
  Future<void> speakHint(String text) async {
    if (!_voiceEnabled) return;
    await audio.stop();
    await phonicsAudio.tryPlayHint(text);
  }

  Future<void> toggleVoice() async {
    await ready;
    _voiceEnabled = !_voiceEnabled;
    if (!_voiceEnabled) {
      await phonicsAudio.stop();
    }
    _changed();
    await _savePrefs();
  }

  Future<void> toggleSfx() async {
    await ready;
    _sfxEnabled = !_sfxEnabled;
    audio.enabled = _sfxEnabled;
    _changed();
    await _savePrefs();
  }

  Future<void> toggleGameAccess() async {
    await ready;
    parentAuth.requireSession();
    _gameAccess = !_gameAccess;
    _changed();
    await _savePrefs();
  }

  Future<void> toggleTimeLimit() =>
      screenTime.setLimitEnabled(!timeLimitEnabled);

  // Rewards: formulas belong to activities; these methods persist exact awards.
  Future<void> addXP(int amount) async {
    await ready;
    _xp += amount;
    _changed();
    await _savePrefs();
  }

  Future<void> addStar() async {
    await ready;
    _stars++;
    _changed();
    await _savePrefs();
  }

  // Letter practice and assessment.
  Future<void> markLetterViewed(String letter) async {
    await ready;
    final p = getLetterProgress(letter);
    _letterProgress[p.letter] = p.copyWith(viewCount: p.viewCount + 1);
    _changed();
    await _savePrefs();
  }

  Future<void> recordLetterListening(
      String letter, LetterListeningKind kind) async {
    await ready;
    final p = getLetterProgress(letter);
    _letterProgress[p.letter] = p.copyWith(
        viewCount: p.viewCount == 0 ? 1 : p.viewCount,
        nameListens: p.nameListens + (kind == LetterListeningKind.name ? 1 : 0),
        soundListens:
            p.soundListens + (kind == LetterListeningKind.sound ? 1 : 0),
        wordListens:
            p.wordListens + (kind == LetterListeningKind.word ? 1 : 0));
    _changed();
    await _savePrefs();
  }

  Future<void> recordLetterPractice(String letter, bool correct) async {
    await ready;
    final p = getLetterProgress(letter);
    _letterProgress[p.letter] = p.copyWith(
        attempts: p.attempts + 1,
        correctAnswers: p.correctAnswers + (correct ? 1 : 0));
    _recordAnswer(correct);
    _changed();
    await _savePrefs();
  }

  /// Answers are recorded as they happen by recordLetterPractice.
  /// Commits the result only, without counting answers twice.
  Future<void> completeLetterAssessment(
      String letter, int correct, int total) async {
    if (total != 5 || correct < 0 || correct > total) {
      throw ArgumentError(
          'A mastery check must contain exactly five scored answers.');
    }
    await ready;
    final p = getLetterProgress(letter);
    final previousMasteredCount = masteredLetterCount;
    final passed = correct >= 4;
    _letterProgress[p.letter] = p.copyWith(
      completedAssessments: p.completedAssessments + 1,
      bestAssessmentScore:
          correct > p.bestAssessmentScore ? correct : p.bestAssessmentScore,
      mastered: p.mastered || passed,
      masteredAt:
          !p.mastered && passed ? _now().toIso8601String() : p.masteredAt,
    );
    final newMasteredCount = masteredLetterCount;
    for (final threshold in masteryThresholds) {
      if (previousMasteredCount < threshold &&
          newMasteredCount >= threshold &&
          !_disposed) {
        _masteryMilestones
            .add(threshold); // Visual achievement only; no automatic voice.
      }
    }
    _recordCompletion();
    _changed();
    await _savePrefs();
  }

  // Daily activity and streaks.
  void _recordAnswer(bool correct) {
    final key = localDateKey(_now());
    final d = _dailyActivity[key] ?? const DailyActivity();
    _dailyActivity[key] = d.copyWith(
        questionsAnswered: d.questionsAnswered + 1,
        correctAnswers: d.correctAnswers + (correct ? 1 : 0),
        activitiesCompleted: d.activitiesCompleted);
    _recordPracticeDay(key);
  }

  void _recordPracticeDay(String key) {
    if (_lastPracticeDate != key) {
      final gap = _lastPracticeDate == null
          ? null
          : calendarDay(_now()) -
              calendarDay(DateTime.parse(_lastPracticeDate!));
      _streak = gap == 1 ? _streak + 1 : 1;
      _lastPracticeDate = key;
    }
  }

  Future<void> recordDailyAnswer({required bool correct}) async {
    await ready;
    _recordAnswer(correct);
    _changed();
    await _savePrefs();
  }

  Future<void> recordSpeechPractice({required bool correct}) async {
    await ready;
    final key = localDateKey(_now());
    final d = _dailyActivity[key] ?? const DailyActivity();
    _dailyActivity[key] = d.copyWith(
        speechAttempts: d.speechAttempts + 1,
        speechRecognized: d.speechRecognized + (correct ? 1 : 0));
    _recordPracticeDay(key);
    _changed();
    await _savePrefs();
  }

  Future<void> recordSpeechCompletion() async {
    await ready;
    final key = localDateKey(_now());
    final d = _dailyActivity[key] ?? const DailyActivity();
    _dailyActivity[key] =
        d.copyWith(speechActivitiesCompleted: d.speechActivitiesCompleted + 1);
    _changed();
    await _savePrefs();
  }

  void _recordCompletion() {
    final key = localDateKey(_now());
    final d = _dailyActivity[key] ?? const DailyActivity();
    _dailyActivity[key] = d.copyWith(
        questionsAnswered: d.questionsAnswered,
        correctAnswers: d.correctAnswers,
        activitiesCompleted: d.activitiesCompleted + 1);
  }

  Future<void> recordActivityCompleted() async {
    await ready;
    _recordCompletion();
    _changed();
    await _savePrefs();
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> markRhymingWordsDone() async {
    await ready;
    if (_rhymingWordsDone) return;
    _rhymingWordsDone = true;
    _changed();
    await _savePrefs();
  }

  // Parent-authorized reset; authentication and screen time are separate stores.
  Future<bool> resetProgress() async {
    await ready;
    parentAuth.requireSession();
    _xp = 0;
    _streak = 0;
    _stars = 0;
    _letterProgress.clear();
    _wordLessons.clear();
    _adventures.clear();
    _recommendedAdventureLetter = null;
    _journeyScores.clear();
    _dailyActivity.clear();
    _lastPracticeDate = null;
    _rhymingWordsDone = false;
    _changed();
    await _savePrefs();
    return !hasUnsavedChanges;
  }
  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _loadPrefs() async {
    final SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (error) {
      // Do not continue with empty data or overwrite an unreadable save.
      _loadError = error;
      _changed();
      return;
    }
    final snapshot = _decodeMap(prefs.get('appStateV1'));
    Object? read(String key) =>
        snapshot.containsKey(key) ? snapshot[key] : prefs.get(key);
    T setting<T>(String key, T fallback) {
      final value = read(key);
      return value is T ? value : fallback;
    }

    if (_disposed) return;
    parentAuth = ParentAuthService(prefs, now: _now);
    screenTime = ScreenTimeService(prefs, parentAuth, now: _now);
    screenTime.addListener(_screenTimeChanged);
    parentAuth.addListener(_authChanged);
    isReady = true;
    _voiceEnabled = setting('voice', true);
    _sfxEnabled = setting('sfx', true);
    _musicEnabled = setting('musicEnabled', true);
    final textSize = read('textSizeMultiplierV1');
    _textSizeMultiplier = textSize is num && textSize.isFinite
        ? textSize.toDouble().clamp(1.0, 1.3)
        : 1;
    _reducedAnimations = setting('reducedAnimationsV1', false);
    final volume = read('musicVolume');
    _musicVolume =
        volume is num && volume.isFinite ? volume.toDouble().clamp(0, .4) : .12;
    _gameAccess = setting('gameAccess', true);
    _studentCharacter =
        setting('studentCharacter', 'boy') == 'girl' ? 'girl' : 'boy';
    _studentName = setting('studentName', '').characters.take(24).toString();
    _welcomeCompleted = setting('welcomeCompletedV1', _studentName.isNotEmpty);

    _rhymingWordsDone = setting('rhymingDone', false);
    final wordLessons = _decodeMap(read('wordLessonProgressV1'));
    for (final lesson in WordLesson.values) {
      _wordLessons[lesson] =
          WordLessonProgress.fromJson(wordLessons[lesson.name], lesson);
    }
    for (final entry in _decodeMap(read('letterAdventuresV1')).entries) {
      if (RegExp(r'^[A-Z]$').hasMatch(entry.key) && entry.value is Map) {
        _adventures[entry.key] = AdventureProgress.fromJson(entry.value as Map);
      }
    }
    final recommendation = read('recommendedAdventureLetterV1');
    if (recommendation is String &&
        RegExp(r'^[A-Z]$').hasMatch(recommendation)) {
      _recommendedAdventureLetter = recommendation;
    }
    // Existing saves migrate using their current recommendation ranking.
    _recommendedAdventureLetter = recommendedAdventureLetter;
    for (final entry in _decodeMap(read('journeyScoresV1')).entries) {
      if (entry.value is int && entry.value >= 0 && entry.value <= 100) {
        _journeyScores[entry.key] = entry.value as int;
      }
    }
    _xp = safeCount(read('xp'));
    _streak = safeCount(read('streakV2'));
    _stars = safeCount(read('stars'));
    final saved = read('letterProgressV2');
    if (saved != null) {
      for (final entry in _decodeMap(saved).entries) {
        if (!RegExp(r'^[A-Z]$').hasMatch(entry.key) || entry.value is! Map) {
          continue;
        }
        final value = Map<String, dynamic>.from(entry.value as Map);
        // The A-Z key owns identity; damaged payloads cannot duplicate letters.
        value['letter'] = entry.key;
        _letterProgress[entry.key] = LetterProgress.fromJson(value);
      }
    } else {
      final legacy = prefs.get('learned');
      for (final letter
          in legacy is List ? legacy.whereType<String>() : <String>[]) {
        final key = letter.toUpperCase();
        if (RegExp(r'^[A-Z]$').hasMatch(key)) {
          // Legacy navigation marked letters learned; it never proved mastery.
          _letterProgress[key] = LetterProgress(letter: key, viewCount: 1);
        }
      }
      await _saveQueue.save(prefs, {
        'letterProgressV2':
            jsonEncode(_letterProgress.map((k, v) => MapEntry(k, v.toJson()))),
        'learned': null,
      });
    }
    for (final entry in _decodeMap(read('dailyActivityV1')).entries) {
      if (validLocalDate(entry.key) == null || entry.value is! Map) continue;
      _dailyActivity[entry.key] =
          DailyActivity.fromJson(Map<String, dynamic>.from(entry.value as Map));
    }
    _lastPracticeDate = validLocalDate(read('lastPracticeDateV1'));
    audio.enabled = _sfxEnabled;
    _changed();
  }

  static Map<String, dynamic> _decodeMap(Object? value) {
    if (value is! String) return {};
    try {
      final decoded = jsonDecode(value);
      return decoded is Map<String, dynamic> ? decoded : {};
    } on FormatException {
      return {};
    }
  }

  Future<void> _savePrefs() async {
    // Serialize snapshots so an older save cannot overwrite a newer result.
    final letters =
        jsonEncode(_letterProgress.map((k, v) => MapEntry(k, v.toJson())));
    final activity =
        jsonEncode(_dailyActivity.map((k, v) => MapEntry(k, v.toJson())));
    final values = <String, Object>{
      'voice': _voiceEnabled,
      'sfx': _sfxEnabled,
      'musicEnabled': _musicEnabled,
      'musicVolume': _musicVolume,
      'textSizeMultiplierV1': _textSizeMultiplier,
      'reducedAnimationsV1': _reducedAnimations,
      'gameAccess': _gameAccess,
      'studentCharacter': _studentCharacter,
      'studentName': _studentName,
      'welcomeCompletedV1': _welcomeCompleted,
      'rhymingDone': _rhymingWordsDone,
      'journeyScoresV1': jsonEncode(_journeyScores),
      'wordLessonProgressV1': jsonEncode({
        for (final entry in _wordLessons.entries)
          entry.key.name: entry.value.toJson(),
      }),
      'xp': _xp,
      'stars': _stars,
      'streakV2': streak,
      'letterProgressV2': letters,
      'letterAdventuresV1':
          jsonEncode(_adventures.map((k, v) => MapEntry(k, v.toJson()))),
      'dailyActivityV1': activity,
    };
    final snapshot = <String, Object?>{
      ...values,
      'lastPracticeDateV1': _lastPracticeDate,
      'recommendedAdventureLetterV1': recommendedAdventureLetter,
    };
    final prefs = await SharedPreferences.getInstance();
    // Commit one authoritative snapshot before mirroring legacy keys.
    final errorBefore = hasUnsavedChanges;
    await _saveQueue.save(prefs, {
      'appStateV1': jsonEncode(snapshot),
      ...snapshot,
      'learned': null,
      'streak': null,
    });
    if (errorBefore != hasUnsavedChanges) _changed();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_masteryMilestones.close());
    if (isReady) {
      parentAuth.removeListener(_authChanged);
      screenTime.removeListener(_screenTimeChanged);
      screenTime.dispose();
      parentAuth.dispose();
    }
    super.dispose();
  }
}
