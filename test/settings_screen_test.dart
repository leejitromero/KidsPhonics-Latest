import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/updated_scene.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/home_screen.dart';
import 'package:kidsphonics/screens/settings_screen.dart';
import 'package:kidsphonics/screens/welcome_screen.dart';
import 'package:kidsphonics/services/app_build_info.dart';
import 'package:kidsphonics/widgets/app_display_preferences.dart';
import 'package:kidsphonics/widgets/kids_navigation_bar.dart';
import 'package:kidsphonics/widgets/scene_dialogue.dart';
import 'package:kidsphonics/widgets/home_guideline_dialog.dart';
import 'package:kidsphonics/widgets/student_character_picker.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show close;
import 'updated_scene_test.dart' show capture;
import 'save_recovery_test.dart' show FailingStore;
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const appInfoChannel = MethodChannel('kidsphonics/app_info');
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    mockProgressAudio();
    SharedPreferences.setMockInitialValues({
      'voice': false,
      'musicEnabled': false,
      'studentName': 'Sam',
      'studentCharacter': 'boy',
      'welcomeCompletedV1': true,
      'xp': 215,
      'stars': 7,
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            appInfoChannel, (_) async => {'version': '2.4.6', 'build': '57'});
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(appInfoChannel, null);
  });

  Future<AppProvider> open(WidgetTester t,
      {Widget page = const SettingsScreen(),
      GlobalKey? boundary,
      GlobalKey? overlayBoundary,
      double systemScale = 1}) async {
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    late AppProvider p;
    await t.runAsync(() async {
      p = AppProvider();
      await p.ready;
    });
    await t.pumpWidget(ChangeNotifierProvider.value(
        value: p,
        child: MaterialApp(
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(systemScale),
                    padding: const EdgeInsets.only(top: 24, bottom: 24)),
                child: RepaintBoundary(
                    key: overlayBoundary,
                    child: AppDisplayPreferences(child: child!))),
            home: RepaintBoundary(key: boundary, child: page))));
    await t.pumpAndSettle();
    return p;
  }

  Future<void> reveal(WidgetTester t, Key key) async {
    final scroll = find.byType(Scrollable).first;
    t.state<ScrollableState>(scroll).position.jumpTo(0);
    await t.pump();
    final position = t.state<ScrollableState>(scroll).position;
    for (var attempt = 0;
        attempt < 200 && find.byKey(key).evaluate().isEmpty;
        attempt++) {
      position
          .jumpTo((position.pixels + 100).clamp(0, position.maxScrollExtent));
      await t.pump();
    }
    expect(find.byKey(key), findsOneWidget, reason: 'Scroll to $key');
    await Scrollable.ensureVisible(t.element(find.byKey(key)), alignment: .5);
    await t.pumpAndSettle();
  }

  test('display and audio saves preserve mastery and restore from one snapshot',
      () async {
    final p = AppProvider();
    await p.ready;
    await p.completeAdventure('A', List.filled(5, true), 'settings-mastered-a');
    final progress = (
      p.xp,
      p.stars,
      p.streak,
      p.adventureAssessments,
      p.adventureProgress('A').mastered,
      p.recommendedAdventureLetter
    );
    await Future.wait([
      p.setTextSizeMultiplier(1.3),
      p.setReducedAnimations(true),
      p.toggleVoice(),
      p.toggleSfx(),
      p.toggleMusic(),
      p.setMusicVolume(.24),
    ]);
    expect(p.parentAuth.isAuthenticated, false);
    final restored = AppProvider();
    await restored.ready;
    expect(restored.textSizeMultiplier, 1.3);
    expect(restored.reducedAnimations, true);
    expect(restored.voiceEnabled, true);
    expect(restored.sfxEnabled, false);
    expect(restored.musicEnabled, true);
    expect(restored.musicVolume, .24);
    expect((
      restored.xp,
      restored.stars,
      restored.streak,
      restored.adventureAssessments,
      restored.adventureProgress('A').mastered,
      restored.recommendedAdventureLetter
    ), progress);
    expect((
      restored.studentName,
      restored.studentCharacter,
      restored.welcomeCompleted
    ), (
      'Sam',
      'boy',
      true
    ));
    await restored.setTextSizeMultiplier(double.nan);
    expect(restored.textSizeMultiplier, 1.3);
    await restored.parentAuth.setup('2580', '2580');
    await restored.resetProgress();
    expect(restored.textSizeMultiplier, 1.3);
    expect(restored.reducedAnimations, true);
    p.dispose();
    restored.dispose();
  });

  test('failed display save retries and keeps the latest preferences',
      () async {
    final store = FailingStore();
    SharedPreferencesStorePlatform.instance = store;
    final p = AppProvider();
    await p.ready;
    store.failKey = 'appStateV1';
    store.failures = 3;
    await p.setTextSizeMultiplier(1.15);
    expect(p.hasUnsavedChanges, true);
    await p.setReducedAnimations(true);
    expect(p.hasUnsavedChanges, false);
    final restored = AppProvider();
    await restored.ready;
    expect(restored.textSizeMultiplier, 1.15);
    expect(restored.reducedAnimations, true);
    p.dispose();
    restored.dispose();
  });

  test('About reads the installed version and handles unavailable native info',
      () async {
    expect((await AppBuildInfo.load()).label, 'Version 2.4.6 (build 57)');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(appInfoChannel,
            (_) async => throw PlatformException(code: 'unavailable'));
    expect((await AppBuildInfo.load()).version, isNull);
  });

  testWidgets(
      'display preferences preserve nonlinear scaling and system motion choices',
      (t) async {
    late AppProvider p;
    await t.runAsync(() async {
      p = AppProvider();
      await p.ready;
    });
    late MediaQueryData actual;
    Future<void> render(bool systemReduced) async {
      await t.pumpWidget(ChangeNotifierProvider.value(
          value: p,
          child: MediaQuery(
              data: MediaQueryData(
                  textScaler: const _NonlinearScale(),
                  disableAnimations: systemReduced),
              child: AppDisplayPreferences(child: Builder(builder: (context) {
                actual = MediaQuery.of(context);
                return const SizedBox();
              })))));
      await t.pump();
    }

    await render(false);
    expect(actual.disableAnimations, false);
    await t.runAsync(() async {
      await p.setTextSizeMultiplier(1.3);
      await p.setReducedAnimations(true);
    });
    await t.pump();
    expect(actual.disableAnimations, true);
    expect(actual.textScaler.scale(16), closeTo(16 * 1.8 * 1.3, .001));
    expect(actual.textScaler.scale(32), closeTo(32 * 1.4 * 1.3, .001));
    await t.runAsync(() => p.setReducedAnimations(false));
    await t.pump();
    expect(actual.disableAnimations, false);
    await render(true);
    expect(actual.disableAnimations, true);
    await close(t, p);
  });

  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(390, 844), 1.0),
    (const Size(768, 1024), 1.0),
    (const Size(844, 390), 1.0),
    (const Size(320, 568), 2.5),
  ]) {
    testWidgets('Settings fits $size at system text $scale without a PIN',
        (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final key = GlobalKey();
      final p = await open(t, boundary: key, systemScale: scale);
      expect(find.text('Set Up Parent PIN'), findsNothing);
      await reveal(t, const PageStorageKey('settings-sound'));
      expect(find.text('Sound & Music'), findsOneWidget);
      expect(find.byType(KidsNavigationBar), findsOneWidget);
      expect(p.parentAuth.isAuthenticated, false);
      if (scale == 1 && [390.0, 768.0].contains(size.width)) {
        await capture(t, key, 'settings_${size.width.toInt()}');
      }
      await t.tap(find.text('Sound & Music'));
      await t.pumpAndSettle();
      await Scrollable.ensureVisible(
          t.element(find.byKey(const PageStorageKey('settings-sound'))),
          alignment: 0);
      await t.pumpAndSettle();
      if (scale == 1 && [390.0, 768.0].contains(size.width)) {
        await capture(t, key, 'settings_sound_${size.width.toInt()}');
      }
      for (final control in [
        'settings-voice',
        'settings-sfx',
        'settings-music',
        'settings-music-volume'
      ]) {
        await reveal(t, ValueKey(control));
        expect(t.takeException(), isNull, reason: 'Expanded sound: $control');
      }
      expect(
          t
              .widget<Slider>(
                  find.byKey(const ValueKey('settings-music-volume')))
              .onChanged,
          isNull,
          reason: 'Volume remains disabled when music is off');
      await reveal(t, const PageStorageKey('settings-sound'));
      await Scrollable.ensureVisible(t.element(find.text('Sound & Music')),
          alignment: .3);
      await t.pumpAndSettle();
      expect(find.text('Sound & Music').hitTestable(), findsOneWidget);
      await t.tap(find.text('Sound & Music'));
      await t.pumpAndSettle();
      await reveal(t, const PageStorageKey('settings-display'));
      await Scrollable.ensureVisible(
          t.element(find.text('Display & Animations')),
          alignment: .5);
      await t.pumpAndSettle();
      await t.tap(find.text('Display & Animations'));
      await t.pumpAndSettle();
      await Scrollable.ensureVisible(
          t.element(find.byKey(const PageStorageKey('settings-display'))),
          alignment: 0);
      await t.pumpAndSettle();
      if (scale == 1 && [390.0, 768.0].contains(size.width)) {
        await capture(t, key, 'settings_display_${size.width.toInt()}');
      }
      await reveal(t, const ValueKey('settings-text-size-1.3'));
      await t.runAsync(() async {
        await t.tap(find.byKey(const ValueKey('settings-text-size-1.3')));
        await p.retrySaving();
      });
      await t.pumpAndSettle();
      expect(p.textSizeMultiplier, 1.3);
      final preview =
          t.element(find.byKey(const ValueKey('settings-text-preview')));
      expect(MediaQuery.textScalerOf(preview).scale(16),
          closeTo(16 * scale * 1.3, .001));
      await reveal(t, const ValueKey('settings-reduced-animations'));
      final reducedSwitch = find.descendant(
          of: find.byKey(const ValueKey('settings-reduced-animations')),
          matching: find.byType(Switch));
      await Scrollable.ensureVisible(t.element(reducedSwitch), alignment: .5);
      await t.pumpAndSettle();
      await t.runAsync(() async {
        await t.tap(reducedSwitch);
        await p.retrySaving();
      });
      await t.pumpAndSettle();
      expect(p.reducedAnimations, true);
      for (final key in [
        'settings-character',
        'settings-introduction',
        'settings-help',
        'settings-about',
        'settings-parent-controls'
      ]) {
        await reveal(t, ValueKey(key));
        expect(find.byKey(ValueKey(key)).hitTestable(), findsOneWidget);
        expect(t.takeException(), isNull, reason: key);
      }
      expect((p.xp, p.stars, p.studentName), (215, 7, 'Sam'));
      await close(t, p);
    });
  }

  testWidgets('audio controls save and character editing preserves learning',
      (t) async {
    final p = await open(t);
    await t.tap(find.text('Sound & Music'));
    await t.pumpAndSettle();
    await reveal(t, const ValueKey('settings-music'));
    await t.runAsync(() async {
      await t.tap(find.byKey(const ValueKey('settings-music')));
      await p.retrySaving();
    });
    await t.pumpAndSettle();
    expect(p.musicEnabled, true);
    final slider =
        t.widget<Slider>(find.byKey(const ValueKey('settings-music-volume')));
    await t.runAsync(() async {
      slider.onChanged!(.3);
      await p.retrySaving();
    });
    expect(p.musicVolume, .3);
    await reveal(t, const ValueKey('settings-sfx'));
    await t.runAsync(() async {
      await t.tap(find.byKey(const ValueKey('settings-sfx')));
      await p.retrySaving();
    });
    await t.pumpAndSettle();
    expect(p.sfxEnabled, false);
    await reveal(t, const ValueKey('settings-character'));
    await t.tap(find.byKey(const ValueKey('settings-character')));
    await t.pumpAndSettle();
    expect(find.byType(StudentCharacterPicker), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('choose-girl')));
    await t.enterText(find.byType(TextField), 'Mia');
    await t.runAsync(() async {
      await t.tap(find.byKey(const ValueKey('save-student')));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await t.pumpAndSettle();
    expect((p.studentCharacter, p.studentName, p.xp, p.stars),
        ('girl', 'Mia', 215, 7));
    expect(p.welcomeCompleted, true);
    expect(t.takeException(), isNull);
    await close(t, p);
  });

  for (final finish in [false, true]) {
    testWidgets(
        'replayed introduction ${finish ? 'finishes' : 'skips'} back to retained Settings',
        (t) async {
      final p = await open(t, page: const HomeScreen());
      await t.tap(find.byKey(const ValueKey('main-nav-settings')));
      await t.pumpAndSettle();
      final state = t.state(find.byType(SettingsScreen));
      final prefs = await SharedPreferences.getInstance();
      final before = jsonDecode(prefs.getString('appStateV1') ?? '{}');
      await reveal(t, const ValueKey('settings-introduction'));
      await t.tap(find.byKey(const ValueKey('settings-introduction')));
      await t.pumpAndSettle();
      expect(t.widget<WelcomeScreen>(find.byType(WelcomeScreen)).replay, true);
      if (finish) {
        await t.pump(const Duration(milliseconds: 1500));
        for (var step = 0; step < homeIntroduction.length - 1; step++) {
          expect(t.widget<SceneDialogue>(find.byType(SceneDialogue)).text,
              homeIntroduction[step].text);
          expect(find.byType(StudentCharacterPicker), findsNothing);
          await t.tap(find.byKey(const ValueKey('welcome-next')));
          await t.pump(const Duration(milliseconds: 200));
          await t.pump();
        }
      } else {
        await t.tap(find.byKey(const ValueKey('welcome-skip')));
      }
      await t.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsNothing);
      expect(t.state(find.byType(SettingsScreen)), same(state));
      expect(jsonDecode(prefs.getString('appStateV1') ?? '{}'), before);
      expect((p.xp, p.stars, p.studentName, p.welcomeCompleted),
          (215, 7, 'Sam', true));
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }

  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(390, 844), 1.0),
    (const Size(844, 390), 1.0),
    (const Size(320, 568), 2.5),
  ]) {
    testWidgets('Help reference and both guides fit $size at text $scale',
        (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final boundary = GlobalKey();
      final p = await open(t, systemScale: scale, overlayBoundary: boundary);
      await reveal(t, const ValueKey('settings-help'));
      await t.tap(find.byKey(const ValueKey('settings-help')));
      await t.pumpAndSettle();
      expect(
          find.byKey(const ValueKey('settings-help-dialog')), findsOneWidget);
      if (size.width == 390 && scale == 1) {
        await capture(t, boundary, 'settings_help_reference');
      }
      for (final games in [false, true]) {
        final button = find
            .byKey(ValueKey('settings-${games ? 'games' : 'lessons'}-guide'));
        await Scrollable.ensureVisible(t.element(button), alignment: .5);
        await t.pumpAndSettle();
        await t.tap(button);
        await t.pumpAndSettle();
        expect(
            t
                .widget<HomeGuidelineDialog>(find.byType(HomeGuidelineDialog))
                .settingsReference,
            true);
        expect(t.widget<SceneDialogue>(find.byType(SceneDialogue)).text,
            homeIntroduction[games ? 7 : 2].text);
        if (size.width == 390 && scale == 1) {
          await capture(
              t, boundary, 'settings_guide_${games ? 'games' : 'lessons'}');
        }
        final next = find.byKey(const ValueKey('settings-guide-next'));
        await Scrollable.ensureVisible(t.element(next), alignment: .5);
        await t.pumpAndSettle();
        await t.tap(next);
        await t.pumpAndSettle();
        expect(t.widget<SceneDialogue>(find.byType(SceneDialogue)).text,
            homeIntroduction[games ? 8 : 3].text);
        await Scrollable.ensureVisible(t.element(next), alignment: .5);
        await t.pumpAndSettle();
        await t.tap(next);
        await t.pumpAndSettle();
        expect(find.byType(HomeGuidelineDialog), findsNothing);
        expect(
            find.byKey(const ValueKey('settings-help-dialog')), findsOneWidget);
        await Scrollable.ensureVisible(t.element(button), alignment: .5);
        await t.pumpAndSettle();
        await t.tap(button);
        await t.pumpAndSettle();
        final skip = find.byKey(const ValueKey('settings-guide-skip'));
        await Scrollable.ensureVisible(t.element(skip), alignment: .5);
        await t.pumpAndSettle();
        await t.tap(skip);
        await t.pumpAndSettle();
        expect(find.byType(HomeGuidelineDialog), findsNothing);
        expect(t.takeException(), isNull);
      }
      final device = find.byKey(const ValueKey('settings-microphone-help'));
      await Scrollable.ensureVisible(t.element(device), alignment: .5);
      await t.pumpAndSettle();
      expect(device.hitTestable(), findsOneWidget);
      await t.tap(find.text('Close'));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('settings-help-dialog')), findsNothing);
      expect((p.xp, p.stars, p.studentName, p.welcomeCompleted),
          (215, 7, 'Sam', true));
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }

  testWidgets(
      'Help and About show usable guides and the actual package version',
      (t) async {
    final p = await open(t);
    await reveal(t, const ValueKey('settings-help'));
    await t.tap(find.byKey(const ValueKey('settings-help')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-help-dialog')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('settings-lessons-guide')), findsOneWidget);
    await t.tap(find.text('Close'));
    await t.pumpAndSettle();
    await reveal(t, const ValueKey('settings-about'));
    await t.tap(find.byKey(const ValueKey('settings-about')));
    await t.pumpAndSettle();
    expect(find.text('Version 2.4.6 (build 57)'), findsOneWidget);
    expect(find.text('Credits'), findsOneWidget);
    await t.tap(find.text('Close'));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    await close(t, p);
  });

  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(390, 844), 1.0),
    (const Size(768, 1024), 1.0),
    (const Size(844, 390), 1.0),
    (const Size(320, 568), 2.5),
  ]) {
    testWidgets('Simple About fits $size at text $scale and opens licenses',
        (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final boundary = GlobalKey();
      final p = await open(t, systemScale: scale, overlayBoundary: boundary);
      await reveal(t, const ValueKey('settings-about'));
      await t.tap(find.byKey(const ValueKey('settings-about')));
      await t.pumpAndSettle();
      expect(find.text('Version 2.4.6 (build 57)'), findsOneWidget);
      expect(find.text('Your saved learning'), findsOneWidget);
      expect(find.text('Speech activities'), findsOneWidget);
      expect(find.text('Credits'), findsOneWidget);
      final about = find.byKey(const ValueKey('settings-about-dialog'));
      expect(
          find.descendant(of: about, matching: find.byIcon(Icons.eco_rounded)),
          findsNothing);
      expect(find.text('Close').hitTestable(), findsOneWidget);
      expect(t.takeException(), isNull);
      if (scale == 1 && [390.0, 768.0].contains(size.width)) {
        await capture(t, boundary, 'settings_about_${size.width.toInt()}');
      }
      final licenses = find.byKey(const ValueKey('settings-about-licenses'));
      await Scrollable.ensureVisible(t.element(licenses), alignment: .5);
      await t.pumpAndSettle();
      await t.tap(licenses);
      await t.pumpAndSettle();
      expect(find.byType(LicensePage), findsOneWidget);
      Navigator.of(t.element(find.byType(LicensePage))).pop();
      await t.pumpAndSettle();
      expect(about, findsOneWidget);
      await t.tap(find.byTooltip('Close About'));
      await t.pumpAndSettle();
      expect(about, findsNothing);
      expect((p.xp, p.stars, p.studentName, p.welcomeCompleted),
          (215, 7, 'Sam', true));
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }
}

class _NonlinearScale extends TextScaler {
  const _NonlinearScale();
  @override
  double scale(double fontSize) => fontSize * (fontSize <= 20 ? 1.8 : 1.4);
  @override
  double get textScaleFactor => 1.8;
}
