// lib/providers/app_provider.dart
import 'dart:async';
import 'dart:convert';
import '../services/parent_auth_service.dart';
import '../services/screen_time_service.dart';
import '../models/learning_progress.dart';
import '../models/weekly_learning_summary.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/audio_service.dart';
import '../services/phonics_audio_service.dart';
import '../services/voice_feedback_service.dart';

class AppProvider extends ChangeNotifier {
  final AudioService audio = AudioService();
  final PhonicsAudioService phonicsAudio = PhonicsAudioService();
  final VoiceFeedbackService voiceFeedback = VoiceFeedbackService();

  bool _voiceEnabled = true;
  bool _sfxEnabled = true;
  bool _musicEnabled = true;
  double _musicVolume = .12;
  bool get musicEnabled => _musicEnabled;
  double get musicVolume => _musicVolume;

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

  bool _rhymingWordsDone = false;
  int _xp = 0;
  int _streak = 0;
  int _stars = 0;
  final Map<String, LetterProgress> _letterProgress = {};
  final Map<String, DailyActivity> _dailyActivity = {};
  final DateTime Function() _now;
  String? _lastPracticeDate;
  late final Future<void> ready;
  Future<void> _pendingSave = Future.value();
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
  bool get hasThreeDayLearningStreak {
    final dates = _dailyActivity.entries
        .where((e) => e.value.questionsAnswered > 0)
        .map((e) => DateTime.tryParse(e.key))
        .whereType<DateTime>()
        .map(calendarDay)
        .toSet()
        .toList()
      ..sort();
    var run = 0;
    int? previous;
    for (final date in dates) {
      if (date > calendarDay(today)) continue;
      run = previous != null && date == previous + 1 ? run + 1 : 1;
      if (run >= 3) return true;
      previous = date;
    }
    return false;
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
    await voiceFeedback.stop();
    await audio.stop();
    await phonicsAudio.tryPlay(text);
  }

  /// Play a hint on the same replaceable instructional channel.
  Future<void> speakHint(String text) async {
    if (!_voiceEnabled) return;
    await voiceFeedback.stop();
    await audio.stop();
    await phonicsAudio.tryPlayHint(text);
  }

  Future<void> toggleVoice() async {
    await ready;
    _voiceEnabled = !_voiceEnabled;
    if (!_voiceEnabled) {
      await phonicsAudio.stop();
      await voiceFeedback.stop();
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
  Future<void> addXP(int amount, {bool announce = true}) async {
    await ready;
    final prevXp = _xp;
    final prevLevel = level;
    _xp += amount;
    _changed();
    await _savePrefs();
    // Check milestones after XP change
    if (announce && _voiceEnabled) {
      voiceFeedback.checkRewardMilestones(
        xp: _xp,
        streak: _streak,
        prevXp: prevXp,
        prevStreak: _streak,
        level: level,
        prevLevel: prevLevel,
      );
    }
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
    _dailyActivity[key] = DailyActivity(
        questionsAnswered: d.questionsAnswered + 1,
        correctAnswers: d.correctAnswers + (correct ? 1 : 0),
        activitiesCompleted: d.activitiesCompleted);
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

  void _recordCompletion() {
    final key = localDateKey(_now());
    final d = _dailyActivity[key] ?? const DailyActivity();
    _dailyActivity[key] = DailyActivity(
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
  Future<void> resetProgress() async {
    await ready;
    parentAuth.requireSession();
    _xp = 0;
    _streak = 0;
    _stars = 0;
    _letterProgress.clear();
    _dailyActivity.clear();
    _lastPracticeDate = null;
    _rhymingWordsDone = false;
    _changed();
    await _savePrefs();
  }
  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_disposed) return;
    parentAuth = ParentAuthService(prefs, now: _now);
    screenTime = ScreenTimeService(prefs, parentAuth, now: _now);
    screenTime.addListener(_changed);
    parentAuth.addListener(_authChanged);
    isReady = true;
    _voiceEnabled = _read(prefs, 'voice', true);
    _sfxEnabled = _read(prefs, 'sfx', true);
    _musicEnabled = _read(prefs, 'musicEnabled', true);
    final volume = prefs.get('musicVolume');
    _musicVolume =
        volume is num && volume.isFinite ? volume.toDouble().clamp(0, .4) : .12;
    _gameAccess = _read(prefs, 'gameAccess', true);

    _rhymingWordsDone = _read(prefs, 'rhymingDone', false);
    _xp = safeCount(prefs.get('xp'));
    _streak = safeCount(prefs.get('streakV2'));
    _stars = safeCount(prefs.get('stars'));
    final saved = prefs.get('letterProgressV2');
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
      final migrated = await prefs.setString('letterProgressV2',
          jsonEncode(_letterProgress.map((k, v) => MapEntry(k, v.toJson()))));
      if (migrated) await prefs.remove('learned');
    }
    for (final entry in _decodeMap(prefs.get('dailyActivityV1')).entries) {
      if (validLocalDate(entry.key) == null || entry.value is! Map) continue;
      _dailyActivity[entry.key] =
          DailyActivity.fromJson(Map<String, dynamic>.from(entry.value as Map));
    }
    _lastPracticeDate = validLocalDate(prefs.get('lastPracticeDateV1'));
    audio.enabled = _sfxEnabled;
    _changed();
  }

  static T _read<T>(SharedPreferences prefs, String key, T fallback) {
    final value = prefs.get(key);
    return value is T ? value : fallback;
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

  Future<void> _savePrefs() {
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
      'gameAccess': _gameAccess,
      'rhymingDone': _rhymingWordsDone,
      'xp': _xp,
      'stars': _stars,
      'streakV2': streak,
      'letterProgressV2': letters,
      'dailyActivityV1': activity,
    };
    final lastDate = _lastPracticeDate;
    _pendingSave = _pendingSave.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      for (final entry in values.entries) {
        final value = entry.value;
        if (value is bool) {
          await prefs.setBool(entry.key, value);
        }
        if (value is int) {
          await prefs.setInt(entry.key, value);
        }
        if (value is double) {
          await prefs.setDouble(entry.key, value);
        }
        if (value is String) {
          await prefs.setString(entry.key, value);
        }
      }
      if (lastDate == null) {
        await prefs.remove('lastPracticeDateV1');
      } else {
        await prefs.setString('lastPracticeDateV1', lastDate);
      }
      await prefs.remove('learned');
      await prefs.remove('streak');
    });
    return _pendingSave;
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_masteryMilestones.close());
    if (isReady) {
      parentAuth.removeListener(_authChanged);
      screenTime.removeListener(_changed);
      screenTime.dispose();
      parentAuth.dispose();
    }
    super.dispose();
  }
}
