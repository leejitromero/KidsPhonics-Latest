import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/screens/home_screen.dart';
import 'package:kidsphonics/widgets/school_home_scene.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';
import 'package:kidsphonics/services/audio_service.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'home_voice_test.dart' show waitForVoice, finishTitle;
import 'quiz_audio_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late QuizAudioHarness audio;
  const title = 'kidsphonics_title_chorus.mp3';
  setUp(() {
    mockProgressAudio();
    SharedPreferences.setMockInitialValues({
      'sfx': false,
      'welcomeCompletedV1': true,
      'studentCharacter': 'boy',
      'studentName': 'Sam',
    });
    audio = QuizAudioHarness()..install();
  });
  Future<void> finish(WidgetTester t, AppProvider p) async {
    await close(t, p);
    await t.runAsync(() async {
      await PhonicsAudioService().stop();
      PhonicsAudioService().dispose();
      AudioService().dispose();
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await t.pump();
  }

  testWidgets('saved learners hear the chorus on each new launch', (t) async {
    for (var launch = 1; launch <= 2; launch++) {
      // A new app process has a fresh native player registry as well.
      audio = QuizAudioHarness()..install();
      final p = await mount(t, const HomeScreen(announceTitle: true));
      expect(p.welcomeCompleted, true);
      await waitForVoice(
          t, () => audio.starts.where((s) => s.endsWith(title)).length == 1);
      await t.pump(const Duration(seconds: 8));
      // Startup speech owns the audio until actual completion, even if slow.
      expect(audio.starts, hasLength(1));
      expect(
          t.widget<SchoolHomeScene>(find.byType(SchoolHomeScene)).busy, true);
      await finishTitle(t, audio);
      expect(
          t.widget<SchoolHomeScene>(find.byType(SchoolHomeScene)).busy, false);
      final nav = Navigator.of(t.element(find.byType(HomeScreen)));
      nav.push(MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Room'))));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      nav.pop();
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(audio.starts.where((s) => s.endsWith(title)), hasLength(1));
      await finish(t, p);
    }
  });

  testWidgets(
      'interrupted startup restarts once and does not overlap idle voice',
      (t) async {
    final p = await mount(t, const HomeScreen(announceTitle: true));
    await waitForVoice(t, () => audio.starts.any((s) => s.endsWith(title)));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.runAsync(() => audio.completeSource(title));
    await t.pump(const Duration(seconds: 8));
    expect(audio.starts, hasLength(1));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    await waitForVoice(
        t, () => audio.starts.where((s) => s.endsWith(title)).length == 2);
    await finishTitle(t, audio);
    await t.pump(const Duration(milliseconds: 4999));
    expect(audio.starts, hasLength(2));
    await t.pump(const Duration(milliseconds: 1));
    await waitForVoice(
        t,
        () =>
            audio.starts.any((s) => s.endsWith('boy_automatic_prompt_4.mp3')));
    await t.runAsync(() => audio.completeSource('boy_automatic_prompt_4.mp3'));
    await t.pump();
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    expect(audio.starts.where((s) => s.endsWith(title)), hasLength(2));
    await finish(t, p);
  });

  testWidgets('muted startup skips the chorus and enables the menu', (t) async {
    SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
    final p = await mount(t, const HomeScreen(announceTitle: true));
    await t.pump();
    expect(audio.starts, isEmpty);
    expect(t.widget<SchoolHomeScene>(find.byType(SchoolHomeScene)).busy, false);
    await finish(t, p);
  });
}
