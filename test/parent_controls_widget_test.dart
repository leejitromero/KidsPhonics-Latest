import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/parent_screen.dart';
import 'package:kidsphonics/screens/games_screen.dart';
import 'package:kidsphonics/widgets/time_limit_overlay.dart';
import 'learning_progress_test.dart' show mockProgressAudio;

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    mockProgressAudio();
  });
  Future<AppProvider> make(WidgetTester tester, {bool blocked = false}) async {
    SharedPreferences.setMockInitialValues({
      'screenTimeDateV2': '2026-09-23',
      'screenTimeUsedSecondsV2': blocked ? 1800 : 0,
      'screenTimeLimitEnabledV2': true,
    });
    late AppProvider p;
    await tester.runAsync(() async {
      p = AppProvider(now: () => DateTime(2026, 9, 23, 12));
      await p.ready;
    });
    return p;
  }

  Widget app(AppProvider p, Widget child) => ChangeNotifierProvider.value(
        value: p,
        child: MaterialApp(
            builder: (_, child) => TimeLimitOverlay(child: child!),
            home: child),
      );
  Future<void> finish(WidgetTester tester, AppProvider p) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    p.dispose();
  }

  testWidgets('first parent visit requires matching PIN before controls appear',
      (tester) async {
    final p = await make(tester);
    await tester.pumpWidget(app(p, const ParentScreen()));
    await tester.pump();
    expect(find.text('Set Up Parent PIN'), findsOneWidget);
    expect(find.text('Daily Time Limit'), findsNothing);
    await tester.enterText(find.byType(TextField).at(0), '2580');
    await tester.enterText(find.byType(TextField).at(1), '2581');
    await tester.tap(find.text('Set PIN'));
    await tester.pump();
    expect(find.text('PINs do not match.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), '2580');
    await tester.enterText(find.byType(TextField).at(1), '2580');
    await tester.runAsync(() async {
      await tester.tap(find.text('Set PIN'));
    });
    await tester.pump();
    expect(find.text('Child Learning Summary'), findsOneWidget);
    expect(p.parentAuth.isAuthenticated, isTrue);
    await finish(tester, p);
  });
  testWidgets(
      'limit covers pushed routes and back; wrong PIN remains blocked; correct PIN grants extra',
      (tester) async {
    final p = await make(tester, blocked: true);
    await tester.runAsync(() async {
      await p.parentAuth.setup('2580', '2580');
      p.parentAuth.endSession();
      await p.screenTime.save();
    });
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: p,
        child: MaterialApp(
            navigatorKey: nav,
            builder: (_, child) => TimeLimitOverlay(child: child!),
            home: const Scaffold(body: Text('Learner Home')))));
    await tester.pump();
    nav.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Deep Lesson'))));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Learning Time Is Finished for Today'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Learning Time Is Finished for Today'), findsOneWidget);
    await tester.tap(find.text('Parent Unlock'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '9876');
    await tester.tap(find.text('Unlock'));
    await tester.pump();
    expect(find.text('Incorrect PIN. Try again.'), findsOneWidget);
    expect(find.text('Add 15 Minutes'), findsNothing);
    await tester.enterText(find.byType(TextField), '2580');
    await tester.tap(find.text('Unlock'));
    await tester.pump();
    expect(find.text('Add 15 Minutes'), findsOneWidget);
    await tester.tap(find.text('Add 15 Minutes'));
    for (var i = 0; i < 100 && p.parentAuth.isAuthenticated; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
    await tester.pump();
    expect(p.screenTime.allowedSecondsToday, 2700);
    expect(p.screenTime.isLimitReached, isFalse);
    expect(p.parentAuth.isAuthenticated, isFalse);
    expect(find.text('Learning Time Is Finished for Today'), findsNothing);
    await finish(tester, p);
  });
  testWidgets('parent session expires after background and on route exit',
      (tester) async {
    final p = await make(tester);
    await tester.runAsync(() => p.parentAuth.setup('2580', '2580'));
    await tester.pumpWidget(app(p, const ParentScreen()));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 61));
    expect(p.parentAuth.isAuthenticated, isFalse);
    expect(p.screenTime.usedSecondsToday, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('Parent Access'), findsOneWidget);
    p.parentAuth.unlock('2580');
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(p.parentAuth.isAuthenticated, isFalse);
    p.dispose();
  });
  testWidgets('direct Games route honors game preference', (tester) async {
    final p = await make(tester);
    await tester.runAsync(() async {
      await p.parentAuth.setup('2580', '2580');
      await p.toggleGameAccess();
      p.parentAuth.endSession();
    });
    await tester.pumpWidget(app(p, const GamesScreen()));
    await tester.pump();
    expect(find.text('Games are turned off by a parent.'), findsOneWidget);
    expect(find.text('Sound Match'), findsNothing);
    await finish(tester, p);
  });
}
