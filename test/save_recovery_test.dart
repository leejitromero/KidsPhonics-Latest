import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/services/preference_write_queue.dart';
import 'package:kidsphonics/services/screen_time_service.dart';
import 'package:kidsphonics/services/parent_auth_service.dart';
import 'package:kidsphonics/models/learning_progress.dart';
import 'package:kidsphonics/widgets/time_limit_overlay.dart';
import 'learning_progress_test.dart' show mockProgressAudio;

class FailingStore extends InMemorySharedPreferencesStore {
  FailingStore() : super.empty();
  int failures = 0, writes = 0, loadFailures = 0;
  bool throwError = false;
  String? failKey;
  @override
  Future<Map<String, Object>> getAll() async {
    if (loadFailures > 0) {
      loadFailures--;
      throw StateError('storage temporarily unreadable');
    }
    return super.getAll();
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    writes++;
    if (failures > 0 && (failKey == null || key == 'flutter.$failKey')) {
      failures--;
      if (throwError) throw StateError('storage unavailable');
      return false;
    }
    return super.setValue(valueType, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FailingStore store;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = FailingStore();
    SharedPreferencesStorePlatform.instance = store;
    mockProgressAudio();
  });
  for (final throws in [false, true]) {
    test(
        'save queue checks ${throws ? 'exceptions' : 'false results'} and recovers',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final queue = PreferenceWriteQueue();
      store
        ..failures = 3
        ..throwError = throws;
      expect(await queue.save(prefs, {'xp': 10}), isFalse);
      expect(queue.lastError, isNotNull);
      expect(await queue.save(prefs, {'xp': 20}), isTrue);
      expect(queue.lastError, isNull);
      await prefs.reload();
      expect(prefs.getInt('xp'), 20);
      final writes = store.writes;
      await queue.save(prefs, {'xp': 20});
      expect(store.writes, writes);
    });
  }
  test('failed startup retries existing data without writing empty progress',
      () async {
    await store.setValue('Int', 'flutter.xp', 125);
    final writesBefore = store.writes;
    store.loadFailures = 2;
    final p = AppProvider();
    await p.ready;
    expect(p.isReady, isFalse);
    expect(p.hasLoadError, isTrue);
    expect(store.writes, writesBefore);
    await p.retryLoading();
    expect(p.hasLoadError, isTrue);
    expect(store.writes, writesBefore);
    await p.retryLoading();
    expect(p.hasLoadError, isFalse);
    expect(p.isReady, isTrue);
    expect(p.xp, 125);
    p.dispose();
  });
  testWidgets('startup Retry restores the app and starts screen time tracking',
      (t) async {
    store.loadFailures = 1;
    late AppProvider p;
    await t.runAsync(() async {
      p = AppProvider();
      await p.ready;
    });
    await t.pumpWidget(ChangeNotifierProvider.value(
        value: p,
        child: MaterialApp(
            builder: (_, child) => TimeLimitOverlay(child: child!),
            home: const Scaffold(body: Text('Learner Home')))));
    await t.pump();
    expect(find.byKey(const ValueKey('startup-retry')), findsOneWidget);
    expect(find.text('Learner Home'), findsNothing);
    await t.runAsync(() async {
      await t.tap(find.byKey(const ValueKey('startup-retry')));
      await p.ready;
    });
    await t.pumpAndSettle();
    expect(find.text('Learner Home'), findsOneWidget);
    expect(find.byKey(const ValueKey('startup-retry')), findsNothing);
    await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1100)));
    await t.pump(const Duration(seconds: 1));
    expect(p.screenTime.usedSecondsToday, greaterThanOrEqualTo(1));
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    p.dispose();
  });
  test(
      'app retries the latest snapshot and restores it independently of mirrors',
      () async {
    final p = AppProvider();
    await p.ready;
    await p.retrySaving();
    store.failures = 3;
    await p.addXP(10);
    expect(p.hasUnsavedChanges, isTrue);
    await p.addXP(20);
    expect(p.hasUnsavedChanges, isFalse);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('xp', 999);
    final restored = AppProvider();
    await restored.ready;
    expect(restored.xp, 30);
    expect(jsonDecode(prefs.getString('appStateV1')!)['xp'], 30);
    p.dispose();
    restored.dispose();
  });
  test('screen time retries failed usage and subsequent saves survive',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final auth = ParentAuthService(prefs);
    var elapsed = 0;
    final time =
        ScreenTimeService(prefs, auth, elapsedMilliseconds: () => elapsed);
    await time.save();
    time.startTracking();
    elapsed = 5000;
    time.tick();
    store.failures = 3;
    await time.save();
    expect(time.hasUnsavedChanges, isTrue);
    await time.save();
    expect(time.hasUnsavedChanges, isFalse);
    await prefs.reload();
    final restored = ScreenTimeService(prefs, auth);
    expect(restored.usedSecondsToday, 5);
    await time.pauseTracking();
    time.dispose();
    restored.dispose();
    auth.dispose();
  });
  test('failed reset reports pending save and retries without losing the reset',
      () async {
    final p = AppProvider();
    await p.ready;
    await p.parentAuth.setup('2580', '2580');
    await p.addXP(25);
    store
      ..failKey = 'appStateV1'
      ..failures = 3;
    expect(await p.resetProgress(), isFalse);
    expect(p.xp, 0);
    expect(p.hasUnsavedChanges, isTrue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    expect(jsonDecode(prefs.getString('appStateV1')!)['xp'], 25);
    await p.retrySaving();
    expect(p.hasUnsavedChanges, isFalse);
    await prefs.reload();
    final restored = AppProvider();
    await restored.ready;
    expect(restored.xp, 0);
    p.dispose();
    restored.dispose();
  });
  test(
      'failed initial migration does not prevent startup or later progress saving',
      () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('learned', ['B']);
    store
      ..failures = 3
      ..throwError = true
      ..failKey = 'letterProgressV2';
    final p = AppProvider();
    await p.ready;
    expect(p.isReady, isTrue);
    expect(p.getLetterStatus('B'), LearningStatus.viewed);
    expect(p.hasUnsavedChanges, isTrue);
    await p.retrySaving();
    expect(p.hasUnsavedChanges, isFalse);
    await prefs.reload();
    expect(prefs.containsKey('learned'), isFalse);
    final restored = AppProvider();
    await restored.ready;
    expect(restored.getLetterStatus('B'), LearningStatus.viewed);
    p.dispose();
    restored.dispose();
  });
  test('speech and listening records persist separately from quiz accuracy',
      () async {
    final p = AppProvider(now: () => DateTime(2026, 10, 7));
    await p.ready;
    await p.recordSpeechPractice(correct: true);
    await p.recordSpeechPractice(correct: false);
    await p.recordSpeechCompletion();
    await p.recordLetterListening('A', LetterListeningKind.sound);
    await p.recordDailyAnswer(correct: true);
    final restored = AppProvider(now: () => DateTime(2026, 10, 7));
    await restored.ready;
    final week = restored.getWeeklySummary();
    expect(week.speechAttempts, 2);
    expect(week.speechRecognized, 1);
    expect(week.speechActivitiesCompleted, 1);
    expect(week.questionsAnswered, 1);
    expect(week.accuracy, 1);
    expect(restored.getLetterProgress('A').soundListens, 1);
    expect(restored.getLetterProgress('A').mastered, isFalse);
    expect(restored.streak, 1);
    p.dispose();
    restored.dispose();
  });
  test(
      'ordinary screen-time seconds do not rebuild the global learning provider',
      () async {
    final p = AppProvider();
    await p.ready;
    await p.retrySaving();
    var changes = 0;
    p.addListener(() => changes++);
    p.screenTime.startTracking(); // Initialize the display projection.
    final before = changes;
    await Future<void>.delayed(const Duration(milliseconds: 2100));
    p.screenTime.tick();
    expect(p.screenTime.usedSecondsToday, greaterThanOrEqualTo(2));
    expect(changes, before);
    p.dispose();
  });
}
