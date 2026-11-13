import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/progress_badge.dart';
import 'package:kidsphonics/models/word_lesson_progress.dart';
import 'package:kidsphonics/models/learning_progress.dart' show localDateKey;
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/widgets/app_display_preferences.dart';
import 'package:kidsphonics/widgets/badge_unlock_celebration.dart';
import 'learning_progress_test.dart' show mockProgressAudio;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts = FontLoader('Nunito');
    for (final weight in ['Regular', 'Bold', 'ExtraBold', 'Black']) {
      fonts.addFont(rootBundle.load('assets/fonts/Nunito-$weight.ttf'));
    }
    await fonts.load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
    mockProgressAudio();
  });
  final popup = find.byKey(const ValueKey('badge-unlock-celebration'));
  Future<void> perform(
      WidgetTester tester, Future<dynamic> Function() action) async {
    var done = false;
    Object? failure;
    action().then((_) => done = true, onError: (Object error) {
      failure = error;
      done = true;
    });
    for (var i = 0; i < 100 && !done; i++) {
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    }
    expect(failure, isNull);
    expect(done, isTrue, reason: 'The provider write must finish.');
  }

  Future<AppProvider> mount(WidgetTester tester, {bool reduced = false}) async {
    late AppProvider provider;
    await tester.runAsync(() async {
      provider = AppProvider();
      await provider.ready;
      if (reduced) await provider.setReducedAnimations(true);
    });
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
          builder: (_, child) =>
              AppDisplayPreferences(child: BadgeCelebrationHost(child: child!)),
          home: Scaffold(
              body: Center(
                  child: Builder(
                      builder: (context) => ElevatedButton(
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (_) => const Scaffold(
                                      body:
                                          Center(child: Text('Next screen'))))),
                          child: const Text('Navigate')))))),
    ));
    await tester.pump();
    return provider;
  }

  Future<void> earnCvc(WidgetTester tester, AppProvider provider) async {
    await perform(tester, () async {
      for (final word in WordLesson.cvc.words.take(5)) {
        await provider.completeWordLessonWord(WordLesson.cvc, word);
      }
    });
  }

  Future<void> waitForPopup(WidgetTester tester) async {
    for (var i = 0; i < 60 && popup.evaluate().isEmpty; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)));
    }
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(popup, findsOneWidget);
  }

  Future<void> close(WidgetTester tester, AppProvider provider) async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    provider.dispose();
  }

  testWidgets(
      'new unlock appears automatically for 2.8 seconds and allows navigation',
      (tester) async {
    final provider = await mount(tester);
    expect(popup, findsNothing);
    await earnCvc(tester, provider);
    await waitForPopup(tester);
    expect(find.text('CVC Explorer'), findsOneWidget);
    expect(provider.pendingBadgeUnlocks, isEmpty);
    await tester.pump(const Duration(milliseconds: 700));
    // The overlay must not trap taps or use a modal route over active games.
    await tester.tap(find.text('Navigate'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Next screen'), findsOneWidget);
    expect(popup, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600));
    expect(popup, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(popup, findsNothing);
    await perform(tester, provider.toggleSfx);
    await tester.pump(const Duration(seconds: 3));
    expect(popup, findsNothing);
    expect((provider.xp, provider.stars), (0, 0));
    await close(tester, provider);
  });

  testWidgets('multiple simultaneous unlocks appear one at a time',
      (tester) async {
    final provider = await mount(tester);
    await perform(tester, () async {
      for (final letter in 'AEIOU'.split('')) {
        await provider.completeAdventure(
            letter, List.filled(5, true), 'new-$letter');
      }
    });
    for (final title in [
      'First Letter Mastery',
      'Vowel Star',
      '5 Letters Mastered'
    ]) {
      await waitForPopup(tester);
      expect(find.text(title), findsOneWidget);
      expect(popup, findsOneWidget);
      await tester.pump(BadgeCelebrationHost.duration);
      await tester.pump(const Duration(milliseconds: 20));
      expect(popup, findsNothing);
      await tester.pump(const Duration(milliseconds: 260));
    }
    await tester.pump(const Duration(seconds: 3));
    expect(popup, findsNothing);
    expect(provider.pendingBadgeUnlocks, isEmpty);
    expect((provider.xp, provider.stars), (150, 5));
    await close(tester, provider);
  });

  testWidgets(
      'background pauses the visible duration and resumes without a duplicate',
      (tester) async {
    final provider = await mount(tester);
    await earnCvc(tester, provider);
    await waitForPopup(tester);
    await tester.pump(const Duration(milliseconds: 900));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 10));
    expect(popup, findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(popup, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600));
    expect(popup, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    expect(popup, findsNothing);
    await close(tester, provider);
  });

  testWidgets(
      'reduced motion retains readable display time and semantic announcement',
      (tester) async {
    final provider = await mount(tester, reduced: true);
    final semantics = tester.ensureSemantics();
    await earnCvc(tester, provider);
    await waitForPopup(tester);
    expect(find.bySemanticsLabel('Badge unlocked. CVC Explorer. Well done!'),
        findsOneWidget);
    final view = tester
        .widget<BadgeUnlockCelebration>(find.byType(BadgeUnlockCelebration));
    expect(view.reducedMotion, isTrue);
    await tester.pump(const Duration(milliseconds: 2200));
    expect(popup, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    expect(popup, findsNothing);
    semantics.dispose();
    await close(tester, provider);
  });

  testWidgets('reset dismisses an active unlock and no stale badge returns',
      (tester) async {
    final provider = await mount(tester);
    await earnCvc(tester, provider);
    await waitForPopup(tester);
    await perform(tester, () async {
      await provider.parentAuth.setup('2580', '2580');
    });
    await perform(tester, provider.resetProgress);
    await tester.pump();
    expect(popup, findsNothing);
    await tester.pump(const Duration(seconds: 4));
    expect(popup, findsNothing);
    await close(tester, provider);
  });

  testWidgets(
      'parental time limit holds a queued celebration until learning resumes',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'voice': false,
      'sfx': false,
      'screenTimeDateV2': localDateKey(DateTime.now()),
      'screenTimeLimitEnabledV2': true,
      'screenTimeLimitMinutesV2': 15,
      'screenTimeUsedSecondsV2': 900,
    });
    final provider = await mount(tester);
    expect(provider.timeLimitReached, isTrue);
    await earnCvc(tester, provider);
    await tester.pump(const Duration(seconds: 4));
    expect(popup, findsNothing);
    expect(provider.pendingBadgeUnlocks, ['CVC Explorer']);
    await perform(tester, () async {
      await provider.parentAuth.setup('2580', '2580');
      await provider.screenTime.addExtraTime(10);
    });
    await waitForPopup(tester);
    expect(provider.timeLimitReached, isFalse);
    expect(find.text('CVC Explorer'), findsOneWidget);
    await close(tester, provider);
  });

  const previewBadge = ProgressBadge(
      id: 'First Mastery',
      title: 'First Letter Mastery',
      description: 'Master 1 letter in Quick Check.',
      current: 1,
      target: 1);
  for (final view in [
    (width: 320.0, scale: 1.0),
    (width: 390.0, scale: 1.0),
    (width: 800.0, scale: 1.0),
    (width: 320.0, scale: 2.5),
    (width: 320.0, scale: 3.25),
  ]) {
    testWidgets('3D badge fits ${view.width}, text ${view.scale}',
        (tester) async {
      await tester.binding.setSurfaceSize(Size(view.width, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const key = ValueKey('badge-preview');
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
        data: MediaQueryData(
            size: Size(view.width, 568),
            textScaler: TextScaler.linear(view.scale)),
        child: const RepaintBoundary(
          key: key,
          child: Scaffold(
              backgroundColor: Color(0xFFECE2FF),
              body: SafeArea(
                  child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Align(
                          alignment: Alignment.topCenter,
                          child: BadgeUnlockCelebration(
                              badge: previewBadge, progress: .46))))),
        ),
      )));
      for (var i = 0; i < 12; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)));
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
      final rect = tester.getRect(popup);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(view.width));
      expect(rect.bottom, lessThan(568));
      final boundary =
          tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
      await tester.runAsync(() async {
        final snapshot = await boundary.toImage(pixelRatio: 1);
        final bytes = await snapshot.toByteData(format: ui.ImageByteFormat.png);
        final directory = Directory('output/badge_unlock_preview');
        await directory.create(recursive: true);
        await File(
                '${directory.path}/${view.width.toInt()}-text-${view.scale}.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        snapshot.dispose();
      });
    });
  }
}
