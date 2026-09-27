import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/services/parent_auth_service.dart';
import 'package:kidsphonics/services/screen_time_service.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'learning_progress_test.dart' show mockProgressAudio;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late ParentAuthService auth;
  late ScreenTimeService time;
  late DateTime date;
  var elapsed = 0;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    date = DateTime(2026, 9, 23, 12);
    elapsed = 0;
    auth = ParentAuthService(prefs, now: () => date);
    time = ScreenTimeService(prefs, auth,
        now: () => date, elapsedMilliseconds: () => elapsed);
  });
  tearDown(() async {
    await time.pauseTracking();
    time.dispose();
    auth.dispose();
  });
  Future<void> enable() async {
    await auth.setup('2580', '2580');
    await time.setLimitEnabled(true);
    auth.endSession();
    time.startTracking();
  }

  void advance(int seconds) {
    elapsed += seconds * 1000;
    date = date.add(Duration(seconds: seconds));
    time.tick();
  }

  test('first access, PIN validation and salted hash only', () async {
    expect(auth.hasPin, isFalse);
    for (final pin in [
      '0000',
      '1111',
      '1234',
      '4321',
      '123',
      '12345',
      'abcd'
    ]) {
      expect(await auth.setup(pin, pin), isNotNull);
      expect(auth.hasPin, isFalse);
    }
    expect(await auth.setup('2580', '2581'), isNotNull);
    expect(await auth.setup('2580', '2580'), isNull);
    expect(auth.isAuthenticated, isTrue);
    final saved = prefs.getString('parentPinHashV1')!;
    expect(saved, isNot('2580'));
    expect(saved.split(':').last.length, 64);
    final reopened = ParentAuthService(prefs);
    expect(reopened.isAuthenticated, isFalse);
    expect(reopened.unlock('9876'), isNotNull);
    expect(reopened.unlock('2580'), isNull);
    reopened.dispose();
  });
  test('five failures delay 30 seconds, success resets attempts', () async {
    await auth.setup('2580', '2580');
    auth.endSession();
    for (var i = 0; i < 5; i++) {
      expect(auth.unlock('9876'), isNotNull);
    }
    expect(auth.lockoutSeconds, 30);
    expect(auth.unlock('2580'), isNotNull);
    date = date.add(const Duration(seconds: 30));
    expect(auth.unlock('2580'), isNull);
    expect(auth.lockoutSeconds, 0);
    auth.endSession();
    expect(auth.unlock('9876'), isNotNull);
    expect(auth.lockoutSeconds, 0);
  });
  test('change PIN verifies current, validates new, persists replacement',
      () async {
    await auth.setup('2580', '2580');
    expect(await auth.changePin('9876', '2468', '2468'), isNotNull);
    expect(await auth.changePin('2580', '1234', '1234'), isNotNull);
    expect(await auth.changePin('2580', '2468', '2468'), isNull);
    auth.endSession();
    expect(auth.unlock('2580'), isNotNull);
    expect(auth.unlock('2468'), isNull);
  });
  test('all parent mutations reject unauthenticated callers', () async {
    await expectLater(time.setDailyLimit(45), throwsStateError);
    await expectLater(time.setLimitEnabled(false), throwsStateError);
    await expectLater(time.addExtraTime(15), throwsStateError);
    await expectLater(time.bypassLimitForToday(), throwsStateError);
    await expectLater(auth.changePin('2580', '2468', '2468'), throwsStateError);
    mockProgressAudio();
    final provider = AppProvider();
    await provider.ready;
    await expectLater(provider.toggleGameAccess(), throwsStateError);
    await expectLater(provider.resetProgress(), throwsStateError);
    provider.dispose();
  });
  for (final minutes in [8, 20, 30]) {
    test('$minutes minutes persist across same-day restart', () async {
      await enable();
      advance(minutes * 60);
      await time.pauseTracking();
      final reopened = ScreenTimeService(prefs, auth, now: () => date);
      expect(reopened.usedSecondsToday, minutes * 60);
      expect(reopened.isLimitReached, minutes == 30);
      reopened.dispose();
    });
  }
  test('background time is excluded; resume has one timer', () async {
    await enable();
    advance(120);
    await time.pauseTracking();
    advance(600);
    expect(time.usedSecondsToday, 120);
    time.startTracking();
    time.startTracking();
    advance(60);
    expect(time.usedSecondsToday, 180);
  });
  test('periodic checkpoint saves without lifecycle pause', () async {
    await enable();
    advance(10);
    await Future<void>.delayed(Duration.zero);
    expect(prefs.getInt('screenTimeUsedSecondsV2'), 10);
  });
  test('limit clamps remaining and stops counting blocked time', () async {
    await enable();
    advance(1805);
    expect(time.isLimitReached, isTrue);
    expect(time.remainingSeconds, 0);
    advance(100);
    expect(time.usedSecondsToday, 1800);
  });
  test('extra allowance persists; tomorrow normal limit returns', () async {
    await enable();
    advance(1800);
    auth.unlock('2580');
    await time.addExtraTime(15);
    expect(time.allowedSecondsToday, 2700);
    expect(time.dailyLimitMinutes, 30);
    final reopened = ScreenTimeService(prefs, auth, now: () => date);
    expect(reopened.extraSecondsToday, 900);
    reopened.dispose();
    await time.pauseTracking();
    date = DateTime(2026, 9, 24);
    time.startTracking();
    expect(time.usedSecondsToday, 0);
    expect(time.extraSecondsToday, 0);
    expect(time.allowedSecondsToday, 1800);
  });
  test('today-only bypass persists and expires on calendar day', () async {
    await enable();
    advance(1800);
    auth.unlock('2580');
    await time.bypassLimitForToday();
    expect(time.isLimitReached, isFalse);
    expect(time.isLimitEnabled, isTrue);
    final reopened = ScreenTimeService(prefs, auth, now: () => date);
    expect(reopened.isBypassedToday, isTrue);
    reopened.dispose();
    await time.pauseTracking();
    date = DateTime(2026, 9, 24);
    time.startTracking();
    expect(time.isBypassedToday, isFalse);
    expect(time.dailyLimitMinutes, 30);
  });
  test('authenticated settings time excluded, leaving resumes', () async {
    await enable();
    advance(120);
    auth.unlock('2580');
    time.setParentActive(true);
    advance(300);
    expect(time.usedSecondsToday, 120);
    auth.endSession();
    time.setParentActive(false);
    advance(60);
    expect(time.usedSecondsToday, 180);
  });
  test('midnight while open counts only new-day part', () async {
    await enable();
    date = DateTime(2026, 9, 23, 23, 59, 58);
    advance(5);
    expect(time.usedSecondsToday, 3);
  });
  test('warnings occur once per daily threshold including after restart',
      () async {
    final warnings = <int>[];
    final sub = time.warnings.listen(warnings.add);
    await enable();
    advance(1500);
    advance(240);
    advance(1);
    await time.save();
    expect(warnings, [5, 1]);
    final reopened = ScreenTimeService(prefs, auth, now: () => date);
    final repeated = <int>[];
    final sub2 = reopened.warnings.listen(repeated.add);
    reopened.startTracking();
    reopened.tick();
    await reopened.save();
    expect(repeated, isEmpty);
    await sub.cancel();
    await sub2.cancel();
    reopened.dispose();
  });
  test('corrupt time preference values fall back safely', () async {
    await prefs.setString('screenTimeUsedSecondsV2', 'bad');
    await prefs.setInt('screenTimeLimitMinutesV2', -1);
    await prefs.setString('screenTimeLimitEnabledV2', 'bad');
    final reopened = ScreenTimeService(prefs, auth, now: () => date);
    expect(reopened.usedSecondsToday, 0);
    expect(reopened.dailyLimitMinutes, 30);
    expect(reopened.remainingSeconds, 1800);
    reopened.dispose();
  });
  test('reset preserves PIN, usage, time configuration, games and audio',
      () async {
    mockProgressAudio();
    final p = AppProvider(now: () => date);
    await p.ready;
    await p.parentAuth.setup('2580', '2580');
    await p.screenTime.setDailyLimit(45);
    await p.screenTime.setLimitEnabled(true);
    await p.screenTime.addExtraTime(15);
    await p.toggleGameAccess();
    await p.toggleVoice();
    await p.addXP(20);
    await p.addStar();
    await p.recordLetterPractice('A', true);
    await p.completeLetterAssessment('A', 4, 5);
    await p.resetProgress();
    final reopened = AppProvider(now: () => date);
    await reopened.ready;
    expect(reopened.parentAuth.hasPin, isTrue);
    expect(reopened.parentAuth.unlock('2580'), isNull);
    expect(reopened.screenTime.dailyLimitMinutes, 45);
    expect(reopened.screenTime.extraSecondsToday, 900);
    expect(reopened.timeLimitEnabled, isTrue);
    expect(reopened.gameAccess, isFalse);
    expect(reopened.voiceEnabled, isFalse);
    expect(reopened.xp, 0);
    expect(reopened.stars, 0);
    expect(reopened.dailyActivity, isEmpty);
    expect(reopened.masteredLetterCount, 0);
    p.dispose();
    reopened.dispose();
  });
}
