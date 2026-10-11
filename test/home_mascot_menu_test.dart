import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/screens/home_screen.dart';
import 'package:kidsphonics/widgets/home_flight_menu.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all five supplied home mascots retain dimensions and transparency',
      () async {
    expect(homeMascotAssets.length, 5);
    for (final asset in homeMascotAssets.values) {
      final bytes = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      expect(frame.image.width, greaterThan(1000), reason: asset);
      expect(frame.image.height, greaterThan(1000), reason: asset);
      final rgba =
          await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect([
        for (var i = 3; i < rgba!.lengthInBytes; i += 4) rgba.getUint8(i)
      ], contains(0), reason: '$asset must retain transparency');
      frame.image.dispose();
      codec.dispose();
    }
  });

  testWidgets('gentle motion keeps buttons fixed and pauses when unavailable',
      (t) async {
    var reduced = false;
    var tickerEnabled = true;
    Future<void> render() => t.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: TickerMode(
                enabled: tickerEnabled,
                child: Center(
                    child: SizedBox(
                        width: 320,
                        child: HomeFlightMenu(
                            onLessons: () {},
                            onGames: () {},
                            onProgress: () {},
                            onParents: () {})))))));
    double y(String name) => t
        .widget<Transform>(find.byKey(ValueKey('home-$name-motion')))
        .transform
        .storage[13];
    List<double> positions() =>
        ['logo', ...homeMascotAssets.keys].map(y).toList();

    await render();
    await t.pump();
    final first = positions();
    final buttonRect = t.getRect(find.byKey(const ValueKey('home-lessons')));
    await t.pump(const Duration(milliseconds: 900));
    expect(positions(), isNot(first));
    for (final name in ['logo', ...homeMascotAssets.keys]) {
      expect(y(name).abs(), lessThanOrEqualTo(name == 'airplane' ? 5 : 3));
    }
    expect(t.getRect(find.byKey(const ValueKey('home-lessons'))), buttonRect);

    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    final background = positions();
    await t.pump(const Duration(seconds: 1));
    expect(positions(), background);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    await t.pump(const Duration(milliseconds: 900));
    expect(positions(), isNot(background));

    tickerEnabled = false;
    await render();
    final offRoute = positions();
    await t.pump(const Duration(seconds: 1));
    expect(positions(), offRoute);
    tickerEnabled = true;
    reduced = true;
    await render();
    await t.pumpAndSettle();
    expect(positions(), everyElement(0));
    await t.pump(const Duration(seconds: 2));
    expect(positions(), everyElement(0));
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  for (final scenario in [
    (size: const Size(320, 568), textScale: 1.0),
    (size: const Size(390, 844), textScale: 1.0),
    (size: const Size(430, 932), textScale: 1.0),
    (size: const Size(800, 600), textScale: 1.0),
    (size: const Size(320, 568), textScale: 2.0),
  ]) {
    final size = scenario.size;
    testWidgets('home sky path layout at $size, text ${scenario.textScale}',
        (t) async {
      await t.binding.setSurfaceSize(size);
      t.platformDispatcher.textScaleFactorTestValue = scenario.textScale;
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(() {
        t.binding.setSurfaceSize(null);
        t.platformDispatcher.clearTextScaleFactorTestValue();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      });
      await t.runAsync(() async {
        await (FontLoader('Nunito')
              ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
              ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf')))
            .load();
      });
      SharedPreferences.setMockInitialValues({});
      mockProgressAudio();
      final boundary = GlobalKey();
      final p = await mount(
          t, RepaintBoundary(key: boundary, child: const HomeScreen()));
      await t.pumpAndSettle();
      final airplane =
          t.getRect(find.byKey(const ValueKey('home-airplane-art')));
      final logo = t.getRect(find.byKey(const ValueKey('home-logo-art')));
      final lessons = t.getRect(find.byKey(const ValueKey('home-lessons')));
      final games = t.getRect(find.byKey(const ValueKey('home-games')));
      final progress = t.getRect(find.byKey(const ValueKey('home-progress')));
      final parents = t.getRect(find.byKey(const ValueKey('home-parents')));
      expect(logo.center.dy, lessThan(airplane.top));
      expect(airplane.center.dy, lessThan(lessons.center.dy));
      expect(airplane.center.dx, greaterThan(logo.center.dx));
      if (size.height >= 800 && scenario.textScale == 1) {
        final footer = t.getRect(find.byKey(const ValueKey('home-footer')));
        expect(footer.bottom, closeTo(size.height, 1));
        expect(parents.bottom, lessThanOrEqualTo(footer.top));
      }
      expect(lessons.top, lessThan(games.top));
      expect(games.top, lessThan(progress.top));
      expect(lessons.center.dx, lessThan(games.center.dx));
      expect(games.center.dx, lessThan(progress.center.dx));
      expect(parents.top, greaterThan(progress.bottom));
      expect(parents.center.dx, greaterThan(progress.center.dx));
      expect(lessons.width, greaterThan(games.width));
      expect(games.width, greaterThan(progress.width));
      expect(parents.width, lessThan(progress.width));
      expect(parents.width, greaterThanOrEqualTo(48));
      final stops = [lessons, games, progress, parents];
      for (var i = 0; i < stops.length; i++) {
        expect(stops[i].left, greaterThanOrEqualTo(0));
        expect(stops[i].right, lessThanOrEqualTo(size.width));
        for (var j = i + 1; j < stops.length; j++) {
          expect(stops[i].overlaps(stops[j]), isFalse,
              reason: 'Destination tap areas must not overlap');
        }
      }
      expect(find.byKey(const ValueKey('home-sky-path')), findsOneWidget);
      await t.ensureVisible(find.text('${p.streak} Day Streak'));
      await t.pumpAndSettle();
      expect(t.getRect(find.text('${p.streak} Day Streak')).bottom,
          lessThanOrEqualTo(size.height + 1));
      expect(find.text('Level ${p.level}'), findsOneWidget);
      expect(find.text('${p.xp} XP'), findsOneWidget);
      expect(find.text('${p.stars} Stars'), findsOneWidget);
      if (scenario.textScale == 1) {
        expect(t.getRect(find.text('${p.streak} Day Streak')).center.dy,
            closeTo(t.getRect(find.text('${p.xp} XP')).center.dy, 1));
      } else {
        expect(t.getRect(find.text('${p.streak} Day Streak')).top,
            greaterThan(t.getRect(find.text('${p.xp} XP')).bottom));
      }
      expect(t.takeException(), isNull);

      if (const bool.fromEnvironment('CAPTURE_UI') && scenario.textScale == 1) {
        await t.drag(find.byType(SingleChildScrollView), const Offset(0, 2000));
        await t.pumpAndSettle();
        await t.runAsync(() async {
          await (FontLoader('Nunito')
                ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
                ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf')))
              .load();
          await (FontLoader('MaterialIcons')
                ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
              .load();
          await Future.wait(t
              .widgetList<Image>(find.byType(Image))
              .map((w) => precacheImage(w.image, boundary.currentContext!)));
        });
        await t.pumpAndSettle();
        await t.runAsync(() async {
          final image = await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file =
              File('build/ui_previews/home_mascots_${size.width.toInt()}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await close(t, p);
    });
  }
}
