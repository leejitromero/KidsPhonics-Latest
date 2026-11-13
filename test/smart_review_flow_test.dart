import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/smart_review.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/smart_review_screen.dart';
import 'package:kidsphonics/screens/progress_screen.dart';
import 'package:kidsphonics/services/audio_service.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';
import 'package:kidsphonics/widgets/smart_review_card.dart';
import 'package:kidsphonics/theme/kids_ui.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'quiz_audio_harness.dart';
import 'updated_scene_test.dart' show capture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late QuizAudioHarness audio;
  setUp(() {
    mockProgressAudio();
    SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
    audio = QuizAudioHarness()..install();
  });

  Future<void> until(WidgetTester t, bool Function() ready) async {
    for (var i = 0; i < 150 && !ready(); i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)));
      await t.pump();
    }
    expect(ready(), true, reason: 'Audio starts: ${audio.starts}');
  }

  Future<AppProvider> review(WidgetTester t, ReviewTarget target,
      {bool voice = false, GlobalKey? boundary}) async {
    SharedPreferences.setMockInitialValues({'voice': voice, 'sfx': false});
    final p = await mount(t, const SizedBox());
    await t.runAsync(
        () => p.recordDailyAnswer(correct: false, reviewTarget: target));
    await t.pumpWidget(ChangeNotifierProvider.value(
        value: p,
        child: MaterialApp(
            home: RepaintBoundary(
                key: boundary, child: const SmartReviewScreen()))));
    await t.pump();
    return p;
  }

  Future<void> finish(WidgetTester t, AppProvider p) async {
    await close(t, p);
    await t.runAsync(() async {
      PhonicsAudioService().dispose();
      AudioService().dispose();
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await t.pump();
  }

  List<FilledButton> choices(WidgetTester t) => [
        for (var i = 0; i < 3; i++)
          t.widget<FilledButton>(find.byKey(ValueKey('smart-review-choice-$i')))
      ];
  Future<void> tapChoice(WidgetTester t, String text) async {
    final button = find.widgetWithText(FilledButton, text);
    await t.ensureVisible(button);
    await t.pump();
    await t.tap(button);
    await t.pump();
  }

  Future<void> next(WidgetTester t) async {
    final button = find.byKey(const ValueKey('smart-review-next'));
    await t.ensureVisible(button);
    await t.tap(button);
    await until(
        t,
        () => find
            .byKey(const ValueKey('smart-review-feedback'))
            .evaluate()
            .isEmpty);
  }

  testWidgets(
      'My Journey starts a focused review and keeps Quick Check available',
      (t) async {
    final p = await review(t, const ReviewTarget.vowel('E'));
    await t.pumpWidget(ChangeNotifierProvider.value(
        value: p, child: const MaterialApp(home: ProgressScreen())));
    await t.pump();
    expect(find.byType(SmartReviewCard), findsOneWidget);
    expect(find.textContaining('Short E'), findsOneWidget);
    await t.scrollUntilVisible(
        find.byKey(const ValueKey('progress-start-quick-check')), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.byKey(const ValueKey('progress-start-quick-check')),
        findsOneWidget);
    await t.scrollUntilVisible(
        find.byKey(const ValueKey('start-smart-review')), -200,
        scrollable: find.byType(Scrollable).first);
    await t.tap(find.byKey(const ValueKey('start-smart-review')));
    await t.pump();
    await t.pump(const Duration(seconds: 2));
    await until(t, () => find.byType(SmartReviewScreen).evaluate().isNotEmpty);
    expect(find.text('Short Vowels'), findsOneWidget);
    expect(choices(t).every((b) => b.onPressed == null), true);
    expect(find.text('Turn Voice On'), findsOneWidget);
    expect(t.takeException(), isNull);
    await finish(t, p);
  });

  testWidgets(
      'two correct practice responses clear the recommendation without changing scores',
      (t) async {
    final p = await review(t, const ReviewTarget.letter('B'));
    final before = (
      p.xp,
      p.stars,
      p.streak,
      p.overallMasteredCount,
      jsonEncode(p.dailyActivity.map((k, v) => MapEntry(k, v.toJson())))
    );
    final first =
        choices(t).firstWhere((b) => (b.child as Text).data == 'b').onPressed!;
    await tapChoice(t, 'b');
    first(); // A retained callback must not count the same task twice.
    await until(t, () => p.smartReviewSuggestions.single.recovery == 1);
    expect(choices(t).every((b) => b.onPressed == null), true);
    await next(t);
    await tapChoice(t, 'b');
    await until(t, () => p.smartReviewSuggestions.isEmpty);
    await next(t);
    expect(find.text('Great practicing!'), findsOneWidget);
    expect(find.byKey(const ValueKey('smart-review-more')), findsNothing);
    expect((
      p.xp,
      p.stars,
      p.streak,
      p.overallMasteredCount,
      jsonEncode(p.dailyActivity.map((k, v) => MapEntry(k, v.toJson())))
    ), before);
    expect(t.takeException(), isNull);
    await finish(t, p);
  });

  testWidgets(
      'incorrect practice explains the answer and cannot be repeatedly submitted',
      (t) async {
    final p = await review(t, const ReviewTarget.letter('B'));
    final wrong = choices(t).firstWhere((b) => (b.child as Text).data != 'b');
    final callback = wrong.onPressed!;
    await tapChoice(t, (wrong.child as Text).data!);
    callback();
    callback();
    await until(t, () => p.smartReviewSuggestions.single.recent.length == 2);
    expect(find.textContaining('B and b are the same letter.'), findsOneWidget);
    expect(p.smartReviewSuggestions.single.recent, [false, false]);
    expect(p.dailyActivity.values.single.questionsAnswered, 1);
    expect(t.takeException(), isNull);
    await finish(t, p);
  });

  testWidgets(
      'auditory practice waits for the complete recording before enabling answers',
      (t) async {
    final p = await review(t, const ReviewTarget.vowel('E'), voice: true);
    await until(t, () => audio.starts.isNotEmpty);
    expect(choices(t).every((b) => b.onPressed == null), true);
    expect(p.smartReviewSuggestions.single.recent, [false]);
    await t.runAsync(() => audio.completeSource(audio.starts.single));
    await until(t, () => choices(t).every((b) => b.onPressed != null));
    await tapChoice(t, 'E');
    await until(t, () => p.smartReviewSuggestions.single.recovery == 1);
    expect(t.takeException(), isNull);
    await finish(t, p);
  });

  testWidgets('word then focus sound finish in order without overlapping',
      (t) async {
    final p =
        await review(t, const ReviewTarget.position('FISH', 'F'), voice: true);
    await until(t, () => audio.starts.length == 1);
    final word = audio.starts.first;
    expect(word.toLowerCase(), contains('fish.mp3'));
    expect(choices(t).every((b) => b.onPressed == null), true);
    await t.runAsync(() => audio.completeSource(word));
    await until(t, () => audio.starts.length == 2);
    expect(audio.starts.last, endsWith('sound-f.mp3'));
    expect(choices(t).every((b) => b.onPressed == null), true);
    await t.runAsync(() => audio.completeSource('sound-f.mp3'));
    await until(t, () => choices(t).every((b) => b.onPressed != null));
    expect(t.takeException(), isNull);
    await finish(t, p);
  });

  testWidgets(
      'background interrupts the cue and stale completion awards no recovery',
      (t) async {
    final p = await review(t, const ReviewTarget.vowel('E'), voice: true);
    await until(t, () => audio.starts.isNotEmpty);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump();
    await until(t, () => PhonicsAudioService().currentPhrase == null);
    await t.runAsync(() => audio.completeSource(audio.starts.single));
    await t.pump();
    expect(p.smartReviewSuggestions.single.recent, [false]);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    await until(t, () => audio.starts.length == 2);
    expect(choices(t).every((b) => b.onPressed == null), true);
    await t.runAsync(() => audio.completeSource(audio.starts.last));
    await until(t, () => choices(t).every((b) => b.onPressed != null));
    await finish(t, p);
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(768, 1024)
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('review remains readable and scrollable at $size text $scale',
          (t) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        t.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final boundary = GlobalKey();
        final p =
            await review(t, const ReviewTarget.letter('B'), boundary: boundary);
        if (size.width == 390 && scale == 1) {
          await capture(t, boundary, 'smart_review_question');
        }
        await tapChoice(t, 'b');
        await until(t, () => p.smartReviewSuggestions.single.recovery == 1);
        for (final choice in choices(t)) {
          expect((choice.child as Text).style!.color, KidsUi.ink);
        }
        await t.ensureVisible(find.byKey(const ValueKey('smart-review-next')));
        await t.pump();
        final button =
            t.getRect(find.byKey(const ValueKey('smart-review-next')));
        expect(button.height, greaterThanOrEqualTo(48));
        expect(button.bottom, lessThanOrEqualTo(size.height));
        if (size.width == 390 && scale == 1) {
          await capture(t, boundary, 'smart_review_feedback');
        }
        await t.pumpWidget(ChangeNotifierProvider.value(
            value: p, child: const MaterialApp(home: ProgressScreen())));
        await t.pump();
        await t.scrollUntilVisible(
            find.byKey(const ValueKey('start-smart-review')), 100,
            scrollable: find.byType(Scrollable).first);
        final card = t.getRect(find.byType(SmartReviewCard));
        for (final text in find
            .descendant(
                of: find.byType(SmartReviewCard), matching: find.byType(Text))
            .evaluate()) {
          final bounds = t.getRect(find.byWidget(text.widget));
          expect(card.inflate(.5).contains(bounds.topLeft), true);
          expect(card.inflate(.5).contains(bounds.bottomRight), true);
        }
        expect(t.takeException(), isNull);
        await finish(t, p);
      });
    }
  }

  testWidgets(
      'fresh learner sees the normal recommendation and an empty review is safe',
      (t) async {
    final p = await mount(t, const ProgressScreen());
    expect(find.byType(SmartReviewCard), findsNothing);
    await t.scrollUntilVisible(
        find.byKey(const ValueKey('progress-start-quick-check')), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.byKey(const ValueKey('progress-start-quick-check')),
        findsOneWidget);
    await t.pumpWidget(ChangeNotifierProvider.value(
        value: p, child: const MaterialApp(home: SmartReviewScreen())));
    await t.pump();
    expect(find.text('Ready for your next adventure!'), findsOneWidget);
    expect(t.takeException(), isNull);
    await finish(t, p);
  });
}
