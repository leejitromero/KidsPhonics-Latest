import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/screens/home_screen.dart';
import 'package:kidsphonics/screens/progress_screen.dart';
import 'package:kidsphonics/screens/parent_screen.dart';
import 'package:kidsphonics/screens/settings_screen.dart';
import 'package:kidsphonics/screens/lessons_screen.dart';
import 'package:kidsphonics/widgets/category_navigation.dart';
import 'package:kidsphonics/widgets/kids_navigation_bar.dart';
import 'package:kidsphonics/widgets/main_navigation_scope.dart';
import 'package:kidsphonics/widgets/progress_journey_view.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'updated_scene_test.dart' show capture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // Match device text metrics even when screenshot capture is disabled.
    for (final (family, path) in [
      ('Fredoka', 'assets/fonts/Fredoka-Regular.ttf'),
      ('Nunito', 'assets/fonts/Nunito-Regular.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(path))).load();
    }
  });
  setUp(() {
    mockProgressAudio();
    SharedPreferences.setMockInitialValues({
      'voice': false,
      'studentName': 'Sam',
      'studentCharacter': 'boy',
      'xp': 212,
      'stars': 5
    });
  });

  void reduced(WidgetTester t) {
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  void expectSelection(WidgetTester t, KidsDestination selected) {
    expect(find.byType(KidsNavigationBar), findsOneWidget);
    expect(find.byType(CategoryNavigation), findsNothing);
    expect(t.widget<KidsNavigationBar>(find.byType(KidsNavigationBar)).current,
        selected);
    for (final tab in KidsDestination.values) {
      final image =
          t.widget<Image>(find.byKey(ValueKey('main-nav-${tab.name}-image')));
      expect(image.fit, BoxFit.contain);
      expect(
          ((image.image as ResizeImage).imageProvider as AssetImage).assetName,
          KidsNavigationArt.button(tab, glowing: tab == selected));
    }
  }

  Future<void> select(WidgetTester t, KidsDestination tab) async {
    await t.tap(find.byKey(ValueKey('main-nav-${tab.name}')));
    await t.pumpAndSettle();
    expectSelection(t, tab);
  }

  test('original ZIP PNGs remain unchanged; new base matches supplied frame',
      () async {
    final report = jsonDecode(File('tools/custom_navigation_assets.json')
        .readAsStringSync()
        .replaceFirst('\ufeff', '')) as List;
    expect(report, hasLength(9));
    final replacement = File(KidsNavigationArt.base).readAsBytesSync();
    expect(sha256.convert(replacement).toString(),
        '283395c567bae22dff665cd7613c08c2af8d5e75169f564c072c4fc1f2a23bc7');
    expect(report.map((entry) => entry['path']).toSet(), {
      ...KidsNavigationArt.assets
          .where((asset) => asset != KidsNavigationArt.base),
      'assets/images/custom_navigation/wooden frame.png'
    });
    for (final entry in report) {
      final bytes = File(entry['path'] as String).readAsBytesSync();
      expect(sha256.convert(bytes).toString().toUpperCase(), entry['sha256']);
      final codec = await ui.instantiateImageCodec(bytes);
      final image = (await codec.getNextFrame()).image;
      final base =
          entry['path'] == 'assets/images/custom_navigation/wooden frame.png';
      expect(image.width, base ? 2172 : 1254);
      expect(image.height, base ? 724 : 1254);
      final rgba =
          (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      expect(rgba.getUint8(3), lessThan(5));
      image.dispose();
      codec.dispose();
    }
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(430, 932),
    const Size(768, 1024),
    const Size(1024, 1366),
    const Size(1024, 768)
  ]) {
    testWidgets('one compact dock respects content and system insets at $size',
        (t) async {
      reduced(t);
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final key = GlobalKey();
      final p = await mount(
          t,
          Builder(
              builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                      padding: const EdgeInsets.only(top: 44, bottom: 24)),
                  child:
                      RepaintBoundary(key: key, child: const HomeScreen()))));
      await t.pumpAndSettle();
      expectSelection(t, KidsDestination.home);
      expect(t.getRect(find.byKey(const ValueKey('school-background'))),
          Offset.zero & size);
      final dock = t.getRect(find.byKey(const ValueKey('kids-navigation-bar')));
      expect(dock.bottom, lessThanOrEqualTo(size.height - 24));
      final rects = [
        for (final tab in KidsDestination.values)
          t.getRect(find.byKey(ValueKey('main-nav-${tab.name}')))
      ];
      for (var i = 0; i < rects.length; i++) {
        expect(rects[i].width, closeTo(rects.first.width, .001));
        expect(rects[i].height, closeTo(rects.first.height, .001));
        expect(rects[i].width, greaterThanOrEqualTo(48));
        expect(rects[i].height, greaterThanOrEqualTo(48));
        if (i > 0) expect(rects[i].left, greaterThan(rects[i - 1].right));
        expect(
            find
                .byKey(ValueKey('main-nav-${KidsDestination.values[i].name}'))
                .hitTestable(),
            findsOneWidget);
      }
      for (final key in [
        'home-lessons',
        'home-games',
        'home-start-adventure'
      ]) {
        final rect = t.getRect(find.byKey(ValueKey(key)));
        expect(rect.bottom, lessThan(dock.top));
        expect(find.byKey(ValueKey(key)).hitTestable(), findsOneWidget);
      }
      final base = t.widget<Image>(
          find.byKey(const ValueKey('kids-navigation-base-image')));
      expect(base.fit, BoxFit.fill);
      expect(base.centerSlice, isNotNull);
      final baseRect =
          t.getRect(find.byKey(const ValueKey('kids-navigation-base')));
      final sourceScale = baseRect.width / KidsNavigationArt.baseWidth;
      final frame = Rect.fromLTWH(
          baseRect.left,
          baseRect.top + KidsNavigationArt.frameTop * sourceScale,
          baseRect.width,
          dock.height);
      expect(frame.top, closeTo(dock.top, .001));
      expect(frame.bottom, closeTo(dock.bottom, .001));
      // Entire button targets, including the active glow, sit inside the frame.
      for (final rect in rects) {
        expect(frame.contains(rect.topLeft), true);
        expect(frame.contains(rect.bottomRight), true);
      }
      if ([390.0, 768.0].contains(size.width)) {
        await capture(t, key, 'custom_navigation_${size.width.toInt()}');
      }
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }

  testWidgets('tabs retain screen state, PIN protection, and all learner data',
      (t) async {
    reduced(t);
    final p = await mount(t, const HomeScreen());
    final homeState = t.state(find.byType(HomeScreen));
    await select(t, KidsDestination.progress);
    expect(find.byType(ProgressScreen), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('progress-tab-1')));
    await t.pumpAndSettle();
    final progressState = t.state(find.byType(ProgressJourneyView));
    await select(t, KidsDestination.parents);
    expect(find.text('Set Up Parent PIN'), findsOneWidget);
    await t.runAsync(() => p.parentAuth.setup('2580', '2580'));
    await t.pumpAndSettle();
    final parentState = t.state(find.byType(ParentScreen));
    await t.tap(find.byKey(const ValueKey('parent-tab-1')));
    await t.pumpAndSettle();
    await select(t, KidsDestination.settings);
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(p.parentAuth.isAuthenticated, false);
    expect(find.text('Sound & Music'), findsOneWidget);
    expect(find.byKey(const ValueKey('parent-tab-2')), findsNothing);
    await select(t, KidsDestination.progress);
    expect(p.parentAuth.isAuthenticated, false);
    expect(t.state(find.byType(ProgressJourneyView)), same(progressState));
    final letterTab = find
        .ancestor(
            of: find.byKey(const ValueKey('progress-tab-1')),
            matching: find.byType(Semantics))
        .first;
    expect(t.widget<Semantics>(letterTab).properties.selected, true);
    await select(t, KidsDestination.parents);
    expect(find.text('Parent Access'), findsOneWidget);
    p.parentAuth.unlock('2580');
    await t.pumpAndSettle();
    expect(t.state(find.byType(ParentScreen)), same(parentState));
    await select(t, KidsDestination.home);
    expect(p.parentAuth.isAuthenticated, false);
    expect(t.state(find.byType(HomeScreen)), same(homeState));
    expect((p.studentCharacter, p.studentName, p.xp, p.stars),
        ('boy', 'Sam', 212, 5));
    expect(t.takeException(), isNull);
    await close(t, p);
  });

  testWidgets('press returns from .95 before one 250ms page fade', (t) async {
    final p = await mount(t, const HomeScreen());
    await t.tap(find.byKey(const ValueKey('main-nav-progress')));
    await t.pump();
    expect(
        t
            .widget<AnimatedScale>(
                find.byKey(const ValueKey('main-nav-progress-scale')))
            .scale,
        .95);
    await t.tap(find.byKey(const ValueKey('main-nav-parents')));
    await t.pump(const Duration(milliseconds: 85));
    expect(
        t
            .widget<AnimatedScale>(
                find.byKey(const ValueKey('main-nav-progress-scale')))
            .scale,
        1);
    await t.pump(const Duration(milliseconds: 85));
    await t.pump();
    expectSelection(t, KidsDestination.progress);
    await t.pump(const Duration(milliseconds: 100));
    expect(find.byType(KidsNavigationBar), findsOneWidget);
    expect(find.byType(ParentScreen), findsNothing);
    await t.pump(const Duration(milliseconds: 151));
    expect(find.byType(ProgressScreen), findsOneWidget);
    expect(find.byType(KidsNavigationBar), findsOneWidget);
    expect(t.takeException(), isNull);
    await close(t, p);
  });

  testWidgets('Lessons footer returns to retained tabs and Back opens Home',
      (t) async {
    reduced(t);
    final p = await mount(t, const HomeScreen());
    await select(t, KidsDestination.progress);
    final progressState = t.state(find.byType(ProgressJourneyView));
    await select(t, KidsDestination.home);
    await t.tap(find.byKey(const ValueKey('home-lessons')));
    await t.pumpAndSettle();
    expect(find.byType(LessonsScreen), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('main-nav-progress')));
    await t.pumpAndSettle();
    expectSelection(t, KidsDestination.progress);
    expect(t.state(find.byType(ProgressJourneyView)), same(progressState));
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expectSelection(t, KidsDestination.home);
    expect(t.takeException(), isNull);
    await close(t, p);
  });
}
