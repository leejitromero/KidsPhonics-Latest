import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/screens/voice_recognition_screen.dart';
import 'package:kidsphonics/services/speech_practice_service.dart';
import 'package:kidsphonics/widgets/speech_practice_design.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

class FakeSpeech extends SpeechPracticeService {
  List<SpeechMicrophonePermission> permissions = [
    SpeechMicrophonePermission.granted
  ];
  List<String> supportedLocales = ['en_US'];
  int requests = 0, starts = 0, stops = 0, settings = 0;
  void Function(String, bool)? result;
  void Function(String)? status, error;
  @override
  Future<SpeechMicrophonePermission> requestPermission() async {
    requests++;
    return permissions.length > 1 ? permissions.removeAt(0) : permissions.first;
  }

  @override
  Future<bool> initialize(
          {required void Function(String) onStatus,
          required void Function(String) onError}) async =>
      _initialize(onStatus, onError);
  bool _initialize(
      void Function(String) onStatus, void Function(String) onError) {
    status = onStatus;
    error = onError;
    return true;
  }

  @override
  Future<List<String>> locales() async => supportedLocales;
  @override
  Future<void> listen(
      {required void Function(String, bool) onResult,
      required String localeId}) async {
    starts++;
    result = onResult;
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<bool> openSettings() async {
    settings++;
    return true;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
  });
  test('matching rejects different short words and substrings on every tier',
      () {
    for (final strict in [false, true]) {
      expect(matchesSpokenWord('cat', 'bat', strict: strict), isFalse);
      expect(matchesSpokenWord('cat', 'a', strict: strict), isFalse);
      expect(matchesSpokenWord('cat', 'caterpillar', strict: strict), isFalse);
      expect(matchesSpokenWord('cat', 'CAT!', strict: strict), isTrue);
      expect(matchesSpokenWord('cat', '', strict: strict), isFalse);
    }
    expect(matchesSpokenWord('cat', 'a cat', strict: false), isTrue);
    expect(matchesSpokenWord('cat', 'a cat', strict: true), isFalse);
    expect(matchesSpokenWord('yo-yo', 'yo yo', strict: true), isTrue);
  });
  test('locale selection uses available English support', () {
    expect(englishSpeechLocale(['fil_PH', 'en-PH']), 'en-PH');
    expect(englishSpeechLocale(['en_GB', 'en_US']), 'en_US');
    expect(englishSpeechLocale(['en_AU']), 'en_AU');
    expect(englishSpeechLocale(['fil_PH']), isNull);
  });
  Future<void> start(WidgetTester t) async {
    final button = find.text('Start Listening').evaluate().isEmpty
        ? find.text('Try Microphone Again')
        : find.text('Start Listening');
    await t.ensureVisible(button);
    await t.tap(button);
    for (var i = 0; i < 8; i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await t.pump(const Duration(milliseconds: 20));
    }
  }

  for (final ending in ['status', 'empty result', 'error']) {
    testWidgets(
        '$ending reports no speech without a wrong answer and can retry',
        (t) async {
      final speech = FakeSpeech();
      final p = await mount(t, VoiceRecognitionScreen(speech: speech));
      await start(t);
      if (ending == 'status') {
        speech.status!('done');
      } else if (ending == 'error') {
        speech.error!('error_no_match');
      } else {
        speech.result!('', true);
      }
      await t.pump();
      expect(find.text('No speech detected. Try again.'), findsOneWidget);
      expect(p.getWeeklySummary().speechAttempts, 0);
      expect((p.xp, p.stars), (0, 0));
      await start(t);
      expect(speech.requests, 1);
      expect(speech.starts, 2);
      final word =
          t.widget<SpeechPictureCard>(find.byType(SpeechPictureCard)).word;
      speech.result!(word, true);
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await t.pump();
      expect(find.text('No speech detected. Try again.'), findsNothing);
      expect(p.getWeeklySummary().speechAttempts, 1);
      await close(t, p);
    });
  }

  testWidgets('a final recognized word arriving after done still counts once',
      (t) async {
    final speech = FakeSpeech();
    final p = await mount(t, VoiceRecognitionScreen(speech: speech));
    await start(t);
    speech.status!('notListening');
    final word =
        t.widget<SpeechPictureCard>(find.byType(SpeechPictureCard)).word;
    speech.result!(word, true);
    speech.result!(word, true);
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await t.pump();
    expect(find.text('No speech detected. Try again.'), findsNothing);
    expect(p.getWeeklySummary().speechAttempts, 1);
    await close(t, p);
  });

  testWidgets('permission denial can be retried without reopening the game',
      (t) async {
    final speech = FakeSpeech()
      ..permissions = [
        SpeechMicrophonePermission.denied,
        SpeechMicrophonePermission.granted
      ];
    final p = await mount(t, VoiceRecognitionScreen(speech: speech));
    await start(t);
    expect(speech.starts, 0);
    expect(find.text('Try Microphone Again'), findsOneWidget);
    await start(t);
    expect(speech.requests, 2);
    expect(speech.starts, 1);
    await close(t, p);
  });
  testWidgets(
      'permanent denial offers settings and unsupported English can retry',
      (t) async {
    final speech = FakeSpeech()
      ..permissions = [SpeechMicrophonePermission.settingsRequired];
    final p = await mount(t, VoiceRecognitionScreen(speech: speech));
    await start(t);
    expect(find.text('Open Device Settings'), findsOneWidget);
    await t.ensureVisible(find.text('Open Device Settings'));
    await t.tap(find.text('Open Device Settings'));
    await t.pump();
    expect(speech.settings, 1);
    speech.permissions = [SpeechMicrophonePermission.granted];
    speech.supportedLocales = ['fil_PH'];
    await start(t);
    expect(speech.starts, 0);
    speech.supportedLocales = ['en_PH'];
    await start(t);
    expect(speech.starts, 1);
    await close(t, p);
  });
  for (final covered in ['background', 'dialog', 'access']) {
    testWidgets('speech stops and rejects late results during $covered',
        (t) async {
      final speech = FakeSpeech();
      final p = await mount(t, VoiceRecognitionScreen(speech: speech));
      await t.runAsync(() => p.toggleSfx());
      await start(t);
      final word =
          t.widget<SpeechPictureCard>(find.byType(SpeechPictureCard)).word;
      if (covered == 'dialog') {
        speech.result!('zzzz', true);
        await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 30)));
        await t.pump();
        await start(t);
      }
      final late = speech.result!;
      final attempts = p.getWeeklySummary().speechAttempts;
      final stoppedBefore = speech.stops;
      if (covered == 'background') {
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      } else if (covered == 'dialog') {
        await t.tap(find.byTooltip('Back'));
        await t.pump(const Duration(milliseconds: 300));
        expect(find.text('Leave this game?'), findsOneWidget);
      } else {
        await t.runAsync(() async {
          await p.parentAuth.setup('2580', '2580');
          await p.toggleGameAccess();
        });
      }
      late(word, true);
      await t.pump();
      expect(speech.stops, greaterThan(stoppedBefore));
      expect(p.getWeeklySummary().speechAttempts, attempts);
      expect(find.text('Recognized'), findsNothing);
      if (covered == 'background') {
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      } else if (covered == 'dialog') {
        await t.tap(find.text('Cancel'));
        await t.pump(const Duration(milliseconds: 300));
      }
      await close(t, p);
    });
  }
}
