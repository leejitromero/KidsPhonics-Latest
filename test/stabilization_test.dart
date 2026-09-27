import 'dart:async';
import 'package:kidsphonics/widgets/parent_pin_form.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/learning_progress.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/services/parent_auth_service.dart';
import 'package:kidsphonics/services/screen_time_service.dart';
import 'package:kidsphonics/services/audio_service.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';
import 'package:kidsphonics/services/mastery_audio_service.dart';
import 'package:kidsphonics/theme/app_theme.dart';
import 'learning_progress_test.dart' show mockProgressAudio;

class _DelayedAuth extends ParentAuthService {
  _DelayedAuth(super.prefs);
  final completed = Completer<String?>();
  int calls = 0;
  @override
  Future<String?> setup(String pin, String confirmation) {
    calls++;
    return completed.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
  });
  test('damaged preference types and JSON cannot block startup', () async {
    SharedPreferences.setMockInitialValues({
      'voice': 'invalid',
      'sfx': 1,
      'gameAccess': 'invalid',
      'xp': -200,
      'stars': 'bad',
      'streakV2': 999,
      'lastPracticeDateV1': 'broken date',
      'letterProgressV2': '{incomplete',
      'dailyActivityV1': '[1,2,3]',
    });
    final p = AppProvider();
    await p.ready;
    expect(p.isReady, isTrue);
    expect(p.voiceEnabled, isTrue);
    expect(p.sfxEnabled, isTrue);
    expect(p.gameAccess, isTrue);
    expect(p.xp, 0);
    expect(p.stars, 0);
    expect(p.streak, 0);
    expect(p.masteredLetterCount, 0);
    expect(p.dailyActivity, isEmpty);
    p.dispose();
  });
  test(
      'valid records survive beside corrupt entries and counters stay in range',
      () async {
    SharedPreferences.setMockInitialValues({
      'letterProgressV2': jsonEncode({
        'A': {
          'letter': 'Z',
          'viewCount': 2,
          'attempts': 3,
          'correctAnswers': 99,
          'completedAssessments': -1,
          'bestAssessmentScore': 99,
          'mastered': true,
          'masteredAt': 'invalid'
        },
        'B': {
          'letter': 'B',
          'attempts': 'bad',
          'viewCount': -6,
          'mastered': 'true'
        },
        'C': [],
        'unknown': {'mastered': true},
      }),
      'dailyActivityV1': jsonEncode({
        '2026-09-23': {
          'questionsAnswered': 4,
          'correctAnswers': 10,
          'activitiesCompleted': -2
        },
        '2026-99-99': {},
        'broken': {},
        '2026-09-22': [],
      }),
    });
    final p = AppProvider();
    await p.ready;
    final a = p.getLetterProgress('A');
    expect(a.letter, 'A');
    expect(a.correctAnswers, 3);
    expect(a.accuracy, 1);
    expect(a.bestAssessmentScore, 5);
    expect(a.completedAssessments, 0);
    expect(a.masteredAt, isNull);
    expect(p.masteredLetterCount, 1);
    expect(p.getLetterProgress('B').status, LearningStatus.notStarted);
    expect(p.dailyActivity.length, 1);
    expect(p.overallActivityAccuracy, 1);
    expect(p.dailyActivity.values.single.activitiesCompleted, 0);
    p.dispose();
  });
  test(
      'legacy learned entries migrate only to Viewed despite invalid neighbors',
      () async {
    SharedPreferences.setMockInitialValues({
      'learned': ['a', 'A', 'Z', 'unknown', '']
    });
    final p = AppProvider();
    await p.ready;
    expect(p.viewedLetterCount, 2);
    expect(p.masteredLetterCount, 0);
    expect(p.getLetterProgress('A').viewCount, 1);
    p.dispose();
  });
  test(
      'disposing before preferences finish does not initialize leaked services',
      () async {
    final p = AppProvider();
    p.dispose();
    await p.ready;
    expect(p.isReady, isFalse);
  });
  test(
      'duplicate foreground starts preserve sub-second time and do not double count',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final auth = ParentAuthService(prefs);
    var elapsed = 0;
    final time = ScreenTimeService(prefs, auth,
        now: () => DateTime(2026, 9, 23), elapsedMilliseconds: () => elapsed);
    time.startTracking();
    elapsed = 750;
    time.startTracking();
    elapsed = 1000;
    time.tick();
    expect(time.usedSecondsToday, 1);
    time.startTracking();
    elapsed = 2000;
    time.tick();
    expect(time.usedSecondsToday, 2);
    await time.pauseTracking();
    elapsed = 100000;
    time.tick();
    expect(time.usedSecondsToday, 2);
    time.dispose();
    auth.dispose();
  });
  test('all declared asset directories exist and no declaration is duplicated',
      () {
    final yaml = File('pubspec.yaml').readAsStringSync();
    final assets = RegExp(r'^\s+- (assets/[^\r\n]+)', multiLine: true)
        .allMatches(yaml)
        .map((m) => m[1]!.trim())
        .toList();
    expect(assets.toSet().length, assets.length);
    for (final path in assets) {
      expect(Directory(path).existsSync() || File(path).existsSync(), isTrue,
          reason: path);
    }
  });
  test(
      'the existing fonts load entirely from bundled assets with HTTP disabled',
      () async {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.theme;
    for (final weight in [
      FontWeight.w400,
      FontWeight.w500,
      FontWeight.w600,
      FontWeight.w700,
      FontWeight.w800,
      FontWeight.w900
    ]) {
      GoogleFonts.nunito(fontWeight: weight);
    }
    GoogleFonts.fredoka();
    await GoogleFonts.pendingFonts();
  });
  test('missing recordings and repeated audio disposal are safe', () async {
    final phonics = PhonicsAudioService();
    expect(await phonics.playInstruction('unmapped recording'), isFalse);
    phonics.dispose();
    phonics.dispose();
    expect(await phonics.playInstruction('Cat'), isFalse);
    expect(identical(PhonicsAudioService(), phonics), isFalse);
    final audio = AudioService();
    audio.dispose();
    audio.dispose();
    await audio.playCorrect();
    expect(identical(AudioService(), audio), isFalse);
    final mastery = LocalMasteryAudio();
    expect(await mastery.play('unmapped recording'), isFalse);
    await mastery.dispose();
    await mastery.dispose();
    expect(await mastery.play('Cat'), isFalse);
  });
  for (final closeEarly in [false, true]) {
    testWidgets('PIN double-submit and pending disposal: close=$closeEarly',
        (t) async {
      final auth = _DelayedAuth(await SharedPreferences.getInstance());
      var successes = 0;
      await t.pumpWidget(MaterialApp(
          home: Scaffold(
              body: ParentPinForm(
                  auth: auth, onSuccess: () => successes++, onBack: () {}))));
      await t.enterText(find.byType(TextField).at(0), '2580');
      await t.enterText(find.byType(TextField).at(1), '2580');
      final submit = t
          .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Set PIN'))
          .onPressed!;
      submit();
      submit();
      await t.pump();
      expect(auth.calls, 1);
      if (closeEarly) await t.pumpWidget(const SizedBox());
      auth.completed.complete(null);
      await t.pump();
      expect(successes, closeEarly ? 0 : 1);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      auth.dispose();
    });
  }
}
